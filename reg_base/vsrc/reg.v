module register_8bit (
    input [7:0] D,      
    input NOE,           
    input clk,          
    input clr,          
    output reg [7:0] Q  
);

   always @(posedge clk or posedge clr) begin
      if (clr)
         Q <= 8'b0;
      else if (~NOE)
         Q <= D;
   end

endmodule