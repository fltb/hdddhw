#include "../build/obj_dir/Vcsa.h"
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <iostream>
#include "verilated_vcd_c.h"


int main() {

    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    int sim_time = 0;

    TOP_NAME top;

    top.trace(tfp, 99);
    tfp->open("./build/wave.vcd");
    for (uint8_t a = 0; a <= 0b1111; a++) {
        for (uint8_t b = 0; b <= 0b1111; b++) {
            for (uint8_t cin = 0; cin <= 1; cin++) {
                uint8_t sum = (a + b + cin) & 0b1111;
                uint8_t cout = ((a + b + cin) >> 4) & 1;
                top.A = a;
                top.B = b;
                top.Cin = cin;
                top.eval();
                tfp->dump(sim_time++);

                if (top.Sum != sum) {
                    printf("FAIL: a=%d b=%d cin=%d sum=%d cout=%d top.sum=%d\n", a, b, cin, sum, cout, top.Sum);
                }
                assert(top.Sum == sum);
                assert(top.CarryOut == cout);
            }
        }
    }

    std::cout << "PASS" << std::endl;
    tfp->close();
    return 0;
}
