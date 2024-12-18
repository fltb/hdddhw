#include "../build/obj_dir/Vclksplitter.h"
#include "verilated_vcd_c.h"
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <iostream>
const int C100M = 100000000;
const int C1M = C100M / 100;
int main() {
  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  int sim_time = 0;

  // Instantiate the clksplitter module
  Vclksplitter top;

  // Enable tracing
  top.trace(tfp, 99);
  tfp->open("./build/wave.vcd");

  // Simulate a 100 MHz clock signal (clk100mhz)
  for (int halfcycle = 0; halfcycle < C100M *2; halfcycle++) {
    const int cycle = halfcycle / 2;
    const int signal = (halfcycle % 2 == 0);
    top.clk100mhz = signal; // Toggle every cycle for 100 MHz clock

    top.eval();            // Evaluate the design
    tfp->dump(sim_time++); // Dump waveforms to VCD file

    // Check the clk_100hz output (expected to be high every 10 million cycles
    // of clk100mhz)
    if (cycle % C1M == 0) {
      if (top.clk_100hz != 1) {
        std::cout << "Cycle: " << cycle << ", Half: " << halfcycle
                  << ", Signal: " << signal << ", 100hz: " << (int)top.clk_100hz
                  << ", 1hz: " << (int)top.clk_1hz << "\n";
      }
      assert(top.clk_100hz == 1);
    } else {
      if (top.clk_100hz != 0) {
        std::cout << "Cycle: " << cycle << ", Half: " << halfcycle
                  << ", Signal: " << signal << ", 100hz: " << (int)top.clk_100hz
                  << ", 1hz: " << (int)top.clk_1hz << "\n";
      }
      assert(top.clk_100hz == 0);
    }

    // Check the clk_1hz output (expected to be high every 100 million cycles of
    // clk100mhz)
    if (cycle % C100M == 0) {
      if (top.clk_1hz != 1) {
        std::cout << "Cycle: " << cycle << ", Half: " << halfcycle
                  << ", Signal: " << signal << ", 100hz: " << (int)top.clk_100hz
                  << ", 1hz: " << (int)top.clk_1hz << "\n";
      }
      assert(top.clk_1hz == 1);
    } else {
      if (top.clk_1hz != 0) {
        std::cout << "Cycle: " << cycle << ", Half: " << halfcycle
                  << ", Signal: " << signal << ", 100hz: " << (int)top.clk_100hz
                  << ", 1hz: " << (int)top.clk_1hz << "\n";
      }

      assert(top.clk_1hz == 0);
    }
  }

  std::cout << "PASS" << std::endl;
  tfp->close();
  return 0;
}
