#include "../build/obj_dir/Vjk_ff.h"
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
  for (uint8_t jk = 0; jk < 4; jk++) {
    for (uint8_t clk = 0; clk < 2; clk++) { // Clock signal has 2 states: 0 or 1
      uint8_t J = (jk >> 1) & 1;            // Extract J from jk
      uint8_t K = jk & 1;                   // Extract K from jk
      uint8_t Q_expected;

      // Define expected output Q based on JK Flip-Flop behavior
      if (clk == 0) {
        // On the falling edge of the clock, output Q does not change
        Q_expected = top.Q; // Retain previous value
      } else {
        // On the rising edge of the clock, update Q based on J and K
        if (J == 0 && K == 0) {
          Q_expected = top.Q; // No change
        } else if (J == 0 && K == 1) {
          Q_expected = 0; // Reset
        } else if (J == 1 && K == 0) {
          Q_expected = 1; // Set
        } else if (J == 1 && K == 1) {
          Q_expected = ~top.Q & 1; // Toggle
        }
      }

      // Set inputs for JK Flip-Flop
      top.J = J;
      top.K = K;
      top.clk = clk;

      // Evaluate and dump the waveform
      top.eval();
      tfp->dump(sim_time++);

      // Check if the output matches the expected value
      if (top.Q != Q_expected) {
        printf("FAIL: J=%d K=%d clk=%d Q_expected=%d top.Q=%d\n", J, K, clk,
               Q_expected, top.Q);
      }
      assert(top.Q == Q_expected);
    }
  }

  std::cout << "PASS" << std::endl;
  tfp->close();
  return 0;
}
