module priority_encoder (
    input [7:0] A,     // 4-bit input
    output reg [2:0] Y, // 2-bit output representing position
    output reg valid   // Indicates if there is any valid input
);

    always @(*) begin
        valid = 1; // Assume there's a valid input by default
        casez (A)
            8'b1???????: Y = 3'd7; // Highest priority - A[7]
            8'b01??????: Y = 3'd6;
            8'b001?????: Y = 3'd5;
            8'b0001????: Y = 3'd4;
            8'b00001???: Y = 3'd3;
            8'b000001??: Y = 3'd2;
            8'b0000001?: Y = 3'd1;
            8'b00000001: Y = 3'd0;
            default: begin
                Y = 3'd0;   // Default output
                valid = 0;   // No valid input
            end
        endcase
    end
endmodule