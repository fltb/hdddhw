module digit_display_with_clk_spliter (
   input [31:0] data,
   input clk_100mhz,
   output reg[2:0] AN,
   output reg[7:0] control_display_signal

);
    
endmodule

module clksplitter (
   input clk100mhz,
   output clk_100hz,
   output clk_1hz
);
   reg [31:0] cnt100hz;
   reg [31:0] cnt1hz;
   initial begin
      cnt100hz = 32'd0;
      cnt1hz = 32'd0;
   end

   always @(posedge clk100mhz) begin
      if (cnt100hz == (32'd1000000 - 1))begin
         cnt100hz <= 0;
      end else begin
         cnt100hz <= cnt100hz + 1;
      end

      if (cnt1hz == (32'd100000000 - 1))begin
         cnt1hz <= 0;
      end else begin
         cnt1hz <= cnt1hz + 1;
      end
   end

   assign clk_100hz = (cnt100hz == 32'd0);
   assign clk_1hz = (cnt1hz == 32'd0);
endmodule


module digit_display (
   input [31:0] data,
   // count should be done in vivado, just increase it when clock arrive
   input clk_100hz,
   output reg[2:0] AN,
   output reg[7:0] control_display_signal
);
   reg [2:0] which=0;
   reg [3:0] digitSelected;
   always @(posedge clk_100hz) begin
      which <= which + 1'b1;
   end
   bit_sel_DATA_and_AN BS (
      .bit_sel(which),
      .data(data),
      .AN(AN),
      .data_selected(digitSelected)
   );
   digit_signal_to_display DS (
      .digit_signal(digitSelected),
      .control_display_signal(control_display_signal)
   );
endmodule

module bit_sel_DATA_and_AN (
   input [2:0] bit_sel,
   input [31:0] data,
   output reg[2:0] AN,
   output reg[3:0] data_selected
);
   assign AN = bit_sel;
   always @(*) begin
         case (bit_sel)
         3'd0: begin
            data_selected = data[31:28];
         end  
         3'd1: begin
            data_selected = data[27:24];
         end
         3'd2: begin
            data_selected = data[23:20];
         end
         3'd3: begin
            data_selected = data[19:16];
         end
         3'd4: begin
            data_selected = data[15:12];
         end
         3'd5: begin
            data_selected = data[11:8];
         end
         3'd6: begin
            data_selected = data[7:4];
         end
         3'd7: begin
            data_selected = data[3:0];
         end
      endcase
   end
endmodule

module digit_signal_to_display (
   input [3:0] digit_signal,
   output reg [7:0] control_display_signal
);
   always @(*) begin
      case (digit_signal)
         4'h0: control_display_signal = 8'b0000_0011;
         4'h1: control_display_signal = 8'b1001_1111;
         4'h2: control_display_signal = 8'b0010_0101;
         4'h3: control_display_signal = 8'b0000_1101;
         4'h4: control_display_signal = 8'b1001_1001;
         4'h5: control_display_signal = 8'b0100_1001;
         4'h6: control_display_signal = 8'b0100_0001;
         4'h7: control_display_signal = 8'b0001_1111;
         4'h8: control_display_signal = 8'b0000_0001;
         4'h9: control_display_signal = 8'b0000_1001;
         4'hA: control_display_signal = 8'b0001_0001;
         4'hB: control_display_signal = 8'b1100_0001;
         4'hC: control_display_signal = 8'b0110_0011;
         4'hD: control_display_signal = 8'b1000_0101;
         4'hE: control_display_signal = 8'b0110_0001;
         4'hF: control_display_signal = 8'b0111_0001;
      endcase
   end
endmodule

module dot_signal_to_display (
   output reg [7:0] control_display_signal
);
   assign control_display_signal = 8'b1111_1110;
endmodule