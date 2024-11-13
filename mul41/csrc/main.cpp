#include "../build/obj_dir/Vmux_4to1.h"
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
  // Test all combinations of sel and 4-bit inputs a, b, c, d
    for (uint8_t sel = 0; sel < 4; sel++) { // sel has 4 possible values (00, 01, 10, 11)
        for (uint8_t a = 0; a < 16; a++) { // a has 16 possible values (4-bit)
            for (uint8_t b = 0; b < 16; b++) { // b has 16 possible values (4-bit)
                for (uint8_t c = 0; c < 16; c++) { // c has 16 possible values (4-bit)
                    for (uint8_t d = 0; d < 16; d++) { // d has 16 possible values (4-bit)

                        // Set inputs for mux_4to1
                        top.a = a;
                        top.b = b;
                        top.c = c;
                        top.d = d;
                        top.sel = sel;

                        // Evaluate the design
                        top.eval();
                        tfp->dump(sim_time++);

                        // Expected output
                        uint8_t expected_out;
                        if (sel == 0) {
                            expected_out = a;  // When sel = 00, output = a
                        } else if (sel == 1) {
                            expected_out = b;  // When sel = 01, output = b
                        } else if (sel == 2) {
                            expected_out = c;  // When sel = 10, output = c
                        } else {
                            expected_out = d;  // When sel = 11, output = d
                        }

                        // Check if the output matches the expected value
                        if (top.out != expected_out) {
                            printf("FAIL: sel=%d a=%d b=%d c=%d d=%d expected_out=%d top.out=%d\n",
                                    sel, a, b, c, d, expected_out, top.out);
                        }
                        assert(top.out == expected_out);
                    }
                }
            }
        }
    }

  std::cout << "PASS" << std::endl;
  tfp->close();
  return 0;
}
