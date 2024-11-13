module singleBitAdder (
    input A,
    input B,
    input Cin,
    output Sum,
    output CarryOut
);
    assign Sum = A ^ B ^ Cin;
    assign CarryOut = (A & B) | (B & Cin) | (A & Cin);
endmodule

module multiBitAdder (
    input [3:0] A,
    input [3:0] B,
    input Cin,
    output [3:0] Sum,
    output CarryOut
);
    wire [2:0] carry;

    singleBitAdder U0 (
        .A(A[0]),
        .B(B[0]),
        .Cin(Cin),
        .Sum(Sum[0]),
        .CarryOut(carry[0])
    );

    singleBitAdder U1 (
        .A(A[1]),
        .B(B[1]),
        .Cin(carry[0]),
        .Sum(Sum[1]),
        .CarryOut(carry[1])
    );

    singleBitAdder U2 (
        .A(A[2]),
        .B(B[2]),
        .Cin(carry[1]),
        .Sum(Sum[2]),
        .CarryOut(carry[2])
    );

    singleBitAdder U3 (
        .A(A[3]),
        .B(B[3]),
        .Cin(carry[2]),
        .Sum(Sum[3]),
        .CarryOut(CarryOut)
    );

endmodule

