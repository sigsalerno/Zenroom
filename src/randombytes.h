#ifndef sss_RANDOMBYTES_H
#define sss_RANDOMBYTES_H

#ifdef ARCH_WIN
/* Load size_t on windows */
#include <crtdefs.h>
#else
#if !defined(ARCH_CORTEX) && !defined(ARCH_STM32H7A3XXQ)
#include <sys/syscall.h>
#endif
#include <unistd.h>
#endif /* _WIN32 */


/*
 * Write `n` bytes of high quality random bytes to `buf`
 */
int randombytes(void *buf, size_t n);


#endif /* sss_RANDOMBYTES_H */
