#include "../build/obj_dir/VRiscV_CPU_Top.h" // <-- IMPORTANT: Change to your Verilated CPU top module header
#include "verilated_vcd_c.h"
#include <cassert>
#include <cstdint>
#include <cstdio>
#include <iostream>
#include <vector>
#include <map>
#include <string>
#include <iomanip>      // For std::hex, std::dec
#include <stdexcept>    // For std::out_of_range, std::runtime_error

// Define TOP_NAME for convenience
#define TOP_NAME VRiscV_CPU_Top // <-- IMPORTANT: Change if your Verilated class name is different

// --- Simulated Memory ---
class SimulatedMemory {
public:
    std::map<uint32_t, uint8_t> data_mem_bytes;
    std::vector<uint32_t> inst_mem_words;
    size_t inst_mem_size_words;

    SimulatedMemory(size_t inst_mem_size_in_words = 1024, size_t data_mem_initial_capacity_bytes = 4096) {
        inst_mem_words.resize(inst_mem_size_in_words, 0xFFFFFFFF); // Init with invalid opcode or NOPs (e.g., all 1s)
        inst_mem_size_words = inst_mem_size_in_words;
        // data_mem_bytes (map) will grow as needed.
    }

    void load_instructions(const std::vector<uint32_t>& program_words, uint32_t start_address_bytes = 0) {
        if ((start_address_bytes % 4) != 0) {
            fprintf(stderr, "ERROR: Instruction memory start address (0x%X) must be word aligned.\n", start_address_bytes);
            throw std::runtime_error("Instruction memory start address must be word aligned.");
        }
        uint32_t start_word_addr = start_address_bytes / 4;
        if (start_word_addr + program_words.size() > inst_mem_words.size()) {
            fprintf(stderr, "ERROR: Program too large for instruction memory or out of bounds.\n");
            throw std::out_of_range("Program too large for instruction memory or out of bounds.");
        }
        printf("Loading %zu instructions starting at byte address 0x%08X (word addr 0x%04X)\n",
               program_words.size(), start_address_bytes, start_word_addr);
        for (size_t i = 0; i < program_words.size(); ++i) {
            inst_mem_words[start_word_addr + i] = program_words[i];
            // printf("  IMEM[0x%08X] = 0x%08X\n", start_address_bytes + (uint32_t)i*4, program_words[i]);
        }
    }

    uint32_t read_inst_word(uint32_t byte_address) {
        if ((byte_address % 4) != 0) {
            // RISC-V spec: PC is normally word-aligned. Misaligned fetch causes an exception.
            // For a simple testbench/CPU, often this is an error or address is truncated.
            fprintf(stderr, "Warning: Misaligned instruction fetch attempt at 0x%08X. Returning 0xFFFFFFFF.\n", byte_address);
            return 0xFFFFFFFF; // Typically an illegal instruction
        }
        uint32_t word_addr = byte_address / 4;
        if (word_addr >= inst_mem_words.size()) {
            fprintf(stderr, "Warning: Out-of-bounds instruction read at 0x%08X (word addr %u). Returning 0xFFFFFFFF.\n", byte_address, word_addr);
            return 0xFFFFFFFF; // Illegal instruction
        }
        return inst_mem_words[word_addr];
    }

    uint32_t read_data_word(uint32_t byte_address) {
        // Allow misaligned reads if CPU supports, otherwise it should trap/error.
        // This model assembles the word assuming little-endian.
        uint32_t word = 0;
        word |= (data_mem_bytes.count(byte_address + 0) ? data_mem_bytes[byte_address + 0] : 0) << 0;
        word |= (data_mem_bytes.count(byte_address + 1) ? data_mem_bytes[byte_address + 1] : 0) << 8;
        word |= (data_mem_bytes.count(byte_address + 2) ? data_mem_bytes[byte_address + 2] : 0) << 16;
        word |= (data_mem_bytes.count(byte_address + 3) ? data_mem_bytes[byte_address + 3] : 0) << 24;
        return word;
    }

    // wmask: bit 0 for byte 0 (addr+0), bit 1 for byte 1 (addr+1), etc.
    void write_data_word(uint32_t byte_address, uint32_t data, uint8_t wmask) {
        // Your RiscV_CPU_Top Verilog assigns d_mem_wmask = 4'b1111, so it always intends full word writes.
        // This memory model will respect the wmask it receives.
        if (wmask & 0x1) data_mem_bytes[byte_address + 0] = (data >> 0) & 0xFF;
        if (wmask & 0x2) data_mem_bytes[byte_address + 1] = (data >> 8) & 0xFF;
        if (wmask & 0x4) data_mem_bytes[byte_address + 2] = (data >> 16) & 0xFF;
        if (wmask & 0x8) data_mem_bytes[byte_address + 3] = (data >> 24) & 0xFF;
    }
};


// --- Main Testbench ---
int main() {
    TOP_NAME* top = new TOP_NAME;
    Verilated::traceEverOn(true);
    VerilatedVcdC* tfp = new VerilatedVcdC;
    top->trace(tfp, 99); // Trace 99 levels of hierarchy
    tfp->open("./build/wave_cpu.vcd"); // VCD file for CPU waveform

    uint64_t sim_time = 0;
    const int MAX_CYCLES = 200; // Max simulation cycles

    // Simulated components
    SimulatedMemory memory_model(1024); // 1024 words for instruction memory
    std::vector<uint32_t> shadow_regs(32, 0);

    // RV32I Program (hand-assembled)
    // Starts at address 0x00000000
    std::vector<uint32_t> program = {
        0x00A00093, // 0x00: addi x1, x0, 10         (x1 = 10)
        0x01400113, // 0x04: addi x2, x0, 20         (x2 = 20)
        0x002081B3, // 0x08: add  x3, x1, x2         (x3 = 10 + 20 = 30)
        0x00400000, // Placeholder for data memory base address if needed for SW/LW
        0x00302223, // 0x0C: sw   x3, 4(x0)         (M[0+4] = 30) (Assuming x0 is 0)
        0x00402203, // 0x10: lw   x4, 4(x0)         (x4 = M[0+4] = 30)
        0xFE008EE3, // 0x14: beq  x1, x0, 28 (target: 0x14 + 28 = 0x30) (10 != 0, not taken)
        0x00500293, // 0x18: addi x5, x0, 5          (x5 = 5)
        0x00000063  // 0x1C: beq  x0, x0, 0          (HALT: infinite loop self branch)
        // 0x030: (Target for the BEQ if it were taken)
    };
    memory_model.load_instructions(program, 0x00000000);

    // --- Reset Sequence ---
    printf("Applying reset...\n");
    top->rst = 1;
    top->clk = 0;
    top->eval(); tfp->dump(sim_time++);
    top->clk = 1;
    top->eval(); tfp->dump(sim_time++);
    top->clk = 0;
    top->eval(); tfp->dump(sim_time++);
    top->rst = 0;
    printf("Reset released.\n");

    // --- Main Simulation Loop ---
    printf("\nStarting CPU simulation...\n");
    printf("Cycle | PC       | Instr    | DMemAddr | DMemWEn | DMemWData | DMemREn | DMemRData | RegWEn | RegWAddr | RegWData\n");
    printf("------|----------|----------|----------|---------|-----------|---------|-----------|--------|----------|----------\n");

    int last_halt_pc = -1;
    int halt_pc_streak = 0;

    for (int cycle = 0; cycle < MAX_CYCLES; ++cycle) {
        // --- Negative Edge of Clock ---
        top->clk = 0;
        top->eval(); // Let combinational logic settle based on current state

        // --- Testbench actions: Provide inputs to CPU for the current cycle ---
        // 1. Instruction Fetch: CPU outputs i_mem_addr (which is current pc_reg)
        uint32_t current_pc_for_fetch = top->i_mem_addr;
        uint32_t instruction_word = memory_model.read_inst_word(current_pc_for_fetch);
        top->i_mem_rdata = instruction_word;

        // (Optional) eval() if instruction decoding itself is very complex and affects d_mem_addr immediately
        // For many single-cycle Verilator models, d_mem_addr might become valid after this eval
        top->eval();

        // 2. Data Memory Read Path (for LW):
        //    CPU outputs d_mem_addr, d_mem_en, d_mem_wen based on decoded instruction
        if (top->d_mem_en && !top->d_mem_wen) { // Load operation signaled by CPU
            top->d_mem_rdata = memory_model.read_data_word(top->d_mem_addr);
        } else {
            top->d_mem_rdata = 0xDEADBEEF; // Default for non-load cycles (or previous value)
        }

        // Evaluate with all inputs (i_mem_rdata, d_mem_rdata) set for the upcoming positive edge
        top->eval();
        tfp->dump(sim_time++); // Dump signals at negedge with inputs ready

        // --- Positive Edge of Clock ---
        top->clk = 1;
        top->eval(); // CPU internal states update (PC_reg, Register File write)
        tfp->dump(sim_time++);

        // --- Post-clock edge actions: Observe CPU outputs, update models ---
        printf("%5d | 0x%08X | 0x%08X | 0x%08X | %7d | 0x%08X | %7d | 0x%08X | %6d | x%-8d | 0x%08X\n",
               cycle,
               current_pc_for_fetch, // PC used for fetch this cycle
               instruction_word,
               top->d_mem_addr,
               (top->d_mem_en && top->d_mem_wen ? 1 : 0),
               top->d_mem_wdata,
               (top->d_mem_en && !top->d_mem_wen ? 1 : 0),
               (top->d_mem_en && !top->d_mem_wen ? top->d_mem_rdata : 0x0), // Show rdata if it was a load
               top->debug_reg_wen,
               top->debug_reg_waddr,
               top->debug_reg_wdata
        );


        // 1. Data Memory Write (for SW):
        if (top->d_mem_en && top->d_mem_wen) { // Store operation signaled by CPU
            memory_model.write_data_word(top->d_mem_addr, top->d_mem_wdata, top->d_mem_wmask);
            printf("        MEM_WRITE: M[0x%08X] <= 0x%08X (mask 0x%X)\n", top->d_mem_addr, top->d_mem_wdata, top->d_mem_wmask);
        }

        // 2. Update Shadow Register File for verification
        if (top->debug_reg_wen) {
            if (top->debug_reg_waddr != 0) { // x0 should remain 0
                shadow_regs[top->debug_reg_waddr] = top->debug_reg_wdata;
            }
            printf("        REG_WRITE: x%d <= 0x%08X\n", top->debug_reg_waddr, top->debug_reg_wdata);
        }
        if (shadow_regs[0] != 0) { // Hard check for x0
            fprintf(stderr, "ERROR: Shadow register x0 is not zero!\n");
            shadow_regs[0] = 0; // Correct it for future checks
        }


        // --- Verification & Halt Condition ---
        // Example assertions (add more as needed for your program)
        if (current_pc_for_fetch == 0x00000008 && top->debug_reg_wen) { // After ADD x3, x1, x2
             assert(shadow_regs[1] == 10); // from addi x1, x0, 10
             assert(shadow_regs[2] == 20); // from addi x2, x0, 20
             assert(shadow_regs[3] == 30); // from add x3, x1, x2
             printf("        VERIFY: x1=10, x2=20, x3=30 PASSED\n");
        }
        if (current_pc_for_fetch == 0x00000010 && top->debug_reg_wen && top->debug_reg_waddr == 4) { // After LW x4, 4(x0)
            assert(shadow_regs[4] == 30); // Loaded from M[4]
            assert(memory_model.read_data_word(4) == 30); // Check data memory directly
            printf("        VERIFY: x4=30 (from M[4]) PASSED\n");
        }
         if (current_pc_for_fetch == 0x00000018 && top->debug_reg_wen && top->debug_reg_waddr == 5) { // After ADDI x5, x0, 5
            assert(shadow_regs[5] == 5);
            printf("        VERIFY: x5=5 PASSED\n");
        }


        // Halt condition: PC stuck at the self-looping BEQ
        uint32_t halt_pc_target = 0x0000001C;
        uint32_t halt_instruction = 0x00000063;
        if (current_pc_for_fetch == halt_pc_target && instruction_word == halt_instruction) {
            if (last_halt_pc == (int)current_pc_for_fetch) {
                halt_pc_streak++;
            } else {
                halt_pc_streak = 1;
            }
            last_halt_pc = current_pc_for_fetch;

            if (halt_pc_streak >= 5) { // Stuck for 5 cycles
                printf("\nProgram HALTED at PC 0x%08X after %d cycles.\n", current_pc_for_fetch, cycle + 1);
                goto tests_done; // Break out of the loop
            }
        } else {
            halt_pc_streak = 0; // Reset if PC moves or instruction changes
            last_halt_pc = -1;
        }

        if (cycle >= MAX_CYCLES - 1) {
            printf("\nMax cycles (%d) reached. Simulation ending.\n", MAX_CYCLES);
        }
    }

tests_done:
    // Final checks (optional)
    printf("\n--- Final State ---\n");
    printf("Shadow Registers:\n");
    for (int i = 0; i < 32; ++i) {
        if (shadow_regs[i] != 0) { // Print non-zero registers
            printf("  x%02d: 0x%08X\n", i, shadow_regs[i]);
        }
    }
    printf("Data Memory (at address 4): 0x%08X\n", memory_model.read_data_word(4));


    // Assert final expected values
    assert(shadow_regs[1] == 10);
    assert(shadow_regs[2] == 20);
    assert(shadow_regs[3] == 30);
    assert(memory_model.read_data_word(4) == 30);
    assert(shadow_regs[4] == 30);
    assert(shadow_regs[5] == 5);
    std::cout << "\nALL FINAL ASSERTIONS PASSED SUCCESSFULLY!" << std::endl;


    tfp->close();
    delete top;
    delete tfp;
    return 0;
}