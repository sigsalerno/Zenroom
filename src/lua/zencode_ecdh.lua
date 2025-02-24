--[[
--This file is part of zenroom
--
--Copyright (C) 2018-2021 Dyne.org foundation
--designed, written and maintained by Denis Roio <jaromil@dyne.org>
--
--This program is free software: you can redistribute it and/or modify
--it under the terms of the GNU Affero General Public License v3.0
--
--This program is distributed in the hope that it will be useful,
--but WITHOUT ANY WARRANTY; without even the implied warranty of
--MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
--GNU Affero General Public License for more details.
--
--Along with this program you should have received a copy of the
--GNU Affero General Public License v3.0
--If not, see http://www.gnu.org/licenses/agpl.txt
--
--Last modified by Denis Roio
--on Saturday, 4th September 2021
--]]

-- defined outside because reused across different schemas
local function public_key_f(o)
	local res = CONF.input.encoding.fun(o)
	ZEN.assert(
		ECDH.pubcheck(res),
		'Public key is not a valid point on curve'
	)
	return res
end

local function warn_keypair()
   warn("Use of 'keypair' is deprecated in favor of 'keyring'")
   warn("Examples: I have my 'keyring' or I create the keyring")
end

ZEN.add_schema(
	{
		-- keypair (ECDH)
		public_key = public_key_f,
		ecdh_public_key = public_key_f,
		keypair = function(obj)
			local pub = public_key_f(obj.public_key)
			local sec = ZEN.get(obj, 'private_key')
			ZEN.assert(
				pub == ECDH.pubgen(sec),
				'Public key does not belong to secret key in keypair'
			)
			warn_keypair()
			return {
				public_key = pub,
				private_key = sec
			}
		end,
		secret_message = function(obj)
			return {
				checksum = ZEN.get(obj, 'checksum'),
				header = ZEN.get(obj, 'header'),
				iv = ZEN.get(obj, 'iv'),
				text = ZEN.get(obj, 'text')
			}
		end,
		signature = function(obj)
			return {
				r = ZEN.get(obj, 'r'),
				s = ZEN.get(obj, 's')
			}
		end
	}
)

-- generate keypair
local function f_keygen()
	empty'keypair'
	local kp = ECDH.keygen()
	ACK.keypair = {
		public_key = kp.public,
		private_key = kp.private
	}
	new_codec('keypair', { zentype = 'schema' })
	warn_keypair()
end
When('create the keypair', f_keygen)

When(
	"create the ecdh key",
	function()
		initkeys'ecdh'
		ACK.keys.ecdh = ECDH.keygen().private
	end
)
When(
	"create the ecdh public key",
	function()
		empty'ecdh public key'
		local sk = havekey'ecdh'
		ACK.ecdh_public_key = ECDH.pubgen(sk)
	end
)
When(
	"create the ecdh key with secret key ''",
	function(sec)
		local sk = have(sec)
		initkeys'ecdh'
		ECDH.pubgen(sk)
		ACK.keys.ecdh = sk
	end
)

When(
	"create the keypair with secret key ''",
	function(sec)
		local sk = have(sec)
		empty'keypair'
		local pub = ECDH.pubgen(sk)
		ACK.keypair = {
			public_key = pub,
			private_key = sk
		}
		warn_keypair()
	end
)

-- encrypt with a header and secret
When(
	"encrypt the secret message '' with ''",
	function(msg, sec)
		local text = have(msg)
		local sk = have(sec)
		empty'secret message'
		-- KDF2 sha256 on all secrets
		local secret = KDF(sk)
		ACK.secret_message = {
			header = ACK.header or OCTET.from_string('DefaultHeader'),
			iv = O.random(32)
		}
		ACK.secret_message.text, ACK.secret_message.checksum =
			ECDH.aead_encrypt(
			secret,
			text,
			ACK.secret_message.iv,
			ACK.secret_message.header
		)
		new_codec('secret message', { zentype = 'dictionary' })
	end
)

-- decrypt with a secret
When(
	"decrypt the text of '' with ''",
	function(msg, sec)
		local sk = have(sec)
		local text = have(msg)
		empty'text'
		empty'checksum'
		local secret = KDF(sk)
		-- KDF2 sha256 on all secrets, this way the
		-- secret is always 256 bits, safe for direct aead_decrypt
		ACK.text, ACK.checksum =
			ECDH.aead_decrypt(
			secret,
			text.text,
			text.iv,
			text.header
		)
		ZEN.assert(
			ACK.checksum == text.checksum,
			'Decryption error: authentication failure, checksum mismatch'
		)
	end
)

local function _havekey_compat()
   initkeys()
   local sk = ACK.keys.ecdh
   if sk then
      return sk
   else
      local kp = have'keypair'
      if not kp then goto fail else
	 warn_keypair()
      end
      sk = kp.private_key
      if not sk then goto fail end
      return sk
   end
   ::fail::
   ZEN.assert(sk, "ECDH Private key not found anywhere in keyring or keypair")
end

-- check various locations to find the public key
local function _pubkey_compat(_key)
	local pubkey = ACK[_key]
	if not pubkey then
		local pubkey_arr
		pubkey_arr = ACK.public_key or ACK.public_key_session or ACK.ecdh_public_key
		if luatype(pubkey_arr) == 'table' then
		   pubkey = pubkey_arr[_key]
		else
		   pubkey = pubkey_arr
		end
		ZEN.assert(pubkey, 'Public key not found for: ' .. _key)
	end
	return pubkey
end

-- encrypt to a single public key
When(
	"encrypt the secret message of '' for ''",
	function(msg, _key)
		local sk = _havekey_compat()
		have(msg)
		local pk = _pubkey_compat(_key)
		empty'secret message'
		local key = ECDH.session(sk, pk)
		ACK.secret_message = {
			header = ACK.header or OCTET.from_string('DefaultHeader'),
			iv = O.random(32)
		}
		ACK.secret_message.text, ACK.secret_message.checksum =
			ECDH.aead_encrypt(
			key,
			ACK[msg],
			ACK.secret_message.iv,
			ACK.secret_message.header
		)
		new_codec('secret message', { zentype = 'dictionary' })
	end
)

When(
	"decrypt the text of '' from ''",
	function(secret, _key)
		local sk = _havekey_compat()
		have(secret)
		local pk = _pubkey_compat(_key)
		local message = ACK[secret][_key] or ACK[secret]
		local session = ECDH.session(sk, pk)
		local checksum
		ACK.text, checksum =
			ECDH.aead_decrypt(session, message.text, message.iv, message.header)
		ZEN.assert(
			checksum == message.checksum,
			'Failed verification of integrity for secret message'
		)
	end
)

-- sign a message and verify
When(
   "create the signature of ''",
   function(doc)
      local sk = _havekey_compat()
      empty'signature'
      local obj = have(doc)
      ACK.signature = ECDH.sign(sk, ZEN.serialize(obj))
      ZEN.CODEC.signature = CONF.output.encoding.name
   end
)

IfWhen(
	"verify the '' has a signature in '' by ''",
	function(msg, sig, by)
	        local pk = _pubkey_compat(by)
		local obj = have(msg)
		local s = have(sig)
		ZEN.assert(
			ECDH.verify(pk, ZEN.serialize(obj), s),
			'The signature by ' .. by .. ' is not authentic'
		)
	end
)
