`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of CS, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/04/27 15:06:57
// Design Name: UART I/O example for Arty
// Module Name: lab4
// Project Name: 
// Target Devices: Xilinx FPGA @ 100MHz
// Tool Versions: 
// Description: 
// 
// The parameters for the UART controller are 9600 baudrate, 8-N-1-N
//
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab4(
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,
  input  uart_rx,
  output uart_tx
);

localparam [2:0] S_MAIN_INIT = 0, S_MAIN_PROMPT = 1,
                 S_MAIN_WAIT_KEY = 2, S_MAIN_HELLO = 3,
                 S_ECHO=6, S_SECWAIT = 5, S_SECHEL = 4;

localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
//assign usr_led[0] = (P == S_ECHO) ? 1 : usr_led[0] ;
// declare system variables
wire print_done;
reg print_enable;
wire enter_pressed,key_pressed;
reg [8:0] send_counter;
reg [2:0] P, P_next;
reg [1:0] Q, Q_next;
reg [23:0] init_counter;

// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
reg  [7:0] rx_temp;
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;


reg [15:0] num1 = 0;
reg [15:0] num2 = 0;
reg [15:0] answer;
reg [7:0] hex[3:0];
reg flag = 0;
reg flag2 = 0;

/* The UART device takes a 100MHz clock to handle I/O at 9600 baudrate */
uart uart(
  .clk(clk),
  .rst(~reset_n),
  .rx(uart_rx),
  .tx(uart_tx),
  .transmit(transmit),
  .tx_byte(tx_byte),
  .received(received),
  .rx_byte(rx_byte),
  .is_receiving(is_receiving),
  .is_transmitting(is_transmitting),
  .recv_error(recv_error)
);

// Initializes some strings.
// System Verilog has an easier way to initialize an array,
// but we are using Verilog 2005 :(
//
localparam MEM_SIZE = 94;
localparam PROMPT_STR = 0;
localparam HELLO_STR = 35;
localparam ECHO_STR = 99;
localparam SECHEL_STR = 71;

reg [7:0] data[0:MEM_SIZE-1];

initial begin
  { data[ 0], data[ 1], data[ 2], data[ 3], data[ 4], data[ 5], data[ 6], data[ 7],
    data[ 8], data[ 9], data[10], data[11], data[12], data[13], data[14], data[15], 
 	data[16], data[17], data[18], data[19], data[20], data[21], data[22], data[23],
    data[24], data[25], data[26], data[27], data[28], data[29], data[30], data[31],
	data[32], data[33], data[34]}
  <= { 8'h0D, 8'h0A, "Enter the first decimal number: ", 8'h00 };

  { data[35], data[36], data[37], data[38], data[39], data[40], data[41], data[42],
    data[43], data[44], data[45], data[46], data[47], data[48], data[49], data[50], 
 	data[51], data[52], data[53], data[54], data[55], data[56], data[57], data[58],
    data[59], data[60], data[61], data[62], data[63], data[64], data[65], data[66],
    data[67], data[68], data[69], data[70]}
  <= { 8'h0D, 8'h0A, "Enter the second decimal number: ", 8'h00 };
  { data[71], data[72], data[73], data[74], data[75], data[76], data[77], data[78], data[79], data[80],
  	data[81], data[82], data[83], data[84], data[85], data[86], data[87], data[88],
  	data[89], data[90], data[91], data[92], data[93]}
  <= { 8'h0D, 8'h0A, "The GCD is: 0x", 8'h30, 8'h30, 8'h30, 8'h30, 8'h0D, 8'h0A, 8'h00 };
end

always@(posedge clk)
begin
    data[87] <= hex[3];
    data[88] <= hex[2];
    data[89] <= hex[1];
    data[90] <= hex[0];
end



// Combinational I/O logics
assign usr_led = hex[0][3:0];
assign enter_pressed = (rx_temp == 8'h0D);
assign tx_byte = (P == S_MAIN_WAIT_KEY || P == S_SECWAIT)?  rx_byte:data[send_counter];

// ------------------------------------------------------------------------
// Main FSM that reads the UART input and triggers
// the output of the string "Hello, World!".
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

assign key_pressed = (rx_temp==8'h30)||(rx_temp==8'h31)||(rx_temp==8'h32)||(rx_temp==8'h33)||(rx_temp==8'h34)||(rx_temp==8'h35)||(rx_temp==8'h36)||(rx_temp==8'h37)||(rx_temp==8'h38)||(rx_temp==8'h39);

reg flag3;  

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // Delay 10 us.
	   if (init_counter < 1000) P_next = S_MAIN_INIT;
		else P_next = S_MAIN_PROMPT;
    S_MAIN_PROMPT: // Print the prompt message.
      if (print_done) P_next = S_MAIN_WAIT_KEY;
      else P_next = S_MAIN_PROMPT;
    S_MAIN_WAIT_KEY: // wait for <Enter> key.
      if (enter_pressed) begin
      	P_next = S_MAIN_HELLO;
		//flag3 <= 1;
		end
      else P_next = S_MAIN_WAIT_KEY;
    S_MAIN_HELLO: // Print the hello message.
      if (print_done) P_next = S_SECWAIT;
      else P_next = S_MAIN_HELLO;
    S_SECWAIT: 
	  if (enter_pressed) begin
		  //flag3 <= 0;
		  P_next = S_SECHEL;
	  end
      else P_next = S_SECWAIT;
    S_SECHEL:
      if (print_done) P_next = S_MAIN_INIT;
      else P_next = S_SECHEL;
    S_ECHO:
	  if(print_done && flag3 == 0) P_next = S_MAIN_WAIT_KEY;
	  else if(print_done && flag3 == 1) P_next = S_SECWAIT;
	  else P_next = S_ECHO;
  endcase
end



// FSM output logics: print string control signals.
/*assign print_enable = (P != S_MAIN_PROMPT && P_next == S_MAIN_PROMPT) ||
                  (P == S_MAIN_WAIT_KEY && P_next == S_MAIN_HELLO)
                  ;*/

always @(posedge clk) begin
  if (~reset_n) print_enable <= 0;
  
  else print_enable <= (P_next == S_MAIN_PROMPT) | (P_next == S_MAIN_HELLO) |(P_next == S_ECHO) |(P_next == S_SECHEL);
  
end









// Initialization counter.
always @(posedge clk) begin
  if (P == S_MAIN_INIT) init_counter <= init_counter + 1;
  else init_counter <= 0;
end 
// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the controller to send a string to the UART.
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for the print_string flag
      if (print_enable) Q_next = S_UART_WAIT;
      else Q_next = S_UART_IDLE;
    S_UART_WAIT: // wait for the transmission of current data byte begins
      if (is_transmitting == 1) Q_next = S_UART_SEND;
      else Q_next = S_UART_WAIT;
    S_UART_SEND: // wait for the transmission of current data byte finishes
      if (is_transmitting == 0) Q_next = S_UART_INCR; // transmit next character
      else Q_next = S_UART_SEND;
    S_UART_INCR:
      if (tx_byte == 8'h0) Q_next = S_UART_IDLE; // string transmission ends
      else Q_next = S_UART_WAIT;
  endcase
end

// FSM output logics
assign transmit = (Q_next == S_UART_WAIT ) || (P == S_MAIN_WAIT_KEY || P == S_SECWAIT)? received : print_enable;
assign tx_byte = (P == S_MAIN_WAIT_KEY || P == S_SECWAIT)?  rx_byte:data[send_counter];

//reg [5:0]string_id;



/*always @(posedge clk) begin
if(P_next == S_MAIN_PROMPT)
	string_id =  PROMPT_STR ;
else if(P_next == S_MAIN_HELLO)
	string_id =HELLO_STR;
else if(P_next == S_SECHEL)
	string_id = SECHEL_STR;
else 
	string_id = ECHO_STR;
end*/




// UART send_counter control circuit
always @(posedge clk) begin
  case (P_next)
    S_MAIN_INIT: send_counter <= PROMPT_STR;
    S_MAIN_WAIT_KEY: send_counter <= HELLO_STR;
    S_ECHO: send_counter <= ECHO_STR;
    S_SECWAIT: send_counter <= 71;
    
    default: send_counter <= send_counter + (Q == S_UART_INCR);
  endcase
end
/*always @(posedge clk) begin
  if (~reset_n)
    send_counter <= 0;
  else if (Q == S_UART_INCR) begin
    // If (tx_byte == 8'h0), it means we hit the end of a string.
    //send_counter <= (tx_byte == 8'h0)? string_id : send_counter + 1;
    print_done <= (tx_byte == 8'h0);
  end
  else // 'print_done' and 'print_enable' are mutually exclusive!
    print_done <= ~print_enable;
end*/

assign print_done = (Q == S_UART_INCR)?  tx_byte == 8'h0 : ~print_enable;






// End of the FSM of the print string controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The following logic stores the UART input in a temporary buffer.
// The input character will stay in the buffer for one clock cycle.
always @(posedge clk) begin
  rx_temp <= (received)? rx_byte : 8'h0;
end
// ------------------------------------------------------------------------



always@(posedge clk) begin
	if(flag2 == 1)begin
		if(num1 == 0)begin
			hex[3] <= (num2[15:12] <= 9)? num2[15:12]+8'd48:num2[15:12]+8'd55;
			hex[2] <= (num2[11: 8] <= 9)? num2[11: 8]+8'd48:num2[11: 8]+8'd55;
			hex[1] <= (num2[ 7: 4] <= 9)? num2[ 7: 4]+8'd48:num2[ 7: 4]+8'd55;
			hex[0] <= (num2[ 3: 0] <= 9)? num2[ 3: 0]+8'd48:num2[ 3: 0]+8'd55;
			flag2 <= 0;
			num2 <= 0;
		end
			//answer <= num2;
		else if(num2 == 0)begin
			hex[3] <= (num1[15:12] <= 9)? num1[15:12]+8'd48:num1[15:12]+8'd55;
			hex[2] <= (num1[11: 8] <= 9)? num1[11: 8]+8'd48:num1[11: 8]+8'd55;
			hex[1] <= (num1[ 7: 4] <= 9)? num1[ 7: 4]+8'd48:num1[ 7: 4]+8'd55;
			hex[0] <= (num1[ 3: 0] <= 9)? num1[ 3: 0]+8'd48:num1[ 3: 0]+8'd55;
			flag2 <= 0;
			num1 <= 0;
		end
			//answer <= num1;
		else begin
			if( num1 <= num2)
				num2 <= num2 - num1;
			else if( num1 > num2)
				num1 <= num1 - num2;
		end
	end
	else if(key_pressed == 1 && flag == 0)begin
		num1=num1*10+(rx_temp-8'h30);
		hex[3] <= 0;
		hex[2] <= 0;
		hex[1] <= 0;
		hex[0] <= 0;
	end
	else if(enter_pressed == 1 && flag == 0)
		flag <= 1;

	else if(key_pressed == 1 && flag == 1)begin
		num2=num2*10+(rx_temp-8'h30);
	end
	else if(enter_pressed == 1 && flag == 1)begin
		flag2 <= 1;
		flag <= 0;
	end

end
endmodule
