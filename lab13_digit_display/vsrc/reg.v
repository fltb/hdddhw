module digit_display (
   input [31:0] data,
   // count should be done in vivado, just increase it when clock arrive
   input [14:0] count, 
   input clk,
   output reg[7:0] AN,
   output reg[7:0] control_display_signal
);
   reg [2:0] which=0;
   reg [3:0] digitSelected;
   always @(negedge clk) begin
      if (&count) which <= which + 1'b1;
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
   output reg[7:0] AN,
   output reg[3:0] data_selected
);
   always @(*) begin
         case (bit_sel)
         3'd0: begin
            AN = 8'b0111_1111;
            data_selected = data[31:28];
         end  
         3'd1: begin
            AN = 8'b1011_1111;
            data_selected = data[27:24];
         end
         3'd2: begin
            AN = 8'b1101_1111;
            data_selected = data[23:20];
         end
         3'd3: begin
            AN = 8'b1110_1111;
            data_selected = data[19:16];
         end
         3'd4: begin
            AN = 8'b1111_0111;
            data_selected = data[15:12];
         end
         3'd5: begin
            AN = 8'b1111_1011;
            data_selected = data[11:8];
         end
         3'd6: begin
            AN = 8'b1111_1101;
            data_selected = data[7:4];
         end
         3'd7: begin
            AN = 8'b1111_1110;
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