
module alu(Data,clk_A,clk_25M,clk_B,clk_F,rst_n,AN,SEG,FR);
      input  clk_A,clk_B,clk_F,rst_n;
	  input  [32:1] Data;
	  input  clk_25M;
	  output [3:0] AN;
      output [7:0] SEG;
	  output  reg [3:0]FR;
	  reg [32:1] F;
	  reg [32:1] A;
	  reg [32:1] B;
	  reg [4:1] ALU_OP;
	  reg  ZF,OF,CF,SF;
	  shumaguan uut(
	  .Data(F),
	  .AN(AN),
	  .clk_25M(clk_25M),
	  .SEG(SEG)
	  );
	  always @(posedge clk_A or posedge rst_n)
	  begin
	       if(rst_n)
	           A<=32'b0;
	       else
	           A<=Data;
	  end
	  always @(posedge clk_B or posedge rst_n)
	  begin
	       if(rst_n)
	           B<=32'b0;
	       else
	           B<=Data;
	  end
	  always @(posedge clk_F or posedge rst_n)
	  begin 
	       if(rst_n)
	           F=32'b0;
	       else
	           begin
	               ALU_OP=Data[32:29];
	               OF=0;
	               CF=0;
	               case(ALU_OP)
	                   4'b0000: begin {CF,F}=A+B; end
	                   4'b0001: begin F=A<<B; end
	                   4'b0010: begin F=($signed(A) < $signed(B))?1:0; end
	                   4'b0011: begin F=A<B?1:0; end
	                   4'b0100: begin F=A^B; end
	                   4'b0101: begin F=A>>B; end
	                   4'b0110: begin F=A|B; end
	                   4'b0111: begin F=A&B; end
	                   4'b1000: begin {CF,F}=A-B; end
	                   4'b1101: begin F=$signed(A)>>>B; end
	               endcase 
	               ZF = F==0;
	               SF = F[32];
	               OF = A[32]^B[32]^CF^F[32];
	               
	               FR[3]=ZF;
				   FR[2]=SF;
				   FR[1]=CF;
				   FR[0]=OF;
	           end
	  end
endmodule

module shumaguan(
      input [32:1]Data,
      input clk_25M,	
      output [3:0] AN,
      output [7:0] SEG
    );
    reg [4:1] Data_4;
    wire[2:0] BIT_SEL;
	reg Increment;
	integer clk_num=0;
	
	delay_5ms uu1(clk_25M,BIT_SEL);
	always @(*)
	begin
	   case(BIT_SEL)
	       0: Data_4[4:1]=Data[32:29];
	       1: Data_4[4:1]=Data[28:25];
	       2: Data_4[4:1]=Data[24:21];
	       3: Data_4[4:1]=Data[20:17];
	       4: Data_4[4:1]=Data[16:13];
	       5: Data_4[4:1]=Data[12:9];
	       6: Data_4[4:1]=Data[8:5];
	       7: Data_4[4:1]=Data[4:1];
	       default:Data_4[4:1]<=Data[4:1];
	   endcase 
	end
	SMG uu2(Data_4,BIT_SEL,SEG,AN);
endmodule

module delay_5ms(clk_25M,BIT_SEL);
	input clk_25M;
	output reg[2:0] BIT_SEL;
	integer cnt=0;
	initial begin BIT_SEL <= 2'b00;end
	always@(posedge clk_25M)
	begin
				cnt<=cnt+1;
				if(cnt>50000)
				begin
					BIT_SEL<=BIT_SEL+2'b01;
					cnt<=0;
				end
	end
endmodule

module SMG(
	  input wire[3:0] data,	
     input wire[2:0] bit_sel,
     output reg[7:0] seg,
     output reg[3:0] AN
);
	always @(*)
		begin
			case(bit_sel)
				3'b000:AN<=4'b1000;
				3'b001:AN<=4'b1001;
				3'b010:AN<=4'b1010;
				3'b011:AN<=4'b1011;
				3'b100:AN<=4'b1100;
				3'b101:AN<=4'b1101;
				3'b110:AN<=4'b1110;
				3'b111:AN<=4'b1111;
				default:AN<=4'b1111;
			endcase
		end
	always @(*)
		begin
			case(data[3:0])
				0:seg[7:0]<=8'b00000011;
				1:seg[7:0]<=8'b10011111;
				2:seg[7:0]<=8'b00100101;
				3:seg[7:0]<=8'b00001101;
				4:seg[7:0]<=8'b10011001;
				5:seg[7:0]<=8'b01001001;
				6:seg[7:0]<=8'b01000001;
				7:seg[7:0]<=8'b00011111;
				8:seg[7:0]<=8'b00000001;
				9:seg[7:0]<=8'b00001001;
				10:seg[7:0]<=8'b00010001;
				11:seg[7:0]<=8'b11000001;
				12:seg[7:0]<=8'b01100011;
				13:seg[7:0]<=8'b10000101;
				14:seg[7:0]<=8'b01100001;
				15:seg[7:0]<=8'b01110001;
				default:seg[7:0]<=8'b11111111;
			endcase
		end
endmodule

module regheap(
    input wire clk_Regs,      // Clock for write operations
    input wire Reg_Write,     // Write enable signal
    input wire [4:0] R_Addr_A,  // Read address for port A
    input wire [4:0] R_Addr_B,  // Read address for port B
    input wire [4:0] W_Addr,    // Write address
    input wire [31:0] W_Data,   // Data to write
    output wire [31:0] R_Data_A, // Data read from port A
    output wire [31:0] R_Data_B  // Data read from port B
);

    // Parameters
    localparam DATA_WIDTH = 32;
    localparam ADDR_WIDTH = 5;
    localparam NUM_REGISTERS = 1 << ADDR_WIDTH; // 32 registers

    // Register array
    // 32 registers, each 32 bits wide.
    reg [DATA_WIDTH-1:0] registers [NUM_REGISTERS-1:0];
    // Synchronous Write Port
    // Writes occur on the positive edge of clk_Regs if Reg_Write is enabled.
    // Writing to address 0 (x0) is prevented to keep it as zero.
    always @(posedge clk_Regs) begin
        if (Reg_Write) begin
            if (W_Addr != 5'b00000) begin // Prevent writing to register x0
                registers[W_Addr] <= W_Data;
            end
        end
    end

    // Asynchronous Read Port A
    // If R_Addr_A is 0, output 0 (for x0). Otherwise, output the register content.
    assign R_Data_A = (R_Addr_A == 5'b00000) ? {DATA_WIDTH{1'b0}} : registers[R_Addr_A];

    // Asynchronous Read Port B
    // If R_Addr_B is 0, output 0 (for x0). Otherwise, output the register content.
    assign R_Data_B = (R_Addr_B == 5'b00000) ? {DATA_WIDTH{1'b0}} : registers[R_Addr_B];

    // Initialization block (primarily for simulation)
    // This sets all registers to 0 at the beginning of a simulation.
    // Register x0 is intrinsically 0 due to read logic, but initializing its storage is good practice.
    integer i;
    initial begin
        registers[0] = {DATA_WIDTH{1'b0}}; // Ensure x0 storage is 0
        for (i = 1; i < NUM_REGISTERS; i = i + 1) begin
            registers[i] = {DATA_WIDTH{1'b0}}; // Initialize other registers to 0
        end
    end

endmodule

