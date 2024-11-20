module register_74LS191 (
    input [3:0] D,      
    input NLD,           
    input NCT,
    input NUD,
    input CP,
    output reg [3:0] Q  
);

   always @(posedge CP or negedge NLD) begin
      if (~NLD)
         Q <= D;
      else if ((~NCT) &(~NUD))  // add
         Q <= Q +1;
      else if ((~NCT) & NUD) // sub
         Q <= Q-1;
      else  // NCT == 1 && NLD == 1
         Q <= Q; // keep
   end

endmodule