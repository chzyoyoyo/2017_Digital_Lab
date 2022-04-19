`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 2017/09/26 15:03:31
// Design Name: 
// Module Name: lab3
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


module lab3(
  input  clk,            // System clock at 100 MHz
  input  reset_n,        // System reset signal, in negative logic
  input  [3:0] usr_btn,  // Four user pushbuttons
  output [3:0] usr_led   // Four yellow LEDs
);

reg [22:0] decounter;
reg signed [3:0] counter;
//assign usr_led = usr_btn;
reg debounce;

//assign usr_led = counter;




always @(posedge clk)
begin 
	if(~reset_n)
		decounter <= 0;
	else if(usr_btn != 0 && decounter != 23'h7fffff)
		decounter <= decounter+1;
    else if(usr_btn != 0 && decounter == 23'h7fffff)
        decounter <= decounter;
	else
	   decounter <= 0;
end

wire test;

assign test = (usr_btn[0] || usr_btn[1] || usr_btn[2] ||usr_btn[3])? 1:0;

always@(posedge clk)
begin
    if(decounter == (23'h7fffff-1))
        debounce <= test;
    else
        debounce <= 0;
end

always@(posedge clk)
begin
    if(~reset_n)
        counter <= 0;
    else if(debounce && usr_btn[0])
    begin
        if(counter == -8)
            counter <= counter;
        else 
            counter <= counter -1;
    end
    else if(debounce && usr_btn[1])
    begin
        if(counter == 7)
            counter <= counter;
        else
            counter <= counter + 1;
     end
end
 
reg [2:0] du_cy;
  
always@ (posedge clk)
begin
    if(~reset_n)
        du_cy <= 0;
    else if(debounce && usr_btn[2] && du_cy >= 1)
        du_cy = du_cy - 1;
    else if(debounce && usr_btn[3] && du_cy <= 3)
        du_cy = du_cy + 1;
    else 
        du_cy <= du_cy;    
end    
    
reg [22:0] high_ticks;

always @(posedge clk)
begin
	if(du_cy == 0) high_ticks = 50000;
	else if(du_cy ==1) high_ticks = 250000;
	else if(du_cy == 2) high_ticks=500000;
	else if(du_cy == 3) high_ticks=750000;
	else if(du_cy == 4) high_ticks=1000000;
end  

reg [22:0] Lcounter;
always@ (posedge clk)
begin
    if(~reset_n || Lcounter == 1000000)
        Lcounter <= 0;
    else if(Lcounter < 1000000)
        Lcounter = Lcounter + 1;
end

assign usr_led[0]=(Lcounter <= high_ticks &&  counter[0])?1:0;
assign usr_led[1]=(Lcounter <= high_ticks &&  counter[1])?1:0;
assign usr_led[2]=(Lcounter <= high_ticks &&  counter[2])?1:0;
assign usr_led[3]=(Lcounter <= high_ticks &&  counter[3])?1:0;



endmodule









