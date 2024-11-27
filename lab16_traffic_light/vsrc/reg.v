module traffic_light_display_unit (
   input clk_2ms,
   input clk_1s,
   output reg[7:0] AN,
   output reg[7:0] control_display_signal,
   // this is test, for product it should be placed in module reg
   output reg[31:0] data,
   output reg[2:0] RGY_PRI,
   output reg[2:0] RGY_SEC
);
   reg [1:0] state;
   reg [7:0] count;

   // reg [31:0] data;

   initial begin
      state=2'd0; // s0
      count=8'd34; 
      RGY_PRI=3'b010; // green
      RGY_SEC=3'b100; // red
   end
   always @(posedge clk_1s) begin
      case (state)
         2'b00:begin
            if (8'd0 == count) begin
               count <= 8'd4;
               state = 2'b01; // s1
               RGY_PRI=3'b001; // yellow
               RGY_SEC=3'b100; // red
            end else begin
               count <= count - 1;
               data <= {8'b0, count, 8'b0, count + 8'd5};
            end
         end
         2'b01:begin
            if (8'd0 == count) begin
               count <= 8'd24;
               state = 2'b10; // s2
               RGY_PRI=3'b100; // red
               RGY_SEC=3'b010; // green
            end else begin
               count <= count - 1;
               data <= {8'b0, count, 8'b0, count};
            end
         end
         2'b10:begin
            if (8'd0 == count) begin
               count <= 8'd4;
               state = 2'b11; // s3
               RGY_PRI=3'b100; // red
               RGY_SEC=3'b001; // yellow
            end else begin
               count <= count - 1;
               data <= {8'b0, count + 8'd5, 8'b0, count};
            end
         end
         2'b11:begin
            if (8'd0 == count) begin
               count <= 8'd34;
               state = 2'b00; // s0
               RGY_PRI=3'b010; // green
               RGY_SEC=3'b100; // red
            end else begin
               count <= count - 1;
               data <= {8'b0, count, 8'b0, count};
            end
         end  
      endcase
   end

   digit_display D (
      .clk_2ms(clk_2ms),
      .data(data),
      .AN(AN),
      .control_display_signal(control_display_signal)
   );
endmodule



module digit_display (
   input [31:0] data,
   // count should be done in vivado, just make this clock
   input clk_2ms,
   output reg[7:0] AN,
   output reg[7:0] control_display_signal
);
   reg [2:0] which=0;
   reg [3:0] digitSelected;
   always @(posedge clk_2ms) begin
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