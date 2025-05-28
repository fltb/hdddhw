// --------------------------------------
// RiscV_CPU_Top.v
// --------------------------------------
module RiscV_CPU_Top (
    input  wire        clk,
    input  wire        rst,

    // Instruction Memory Interface
    output wire [31:0] i_mem_addr,
    input  wire [31:0] i_mem_rdata,

    // Data Memory Interface
    output wire [31:0] d_mem_addr,
    output wire [31:0] d_mem_wdata,
    output wire [3:0]  d_mem_wmask,
    output wire        d_mem_en,
    output wire        d_mem_wen,
    input  wire [31:0] d_mem_rdata,

    // Debug/Observation
    output wire [31:0] debug_pc,
    output wire [31:0] debug_reg_wdata,
    output wire [4:0]  debug_reg_waddr,
    output wire        debug_reg_wen
);

    // ----- PC -----
    reg  [31:0] pc_reg;
    wire [31:0] pc_next, pc_plus_4, pc_target;
    wire        pc_sel;

    assign pc_plus_4    = pc_reg + 32'd4;
    assign i_mem_addr   = pc_reg;
    assign debug_pc     = pc_reg;

    always @(posedge clk or posedge rst) begin
        if (rst) pc_reg <= 32'h0;
        else      pc_reg <= pc_next;
    end

    // ----- IF/ID -----
    wire [31:0] instr = i_mem_rdata;
    wire [6:0]  opcode  = instr[6:0];
    wire [4:0]  rd      = instr[11:7];
    wire [2:0]  funct3  = instr[14:12];
    wire [4:0]  rs1     = instr[19:15];
    wire [4:0]  rs2     = instr[24:20];
    wire [6:0]  funct7  = instr[31:25];

    // ----- Control -----
    wire        RegWrite, MemRead, MemWrite, MemToReg;
    wire        ALUSrc;
    wire [1:0]  ALUOp;
    wire        Branch, Jump;

    ControlUnit ctrl (
        .opcode   (opcode),
        .RegWrite (RegWrite),
        .MemRead  (MemRead),
        .MemWrite (MemWrite),
        .MemToReg (MemToReg),
        .ALUSrc   (ALUSrc),
        .ALUOp    (ALUOp),
        .Branch   (Branch),
        .Jump     (Jump)
    );

    assign debug_reg_wen   = RegWrite;
    assign debug_reg_waddr = rd;

    // ----- Immediate Generator -----
    wire [31:0] imm;
    ImmGen ig (
        .instr   (instr),
        .imm_out (imm)
    );

    // ----- Register File -----
    wire [31:0] rd_data1, rd_data2;
    wire [31:0] link_address = pc_plus_4;
    wire [31:0] alu_or_mem_data = MemToReg ? d_mem_rdata : alu_res;
    wire [31:0] wb_data = (Jump && RegWrite) ? link_address : alu_or_mem_data; // Jump 信号来自 ControlUnit
    // wire [31:0] wb_data = (MemToReg ? d_mem_rdata : /* ALU result */ alu_res);

    RegisterFile rf (
        .clk      (clk),
        .rst      (rst),
        .rs1_addr (rs1),
        .rs2_addr (rs2),
        .rd_addr  (rd),
        .rd_wdata (wb_data),
        .rd_wen   (RegWrite),
        .rs1_data (rd_data1),
        .rs2_data (rd_data2)
    );
    assign debug_reg_wdata = wb_data;

    // ----- ALU Control -----
    wire [3:0] alu_ctrl;
    ALUControl aluctrl (
        .ALUOp     (ALUOp),
        .funct7    (funct7),
        .funct3    (funct3),
        .alu_ctrl  (alu_ctrl)
    );

    // ----- ALU -----
    wire [31:0] alu_in2 = ALUSrc ? imm : rd_data2;
    wire        zero;
    wire [31:0] alu_res;
    ALU alu (
        .a        (rd_data1),
        .b        (alu_in2),
        .alu_ctrl (alu_ctrl),
        .result   (alu_res),
        .zero     (zero)
    );

    // ----- Data Memory -----
    assign d_mem_addr = alu_res;
    assign d_mem_wdata = rd_data2;
    assign d_mem_en   = MemRead | MemWrite;
    assign d_mem_wen  = MemWrite;
    assign d_mem_wmask = 4'b1111;

    // ----- Branch Target / PC Logic -----
    BranchCalc bcalc (
        .pc        (pc_reg),
        .imm       (imm),
        .rs1_data  (rd_data1),
        .zero      (zero),
        .Branch    (Branch),
        .Jump      (Jump),
        .pc_sel    (pc_sel),
        .pc_target (pc_target)
    );

    assign pc_next = pc_sel ? pc_target : pc_plus_4;

endmodule


// --------------------------------------
// ControlUnit.v
// --------------------------------------
module ControlUnit (
    input  wire [6:0] opcode,
    output reg        RegWrite,
    output reg        MemRead,
    output reg        MemWrite,
    output reg        MemToReg,
    output reg        ALUSrc,
    output reg [1:0]  ALUOp,
    output reg        Branch,
    output reg        Jump
);
    always @(*) begin
        // defaults
        RegWrite = 0; MemRead = 0; MemWrite = 0; MemToReg = 0;
        ALUSrc   = 0; ALUOp    = 2'b00; Branch    = 0; Jump      = 0;
        case (opcode)
            7'b0110011: begin // R-type
                RegWrite = 1; ALUOp = 2'b10;
            end
            7'b0010011: begin // I-type ALU
                RegWrite = 1; ALUSrc = 1; ALUOp = 2'b10;
            end
            7'b0000011: begin // Load
                RegWrite = 1; MemRead = 1; MemToReg = 1; ALUSrc = 1; ALUOp = 2'b00;
            end
            7'b0100011: begin // Store
                MemWrite = 1; ALUSrc = 1; ALUOp = 2'b00;
            end
            7'b1100011: begin // Branch
                Branch = 1; ALUOp = 2'b01;
            end
            7'b1101111: begin // JAL
                RegWrite = 1; Jump = 1;
            end
            7'b1100111: begin // JALR
                RegWrite = 1; Jump = 1; ALUSrc = 1;
            end
            7'b0010111, 7'b0110111: begin // AUIPC, LUI
                RegWrite = 1; ALUSrc = 1; ALUOp = 2'b11; // special code
            end
            default: begin
                // 可选：保留默认值，也可以显示置零
                RegWrite = 0; MemRead = 0; MemWrite = 0; MemToReg = 0;
                ALUSrc   = 0; ALUOp    = 2'b00; Branch    = 0; Jump = 0;
            end
        endcase
    end
endmodule


// --------------------------------------
// ImmGen.v
// --------------------------------------
module ImmGen (
    input  wire [31:0] instr,
    output reg  [31:0] imm_out
);
    wire [6:0] opcode = instr[6:0];
    always @(*) begin
        case (opcode)
            7'b0010011, 7'b0000011, 7'b1100111: // I-type
                imm_out = {{20{instr[31]}}, instr[31:20]};
            7'b0100011: // S-type
                imm_out = {{20{instr[31]}}, instr[31:25], instr[11:7]};
            7'b1100011: // B-type
                imm_out = {{19{instr[31]}}, instr[31], instr[7], instr[30:25], instr[11:8], 1'b0};
            7'b0010111, 7'b0110111: // U-type
                imm_out = {instr[31:12], 12'b0};
            7'b1101111: // J-type
                imm_out = {{11{instr[31]}}, instr[31], instr[19:12],
                           instr[20], instr[30:21], 1'b0};
            default:
                imm_out = 32'd0;
        endcase
    end
endmodule


// --------------------------------------
// RegisterFile.v
// --------------------------------------
module RegisterFile (
    input  wire        clk,
    input  wire        rst,
    input  wire [4:0]  rs1_addr,
    input  wire [4:0]  rs2_addr,
    input  wire [4:0]  rd_addr,
    input  wire [31:0] rd_wdata,
    input  wire        rd_wen,
    output wire [31:0] rs1_data,
    output wire [31:0] rs2_data
);
    reg [31:0] regs [0:31];
    integer i;
    // reset all regs to 0
    always @(posedge clk) if (rst) for (i=0; i<32; i=i+1) regs[i]<=32'd0;
    // write
    always @(posedge clk) if (rd_wen && rd_addr!=0) regs[rd_addr] <= rd_wdata;
    assign rs1_data = regs[rs1_addr];
    assign rs2_data = regs[rs2_addr];
endmodule


// --------------------------------------
// ALUControl.v
// --------------------------------------
module ALUControl (
    input  wire [1:0] ALUOp,
    input  wire [6:0] funct7,
    input  wire [2:0] funct3,
    output reg  [3:0] alu_ctrl
);
    always @(*) begin
        case (ALUOp)
            2'b00: alu_ctrl = 4'b0000; // ADD for load/store
            2'b01: alu_ctrl = 4'b0001; // SUB for branch
            2'b10: begin // R/I type
                case ({funct7[5], funct3})
                    4'b0000: alu_ctrl = funct7[5]?4'b0001:4'b0000; // SUB/ADD
                    4'b0001: alu_ctrl = 4'b0010; // SLL
                    4'b0010: alu_ctrl = 4'b0011; // SLT
                    4'b0011: alu_ctrl = 4'b0100; // SLTU
                    4'b0100: alu_ctrl = 4'b0101; // XOR
                    4'b0101: alu_ctrl = funct7[5]?4'b0111:4'b0110; // SRA/SRL
                    4'b0110: alu_ctrl = 4'b1000; // OR
                    4'b0111: alu_ctrl = 4'b1001; // AND
                    default: alu_ctrl = 4'b0000;
                endcase
            end
            2'b11: alu_ctrl = 4'b0000; // for LUI/AUIPC, effectively pass imm or PC+imm
            default: alu_ctrl = 4'b0000;
        endcase
    end
endmodule


// --------------------------------------
// ALU.v
// --------------------------------------
module ALU (
    input  wire [31:0] a,
    input  wire [31:0] b,
    input  wire [3:0]  alu_ctrl,
    output reg  [31:0] result,
    output wire        zero
);
    always @(*) begin
        case (alu_ctrl)
            4'b0000: result = a + b;
            4'b0001: result = a - b;
            4'b0010: result = a << b[4:0];
            4'b0011: result = ($signed(a) < $signed(b)) ? 32'd1 : 32'd0;
            4'b0100: result = (a < b) ? 32'd1 : 32'd0;
            4'b0101: result = a ^ b;
            4'b0110: result = a >> b[4:0];
            4'b0111: result = $signed(a) >>> b[4:0];
            4'b1000: result = a | b;
            4'b1001: result = a & b;
            default: result = 32'd0;
        endcase
    end
    assign zero = (result == 32'd0);
endmodule


// --------------------------------------
// BranchCalc.v
// 合并 BranchTargetAddressCalculator 和 BranchDecisionLogic
// --------------------------------------
module BranchCalc (
    input  wire [31:0] pc,
    input  wire [31:0] imm,
    input  wire [31:0] rs1_data,
    input  wire        zero,
    input  wire        Branch,
    input  wire        Jump,
    output wire        pc_sel,
    output wire [31:0] pc_target
);
    wire branch_taken = Branch & zero;
    assign pc_sel    = branch_taken | Jump;
    assign pc_target = Jump
                       ? (rs1_data + imm)            // JALR
                       : (pc + imm);                 // BEQ, BNE, JAL
endmodule
