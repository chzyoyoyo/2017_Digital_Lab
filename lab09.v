`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: Dept. of Computer Science, National Chiao Tung University
// Engineer: Chun-Jen Tsai
// 
// Create Date: 2017/12/06 20:44:08
// Design Name: 
// Module Name: lab9
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: This is a sample circuit to show you how to initialize an SRAM
//              with a pre-defined data file. Hit BTN0/BTN1 let you browse
//              through the data.
// 
// Dependencies: LCD_module, debounce
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module lab9(
  // General system I/O ports
  input  clk,
  input  reset_n,
  input  [3:0] usr_btn,
  output [3:0] usr_led,

  // 1602 LCD Module Interface
  output LCD_RS,
  output LCD_RW,
  output LCD_E,
  output [3:0] LCD_D
);

localparam [1:0] S_MAIN_ADDR = 3'b000, S_MAIN_READ = 3'b001,
                 S_MAIN_SHOW = 3'b010, S_MAIN_WAIT = 3'b011;

// declare system variables
wire [1:0]        btn_level, btn_pressed;
reg  [1:0]        prev_btn_level;
reg  [1:0]        P, P_next;
reg  [11:0]       sample_addr;
reg  signed [7:0] sample_data;
wire [7:0]        abs_data;

reg  [127:0] row_A, row_B;

// declare SRAM control signals
wire [10:0] sram_addr;
wire [7:0]  data_in;
wire [7:0]  data_out;
wire        sram_we, sram_en;


//LAB9 
reg signed [7:0] f[1023:0];
reg signed [7:0] g[63:0];

reg [23:0] x;
reg [ 6:0] k;

reg signed [23:0] max;
reg signed [23:0] sum;
reg [11:0] maxpos;

reg forend;
reg finish;

reg btnpr;
reg storeflag;

assign usr_led = 4'h00;

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
  .btn_input(usr_btn[0]),
  .btn_output(btn_level[0])
);

debounce btn_db1(
  .clk(clk),
  .btn_input(usr_btn[1]),
  .btn_output(btn_level[1])
);

//
// Enable one cycle of btn_pressed per each button hit
//
always @(posedge clk) begin
  if (~reset_n)
    prev_btn_level <= 2'b00;
  else
    prev_btn_level <= btn_level;
end

assign btn_pressed = (btn_level & ~prev_btn_level);

// ------------------------------------------------------------------------
// The following code describes an initialized SRAM memory block that
// stores an 1024+64 8-bit signed data samples.
sram ram0(.clk(clk), .we(sram_we), .en(sram_en),
          .addr(sram_addr), .data_i(data_in), .data_o(data_out));

assign sram_we = usr_btn[3]; // In this demo, we do not write the SRAM. However,
                             // if you set 'we' to 0, Vivado fails to synthesize
                             // ram0 as a BRAM -- this is a bug in Vivado.
assign sram_en = (P == S_MAIN_ADDR || P == S_MAIN_READ); // Enable the SRAM block.
assign sram_addr = sample_addr[11:0];
assign data_in = 8'b0; // SRAM is read-only so we tie inputs to zeros.
// End of the SRAM memory block.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// FSM of the main controller
always @(posedge clk) begin
  if (~reset_n) begin
    P <= S_MAIN_ADDR; // read samples at 000 first
  end
  else begin
    P <= P_next;
  end
end

always @(*) begin // FSM next-state logic
  case (P)
    S_MAIN_ADDR: // send an address to the SRAM 
      P_next = S_MAIN_READ;
    S_MAIN_READ: // fetch the sample from the SRAM
      P_next = S_MAIN_SHOW;
    S_MAIN_SHOW:
      P_next = S_MAIN_WAIT;
    S_MAIN_WAIT: // wait for a button click
      P_next = S_MAIN_ADDR;
      //else P_next = S_MAIN_WAIT;
  endcase
end

// FSM ouput logic: Fetch the data bus of sram[] for display
always @(posedge clk) begin
  if (~reset_n) sample_data <= 8'b0;
  else if (sram_en && !sram_we) sample_data <= data_out;
end
// End of the main controller
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The following code updates the 1602 LCD text messages.
always @(posedge clk) begin
  if (~reset_n) begin
    row_B <= "x-correlation...";
  end
  else if (finish) begin
    row_B[127:24] <="Max location ";
    row_B[23:16] <= ((maxpos[11: 8] > 9)? "7" : "0") + maxpos[11: 8];
    row_B[15: 8] <= ((maxpos[ 7: 4] > 9)? "7" : "0") + maxpos[ 7: 4];
    row_B[ 7: 0] <= ((maxpos[ 3: 0] > 9)? "7" : "0") + maxpos[ 3: 0];
  end
end

assign abs_data = (sample_data < 0)? -sample_data : sample_data;

always @(posedge clk) begin
  if (~reset_n) begin
    row_A <= "Press BTN0 to do";
  end
  else if (finish) begin
    row_A[127:48] <= "Max value ";// (sample_data[7])? "-" : "+";
    row_A[47:40] <= ((max[23:21] > 9)? "7" : "0") + max[23:20];
    row_A[39:32] <= ((max[19:16] > 9)? "7" : "0") + max[19:16];
    row_A[31:24] <= ((max[15:12] > 9)? "7" : "0") + max[15:12];
    row_A[23:16] <= ((max[11: 8] > 9)? "7" : "0") + max[11: 8];
    row_A[15: 8] <= ((max[ 7: 4] > 9)? "7" : "0") + max[ 7: 4];
    row_A[ 7: 0] <= ((max[ 3: 0] > 9)? "7" : "0") + max[ 3: 0];
  end
end
// End of the 1602 LCD text-updating code.
// ------------------------------------------------------------------------

// ------------------------------------------------------------------------
// The circuit block that processes the user's button event.
always @(posedge clk) begin
  if (~reset_n)
    sample_addr <= 12'h000;
  else if (sample_addr < 2048 && P == S_MAIN_WAIT)
    sample_addr <= sample_addr + 1;
  else
    sample_addr <= sample_addr;
end
// End of the user's button control.
// ------------------------------------------------------------------------

integer i;

always @(posedge clk ) begin
	if (~reset_n) begin
		storeflag <= 0;
		for(i = 0; i < 1024; i = i+1)begin
			f[i] <= 0;
			 if (i < 64) begin
			 	g[i] <= 0;
			 end
		end
	end

	else if (sample_addr < 1024) begin 
		if (P == S_MAIN_READ)begin
			f[sample_addr] <= data_out;
		end

	end
	else if (sample_addr < 1088) begin
		if (P == S_MAIN_READ) begin
			g[sample_addr - 1024] <= data_out;
		end
	end
	else if (sample_addr == 1088) begin
		storeflag <= 1;
		
	end
end






always @(posedge clk ) begin
  if (~reset_n) begin
    // reset
    btnpr <= 0;
  end
  else if (btn_pressed[0]) begin
    btnpr <= 1;
  end
  else if (finish) begin
    btnpr <= 0;
  end
  else begin
    btnpr <= btnpr;
  end
end

//reg forbeg;

always @(posedge clk ) begin
  if (~reset_n) begin
    // reset
    x <= 0;
    k <= 0;
    sum <= 0;
    max <= 0;
    maxpos <= 0;
    forend <= 1;
    finish <= 0;
    //forbeg <= 0;
  end

  if (btnpr && storeflag) begin

    if(x < 1024-64) begin
      if (forend) begin
        sum <= 0;
        k <= 0;
        //forbeg <= 1;
        forend <= 0;
      end
      else if(forend == 0 && k < 64) begin
        sum <= sum + f[k+x] * g[k];
        k <= k + 1;
      end
      else if (k == 64) begin
        if (sum > max) begin
          max <= sum;
          maxpos <= x;
          forend <= 1;
          //forbeg <= 0;
          x <= x+1;
        end
        else begin
          forend <= 1;
          //forbeg <= 0;
          x <= x+1;
        end
      end
    end

    else if (x == 1024-64) begin
      finish <= 1;
    end
  end

end
endmodule
