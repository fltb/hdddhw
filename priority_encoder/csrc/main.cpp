#include "../build/obj_dir/Vpriority_encoder.h"
#include "verilated_vcd_c.h"
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <iostream>

int main() {

  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  int sim_time = 0;

  TOP_NAME top;

  top.trace(tfp, 99);
  tfp->open("./build/wave.vcd");
  for (uint16_t a = 0; a <= 0b11111111; a++) {
    uint16_t y, valid = 1;
    for (y = 0; !((0b10000000 >> y) & a) && y < 8; y++) {
    }
    y = 7 - y;
    if (!a) {
      y = 0;
      valid = 0;
    }
    top.A = a;
    top.eval();
    tfp->dump(sim_time++);

    if (top.Y != y || top.valid != valid) {
      printf("FAIL: a=%d y=%d top.Y=%d top.valid=%d\n", a, y, top.Y, top.valid);
    }
    assert(top.Y == y);
    assert(top.valid == valid);
  }

  std::cout << "PASS" << std::endl;
  tfp->close();
  return 0;
}
