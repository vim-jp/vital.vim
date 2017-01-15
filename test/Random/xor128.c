/**
 * xor128.c - Reference implementation of Random.Xor128
 * Written in 2017 by Kaito Udagawa
 * Released under CC0 <http://creativecommons.org/publicdomain/zero/1.0/>
 */

#include <stdio.h>
#include <stdlib.h>
#include <stdint.h>
#include <inttypes.h>

/* https://github.com/aappleby/smhasher/blob/master/src/MurmurHash3.cpp */
uint32_t fmix32(uint32_t z) {
  z = (z ^ (z >> 16)) * 0x85ebca6b;
  z = (z ^ (z >> 13)) * 0xc2b2ae35;
  return z ^ (z >> 16);
}

/* https://github.com/umireon/my-random-stuff/blob/master/xorshift/splitmix32.c */
uint32_t s;
uint32_t splitmix32(void) {
  return fmix32(s += 0x9e3779b9);
}

/* http://www.jstatsoft.org/v08/i14/paper */
uint32_t x, y, z, w;
uint32_t xor128(void) {
  uint32_t t = (x ^ (x << 11));
  x = y;
  y = z;
  z = w;
  return w = (w ^ (w >> 19)) ^ (t ^ (t >> 8));
}

/**
 * Usage: xor128 [seeds]
 *   xor128         # []
 *   xor128 0       # [0]
 *   xor128 0 0 0 0 # [0, 0, 0, 0]
 */
int main(int ac, char** av) {
  s = 123456789;
  for (int i = 1; i < ac; i++) {
    uint32_t seed = strtoul(av[i], NULL, 10);
    s = fmix32(s + seed);
  }

  x = splitmix32();
  y = splitmix32();
  z = splitmix32();
  w = splitmix32();
  for (int i = 0; i < 10000; i++) {
    printf("%"PRIi32"\t#%d\n", xor128(), i + 1);
  }
}
