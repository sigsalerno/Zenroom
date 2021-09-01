--[[
--This file is part of zenroom
--
--Copyright (C) 2021 Dyne.org foundation
--designed, written and maintained by Alberto Lerda
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
--on Wednesday, 1st September 2021
--]]

-- the empty octect is encoded as nil
-- a table contains in the first position (i.e. 1) the number of elements
function encodeRLP(data)
   local header = nil
   local res = nil
   local byt = nil

   if type(data) == 'table' then
      -- empty octet
      res = O.new()
      for _, v in pairs(data) do
	 res = res .. encodeRLP(v)
      end
      if #res < 56 then
	 res = INT.new(192+#res):octet() .. res
      else
	 -- Length of the result to be saved before the bytes themselves
	 byt = INT.new(#res):octet()
	 header = INT.new(247+#byt):octet() .. byt

      end
   elseif iszen(type(data)) then
      -- Octet aka byte array
      res = data:octet()

      -- Empty octet?
      -- index single bytes of an octet
      local byt = INT.new(0)
      if #res > 0 then
	 byt = INT.new( res:chop(1) )
      end

      if #res ~= 1 or byt >= INT.new(128) then
	 if #res < 56 then
	    header = INT.new(128+#res):octet()
	 else
	    -- Length of the result to be saved before the bytes themselves
	    byt = INT.new(#res):octet()
	    header = INT.new(183+#byt):octet() .. byt
	 end
      end

   else
      error("Invalid data type for ETH RLP encoder: "..type(data))      
   end
   if header then
      res = header .. res
   end
   return res
end

assert(encodeRLP(O.from_hex('7f')) == O.from_hex('7f'))
assert(encodeRLP(O.from_hex('ff')) == O.from_hex('81ff'))
-- ATTENTION empty sequence
assert(encodeRLP(O.new()) == O.from_hex('80'))
assert(encodeRLP(O.from_hex('00')) == O.from_hex('00'))
assert(encodeRLP(O.from_hex('1122334455667788112233445566778811223344556677881122334455667788')) == O.from_hex('a01122334455667788112233445566778811223344556677881122334455667788'))
assert(encodeRLP(O.from_hex('11223344556677881122334455667788112233445566778811223344556677881122334455667788112233445566778811223344556677881122334455667788')) == O.from_hex('b84011223344556677881122334455667788112233445566778811223344556677881122334455667788112233445566778811223344556677881122334455667788'))
assert(encodeRLP(O.from_hex('111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444')) == O.from_hex('b90300111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444'))
assert(encodeRLP({O.from_hex('11223344556677881122334455667788'), O.from_hex('1122334455667788')}) == O.from_hex('da9011223344556677881122334455667788881122334455667788'))

assert(encodeRLP({O.from_hex('627306090abab3a6e1400e9345bc60c78a8bef57'), O.from_hex('ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f'), O.from_hex('8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63')}) == O.from_hex('f85794627306090abab3a6e1400e9345bc60c78a8bef57a0ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162fa08f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63'))
assert(encodeRLP({O.from_hex('c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'), O.from_hex('627306090abab3a6e1400e9345bc60c78a8bef57'), O.from_hex('ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f'), O.from_hex('8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63')}) == O.from_hex('f878a0c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d394627306090abab3a6e1400e9345bc60c78a8bef57a0ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162fa08f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63'))

-- i is the position from which we start to parse
-- return a table with
-- * res which is the content read
-- * idx which is the position of the next byte to read
function decodeRLPgeneric(rlp, i)
   local byt, res, idx
   local u128

   u128 = INT.new(128)

   byt = rlp:sub(i, i)
   idx=i+1
   bytInt = tonumber(byt:hex(), 16)

   if bytInt < 128 then
      res = byt
   elseif bytInt <= 183 then
      idx = i+bytInt-128+1
      if bytInt == 128 then
	 res = O.new()
      else
	 res = rlp:sub(i+1, idx-1)
      end

   elseif bytInt < 192 then
      local sizeEnd = bytInt-183;
      local size = tonumber(rlp:sub(i+1, i+sizeEnd):hex(), 16)
      idx = i+sizeEnd+size+1
      res = rlp:sub(i+sizeEnd+1, idx-1)
   else -- it is a tuple
      local j
      if bytInt <= 247 then
	 idx = i+bytInt-192+1 -- total number of bytes
      else -- decode big endian encoding
	 local sizeEnd
	 sizeEnd = bytInt-247;
	 local size = tonumber(rlp:sub(i+1, i+sizeEnd):hex(), 16)
	 idx = i+sizeEnd+size+1
	 i=i+sizeEnd
      end
      i=i+1 -- initial position
      j=1 -- index inside res
      res = {}
      -- decode the tuple in a table
      while i < idx do
	 local readNext
	 readNext = decodeRLPgeneric(rlp, i)
	 res[j] = readNext.res
	 j = j+1
	 i = readNext.idx
      end
   end
   return {
      res=res,
      idx=idx
   }
end

function decodeRLP(rlp)
   return decodeRLPgeneric(rlp, 1).res
end

assert(decodeRLP(O.from_hex('7f')) == O.from_hex('7f'))
assert(decodeRLP(O.from_hex('81ff')) == O.from_hex('ff'))
assert(decodeRLP(O.from_hex('80')) == O.new())
assert(O.from_hex('1122334455667788112233445566778811223344556677881122334455667788') == decodeRLP(O.from_hex('a01122334455667788112233445566778811223344556677881122334455667788')))
assert(O.from_hex('11223344556677881122334455667788112233445566778811223344556677881122334455667788112233445566778811223344556677881122334455667788') == decodeRLP(O.from_hex('b84011223344556677881122334455667788112233445566778811223344556677881122334455667788112233445566778811223344556677881122334455667788')))
assert(O.from_hex('111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444') == decodeRLP(O.from_hex('b90300111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444111122223333444411112222333344441111222233334444')))

assert( array_equals( {O.from_hex('11223344556677881122334455667788'), O.from_hex('1122334455667788')},
                     decodeRLP(O.from_hex('da9011223344556677881122334455667788881122334455667788'))) )
-- use directly ZEN.serialize which is what does array_equals inside
assert(
    ZEN.serialize({O.from_hex('627306090abab3a6e1400e9345bc60c78a8bef57'), O.from_hex('ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f'), O.from_hex('8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63')})
    ==
    ZEN.serialize(decodeRLP(O.from_hex('f85794627306090abab3a6e1400e9345bc60c78a8bef57a0ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162fa08f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63'))))
assert(
    ZEN.serialize({O.from_hex('c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d3'), O.from_hex('627306090abab3a6e1400e9345bc60c78a8bef57'), O.from_hex('ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f'), O.from_hex('8f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63')})
    ==
    ZEN.serialize(decodeRLP(O.from_hex('f878a0c87509a1c067bbde78beb793e6fa76530b6382a4c0241e5e4a9ec0a0f44dc0d394627306090abab3a6e1400e9345bc60c78a8bef57a0ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162fa08f2a55949038a9610f50fb23b5883af3b4ecb3c3bb792cbcefbd1542c692be63'))))

-- the transaction I want to encode is (e.g.)
-- | nonce     |                                          0 |
-- | gas price |                                          0 |
-- | gas limit |                                      25000 |
-- | to        | 0x627306090abaB3A6e1400e9345bC60c78a8BEf57 |
-- | value     |                                         11 |
-- | data      |                                            |
-- | chainId   |                                       1337 |

-- start Besu with the following command
-- besu --network=dev --miner-enabled --miner-coinbase=0xfe3b557e8fb62b89f4916b721be55ceb828dbd73 --rpc-http-cors-origins="all" --host-allowlist="*" --rpc-ws-enabled --rpc-http-enabled --data-path=/tmp/tmpDatdir

-- 0 is encoded as the empty octet, which is treated as nil

tx = {}
tx["nonce"] = O.new()
tx["gasPrice"] = INT.new(1000)
tx["gasLimit"] = INT.new(25000) 
tx["to"] = O.from_hex('627306090abaB3A6e1400e9345bC60c78a8BEf57')
tx["value"] = O.from_hex('11')
tx["data"] = O.new()
-- v contains the chain id (when the transaction is not signed)
-- We always use the chain id
tx["v"] = INT.new(1337)
tx["r"] = O.new()
tx["s"] = O.new()

from = O.from_hex('ae6ae8e5ccbfb04590405997ee2d52d2b330726137b875053c36d94e974d162f')
pk = ECDH.pubgen(from)

function encodeTransaction(tx)
   local fields = {tx["nonce"], tx["gasPrice"], tx["gasLimit"], tx["to"],
		   tx["value"], tx["data"], tx["v"], tx["r"], tx["s"]}
   return encodeRLP(fields)
end

function decodeTransaction(rlp)
   local t = decodeRLP(rlp)
   return {
      nonce=t[1],
      gasPrice=INT.new(t[2]),
      gasLimit=INT.new(t[3]),
      to=t[4],
      value=t[5],
      data=t[6],
      v=INT.new(t[7]),
      r=t[8],
      s=t[9]
   }
end

-- from milagro's ROM, halved (works only with SECP256K1 curve)
-- const BIG_256_28 CURVE_Order_SECP256K1= {0x364141,0xD25E8CD,0x8A03BBF,0xDCE6AF4,0xFFEBAAE,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xFFFFFFF,0xF};
halfSecp256k1n = INT.new(hex('7fffffffffffffffffffffffffffffff5d576e7357a4501ddfe92f46681b20a0'))

function signEcdsaEth(sk, data) 
  local sig
  sig = nil
  repeat
    sig = ECDH.sign_hashed(sk, data, #data)
  until(INT.new(sig.s) < halfSecp256k1n);

  return sig
end

-- modify the input transaction
function encodeSignedTransaction(sk, tx)
   local H, txHash, sig, pk, x, y, two, res
   H = HASH.new('keccak256')
   txHash = H:process(encodeTransaction(tx))

   sig = signEcdsaEth(sk, txHash);

   pk = ECDH.pubgen(sk)
   x, y = ECDH.pubxy(pk);

   two = INT.new(2);
   res = tx
   res.v = two * INT.new(tx.v) + INT.new(35) + INT.new(y) % two
   res.r = sig.r
   res.s = sig.s

   return encodeTransaction(res)

end

encodedTx = encodeSignedTransaction(from, tx)

print(encodedTx:hex())
decodedTx = decodeTransaction(encodedTx)

fields = {"nonce", "gasPrice", "gasLimit", "to",
	  "value", "data"}
for _, v in pairs(fields) do
   assert(tx[v] == decodedTx[v])
end

-- Verify the signature of a transaction which implements EIP-155
-- Simple replay attack protection
-- https://github.com/ethereum/EIPs/blob/master/EIPS/eip-155.md
function verifySignatureTransaction(pk, txSigned)
   local fields, H, txHash, tx
   fields = {"nonce", "gasPrice", "gasLimit", "to",
	     "value", "data"}

   -- construct the transaction which was signed
   tx = {}
   for _, v in pairs(fields) do
      tx[v] = txSigned[v]
   end
   tx["v"] = (txSigned["v"]-INT.new(35))/INT.new(2)
   tx["r"] = O.new()
   tx["s"] = O.new()


   H = HASH.new('keccak256')
   txHash = H:process(encodeTransaction(tx))

   sig = {
      r=txSigned["r"],
      s=txSigned["s"]
   }

   return ECDH.verify_hashed(pk, txHash, sig, #txHash)
end

assert(verifySignatureTransaction(pk, tx))
assert(verifySignatureTransaction(pk, decodedTx))

-- TEST internal crypto api
require'crypto_ethereum'
-- verify transactions done with test code above
assert(verify_eth_tx(pk, decode_eth_rlp(encodedTx)))
assert(verify_eth_tx(pk, decodedTx))
-- redo all transaction flow
tx = {}
tx["nonce"] = O.new()
tx["gasPrice"] = INT.new(1000)
tx["gasLimit"] = INT.new(25000) 
tx["to"] = O.from_hex('627306090abaB3A6e1400e9345bC60c78a8BEf57')
tx["value"] = O.from_hex('11')
tx["data"] = O.new()
-- v contains the chain id (when the transaction is not signed)
-- We always use the chain id
tx["v"] = INT.new(1337)
tx["r"] = O.new()
tx["s"] = O.new()
kp = ECDH.keygen()
stx = sign_eth_tx(kp.private, tx)
rlp = encode_eth_rlp(stx)
print(rlp)
assert(verify_eth_tx(kp.public, decode_eth_rlp(rlp)))