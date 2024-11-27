#include "Vdigit_display.h"
#include "verilated_vcd_c.h"
#include <bitset>
#include <cassert>
#include <iostream>

int main() {
  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  Vdigit_display top;

  top.trace(tfp, 99);
  tfp->open("./build/wave.vcd");

  int sim_time = 0;

  // Reset and initialize signals
  top.clk_2ms = 0;           // Initial clock low
  top.data = 0x123ABF78; // Example input data
  top.eval();
  tfp->dump(sim_time++);

  // Test: Check digit selection, data mapping, and AN signal
  for (int i = 0; i < 8; ++i) {
    // Simulate count reaching maximum for switching digits
    top.clk_2ms = 0;        // Rising edge of clock
    top.eval();
    tfp->dump(sim_time++);
    top.clk_2ms = 1; // pos edge of clock
    top.eval();
    tfp->dump(sim_time++);

    int j = (i + 1) % 8;

    // Expected AN and digit selection
    uint8_t expected_AN = ~(1 << (7 - j)); // Activate the i-th segment
    uint8_t expected_digit =
        (top.data >> ((7 - j) * 4)) & 0xF; // Extract 4 bits for the digit

    uint8_t expected_display_signal;
    switch (expected_digit) {
    case 0x0:
      expected_display_signal = 0x03;
      break;
    case 0x1:
      expected_display_signal = 0x9F;
      break;
    case 0x2:
      expected_display_signal = 0x25;
      break;
    case 0x3:
      expected_display_signal = 0x0D;
      break;
    case 0x4:
      expected_display_signal = 0x99;
      break;
    case 0x5:
      expected_display_signal = 0x49;
      break;
    case 0x6:
      expected_display_signal = 0x41;
      break;
    case 0x7:
      expected_display_signal = 0x1F;
      break;
    case 0x8:
      expected_display_signal = 0x01;
      break;
    case 0x9:
      expected_display_signal = 0x09;
      break;
    case 0xA:
      expected_display_signal = 0x11;
      break;
    case 0xB:
      expected_display_signal = 0xC1;
      break;
    case 0xC:
      expected_display_signal = 0x63;
      break;
    case 0xD:
      expected_display_signal = 0x85;
      break;
    case 0xE:
      expected_display_signal = 0x61;
      break;
    case 0xF:
      expected_display_signal = 0x71;
      break;
    }

    std::cout << "Test " << j + 1 << ": AN = " << std::bitset<8>(top.AN)
              << ", Number = " << (int)expected_digit
              << ", digitSelected = "
              << std::bitset<8>(top.control_display_signal) << std::endl;

    assert(top.AN == expected_AN); // Validate AN signal
    assert(top.control_display_signal ==
           expected_display_signal); // Validate selected digit
  }
  std::cout << "PASS" << std::endl;

  tfp->close();
  delete tfp;

  return 0;
}
