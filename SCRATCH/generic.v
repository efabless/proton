module BUF (out, in);
input in;
output out;
endmodule

module TRIBUF (out, in, enable);
input in;
input enable;
output out;
endmodule

module INV (out, in);
input in;
output out;
endmodule

module AND2 (out, in);
input [1:0] in;
output out;
endmodule

module AND3 (out, in);
input [2:0] in;
output out;
endmodule

module AND4 (out, in);
input [3:0] in;
output out;
endmodule

module OR2 (out, in);
input [1:0] in;
output out;
endmodule

module OR3 (out, in);
input [2:0] in;
output out;
endmodule

module OR4 (out, in);
input [3:0] in;
output out;
endmodule

module NAND2 (out, in);
input [1:0] in;
output out;
endmodule

module NAND3 (out, in);
input [2:0] in;
output out;
endmodule


module NAND4 (out, in);
input [3:0] in;
output out;
endmodule

module NOR2 (out, in);
input [1:0] in;
output out;
endmodule

module NOR3 (out, in);
input [2:0] in;
output out;
endmodule

module NOR4 (out, in);
input [3:0] in;
output out;
endmodule

module XOR2 (out, in);
input [1:0] in;
output out;
endmodule

module XOR3 (out, in);
input [2:0] in;
output out;
endmodule

module XOR4 (out, in);
input [3:0] in;
output out;
endmodule

module XNOR2 (out, in);
input [1:0] in;
output out;
endmodule

module XNOR3 (out, in);
input [2:0] in;
output out;
endmodule

module XNOR4 (out, in);
input [3:0] in;
output out;
endmodule

module ENC2 (out, in, enable);
input [1:0] in;
input enable;
output out;
endmodule

module ENC4 (out, in, enable);
input [3:0] in;
input enable;
output [1:0] out;
endmodule

module ENC8 (out, in, enable);
input [7:0] in;
input enable;
output [2:0] out;
endmodule

module ENC16 (out, in, enable);
input [15:0] in;
input enable;
output [3:0] out;
endmodule

module ENC32 (out, in, enable);
input [31:0] in;
input enable;
output [4:0] out;
endmodule

module ENC64 (out, in, enable);
input [63:0] in;
input enable;
output [5:0] out;
endmodule

module DEC1 (out ,in, enable);
input in;
input enable;
output [1:0] out;
endmodule

module DEC2 (out ,in, enable);
input [1:0] in;
input enable;
output [3:0] out;
endmodule

module DEC3 (out ,in, enable);
input [2:0] in;
input enable;
output [7:0] out;
endmodule

module DEC4 (out ,in, enable);
input [3:0] in;
input enable;
output [15:0] out;
endmodule

module DEC5 (out ,in, enable);
input [4:0] in;
input enable;
output [31:0] out;
endmodule

module DEC6 (out ,in, enable);
input [5:0] in;
input enable;
output [63:0] out;
endmodule

module MUX2 (out, in, select);
input [1:0] in;
input select;
output out;
endmodule

module MUX4 (out, in, select);
input [3:0] in;
input [1:0] select;
output out;
endmodule

module MUX8 (out, in, select);
input [7:0] in;
input [2:0] select;
output out;
endmodule

module MUX16 (out, in, select);
input [15:0] in;
input [3:0] select;
output out;
endmodule

module MUX32 (out, in, select);
input [31:0] in;
input [4:0] select;
output out;
endmodule

module MUX64 (out, in, select);
input [63:0] in;
input [5:0] select;
output out;
endmodule

module ADD1 (in1, in2, cin, cout, out);
input in1;
input in2;
input cin;
output cout;
output out;
endmodule

module ADD2 (in1, in2, cin, cout, out);
input [1:0] in1;
input [1:0] in2;
input cin;
output cout;
output [1:0] out;
endmodule

module ADD4 (in1, in2, cin, cout, out);
input [3:0] in1;
input [3:0] in2;
input cin;
output cout;
output [3:0] out;
endmodule

module ADD8 (in1, in2, cin, cout, out);
input [7:0] in1;
input [7:0] in2;
input cin;
output cout;
output [7:0] out;
endmodule

module ADD16 (in1, in2, cin, cout, out);
input [15:0] in1;
input [15:0] in2;
input cin;
output cout;
output [15:0] out;
endmodule

module ADD32 (in1, in2, cin, cout, out);
input [31:0] in1;
input [31:0] in2;
input cin;
output cout;
output [31:0] out;
endmodule

module ADD64 (in1, in2, cin, cout, out);
input [63:0] in1;
input [63:0] in2;
input cin;
output cout;
output [63:0] out;
endmodule

module SUB1 (in1, in2, cin, cout, out);
input in1;
input in2;
input cin;
output cout;
output out;
endmodule

module SUB2 (in1, in2, cin, cout, out);
input [1:0] in1;
input [1:0] in2;
input cin;
output cout;
output [1:0] out;
endmodule

module SUB4 (in1, in2, cin, cout, out);
input [3:0] in1;
input [3:0] in2;
input cin;
output cout;
output [3:0] out;
endmodule

module SUB8 (in1, in2, cin, cout, out);
input [7:0] in1;
input [7:0] in2;
input cin;
output cout;
output [7:0] out;
endmodule

module SUB16 (in1, in2, cin, cout, out);
input [15:0] in1;
input [15:0] in2;
input cin;
output cout;
output [15:0] out;
endmodule

module SUB32 (in1, in2, cin, cout, out);
input [31:0] in1;
input [31:0] in2;
input cin;
output cout;
output [31:0] out;
endmodule

module SUB64 (in1, in2, cin, cout, out);
input [63:0] in1;
input [63:0] in2;
input cin;
output cout;
output [63:0] out;
endmodule

module MUL1 (in1, in2, out);
input in1;
input in2;
output [1:0] out;
endmodule

module MUL2 (in1, in2, out);
input [1:0] in1;
input [1:0] in2;
output [3:0] out;
endmodule

module MUL4 (in1, in2, out);
input [3:0] in1;
input [3:0] in2;
output [7:0] out;
endmodule

module MUL8 (in1, in2, out);
input [7:0] in1;
input [7:0] in2;
output [15:0] out;
endmodule

module MUL16 (in1, in2, out);
input [15:0] in1;
input [15:0] in2;
output [31:0] out;
endmodule

module MUL32 (in1, in2, out);
input [31:0] in1;
input [31:0] in2;
output [63:0] out;
endmodule

module MUL64 (in1, in2, out);
input [63:0] in1;
input [63:0] in2;
output [127:0] out;
endmodule

module DIV1 (in1, in2, out, rem);
input in1;
input in2;
output out;
output rem;
endmodule

module DIV2 (in1, in2, out, rem);
input [1:0] in1;
input [1:0] in2;
output [1:0] out;
output [1:0] rem;
endmodule

module DIV4 (in1, in2, out, rem);
input [3:0] in1;
input [3:0] in2;
output [3:0] out;
output [3:0] rem;
endmodule

module DIV8 (in1, in2, out, rem);
input [7:0] in1;
input [7:0] in2;
output [7:0] out;
output [7:0] rem;
endmodule

module DIV16 (in1, in2, out, rem);
input [15:0] in1;
input [15:0] in2;
output [15:0] out;
output [15:0] rem;
endmodule

module DIV32 (in1, in2, out, rem);
input [31:0] in1;
input [31:0] in2;
output [31:0] out;
output [31:0] rem;
endmodule

module DIV64 (in1, in2, out, rem);
input [63:0] in1;
input [63:0] in2;
output [63:0] out;
output [63:0] rem;
endmodule

module FF (d, clk, q);
input d;
input clk;
output q;
endmodule

module RFF (d, clk, reset, q);
input d;
input clk;
input reset;
output q;
endmodule


module SFF (d, clk, set, q);
input d;
input clk;
input set;
output q;
endmodule


module RSFF (d, clk, reset, set, q);
input d;
input clk;
input reset;
input set;
output q;
endmodule

module SRFF (d, clk, reset, set, q);
input d;
input clk;
input reset;
input set;
output q;
endmodule

module LATCH (d, enable, q);
input d;
input enable;
output q;
endmodule

module RLATCH (d, enable, reset, q);
input d;
input enable;
input reset;
output q;
endmodule

module LSHIFT1 (in, shift, out, val);
input in;
input shift;
input val;
output out;
endmodule

module LSHIFT2 (in, shift, out, val);
input [1:0] in;
input [1:0] shift;
input val;
output [1:0] out;
endmodule

module LSHIFT4 (in, shift, out, val);
input [3:0] in;
input [2:0] shift;
input val;
output [3:0]out;
endmodule

module LSHIFT8 (in, shift, out, val);
input [7;0] in;
input [3;0] shift;
input val;
output [7:0] out;
endmodule

module LSHIFT16 (in, shift, out, val);
input [15:0] in;
input [4:0] shift;
input val;
output [15:0] out;
endmodule

module LSHIFT32 (in, shift, out, val);
input [31:0] in;
input [5:0] shift;
input val;
output [31:0] out;
endmodule

module LSHIFT64 (in, shift, out, val);
input [63:0] in;
input [6:0] shift;
input val;
output [63:0] out;
endmodule

module RSHIFT1 (in, shift, out, val);
input in;
input shift;
input val;
output out;
endmodule

module RSHIFT2 (in, shift, out, val);
input [1:0] in;
input [1:0] shift;
input val;
output  [1:0] out;
endmodule

module RSHIFT4 (in, shift, out, val);
input [3:0] in;
input [2:0] shift;
input val;
output  [3:0] out;
endmodule

module RSHIFT8 (in, shift, out, val);
input [7:0] in;
input [3:0] shift;
input val;
output  [7:0] out;
endmodule

module RSHIFT16 (in, shift, out, val);
input [15:0] in;
input [4:0] shift;
input val;
output  [15:0] out;
endmodule

module RSHIFT32 (in, shift, out, val);
input [31:0] in;
input [5:0] shift;
input val;
output  [31:0] out;
endmodule

module RSHIFT64 (in, shift, out, val);
input [63:0] in;
input [6:0] shift;
input val;
output  [63:0] out;
endmodule

module CMP1 (in1, in2, equal, unequal, greater, lesser);
input in1;
input in2;
output equal;
output unequal;
output greater;
output lesser;
endmodule

module CMP2 (in1, in2, equal, unequal, greater, lesser);
input [1:0] in1;
input [1:0] in2;
output equal;
output unequal;
output greater;
output lesser;
endmodule

module CMP4 (in1, in2, equal, unequal, greater, lesser);
input [3:0] in1;
input [3:0] in2;
output equal;
output unequal;
output greater;
output lesser;
endmodule

module CMP8 (in1, in2, equal, unequal, greater, lesser);
input [7:0] in1;
input [7:0] in2;
output equal;
output unequal;
output greater;
output lesser;
endmodule

module CMP16 (in1, in2, equal, unequal, greater, lesser);
input [15:0] in1;
input [15:0] in2;
output equal;
output unequal;
output greater;
output lesser;
endmodule

module CMP32 (in1, in2, equal, unequal, greater, lesser);
input [31:0] in1;
input [31:0] in2;
output equal;
output unequal;
output greater;
output lesser;
endmodule

module CMP64 (in1, in2, equal, unequal, greater, lesser);
input [63:0] in1;
input [63:0] in2;
output equal;
output unequal;
output greater;
output lesser;
endmodule

module VCC (out);
output out;
endmodule

module GND (out);
output out;
endmodule

module INC1 (in, out);
input in;
output [1:0] out;
endmodule

module INC2 (in, out);
input [1:0] in;
output [2:0] out;
endmodule

module INC4 (in, out);
input [3:0] in;
output [4:0] out;
endmodule

module INC8 (in, out);
input [7:0] in;
output [8:0] out;
endmodule

module INC16 (in, out);
input [15:0] in;
output [16:0] out;
endmodule

module INC32 (in, out);
input [31:0] in;
output [32:0] out;
endmodule

module INC64 (in, out);
input [63:0] in;
output [64:0] out;
endmodule










































































