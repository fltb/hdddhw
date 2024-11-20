module register_74LS198 (
    input [7:0] D,      
    input NCR,           
    input S1,
    input S0,
    input SL,
    input SR,        
    input CP,          
    output reg [7:0] Q  
);

   always @(posedge CP or negedge NCR) begin
      if (~NCR)
         Q <= 8'd0;
      else if (S0 & (~S1)) // SR at high(right)
         Q <= ({SR, Q[7:1]});
      else if ((~S0) & S1) // SL at low(left)
         Q <= ({Q[6:0], SL});
      else if (S0 & S1) // Set D
         Q <= D;
      else // 0 0 keep
         Q <= Q;
   end

endmodule