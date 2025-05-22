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
  tp->clk_Regs = 0;
  tp->Reg_Write = 0;
  tp->R_Addr_A = 0;
  tp->R_Addr_B = 0;
  tp->W_Addr = 0;
  tp->W_Data = 0;
  tp->eval();

  // 打印表头
  std::cout << "W_Addr,W_Data,Reg_Write,R_Addr_A,R_Addr_B,ExpectedA,ExpectedB,"
               "R_Data_A,R_Data_B\n";

  // 测试向量：写 0、写非零、再读
  struct Test {
    uint8_t waddr;
    uint32_t wdata;
  };
  std::vector<Test> tests = {// 尝试写 x0（应被忽略）
                             {0, 0xDEADBEEF},
                             // 写几个不同寄存器
                             {1, 0x12345678},
                             {5, 0x0000FFFF},
                             {31, 0xAAAAAAAA}};

  for (auto &t : tests) {
    // 设置写端口
    tp->W_Addr = t.waddr;
    tp->W_Data = t.wdata;
    tp->Reg_Write = 1;
    // 时钟上升沿，执行写操作
    tp->clk_Regs = 1;
    tp->eval();
    tp->clk_Regs = 0;
    tp->eval();
    tp->Reg_Write = 0;

    // 对所有读端口地址做一轮读测试
    for (uint8_t ra = 0; ra < 32; ra += (ra == 0   ? 1
                                         : ra == 1 ? 4
                                         : ra == 5 ? 26
                                                   : 31)) {
      for (uint8_t rb = 0; rb < 32; rb += (rb == 0   ? 1
                                           : rb == 1 ? 4
                                           : rb == 5 ? 26
                                                     : 31)) {
        tp->R_Addr_A = ra;
        tp->R_Addr_B = rb;
        tp->eval();

        // 计算期望值：如果写的是 x0，则所有寄存器仍为 0
        uint32_t expA = (ra == 0 ? 0 : (t.waddr == ra ? t.wdata : 0));
        uint32_t expB = (rb == 0 ? 0 : (t.waddr == rb ? t.wdata : 0));

        // 读取实际值
        uint32_t outA = tp->R_Data_A;
        uint32_t outB = tp->R_Data_B;

        // 打印一行 CSV
        std::cout << int(t.waddr) << "," << std::hex << t.wdata << std::dec
                  << ","
                  << "1," // Reg_Write
                  << int(ra) << "," << int(rb) << "," << std::hex << expA << ","
                  << expB << std::dec << "," << std::hex << outA << "," << outB
                  << std::dec << "\n";

        // 断言
        assert(outA == expA);
        assert(outB == expB);
      }
    }
  }

  std::cout << "PASS" << std::endl;
  tfp->close();
  return 0;
}
