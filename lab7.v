`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/05/08 15:29:41
// Design Name: 
// Module Name: lab6
// Project Name: 
// Target Devices: 
// Tool Versions:
// Description: The sample top module of lab 6: sd card reader. The behavior of
//              this module is as follows
//              1. When the SD card is initialized, display a message on the LCD.
//                 If the initialization fails, an error message will be shown.
//              2. The user can then press usr_btn[2] to trigger the sd card
//                 controller to read the super block of the sd card (located at
//                 block # 8192) into the SRAM memory.
//              3. During SD card reading time, the four LED lights will be turned on.
//                 They will be turned off when the reading is done.
//              4. The LCD will then displayer the sector just been read, and the
//                 first byte of the sector.
//              5. Everytime you press usr_btn[2], the next byte will be displayed.
// 
// Dependencies: clk_divider, LCD_module, debounce, sd_card
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

module lab6(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // SD card specific I/O ports
  output spi_ss,
  output spi_sck,
  output spi_mosi,
  input  spi_miso,

  // 1602 LCD Module Interface
  /*output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D*/
  input  uart_rx,
  output uart_tx
);

localparam [3:0] S_MAIN_INIT = 0, S_MAIN_IDLE = 1, S_MAIN_MSG1 = 2,
                 S_MAIN_READ = 3, S_MAIN_LOOP = 4, S_MAIN_HEX2TXT = 5,
                 S_MAIN_MSG2 = 6, S_MAIN_DONE = 7, S_MAIN_DATA = 8 ,
				 S_MAIN_cycle0 = 9, S_MAIN_cycle1 = 10, S_MAIN_cycle2 = 11 , S_MAIN_cycle3 = 12,
	             S_MAIN_cycle4 = 13, S_MAIN_cycle5 = 14, S_MAIN_cycle6 = 15;
localparam [1:0] S_UART_IDLE = 0, S_UART_WAIT = 1,
                 S_UART_SEND = 2, S_UART_INCR = 3;
				 
				 
localparam MEM_SIZE = 148;
localparam MESSAGE_STR = 0;
localparam NUMBER_STR = 17;

// declare system variables
wire btn_level, btn_pressed;
reg  prev_btn_level;
reg  print_enable, print_done;
reg  [8:0] send_counter; 
reg  [3:0] P, P_next;
reg  [1:0] Q, Q_next;
reg  [9:0] sd_counter;
reg  [7:0] byte0;
reg  [0:(MEM_SIZE-1)*8+7] data;
reg  [31:0] blk_addr;
//reg  done_flag; // Signals the completion of reading one SD sector.


// declare UART signals
wire transmit;
wire received;
wire [7:0] rx_byte;
wire [7:0] tx_byte;
wire is_receiving;
wire is_transmitting;
wire recv_error;


// Declare SD card interface signals
wire clk_sel;
wire clk_500k;
reg  rd_req;
reg  [31:0] rd_addr;
wire init_finished;
wire [7:0] sd_dout;
wire sd_valid;

// declare a SRAM memory block
wire [7:0] data_in;
wire [7:0] data_out;
wire       we, en;
wire [8:0] sram_addr;

//Matrix operation
reg [7:0]A1[0:3];
reg [7:0]A2[0:3];
reg [7:0]A3[0:3];
reg [7:0]A4[0:3];
reg [7:0]B1[0:3];
reg [7:0]B2[0:3];
reg [7:0]B3[0:3];
reg [7:0]B4[0:3] ; 
reg [17:0]t[0:15] ;
reg [17:0]ans[0:15] ; 
reg [39:0]hex[0:15] ;
wire [3:0]data_out_number ;

assign clk_sel = (init_finished)? clk : clk_500k; // clock for the SD controller

assign data_out_number = (data_out >= "A" )? (data_out - "A" + 10) : (data_out - "0") ;

assign usr_led = ans[0][15:12];

clk_divider#(200) clk_divider0(
  .clk(clk),
  .reset(~reset_n),
  .clk_out(clk_500k)
);

debounce btn_db0(
  .clk(clk),
  .btn_input(usr_btn[2]),
  .btn_output(btn_level)
);

uart uart0(
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
  .recv_error(recv_error));

/*LCD_module lcd0( 
  .clk(clk),
  .reset(~reset_n),
  .row_A(row_A),
  .row_B(row_B),
  .LCD_E(LCD_E),
  .LCD_RS(LCD_RS),
  .LCD_RW(LCD_RW),
  .LCD_D(LCD_D)
);*/

sd_card sd_card0(
  .cs(spi_ss),
  .sclk(spi_sck),
  .mosi(spi_mosi),
  .miso(spi_miso),

  .clk(clk_sel),
  .rst(~reset_n),
  .rd_req(rd_req),
  .block_addr(rd_addr),
  .init_finished(init_finished),
  .dout(sd_dout),
  .sd_valid(sd_valid)
);

sram ram0(
  .clk(clk),
  .we(we),
  .en(en),
  .addr(sram_addr),
  .data_i(data_in),
  .data_o(data_out)
);

//
// Enable one cycle of btn_pressed per each button hit
//





always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 0;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level == 1 && prev_btn_level == 0)? 1 : 0;

// ------------------------------------------------------------------------
// The following code sets the control signals of an SRAM memory block
// that is connected to the data output port of the SD controller.
// Once the read request is made to the SD controller, 512 bytes of data
// will be sequentially read into the SRAM memory block, one byte per
// clock cycle (as long as the sd_valid signal is high).
assign we = sd_valid;          // Write data into SRAM when sd_valid is high.
assign en = 1;                 // Always enable the SRAM block.
assign data_in = sd_dout;           // Input data always comes from the SD controller.
assign sram_addr = sd_counter[8:0]; // Set the driver of the SRAM address signal.
// End of the SRAM memory block
// ------------------------------------------------------------------------

always @(posedge clk) begin // Controller of the 'sd_counter' signal.
  if (~reset_n || P == S_MAIN_MSG2 || (P == S_MAIN_HEX2TXT && P_next == S_MAIN_READ))
    sd_counter <= 0;
  else if ( (P == S_MAIN_LOOP && sd_valid) || P == S_MAIN_HEX2TXT || P == S_MAIN_DATA )
    sd_counter <= sd_counter + 1;
end

always @(posedge clk) begin // Stores sram[0] in the register 'byte0'.
  if (~reset_n) byte0 <= 8'b0;
  else if (en && (P == S_MAIN_HEX2TXT || P == S_MAIN_DATA) ) byte0 <= data_out;
end



// ------------------------------------------------------------------------
// FSM of the SD card reader that reads the super block (512 bytes)
always @(posedge clk) begin
  if (~reset_n) P <= S_MAIN_INIT;
  else P <= P_next;
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_INIT: // wait for SD card initialization
      if (init_finished) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_INIT;
    S_MAIN_IDLE: // wait for button click
      if (btn_pressed == 1) P_next = S_MAIN_MSG1;
      else P_next = S_MAIN_IDLE;
    S_MAIN_MSG1:
      if (print_done) P_next = S_MAIN_READ;
      else P_next = S_MAIN_MSG1;
    S_MAIN_READ: // issue a read request to the SD controller
      P_next = S_MAIN_LOOP;
    S_MAIN_LOOP: // wait for the input data to enter the SRAM buffer
      if (sd_counter == 512) P_next = S_MAIN_HEX2TXT;
      else P_next = S_MAIN_LOOP;
    S_MAIN_HEX2TXT:  //read sram and find MATX_TAG
		if(sram_addr == 0 ) P_next =S_MAIN_HEX2TXT ;
		else if(sram_addr == 1 && data_out == "M") P_next =S_MAIN_HEX2TXT ;
		else if(sram_addr == 2 && data_out == "A") P_next =S_MAIN_HEX2TXT ;
		else if(sram_addr == 3 && data_out == "T") P_next =S_MAIN_HEX2TXT ;
		else if(sram_addr == 4 && data_out == "X") P_next =S_MAIN_HEX2TXT ;
		else if(sram_addr == 5 && data_out == "_") P_next =S_MAIN_HEX2TXT ;
		else if(sram_addr == 6 && data_out == "T") P_next =S_MAIN_HEX2TXT ;
		else if(sram_addr == 7 && data_out == "A") P_next =S_MAIN_HEX2TXT ;
		else if(sram_addr == 8 && data_out == "G")P_next = S_MAIN_DATA;
		else P_next = S_MAIN_READ ;
	  S_MAIN_DATA:  //read 9 16-bit hex ;
		if(sram_addr == 137) P_next = S_MAIN_cycle0 ; 
		else P_next = S_MAIN_DATA ;
		S_MAIN_cycle0:
		  P_next = S_MAIN_cycle1 ;
		S_MAIN_cycle1:
		  P_next = S_MAIN_cycle2 ;
		S_MAIN_cycle2:
		  P_next = S_MAIN_cycle3 ;
		S_MAIN_cycle3:
		  P_next = S_MAIN_cycle4 ;
		S_MAIN_cycle4:
	 	  P_next = S_MAIN_cycle5;
		S_MAIN_cycle5:
	 	  P_next = S_MAIN_cycle6 ;
	  S_MAIN_cycle6:
	    P_next = S_MAIN_MSG2 ;

    S_MAIN_MSG2: // read byte 0 of the sector from sram[]
      P_next = S_MAIN_DONE;
    S_MAIN_DONE:
      if (print_done) P_next = S_MAIN_IDLE;
      else P_next = S_MAIN_DONE;
  endcase
end


// FSM output logics: print string control signals.
always @(*) begin
  if ((P == S_MAIN_IDLE && btn_pressed == 1) || P == S_MAIN_MSG2)
    print_enable = 1;
  else
    print_enable = 0;
end

// FSM output logic: controls the 'rd_req' and 'rd_addr' signals.
always @(*) begin
  rd_req = (P == S_MAIN_READ);
  rd_addr = blk_addr;
end

always @(posedge clk) begin
  if (~reset_n|| P == S_MAIN_IDLE || blk_addr == 32'd7736319 ) blk_addr <= 32'h2000;
  else blk_addr <= blk_addr + (P == S_MAIN_MSG2) + (P == S_MAIN_HEX2TXT && P_next == S_MAIN_READ);
end


// End of the FSM of the SD card reader
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the controller to send a string to the UART.
//
always @(posedge clk) begin
  if (~reset_n) Q <= S_UART_IDLE;
  else Q <= Q_next;
end

always @(*) begin // FSM next-state logic
  case (Q)
    S_UART_IDLE: // wait for print_string flag
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
assign transmit = (Q == S_UART_WAIT)? 1 : 0;
assign tx_byte = data[{ send_counter, 3'b000 } +: 8];

// Send_counter incrementing circuit.
always @(posedge clk) begin
  if (~reset_n) begin
    send_counter <= MESSAGE_STR;
    print_done <= 0;
  end
  else begin
    if (P == S_MAIN_IDLE)
      send_counter <= MESSAGE_STR;
    else if (P == S_MAIN_MSG2)
      send_counter <= NUMBER_STR;
    else
      send_counter <= send_counter + (Q == S_UART_SEND && Q_next == S_UART_INCR);
    print_done <= (print_enable)? 0 : (tx_byte == 8'h0);
  end
end
//
// End of the FSM of the print string controller
// ------------------------------------------------------------------------
// Text messages configuration circuit.
always @(posedge clk) begin
  /*if (~reset_n) begin
data[0   :13*8+7] <= "The result is:";
	 data[14*8:14*8+7] <= 8'h0D ;
	 data[15*8:15*8+7] <= 8'h0A ;
    data[16*8:16*8+7] <= 8'h00 ;

  end
  else*/ if(P == S_MAIN_cycle6) begin
 
    // print byte 0
     data[0   :13*8+7] <= "The result is:";
	 data[14*8:14*8+7] <= 8'h0D ;
	 data[15*8:15*8+7] <= 8'h0A ;
     data[16*8:16*8+7] <= 8'h00 ;
	 
     data[17*8:18*8+7] <= "[ " ;
	 data[19*8:23*8+7] <= hex[0];//[19:16], 4'b0, hex[0][15:12], 4'b0, hex[0][11:8], 4'b0, hex[0][7:4], 4'b0, hex[0][3:0] } ;
	 
	 data[24*8:25*8+7] <= ", " ;
	 
	 data[26*8:30*8+7] <=  hex[1];//[19:16],  4'b0, hex[1][15:12], 4'b0, hex[1][11:8], 4'b0, hex[1][7:4], 4'b0, hex[1][3:0]};
	 
	 data[31*8:32*8+7] <= ", " ;
	 
	 data[33*8:37*8+7] <=  hex[2];//[19:16], 4'b0, hex[2][15:12], 4'b0, hex[2][11:8], 4'b0, hex[2][7:4], 4'b0, hex[2][3:0] } ;
	 
	 data[38*8:39*8+7] <= ", " ;
	 
	 data[40*8:44*8+7] <= hex[3];//[19:16], 4'b0, hex[3][15:12], 4'b0, hex[3][11:8], 4'b0, hex[3][7:4], 4'b0, hex[3][3:0] } ;
	 
	 data[45*8:46*8+7] <= " ]" ;
	 
	 data[47*8:47*8+7] <= 8'h0D ;
	 data[48*8:48*8+7] <= 8'h0A ;
	 
	 data[49*8:50*8+7] <= "[ " ;
	 data[51*8:55*8+7] <=  hex[4];//[19:16], 4'b0, hex[4][15:12], 4'b0, hex[4][11:8], 4'b0, hex[4][7:4], 4'b0, hex[4][3:0] } ;
	 
	 data[56*8:57*8+7] <= ", " ;
	 
	 data[58*8:62*8+7] <= hex[5];//[19:16], 4'b0, hex[5][15:12], 4'b0, hex[5][11:8], 4'b0, hex[5][7:4], 4'b0, hex[5][3:0] } ;

	 data[63*8:64*8+7] <= ", " ;
	 
	 data[65*8:69*8+7] <= hex[6];//[19:16], 4'b0, hex[6][15:12], 4'b0, hex[6][11:8], 4'b0, hex[6][7:4], 4'b0, hex[6][3:0]  } ;
	 
	 data[70*8:71*8+7] <= ", " ;
	 
	 data[72*8:76*8+7] <= hex[7];//[19:16], 4'b0, hex[7][15:12], 4'b0, hex[7][11:8], 4'b0, hex[7][7:4], 4'b0, hex[7][3:0]  } ;
	 
	 data[77*8:78*8+7] <= " ]" ;
	 
	 data[79*8:79*8+7] <= 8'h0D ;
	 data[80*8:80*8+7] <= 8'h0A ;
	 
	 data[81*8:82*8+7] <= "[ " ;
	 data[83*8:87*8+7] <=  hex[8];//[19:16], 4'b0, hex[8][15:12], 4'b0, hex[8][11:8], 4'b0, hex[8][7:4], 4'b0, hex[8][3:0]  } ;
	
	 data[88*8:89*8+7] <= ", " ;
	 
	 data[90*8:94*8+7] <= hex[9];//[19:16], 4'b0, hex[9][15:12], 4'b0, hex[9][11:8], 4'b0, hex[9][7:4], 4'b0, hex[9][3:0]  } ;
	 
	 data[95*8:96*8+7] <= ", " ;
	 
	 data[97*8:101*8+7] <= hex[10];//[19:16], 4'b0, hex[10][15:12], 4'b0, hex[10][11:8], 4'b0, hex[10][7:4], 4'b0, hex[10][3:0]  } ;
	 
	 data[102*8:103*8+7] <= ", " ;
	 
	 data[104*8:108*8+7] <= hex[11];//[19:16], 4'b0, hex[11][15:12], 4'b0, hex[11][11:8], 4'b0, hex[11][7:4], 4'b0, hex[11][3:0]  } ;
	 
	 data[109*8:110*8+7] <= " ]" ;
	 
	 data[111*8:111*8+7] <= 8'h0D ;
	 data[112*8:112*8+7] <= 8'h0A ;
	 
	 data[113*8:114*8+7] <= "[ " ;
	 data[115*8:119*8+7] <=  hex[12];//[19:16], 4'b0, hex[12][15:12], 4'b0, hex[12][11:8], 4'b0, hex[12][7:4], 4'b0, hex[12][3:0]  } ;
	
	 data[120*8:121*8+7] <= ", " ;
	 
	 data[122*8:126*8+7] <= hex[13];//[19:16], 4'b0, hex[13][15:12], 4'b0, hex[13][11:8], 4'b0, hex[13][7:4], 4'b0, hex[13][3:0]  } ;
	
	 data[127*8:128*8+7] <= ", " ;
	 
	 data[129*8:133*8+7] <= hex[14];//[19:16], 4'b0, hex[14][15:12], 4'b0, hex[14][11:8], 4'b0, hex[14][7:4], 4'b0, hex[14][3:0]  } ;
	 
	 data[134*8:135*8+7] <= ", " ;
	 
	 data[136*8:140*8+7] <= hex[15];//[19:16], 4'b0, hex[15][15:12], 4'b0, hex[15][11:8], 4'b0, hex[15][7:4], 4'b0, hex[15][3:0]  } ;
	
	 data[141*8:142*8+7] <= " ]" ;
	 
     data[143*8:147*8+7] <= { 8'h0D, 8'h0A, 8'h0D, 8'h0A, 8'h00 };
  end
end

// -----------------------------------------------------------------------------------
// find tag
always@(posedge clk) begin
	if(~reset_n || P == S_MAIN_IDLE)begin
	  A1[0] <= 0 ;A1[1] <= 0 ;A1[2] <= 0 ;A1[3] <= 0 ;
		A2[0] <= 0 ;A2[1] <= 0 ;A2[2] <= 0 ;A2[3] <= 0 ;
		A3[0] <= 0 ;A3[1] <= 0 ;A3[2] <= 0 ;A3[3] <= 0 ;
		A4[0] <= 0 ;A4[1] <= 0 ;A4[2] <= 0 ;A4[3] <= 0 ;
		B1[0] <= 0 ;B1[1] <= 0 ;B1[2] <= 0 ;B1[3] <= 0 ;
		B2[0] <= 0 ;B2[1] <= 0 ;B2[2] <= 0 ;B2[3] <= 0 ;
		B3[0] <= 0 ;B3[1] <= 0 ;B3[2] <= 0 ;B3[3] <= 0 ;
		B4[0] <= 0 ;B4[1] <= 0 ;B4[2] <= 0 ;B4[3] <= 0 ;
	end
	else begin
		A1[0] <= (sram_addr == 11 || sram_addr == 12)? (A1[0] * 16 + data_out_number) : A1[0] ;
		A1[1] <= (sram_addr == 27 || sram_addr == 28)? A1[1] * 16 + data_out_number : A1[1] ;
		A1[2] <= (sram_addr == 43 || sram_addr == 44)? A1[2] * 16 + data_out_number : A1[2] ;
		A1[3] <= (sram_addr == 59 || sram_addr == 60)? A1[3] * 16 + data_out_number : A1[3] ;
		
		A2[0] <= (sram_addr == 15 || sram_addr == 16)? A2[0] * 16 + data_out_number : A2[0] ;
		A2[1] <= (sram_addr == 31 || sram_addr == 32)? A2[1] * 16 + data_out_number : A2[1] ;
		A2[2] <= (sram_addr == 47 || sram_addr == 48)? A2[2] * 16 + data_out_number : A2[2] ;
		A2[3] <= (sram_addr == 63 || sram_addr == 64)? A2[3] * 16 + data_out_number : A2[3] ;
		
		A3[0] <= (sram_addr == 19 || sram_addr == 20)? A3[0] * 16 + data_out_number : A3[0] ;
		A3[1] <= (sram_addr == 35 || sram_addr == 36)? A3[1] * 16 + data_out_number : A3[1] ;
		A3[2] <= (sram_addr == 51 || sram_addr == 52)? A3[2] * 16 + data_out_number : A3[2] ;
		A3[3] <= (sram_addr == 67 || sram_addr == 68)? A3[3] * 16 + data_out_number : A3[3] ;
		
		A4[0] <= (sram_addr == 23 || sram_addr == 24)? A4[0] * 16 + data_out_number : A4[0] ;
		A4[1] <= (sram_addr == 39 || sram_addr == 40)? A4[1] * 16 + data_out_number : A4[1] ;
		A4[2] <= (sram_addr == 55 || sram_addr == 56)? A4[2] * 16 + data_out_number : A4[2] ;
		A4[3] <= (sram_addr == 71 || sram_addr == 72)? A4[3] * 16 + data_out_number : A4[3] ;
		
		B1[0] <= (sram_addr == 75 || sram_addr == 76)? B1[0] * 16 + data_out_number : B1[0] ;
		B1[1] <= (sram_addr == 79 || sram_addr == 80)? B1[1] * 16 + data_out_number : B1[1] ;
		B1[2] <= (sram_addr == 83 || sram_addr == 84)? B1[2] * 16 + data_out_number : B1[2] ;
		B1[3] <= (sram_addr == 87 || sram_addr == 88)? B1[3] * 16 + data_out_number : B1[3] ;
		
		B2[0] <= (sram_addr == 91 || sram_addr == 92)? B2[0] * 16 + data_out_number : B2[0] ;
		B2[1] <= (sram_addr == 95 || sram_addr == 96)? B2[1] * 16 + data_out_number : B2[1] ;
		B2[2] <= (sram_addr == 99 || sram_addr == 100)? B2[2] * 16 + data_out_number : B2[2] ;
		B2[3] <= (sram_addr == 103 || sram_addr == 104)? B2[3] * 16 + data_out_number : B2[3] ;
		
		B3[0] <= (sram_addr == 107 || sram_addr == 108)? B3[0] * 16 + data_out_number : B3[0] ;
		B3[1] <= (sram_addr == 111 || sram_addr == 112)? B3[1] * 16 + data_out_number : B3[1] ;
		B3[2] <= (sram_addr == 115 || sram_addr == 116)? B3[2] * 16 + data_out_number : B3[2] ;
		B3[3] <= (sram_addr == 119 || sram_addr == 120)? B3[3] * 16 + data_out_number : B3[3] ;
		
		B4[0] <= (sram_addr == 123 || sram_addr == 124)? B4[0] * 16 + data_out_number : B4[0] ;
		B4[1] <= (sram_addr == 127 || sram_addr == 128)? B4[1] * 16 + data_out_number : B4[1] ;
		B4[2] <= (sram_addr == 131 || sram_addr == 132)? B4[2] * 16 + data_out_number : B4[2] ;
		B4[3] <= (sram_addr == 135 || sram_addr == 136)? B4[3] * 16 + data_out_number : B4[3] ;
		end
end

//Inner product : Multiple
always@(posedge clk)begin
	if(P == S_MAIN_cycle0)begin
	//M(1,1): A1 * B1 , r = 1,2,3,4 
		t[0] <= A1[0] * B1[0] ;
		t[1] <= A1[1] * B1[1] ;
		t[2] <= A1[2] * B1[2] ;
		t[3] <= A1[3] * B1[3] ;
	//M(1,2): A1 * B2
		t[4] <= A1[0] * B2[0] ;
		t[5] <= A1[1] * B2[1] ;
		t[6] <= A1[2] * B2[2] ;
		t[7] <= A1[3] * B2[3] ;
	//M(1,3): A1 * B3 
		t[8] <= A1[0] * B3[0] ;
		t[9] <= A1[1] * B3[1] ;
		t[10] <= A1[2] * B3[2] ;
		t[11] <= A1[3] * B3[3] ;
  //M(1,4): A1 * B4 
		t[12] <= A1[0] * B4[0] ;
		t[13] <= A1[1] * B4[1] ;
		t[14] <= A1[2] * B4[2] ;
		t[15] <= A1[3] * B4[3] ;
	end
	else if(P == S_MAIN_cycle1)begin
	//M(2,1): A2 * B1 , r = 1,2,3,4 
		t[0] <= A2[0] * B1[0] ;
		t[1] <= A2[1] * B1[1] ;
		t[2] <= A2[2] * B1[2] ;
		t[3] <= A2[3] * B1[3] ;
	//M(2,2): A2 * B2
		t[4] <= A2[0] * B2[0] ;
		t[5] <= A2[1] * B2[1] ;
		t[6] <= A2[2] * B2[2] ;
		t[7] <= A2[3] * B2[3] ;
	//M(2,3): A2 * B3 
		t[8] <= A2[0] * B3[0] ;
		t[9] <= A2[1] * B3[1] ;
		t[10] <= A2[2] * B3[2] ;
		t[11] <= A2[3] * B3[3] ;
  //M(2,4): A2 * B4 
		t[12] <= A2[0] * B4[0] ;
		t[13] <= A2[1] * B4[1] ;
		t[14] <= A2[2] * B4[2] ;
		t[15] <= A2[3] * B4[3] ;
	end
	else if(P == S_MAIN_cycle2)begin
	//M(3,1): A3 * B1 , r = 1,2,3,4 
		t[0] <= A3[0] * B1[0] ;
		t[1] <= A3[1] * B1[1] ;
		t[2] <= A3[2] * B1[2] ;
		t[3] <= A3[3] * B1[3] ;
	//M(3,2): A3 * B2
		t[4] <= A3[0] * B2[0] ;
		t[5] <= A3[1] * B2[1] ;
		t[6] <= A3[2] * B2[2] ;
		t[7] <= A3[3] * B2[3] ;
	//M(3,3): A3 * B3 
		t[8] <= A3[0] * B3[0] ;
		t[9] <= A3[1] * B3[1] ;
		t[10] <= A3[2] * B3[2] ;
		t[11] <= A3[3] * B3[3] ;
  //M(3,4): A3 * B4 
		t[12] <= A3[0] * B4[0] ;
		t[13] <= A3[1] * B4[1] ;
		t[14] <= A3[2] * B4[2] ;
		t[15] <= A3[3] * B4[3] ;
	end
	else if(P == S_MAIN_cycle3)begin
	//M(4,1): A4 * B1 , r = 1,2,3,4 
		t[0] <= A4[0] * B1[0] ;
		t[1] <= A4[1] * B1[1] ;
		t[2] <= A4[2] * B1[2] ;
		t[3] <= A4[3] * B1[3] ;
	//M(4,2): A4 * B2
		t[4] <= A4[0] * B2[0] ;
		t[5] <= A4[1] * B2[1] ;
		t[6] <= A4[2] * B2[2] ;
		t[7] <= A4[3] * B2[3] ;
	//M(4,3): A4 * B3 
		t[8] <= A4[0] * B3[0] ;
		t[9] <= A4[1] * B3[1] ;
		t[10] <= A4[2] * B3[2] ;
		t[11] <= A4[3] * B3[3] ;
  //M(4,4): A4 * B4 
		t[12] <= A4[0] * B4[0] ;
		t[13] <= A4[1] * B4[1] ;
		t[14] <= A4[2] * B4[2] ;
		t[15] <= A4[3] * B4[3] ;
	end
end
//Inner product : Add
always@(posedge clk)begin
	if(P == S_MAIN_cycle1)begin
		//A(1,1)
		ans[0] <= t[0] + t[1] + t[2] + t[3] ;
		//A(1,2)
		ans[1] <= t[4] + t[5] + t[6] + t[7] ;
		//A(1,3)
		ans[2] <= t[8] + t[9] + t[10] + t[11] ;
		//A(1,4)
		ans[3] <= t[12] + t[13] + t[14] + t[15] ;
	end
	else if(P == S_MAIN_cycle2)begin
		//A(1,1)
		ans[4] <= t[0] + t[1] + t[2] + t[3] ;
		//A(1,2)
		ans[5] <= t[4] + t[5] + t[6] + t[7] ;
		//A(1,3)
		ans[6] <= t[8] + t[9] + t[10] + t[11] ;
		//A(1,4)
		ans[7] <= t[12] + t[13] + t[14] + t[15] ;
	end
	else if(P == S_MAIN_cycle3)begin
		//A(1,1)
		ans[8] <= t[0] + t[1] + t[2] + t[3] ;
		//A(1,2)
		ans[9] <= t[4] + t[5] + t[6] + t[7] ;
		//A(1,3)
		ans[10] <= t[8] + t[9] + t[10] + t[11] ;
		//A(1,4)
		ans[11] <= t[12] + t[13] + t[14] + t[15] ;
	end
	else if(P == S_MAIN_cycle4)begin
		//A(1,1)
		ans[12] <= t[0] + t[1] + t[2] + t[3] ;
		//A(1,2)
		ans[13] <= t[4] + t[5] + t[6] + t[7] ;
		//A(1,3)
		ans[14] <= t[8] + t[9] + t[10] + t[11] ;
		//A(1,4)
		ans[15] <= t[12] + t[13] + t[14] + t[15] ;
	end
	else if(P == S_MAIN_cycle5) begin
		
		 hex[0][31:24] <= ((ans[0][15:12] > 9 )?"7":"0") + ans[0][15:12] ;
		 hex[0][23:16] <= ((ans[0][11:8] > 9 )?"7":"0") + ans[0][11:8] ;
		 hex[0][15:8] <= ((ans[0][7:4] > 9 )?"7":"0") + ans[0][7:4] ;
		 hex[0][7:0] <= ((ans[0][3:0] > 9 )?"7":"0") + ans[0][3:0] ;
		 hex[0][39:32] <= "0" + ans[0][17:16] ;
		 
		
		 hex[1][31:24] <= ((ans[1][15:12] > 9 )?"7":"0") + ans[1][15:12] ;
		 hex[1][23:16]<= ((ans[1][11:8] > 9 )?"7":"0") + ans[1][11:8] ;
		 hex[1][15:8] <= ((ans[1][7:4] > 9 )?"7":"0") + ans[1][7:4] ;
		 hex[1][7:0] <= ((ans[1][3:0] > 9 )?"7":"0") + ans[1][3:0] ;
		 hex[1][39:32] <= "0" + ans[1][17:16] ;
		 
		
		 hex[2][31:24] <= ((ans[2][15:12] > 9 )?"7":"0") + ans[2][15:12] ;
		 hex[2][23:16] <= ((ans[2][11:8] > 9 )?"7":"0") + ans[2][11:8] ;
		 hex[2][15:8] <= ((ans[2][7:4] > 9 )?"7":"0") + ans[2][7:4] ;
		 hex[2][7:0] <= ((ans[2][3:0] > 9 )?"7":"0") + ans[2][3:0] ;
		 hex[2][39:32] <= "0" + ans[2][17:16] ;
		 
		
		 hex[3][31:24] <= ((ans[3][15:12] > 9 )?"7":"0") + ans[3][15:12] ;
		 hex[3][23:16] <= ((ans[3][11:8] > 9 )?"7":"0") + ans[3][11:8] ;
		 hex[3][15:8] <= ((ans[3][7:4] > 9 )?"7":"0") + ans[3][7:4] ;
		 hex[3][7:0] <= ((ans[3][3:0] > 9 )?"7":"0") + ans[3][3:0] ;
		 hex[3][39:32] <= "0" + ans[3][17:16] ;
		 
		 
		
		 hex[4][31:24] <= ((ans[4][15:12] > 9 )?"7":"0") + ans[4][15:12] ;
		 hex[4][23:16] <= ((ans[4][11:8] > 9 )?"7":"0") + ans[4][11:8] ;
		 hex[4][15:8] <= ((ans[4][7:4] > 9 )?"7":"0") + ans[4][7:4] ;
		 hex[4][7:0] <= ((ans[4][3:0] > 9 )?"7":"0") + ans[4][3:0] ;
		 hex[4][39:32] <= "0" + ans[4][17:16] ;
		 
		
		 hex[5][31:24] <= ((ans[5][15:12] > 9 )?"7":"0") + ans[5][15:12] ;
		 hex[5][23:16] <= ((ans[5][11:8] > 9 )?"7":"0") + ans[5][11:8] ;
		 hex[5][15:8] <= ((ans[5][7:4] > 9 )?"7":"0") + ans[5][7:4] ;
		 hex[5][7:0] <= ((ans[5][3:0] > 9 )?"7":"0") + ans[5][3:0] ;
		 hex[5][39:32] <= "0" + ans[5][17:16] ;
		 
		
		 hex[6][31:24] <= ((ans[6][15:12] > 9 )?"7":"0") + ans[6][15:12] ;
		 hex[6][23:16] <= ((ans[6][11:8] > 9 )?"7":"0") + ans[6][11:8] ;
		 hex[6][15:8] <= ((ans[6][7:4] > 9 )?"7":"0") + ans[6][7:4] ;
		 hex[6][7:0] <= ((ans[6][3:0] > 9 )?"7":"0") + ans[6][3:0] ;
		 hex[6][39:32] <= "0" + ans[6][17:16] ;
		 
		
		 hex[7][31:24] <= ((ans[7][15:12] > 9 )?"7":"0") + ans[7][15:12] ;
		 hex[7][23:16] <= ((ans[7][11:8] > 9 )?"7":"0") + ans[7][11:8] ;
		 hex[7][15:8] <= ((ans[7][7:4] > 9 )?"7":"0") + ans[7][7:4] ;
		 hex[7][7:0] <= ((ans[7][3:0] > 9 )?"7":"0") + ans[7][3:0] ;
		 hex[7][39:32] <= "0" + ans[7][17:16] ;
		

		 hex[8][31:24] <= ((ans[8][15:12] > 9 )?"7":"0") + ans[8][15:12] ;
		 hex[8][23:16] <= ((ans[8][11:8] > 9 )?"7":"0") + ans[8][11:8] ;
		 hex[8][15:8] <= ((ans[8][7:4] > 9 )?"7":"0") + ans[8][7:4] ;
		 hex[8][7:0] <= ((ans[8][3:0] > 9 )?"7":"0") + ans[8][3:0] ;
		 hex[8][39:32] <= "0" + ans[8][17:16] ;
		 
		
		 hex[9][31:24] <= ((ans[9][15:12] > 9 )?"7":"0") + ans[9][15:12] ;
		 hex[9][23:16] <= ((ans[9][11:8] > 9 )?"7":"0") + ans[9][11:8] ;
		 hex[9][15:8] <= ((ans[9][7:4] > 9 )?"7":"0") + ans[9][7:4] ;
		 hex[9][7:0] <= ((ans[9][3:0] > 9 )?"7":"0") + ans[9][3:0] ;
		 hex[9][39:32] <= "0" + ans[9][17:16] ;
		 
		 
		 hex[10][31:24] <= ((ans[10][15:12] > 9 )?"7":"0") + ans[10][15:12] ;
		 hex[10][23:16]<= ((ans[10][11:8] > 9 )?"7":"0") + ans[10][11:8] ;
		 hex[10][15:8] <= ((ans[10][7:4] > 9 )?"7":"0") + ans[10][7:4] ;
		 hex[10][7:0] <= ((ans[10][3:0] > 9 )?"7":"0") + ans[10][3:0] ;
		 hex[10][39:32] <= "0" + ans[10][17:16] ;

		 
		 hex[11][31:24] <= ((ans[11][15:12] > 9 )?"7":"0") + ans[11][15:12] ;
		 hex[11][23:16]<= ((ans[11][11:8] > 9 )?"7":"0") + ans[11][11:8] ;
		 hex[11][15:8] <= ((ans[11][7:4] > 9 )?"7":"0") + ans[11][7:4] ;
		 hex[11][7:0] <= ((ans[11][3:0] > 9 )?"7":"0") + ans[11][3:0] ;
		 hex[11][39:32] <= "0" + ans[11][17:16] ;
		 
		 
		 
		 hex[12][31:24] <= ((ans[12][15:12] > 9 )?"7":"0") + ans[12][15:12] ;
		 hex[12][23:16]<= ((ans[12][11:8] > 9 )?"7":"0") + ans[12][11:8] ;
		 hex[12][15:8] <= ((ans[12][7:4] > 9 )?"7":"0") + ans[12][7:4] ;
		 hex[12][7:0] <= ((ans[12][3:0] > 9 )?"7":"0") + ans[12][3:0] ;
		 hex[12][39:32] <= "0" + ans[12][17:16] ;
		 
		 
		 hex[13][31:24] <= ((ans[13][15:12] > 9 )?"7":"0") + ans[13][15:12] ;
		 hex[13][23:16]<= ((ans[13][11:8] > 9 )?"7":"0") + ans[13][11:8] ;
		 hex[13][15:8] <= ((ans[13][7:4] > 9 )?"7":"0") + ans[13][7:4] ;
		 hex[13][7:0] <= ((ans[13][3:0] > 9 )?"7":"0") + ans[13][3:0] ;
		 hex[13][39:32] <= "0" + ans[13][17:16] ;
		 
		 
		 hex[14][31:24] <= ((ans[14][15:12] > 9 )?"7":"0") + ans[14][15:12] ;
		 hex[14][23:16]<= ((ans[14][11:8] > 9 )?"7":"0") + ans[14][11:8] ;
		 hex[14][15:8] <= ((ans[14][7:4] > 9 )?"7":"0") + ans[14][7:4] ;
		 hex[14][7:0] <= ((ans[14][3:0] > 9 )?"7":"0") + ans[14][3:0] ;
		 hex[14][39:32] <= "0" + ans[14][17:16] ;
		 
		 
		 hex[15][31:24] <= ((ans[15][15:12] > 9 )?"7":"0") + ans[15][15:12] ;
		 hex[15][23:16]<= ((ans[15][11:8] > 9 )?"7":"0") + ans[15][11:8] ;
		 hex[15][15:8] <= ((ans[15][7:4] > 9 )?"7":"0") + ans[15][7:4] ;
		 hex[15][7:0] <= ((ans[15][3:0] > 9 )?"7":"0") + ans[15][3:0] ;
		 hex[15][39:32] <= "0" + ans[15][17:16] ;
	end
end


endmodule

// End of the LCD display function
// ------------------------------------------------------------------------

