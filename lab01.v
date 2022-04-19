`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/09/18 20:22:12
// Design Name: 
// Module Name: lab1
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module SeqMultiplier(
input wire clk,
input wire enable,
input wire [7:0] A,
input wire [7:0] B,
output wire [15:0] C
);

reg [7:0] mB;
reg [15:0] mC;
reg [4:0] test;

assign C = mC;

always@(clk)
begin

if(enable == 0)
begin
    mB <= B;
    mC <= 0;
    test<=0;
end     

else if(test<=7)
begin
mC= mC << 1;
    if(mB[7] == 0)
    begin
       // mC = mC;
        mB <= mB << 1;
    end

    else if(mB[7] == 1)
    begin
        mC <= mC + A;
        mB <= mB << 1;
    end
    test<=test+1;
end

end
endmodule






