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
