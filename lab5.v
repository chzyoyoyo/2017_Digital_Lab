`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of CS, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/10/16 14:21:33
// Design Name: 
// Module Name: lab5
// Project Name: 
// Target Devices: Xilinx FPGA @ 100MHz 
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


module lab5(
  input clk,
  input reset_n,
  input [3:0] usr_btn,
  output [3:0] usr_led,
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

// turn off all the LEDs
assign usr_led = 4'b0000;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Prime #01 is 002"; // Initialize the text of the first row. 
reg [127:0] row_B = "Prime #02 is 003"; // Initialize the text of the second row.

reg [27:0]counter;

reg [7:0] realidx;

reg [11: 0]data_out;
reg [11: 0] store[171:0];
reg [11: 0] j;
reg [ 7: 0] k;
reg [ 7: 0] stocount;

reg scroll ; // 0  up , 1 down
reg prv_scroll ; //previous scroll direction

reg prv1_updataed_lcd ,has_updataed_lcd ;//prv1 and prv2 's next_en
reg updataed_lcd;

reg prime[1023:0];
reg [11: 0]idx;
reg [11: 0]jdx;  
integer i;
reg OK_pri;

LCD_module lcd0(
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);
    
debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[3]),
  .btn_output(btn_level)
);
    
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 1;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0);

always @(posedge clk) begin
	if (~reset_n) begin
		// reset
		realidx <= 1;
	end
	else begin
		realidx <= stocount + 1;
	end
end

always @(posedge clk) begin
  if (~reset_n) begin
    // Initialize the text when the user hit the reset button
    row_A <= "Prime #01 is 002";
    row_B <= "Prime #02 is 003";
  end
	else if(OK_pri)begin
	
		if(!scroll && has_updataed_lcd) begin
			row_A <= row_B ;
			//row A Answer
			row_B[71 :64 ] <= (realidx[7:4] >=10) ? {4'd0,realidx[7:4]}-10 + "A" : {4'd0,realidx[7:4]} + "0" ;
			row_B[63 :56 ] <= (realidx[3:0] >=10) ? {4'd0,realidx[3:0]}-10 + "A" : {4'd0,realidx[3:0]} + "0" ;

			row_B[23 :16 ] <= (data_out[11:8 ] >=10) ? {4'd0,data_out[11:8 ]}-10 + "A" : {4'd0,data_out[11:8 ]} + "0" ;
			row_B[15 :8  ] <= (data_out[7 :4 ] >=10) ? {4'd0,data_out[7 :4 ]}-10 + "A" : {4'd0,data_out[7 :4 ]} + "0" ;
			row_B[7  :0  ] <= (data_out[3 :0 ] >=10) ? {4'd0,data_out[3 :0 ]}-10 + "A" : {4'd0,data_out[3 :0 ]} + "0" ;
		end
		
		else if(scroll && has_updataed_lcd) begin
			row_B <= row_A ;
			//row B Answer
			row_A[71 :64 ] <= (realidx[7:4] >=10) ? {4'd0,realidx[7:4]}-10 + "A" : {4'd0,realidx[7:4]} + "0" ;
			row_A[63 :56 ] <= (realidx[3:0] >=10) ? {4'd0,realidx[3:0]}-10 + "A" : {4'd0,realidx[3:0]} + "0" ;

			row_A[23 :16 ] <= (data_out[11:8 ] >=10) ? {4'd0,data_out[11:8 ]}-10 + "A" : {4'd0,data_out[11:8 ]} + "0" ;
			row_A[15 :8  ] <= (data_out[7 :4 ] >=10) ? {4'd0,data_out[7 :4 ]}-10 + "A" : {4'd0,data_out[7 :4 ]} + "0" ;
			row_A[7  :0  ] <= (data_out[3 :0 ] >=10) ? {4'd0,data_out[3 :0 ]}-10 + "A" : {4'd0,data_out[3 :0 ]} + "0" ;
		end
		
		else begin
			row_A <= row_A ;
			row_B <= row_B ;
		end	
	end
end

//store prime
always @(posedge clk) begin
	if (~reset_n) begin
		// reset
	    for(i = 0; i < 172; i = i + 1)
	      store[i] = 1;
		j <= 0;
		k <= 0;
	end
	else if(OK_pri == 1) begin
		if(prime[j] == 1 && k < 172)begin
			store[k] <= j;
			k <= k + 1;
			j <= j + 1;
		end

		else if(prime[j] == 0 && k < 172)begin
			j <= j + 1;
		end
	end
end

//store to data_out
always @(posedge clk) begin
	if (~has_updataed_lcd && OK_pri) begin
		// reset
		data_out <= store[stocount];
	end
	else begin
		data_out <= data_out;
	end
end

//stocount control
always @(posedge clk) begin
		if(~reset_n) begin
			stocount <= 1 ;
		end
		else if(OK_pri) begin
			if(updataed_lcd && !scroll && !prv_scroll) stocount <= (stocount < 171) ? stocount + 1 : 0 ;
			else if(updataed_lcd && !scroll && prv_scroll) stocount <= (stocount < 170 ) ? stocount + 2 : stocount - 170  ;
			else if(updataed_lcd && scroll && prv_scroll) stocount <= (stocount > 0 ) ? stocount - 1 : 171 ; 
			else if(updataed_lcd && scroll && !prv_scroll) stocount <= (stocount > 1 ) ? stocount - 2 : stocount + 170  ;
			else stocount <= stocount ; 
		end
	end

//counter to wait 0.7s(7000W clk) between update the screen 
always @(posedge clk)	begin
	if(~reset_n)begin
		counter <= 0 ;
		updataed_lcd <= 0 ;
	end
	else if(OK_pri) begin
		counter <= counter + 1 ;
		if(counter >= 70000000) begin
			updataed_lcd <= 1 ;
			counter <= 0;
		end 
		else 	updataed_lcd <= 0 ;			
	end
end

//scroll control
always@(posedge clk ) begin
		if(~reset_n) scroll <= 0 ;
		else if(btn_pressed ) scroll <= !scroll ;
		else scroll <= scroll ;
	end

always@(posedge clk)begin
	if(~reset_n) begin
	has_updataed_lcd <= 0 ;
	prv1_updataed_lcd <= 0 ;
	end
	else begin 
	prv1_updataed_lcd <= updataed_lcd ;
	has_updataed_lcd <= prv1_updataed_lcd ;
	end
end

always@(posedge clk) begin
	if(~reset_n) prv_scroll <= 0 ;
	else if (updataed_lcd) prv_scroll <= scroll ;
	else prv_scroll <= prv_scroll ;
end

//find prime numbers

always @(posedge clk ) begin
  if (~reset_n) begin
    // reset
    idx <= 2;
    for(i = 0; i < 1024; i = i + 1)
      prime[i] = 1;
    //jdx = idx + idx;
    prime[0] = 0;
    prime[1] = 0;
    jdx <= 4;
    OK_pri <= 0;
  end
  else begin
	if(idx < 512)begin
	  	
	  	if(jdx > 1023)begin
			
		    idx = idx + 1;
		    jdx = idx + idx;	

	  	end

	    else begin
		    prime[jdx] = 0;
		    jdx <= jdx + idx;
	    end	
	end

	else begin
	 	OK_pri <= 1;
	 end 
  end
end
endmodule
