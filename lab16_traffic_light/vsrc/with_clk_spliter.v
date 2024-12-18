module with_spliter (
    input clk100mhz,
    output reg[2:0] AN,
   output reg[7:0] control_display_signal,
);
    wire clk100hz;
    wire clk1hz;
    clksplitter C (
        .clk100mhz(clk100mhz),
        .clk_100hz(clk100hz),
        .clk_1hz(clk1hz)
    );

    traffic_light_display_unit U(
        .clk_100hz(clk100hz),
        .clk_1hz(clk1hz),
        .AN(AN),
        .control_display_signal(control_display_signal),
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
