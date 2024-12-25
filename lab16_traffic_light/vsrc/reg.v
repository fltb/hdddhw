module traffic_light_display_unit (
   input clk_100hz,
   input clk_1hz,
   output reg[2:0] AN,
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
   always @(posedge clk_1hz) begin
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
      .clk_100hz(clk_100hz),
      .data(data),
      .AN(AN),
      .control_display_signal(control_display_signal)
   );
endmodule

module digit_display (
   input [31:0] data,
   // count should be done in vivado, just make this clock
   input clk_100hz,
   output reg[2:0] AN,
   output reg[7:0] control_display_signal
);
   reg [2:0] which=0;
   reg [3:0] digitSelected;
   always @(posedge clk_100hz) begin
      which <= which + 1'b1;
   end
   bit_sel_decimal BS (
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

module bit_sel_decimal (
    input [2:0] bit_sel,           // 位选择，范围 0-7
    input [31:0] data,             // 32 位输入数据
      output reg[2:0] AN,
    output reg [3:0] data_selected // 输出的十进制数字（0-9）
);
      assign AN = bit_sel;

    reg [31:0] upper_decimal; // data[31:16] 的十进制值
    reg [31:0] lower_decimal; // data[15:0] 的十进制值
   typedef logic [3:0] FOURBIT;
    // 提取逻辑
    always @(*) begin
        upper_decimal = data[31:16] * 1; // 转换为十进制
        lower_decimal = data[15:0] * 1;  // 转换为十进制

        // 根据 bit_sel 提取相应的数字
        case (bit_sel)
               3'd0: data_selected = FOURBIT'((upper_decimal / 1000) % 10); // data[31:16] 的第 3 位
               3'd1: data_selected = FOURBIT'((upper_decimal / 100) % 10);  // data[31:16] 的第 2 位
               3'd2: data_selected = FOURBIT'((upper_decimal / 10) % 10);   // data[31:16] 的第 1 位
               3'd3: data_selected = FOURBIT'( (upper_decimal) % 10);        // data[31:16] 的第 0 位
               3'd4: data_selected = FOURBIT'((lower_decimal / 1000) % 10); // data[15:0] 的第 3 位
               3'd5: data_selected = FOURBIT'((lower_decimal / 100) % 10);  // data[15:0] 的第 2 位
               3'd6: data_selected = FOURBIT'((lower_decimal / 10) % 10);   // data[15:0] 的第 1 位
               3'd7: data_selected = FOURBIT'((lower_decimal) % 10);        // data[15:0] 的第 0 位
               default: data_selected = 4'd0; // 默认输出 0
        endcase
    end
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