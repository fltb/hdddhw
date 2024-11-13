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

module gen(
    input [3:0] A,
    input [3:0] B,
    output [3:0] G
);
    assign G = A & B;
endmodule

module prop(
    input [3:0] A,
    input [3:0] B,
    output [3:0] P
);
    assign P = A | B;
endmodule

module csa (
    input [3:0] A,
    input [3:0] B,
    input Cin,
    output [3:0] Sum,
    output CarryOut
);

    wire [3:0] discard;
    wire [3:0] G;
    wire [3:0] P;
    wire [3:0] C;

    gen G0 (
        .A(A),
        .B(B),
        .G(G)
    );

    prop P0 (
        .A(A),
        .B(B),
        .P(P)
    );

    assign C[0] = G[0] | (P[0] & Cin);
    assign C[1] = G[1] | (P[1] & G[0]) | (P[1] & P[0] & Cin);
    assign C[2] = G[2] | (P[2] & G[1]) | (P[2] & P[1] & G[0]) | (P[2] & P[1] & P[0] & Cin);

    singleBitAdder U0 (
        .A(A[0]),
        .B(B[0]),
        .Cin(Cin),
        .Sum(Sum[0]),
        .CarryOut(discard[0])
    );

    singleBitAdder U1 (
        .A(A[1]),
        .B(B[1]),
        .Cin(C[0]),
        .Sum(Sum[1]),
        .CarryOut(discard[1])
    );

    singleBitAdder U2 (
        .A(A[2]),
        .B(B[2]),
        .Cin(C[1]),
        .Sum(Sum[2]),
        .CarryOut(discard[2])
    );

    singleBitAdder U3 (
        .A(A[3]),
        .B(B[3]),
        .Cin(C[2]),
        .Sum(Sum[3]),
        .CarryOut(CarryOut)
    );

endmodule

