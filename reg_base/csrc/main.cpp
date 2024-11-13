#include "../build/obj_dir/Vregister_8bit.h"
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
  // Test all combinations of NOE, clr, and 8-bit input data D
  for (uint8_t D = 0; D != 255;
       D++) { // 8-bit input data has 256 possible values (0-255)
    for (uint8_t clr_signal = 0; clr_signal < 2;
         clr_signal++) { // clr has 2 possible values: 0 or 1
      for (uint8_t NOE_signal = 0; NOE_signal < 2;
           NOE_signal++) { // NOE has 2 possible values: 0 or 1
        for (uint8_t clk = 0; clk < 2; clk++) {
          // Set inputs for register_8bit
          top.D = D;
          top.NOE = NOE_signal;
          top.clr = clr_signal;
          top.clk = clk;

          // Expected output logic
          uint8_t expected_Q;

          if (clr_signal == 1) {
            expected_Q = 0b00000000; // Clear signal is active, Q should be 0
          } else if (clk == 0) {
            expected_Q = top.Q; // dont set when clk0
          } else {              // clk =1
            expected_Q = D;
          }

          // Evaluate the design
          top.eval();
          tfp->dump(sim_time++);

          // Check if the output matches the expected value
          if (top.Q != expected_Q) {
            printf("FAIL: clr=%d NOE=%d clk=%d D=%d expected_Q=%d top.Q=%d\n",
                   clr_signal, NOE_signal, clk, D, expected_Q, top.Q);
          }
          assert(top.Q == expected_Q);
        }
      }
    }
  }

  std::cout << "PASS" << std::endl;
  tfp->close();
  return 0;
}
