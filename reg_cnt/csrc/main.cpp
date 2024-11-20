#include "../build/obj_dir/Vregister_74LS191.h"
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

  for (uint8_t D = 0; D < 16; D++) { // D is 4-bit, values range from 0 to 15
    for (uint8_t NLD_signal = 0; NLD_signal < 2; NLD_signal++) { // Load active low
      for (uint8_t NCT_signal = 0; NCT_signal < 2; NCT_signal++) { // Count enable
        for (uint8_t NUD_signal = 0; NUD_signal < 2; NUD_signal++) { // Up/Down
          for (uint8_t clk = 0; clk < 2; clk++) { // Clock signal
            // Set inputs
            top.D = D;
            top.NLD = NLD_signal;
            top.NCT = NCT_signal;
            top.NUD = NUD_signal;
            top.CP = clk;

            // Expected output logic
            uint8_t expected_Q = top.Q;

            if (!NLD_signal) {
              // Load is active (low), load D into Q
              expected_Q = D;
            } else if (!NCT_signal && clk) {
              // Counting is enabled
              if (!NUD_signal) {
                // Count up
                expected_Q = (top.Q + 1) & 0b1111; // Wrap around at 4 bits
              } else {
                // Count down
                expected_Q = (top.Q - 1) & 0b1111; // Wrap around at 4 bits
              }
            }

            // Evaluate the design
            top.eval();
            tfp->dump(sim_time++);

            // Check if the output matches the expected value
            if (top.Q != expected_Q) {
              printf("FAIL: NLD=%d NCT=%d NUD=%d CP=%d D=%d expected_Q=%d top.Q=%d\n",
                     NLD_signal, NCT_signal, NUD_signal, clk, D, expected_Q, top.Q);
            }
            assert(top.Q == expected_Q);
          }
        }
      }
    }
  }

  std::cout << "PASS" << std::endl;
  tfp->close();
  return 0;
}