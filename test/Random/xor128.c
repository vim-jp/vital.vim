#include <stdio.h>
#include <stdint.h>
#include <inttypes.h>

/* https://github.com/umireon/my-random-stuff/blob/master/xorshift/splitmix32.c */
uint32_t s;
uint32_t splitmix32(void) {
  uint32_t z = (s += 0x9e3779b9);
  z = (z ^ (z >> 16)) * 0x85ebca6b;
  z = (z ^ (z >> 13)) * 0xc2b2ae35;
  return z ^ (z >> 16);
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

int main(void) {
  s = 0;
  x = splitmix32();
  y = splitmix32();
  z = splitmix32();
  w = splitmix32();
  for (int i = 0; i < 10000; i++) {
    printf("%"PRIi32"\t#%d\n", xor128(), i + 1);
  }
}
