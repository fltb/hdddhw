#include "Vtraffic_light_display_unit.h"
#include "verilated_vcd_c.h"
#include <bitset>
#include <cassert>
#include <iostream>

int main() {
  // Enable waveform tracing
  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  Vtraffic_light_display_unit top; // Instantiate the top-level module

  top.trace(tfp, 99); // Set up waveform tracing
  tfp->open("./build/wave.vcd");

  int sim_time = 0;

  // Reset and initialize signals
  top.clk_100hz = 0; // Initialize 2ms clock signal
  top.clk_1hz = 0;  // Initialize 1s clock signal
  top.eval();      // Evaluate initial state
  tfp->dump(sim_time++);

  // Simulate for a given period
  for (int cycle = 0; cycle < 2000; ++cycle) { // Simulate 500 clock cycles
    // Toggle the 2ms clock signal
    top.clk_100hz = !top.clk_100hz;
    top.eval();
    tfp->dump(sim_time++);

    // Toggle the 1s clock signal every 500ms (assuming clk_2ms toggles every
    // 2ms)
    if (cycle % 4 == 0) {
      top.clk_1hz = !top.clk_1hz;
    }

    // Evaluate the circuit
    top.eval();
    tfp->dump(sim_time++);

    // Display the output for debugging
    std::cout << "Time: " << sim_time << ", Second: " <<( (int)(cycle) / 8) + 1
              << ", AN: " << std::bitset<3>(top.AN)
              << ", control_display_signal: "
              << std::bitset<8>(top.control_display_signal)
              << ", NUM_PRI: " << ((top.data & 0xFFFF0000)>>16)
              << ", NUM_SEC: " << (top.data & 0x0000FFFF)
              << ", RGY_PRI: " << ((top.RGY_PRI == 0b100) ? "RED" : ((top.RGY_PRI == 0b010) ? "GREEN" : "YELLOW"))
              << ", RGY_SEC: " <<  ((top.RGY_SEC == 0b100) ? "RED" : ((top.RGY_SEC == 0b010) ? "GREEN" : "YELLOW")) << "\n";
  }

  // Close the waveform dump file
  tfp->close();
  delete tfp;

  std::cout << "Simulation Complete" << std::endl;
  return 0;
}
