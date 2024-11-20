module stream_light (
    input [1:0] SW,      
    input clk, // remember to set this to 1HZ!!!!    
    input rst,
    input CP,
    output reg [15:0] LED
);
   reg [1:0] SW_PRE;
   always @(posedge clk or posedge rst or SW) begin
      if (rst | (SW != SW_PRE)) begin
         case (SW)
            2'b00: LED <= 16'h8000;
            2'b01: LED <= 16'h0001;
            2'b10: LED <= 16'h0180;
            2'b11: LED <= 16'h8001;
         endcase
         SW_PRE <= SW;
      end else begin // posedge clk
         case (SW)
            2'b00: LED <= {LED[0], LED[15:1]};
            2'b01: LED <= {LED[14:0], LED[15]};
            2'b10: LED <= {LED[14:8], LED[15], LED[0], LED[7:1]};
            2'b11: LED <= {LED[8], LED[15:9], LED[6:0], LED[7]};
         endcase
      end
   end
endmodule