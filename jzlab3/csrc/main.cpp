#include "../build/obj_dir/Vregheap.h"
#include "verilated_vcd_c.h"
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <iostream>

int main() {
  Vregheap top;
  Vregheap *tp = &top;
  Verilated::traceEverOn(true);
  VerilatedVcdC *tfp = new VerilatedVcdC;
  top.trace(tfp, 99);
  tfp->open("./build/wave.vcd");

  int sim_time = 0;
  // 初始化信号
  std::vector<uint32_t> shadow_registers(32, 0);

  // Initialize signals
  tp->clk_Regs = 0;
  tp->Reg_Write = 0;
  tp->R_Addr_A = 0;
  tp->R_Addr_B = 0;
  tp->W_Addr = 0;
  tp->W_Data = 0;
  tp->eval();
  tfp->dump(sim_time++);


  // Print表头
  std::cout << "W_Addr,W_Data,Reg_Write,R_Addr_A,R_Addr_B,ExpectedA,ExpectedB,"
               "R_Data_A,R_Data_B,Status\n"; // Added Status column

  struct Test {
    uint8_t waddr;
    uint32_t wdata;
    std::string description; // Optional: for better logging
  };

  std::vector<Test> tests = {
      {0, 0xDEADBEEF, "Try Write x0"},
      {1, 0x12345678, "Write x1"},
      {5, 0x0000FFFF, "Write x5"},
      {31, 0xAAAAAAAA, "Write x31"},
      {1, 0xCAFEBABE, "Overwrite x1"} // Test overwriting a register
  };

  for (auto &t : tests) {
    // Set write port
    tp->W_Addr = t.waddr;
    tp->W_Data = t.wdata;
    tp->Reg_Write = 1;

    // Clock rising edge, perform write
    tp->clk_Regs = 1;
    tp->eval();
    tfp->dump(sim_time++);

    // Update shadow register model (only if W_Addr is not x0)
    if (t.waddr != 0) {
      shadow_registers[t.waddr] = t.wdata;
    }

    tp->clk_Regs = 0;
    tp->eval();
    tfp->dump(sim_time++);
    tp->Reg_Write = 0; // Lower Reg_Write after write cycle
    tp->eval();        // Evaluate with Reg_Write low
    tfp->dump(sim_time++);


    // Test read ports for a selection of addresses
    // The original sparse iteration logic for ra and rb:
    // uint8_t read_addrs[] = {0, 1, 5, 31}; // Simplified for clarity, use your original if needed
    // for (uint8_t ra : read_addrs) {
    //   for (uint8_t rb : read_addrs) {
    // Using the original complex iteration logic:
    for (uint8_t ra = 0; ra < 32; ra += (ra == 0   ? 1
                                         : ra == 1 ? 4
                                         : ra == 5 ? 26
                                                   : 32)) { // Ensure loop terminates, using 32 for last increment
      for (uint8_t rb = 0; rb < 32; rb += (rb == 0   ? 1
                                           : rb == 1 ? 4
                                           : rb == 5 ? 26
                                                     : 32)) { // Ensure loop terminates
        if (ra >=32 || rb >=32) continue; // Safety break if increment logic is complex

        tp->R_Addr_A = ra;
        tp->R_Addr_B = rb;
        tp->eval();
        tfp->dump(sim_time++);


        // Calculate expected values from the shadow model
        uint32_t expA = (ra == 0) ? 0 : shadow_registers[ra];
        uint32_t expB = (rb == 0) ? 0 : shadow_registers[rb];

        // Read actual values
        uint32_t outA = tp->R_Data_A;
        uint32_t outB = tp->R_Data_B;

        bool current_test_passed = (outA == expA && outB == expB);

        // Print CSV row
        std::cout << "W_Addr=" << static_cast<int>(t.waddr)
                  << " W_Data=0x" << std::hex << t.wdata << std::dec
                  << " Reg_Write=1" // This Reg_Write refers to the write phase, not current state
                  << " R_Addr_A=" << static_cast<int>(ra)
                  << " R_Addr_B=" << static_cast<int>(rb)
                  << " ExpectedA=0x" << std::hex << expA
                  << " ExpectedB=0x" << expB
                  << " R_Data_A=0x" << outA
                  << " R_Data_B=0x" << outB << std::dec
                  << (current_test_passed ? ",PASS" : ",FAIL") // Added status
                  << "\n";

        // Assert
        assert(outA == expA);
        assert(outB == expB);
      }
    }
  }

  std::cout << "ALL TESTS PASSED SUCCESSFULLY!" << std::endl;

  tfp->close();
  return 0;
}
