#include "../build/obj_dir/Vstream_light.h"
#include "verilated_vcd_c.h"
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <iostream>

int main() {
  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  int sim_time = 0;

  Vstream_light top;
  top.trace(tfp, 99);
  tfp->open("./build/wave.vcd");

  // Variables for inputs and expected output
  uint16_t expected_LED = 0;
  uint16_t initial_LED = 0;
  uint16_t prev_LED = 0;
  uint8_t PRE_SW = 0;
  for (uint8_t rst = 0; rst < 2; rst++) { // Reset signal
    for (uint8_t SW = 0; SW < 4;
         SW++) { // SW is 2-bit, values range from 0 to 3
      for (uint8_t clk = 0; clk < 2; clk++) { // Clock signal, toggling
        // Set inputs
        top.rst = rst;
        top.SW = SW;
        top.clk = clk;

        if (rst || (PRE_SW != SW)) {
          // If reset is active, LED should initialize based on SW
          switch (SW) {
          case 0b00:
            expected_LED = 0x8000;
            break;
          case 0b01:
            expected_LED = 0x0001;
            break;
          case 0b10:
            expected_LED = 0x0180;
            break;
          case 0b11:
            expected_LED = 0x8001;
            break;
          }
          PRE_SW = SW;
        } else if (clk) {
          // Simulate behavior on positive clock edge
          switch (SW) {
          case 0b00: // Rotate right
            expected_LED = (prev_LED >> 1) | ((prev_LED & 0x1) << 15);
            break;
          case 0b01: // Rotate left
            expected_LED = (prev_LED << 1) | ((prev_LED & 0x8000) >> 15);
            break;
          case 0b10: // Custom middle rotation
            expected_LED = ((prev_LED & 0b0111111100000000) << 1) | // LED[14:8]
                           ((prev_LED & 0b1000000000000000) >> 7) | // LED[15]
                           ((prev_LED & 0b0000000011111110) >> 1) | // LED[0]
                           ((prev_LED & 0b0000000000000001) << 7);  // LED[7:1]

            break;
          case 0b11: // Custom top and bottom
            expected_LED = ((prev_LED & 0b0000000100000000) << 7) | // LED[8]
                           ((prev_LED & 0b1111111000000000) >> 1) | // LED[15:9]
                           ((prev_LED & 0b0000000010000000) >> 7) |                      // LED[6:0]
                           ((prev_LED & 0b0000000001111111) << 1);                // LED[7]
            break;
          }
        }

        // Evaluate the design
        top.eval();
        tfp->dump(sim_time++);

        // Store current LED for next clock iteration
        prev_LED = top.LED;

        // Check if the output matches the expected value
        if (top.LED != expected_LED) {
          printf(
              "FAIL: rst=%d SW=%d clk=%d expected_LED=0x%04X top.LED=0x%04X\n",
              rst, SW, clk, expected_LED, top.LED);
        }
        assert(top.LED == expected_LED);
      }
    }
  }

  std::cout << "PASS" << std::endl;
  tfp->close();
  return 0;
}
