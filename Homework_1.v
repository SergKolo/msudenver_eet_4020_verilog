/*  Title: Homework 1
 *  Description: Homework assignment #1 for EET-4020
 *  Author: Sergiy Kolodyazhnyy
 *  Date: 2/23/2017
 *
 */

/* #1: Create your own 2-input verilog gates 
 * called my_or,my_and,and my_not from 2-input nand gates.
 */

module my_and(C,A,B); 
    // Output definitions
    output C;
    input A,B;
    wire W1;
    // AND gate implemented with NAND gates is
    // effectively two nand gates, daisy chained.
    nand input_nand(W1,A,B);
    nand output_nand(C,W1,W1);
endmodule

module my_or(C,A,B);
    // input and output definitions
    output C;
    input A,B;
    wire A_out;
    wire B_out;
    // or gate can be implemented via two
    // not gates implemented with nand, and output of each
    // sent to another nand
    nand input_nand1(A_out,A,A);
    nand input_nand2(B_out,B,B);
    nand output_nand(C,A_out,B_out);
endmodule

module my_not(C,A);
    output C;
    input A;
    nand output_nand(C,A,A);
endmodule

/*
 * #2: Create a 2-input xorg gate, built 
 * from the gates you designed in problem #1
 */

module my_xor(Z,X,Y);
    //output and input definitions
    output Z;
    input X,Y;
    wire Y_not,X_not,x_and_Yprime,Y_and_Xprime;
    // instantiate the gates
    my_not mn1(Y_not,Y);
    my_not mn2(X_not,X);

    my_and ma1(X_and_Yprime,mn1,X);
    my_and ma2(Y_and_Xprime,mn2,Y);

    my_or mo(Z,X_and_Yprime,Y_and_Xprime);
endmodule

/* #3: Design a 2-to-1 multiplexer using bufif0 and bufif1 gates
 *
 */
module mux_2to1(OUT,IN0,IN1,S0);
    output OUT;
    input IN0,IN1,S0;
    wire S0_not;
    
    not(S0_not,S0);
    bufif0 b0(OUT,IN0,S0_not);
    bufif1 b1(OUT, IN1,S0);
endmodule
