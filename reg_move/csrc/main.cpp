#include "../build/obj_dir/Vregister_74LS198.h"
#include "verilated_vcd_c.h"
#include <cassert>
#include <bitset>
#include <iostream>

int main() {
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    Vregister_74LS198 top;

    top.trace(tfp, 99);
    tfp->open("./build/wave.vcd");

    int sim_time = 0;

    // Reset and initialization
    top.NCR = 0; // Assert reset
    top.CP = 0;  // Initial clock low
    top.S0 = 0;
    top.S1 = 0;
    top.D = 0;
    top.SL = 0;
    top.SR = 0;
    top.eval();
    tfp->dump(sim_time++);
    assert(top.Q == 0); // Q should be 0 after reset

    // Release reset
    top.NCR = 1;
    top.eval();
    tfp->dump(sim_time++);

    // Test 1: Shift Right
    top.Q = 0b10101010; // Initialize Q
    top.S0 = 1;
    top.S1 = 0; // Shift Right mode
    top.SR = 1; // Serial right input
    for (int i = 0; i < 8; ++i) {
        uint8_t expected_Q = (1 << 7) | (top.Q >> 1); // Expected value after shift right
        top.CP = 1; // Clock rising edge
        top.eval();
        tfp->dump(sim_time++);
        top.CP = 0; // Clock falling edge
        top.eval();
        tfp->dump(sim_time++);
        std::cout << "Q after shift right: " << std::bitset<8>(top.Q) << std::endl;
        assert(top.Q == expected_Q); // Check if Q matches expected value
    }

    // Test 2: Shift Left
    top.Q = 0b10101010; // Reinitialize Q
    top.S0 = 0;
    top.S1 = 1; // Shift Left mode
    top.SL = 1; // Serial left input
    for (int i = 0; i < 8; ++i) {
        uint8_t expected_Q = (top.Q << 1) | 1; // Expected value after shift left
        top.CP = 1; // Clock rising edge
        top.eval();
        tfp->dump(sim_time++);
        top.CP = 0; // Clock falling edge
        top.eval();
        tfp->dump(sim_time++);
        std::cout << "Q after shift left: " << std::bitset<8>(top.Q) << std::endl;
        assert(top.Q == expected_Q); // Check if Q matches expected value
    }

    // Test 3: Load D
    top.S0 = 1;
    top.S1 = 1; // Parallel Load mode
    top.D = 0b11110000;
    top.CP = 1; // Clock rising edge
    top.eval();
    tfp->dump(sim_time++);
    assert(top.Q == 0b11110000); // Check if Q matches D
    std::cout << "Q after loading D: " << std::bitset<8>(top.Q) << std::endl;
    top.CP = 0; // Clock falling edge
    top.eval();
    tfp->dump(sim_time++);

    // Test 4: Hold State
    uint8_t hold_value = top.Q; // Save the current state
    top.S0 = 0;
    top.S1 = 0; // Hold state
    for (int i = 0; i < 5; ++i) {
        top.CP = 1; // Clock rising edge
        top.eval();
        tfp->dump(sim_time++);
        top.CP = 0; // Clock falling edge
        top.eval();
        tfp->dump(sim_time++);
        std::cout << "Q holding: " << std::bitset<8>(top.Q) << std::endl;
        assert(top.Q == hold_value); // Q should remain unchanged
    }

    std::cout << "PASS" << std::endl;

    tfp->close();
    delete tfp;

    return 0;
}
