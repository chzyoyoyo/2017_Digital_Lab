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


module lab8(
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
assign usr_led[0] = btnpr;

wire btn_level, btn_pressed;
reg prev_btn_level;
reg [127:0] row_A = "Press BTN3 to   "; // Initialize the text of the first row. 
reg [127:0] row_B = "show a message.9"; // Initialize the text of the second row.


reg [29:0] brucount;
reg hashfin;
reg [7:0] msg[56+64-1:0];
reg hashbeg;

reg btnpr;



reg [31:0] h0;
reg [31:0] h1;
reg [31:0] h2;
reg [31:0] h3;

reg [31:0] a;
reg [31:0] b;
reg [31:0] c;
reg [31:0] d;
reg [31:0] www[15:0];

reg [63:0] bits_len;

reg forbeg;
integer i;
reg [31:0] f, g;
reg ifend;

reg [31:0] r [0:63];
reg [31:0] k [0:63];

reg forend;

reg [127:0] rehash;

reg [99:0] timecount;

reg [7:0] timeco[6:0];

reg [0:127] passwd_hash = 128'hE9982EC5CA981BD365603623CF4B2277;
//reg [0: 31] pass4[3:0]; 

reg timeflag, timeflag2;


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
    // Initialize the text when the user hit the reset button
    row_A = "Press BTN3 to   ";
    row_B = "show a message..";
    timeflag2 <= 0;
//   end else if (btn_pressed) begin
//     row_A <= "Passwd: xxxxxxxx";
//     row_B <= "Time: yyyyyyy ms";
    end
   else if (rehash == passwd_hash) begin
        row_A[127:64] <= "Passwd: "; 
        row_B[127:80] <= "Time: ";
        row_B[23:0] <= " ms";
        row_A[63: 0] <= {msg[0], msg[1], msg[2], msg[3], msg[4], msg[5], msg[6], msg[7]};
        if(timeflag == 1) begin
            row_B[79:24] <= {timeco[6]+"0", timeco[5]+"0", timeco[4]+"0", timeco[3]+"0",timeco[2]+"0", timeco[1]+"0", timeco[0]+"0"};
            timeflag2 <= 1;
      end
   end
end

always @(posedge clk) begin
   if (~reset_n) begin
    timeco[0] <= 0;
    timeco[1] <= 0;
    timeco[3] <= 0;
    timeco[2] <= 0;
    timeco[4] <= 0;
    timeco[5] <= 0;
    timeco[6] <= 0;
    timeflag <= 0;
    end
   else if (rehash == passwd_hash && timeflag2 == 0) begin
//      timeco[0] <= timeco[0]/1000000;
//       timeco[1] <= (timeco[1]/100000)%10;
//       timeco[2] <= (timeco[2]/10000)%10;
//       timeco[3] <= (timeco[3]/1000)%10;
//       timeco[4] <= (timeco[4]/100)%10;
//       timeco[5] <= (timeco[5]/10)%10;
//       timeco[6] <= (timeco[6]/1)%10; 
       timeflag <= 1;
       
     end
   else if(timecount == 100000) begin
            if(timeco[5] >= 10)begin
              timeco[5]= timeco[5]-10;
              timeco[6]= timeco[6]+1;
              end
             if(timeco[4] >= 10)begin
               timeco[4]= timeco[4]-10;
               timeco[5]= timeco[5]+1;
               end
              if(timeco[3] >= 10)begin
                timeco[3]= timeco[3]-10;
                timeco[4]= timeco[4]+1;
                end
               if(timeco[2] >= 10)begin
                 timeco[2]= timeco[2]-10;
                 timeco[3]= timeco[3]+1;
                 end
                if(timeco[1] >= 10)begin
                  timeco[1]= timeco[1]-10;
                  timeco[2]= timeco[2]+1;
                  end
                 if(timeco[0] >= 10)begin
                   timeco[0]= timeco[0]-10;
                   timeco[1]= timeco[1]+1;
                   end
                                                           
       timeco[0] = timeco[0]+1;
//       timeco[1] <= timeco[1]+1;
//       timeco[2] <= timeco[2]+1;
//       timeco[3] <= timeco[3]+1;
//       timeco[4] <= timeco[4]+1;
//       timeco[5] <= timeco[5]+1;
//       timeco[6] <= timeco[6]+1;
     
   end
    
end

always @(posedge clk ) begin
  if (~reset_n) begin
    btnpr <= 0;
    
  end
  else if (btn_pressed) begin
    btnpr <= 1;
  end
  else if (rehash == passwd_hash)
    btnpr <= 0;
  else begin
    btnpr <= btnpr;
  end
end


always @(posedge clk ) begin
  if (~reset_n) begin
    // reset
    timecount <= 0;
  end
  else if (btnpr) begin
    if(timecount == 100000)
        timecount <= 0;
    else
        timecount <= timecount + 1;
  end
end




//Main function
always @(posedge clk) begin
  if (~reset_n) begin
    // reset
    brucount <= 0;
    hashfin <= 1;
    forbeg <= 0;
    rehash <= 0;
    for(i = 0; i < 56+64; i = i+1)
      msg[i] <= 0;
    
     
  { r[ 0], r[ 1], r[ 2], r[ 3], r[ 4], r[ 5], r[ 6], r[ 7], 
     r[ 8], r[ 9], r[10], r[11], r[12], r[13], r[14], r[15],
     r[16], r[17], r[18], r[19], r[20], r[21], r[22], r[23],
     r[24], r[25], r[26], r[27], r[28], r[29], r[30], r[31],
     r[32], r[33], r[34], r[35], r[36], r[37], r[38], r[39], 
     r[40], r[41], r[42], r[43], r[44], r[45], r[46], r[47],
     r[48], r[49], r[50], r[51], r[52], r[53], r[54], r[55],
     r[56], r[57], r[58], r[59], r[60], r[61], r[62], r[63] } <=
   { 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22, 7, 12, 17, 22,
     5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20, 5,  9, 14, 20,
     4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23, 4, 11, 16, 23,
     6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21, 6, 10, 15, 21  };
   
   { k[ 0], k[ 1], k[ 2], k[ 3], k[ 4], k[ 5], k[ 6], k[ 7], 
     k[ 8], k[ 9], k[10], k[11], k[12], k[13], k[14], k[15],
     k[16], k[17], k[18], k[19], k[20], k[21], k[22], k[23],
     k[24], k[25], k[26], k[27], k[28], k[29], k[30], k[31],
     k[32], k[33], k[34], k[35], k[36], k[37], k[38], k[39], 
     k[40], k[41], k[42], k[43], k[44], k[45], k[46], k[47],
     k[48], k[49], k[50], k[51], k[52], k[53], k[54], k[55],
     k[56], k[57], k[58], k[59], k[60], k[61], k[62], k[63] } <=
   {
         32'hd76aa478, 32'he8c7b756, 32'h242070db, 32'hc1bdceee,
         32'hf57c0faf, 32'h4787c62a, 32'ha8304613, 32'hfd469501,
         32'h698098d8, 32'h8b44f7af, 32'hffff5bb1, 32'h895cd7be,
         32'h6b901122, 32'hfd987193, 32'ha679438e, 32'h49b40821,
         32'hf61e2562, 32'hc040b340, 32'h265e5a51, 32'he9b6c7aa,
         32'hd62f105d, 32'h02441453, 32'hd8a1e681, 32'he7d3fbc8,
         32'h21e1cde6, 32'hc33707d6, 32'hf4d50d87, 32'h455a14ed,
         32'ha9e3e905, 32'hfcefa3f8, 32'h676f02d9, 32'h8d2a4c8a,
         32'hfffa3942, 32'h8771f681, 32'h6d9d6122, 32'hfde5380c,
         32'ha4beea44, 32'h4bdecfa9, 32'hf6bb4b60, 32'hbebfbc70,
         32'h289b7ec6, 32'heaa127fa, 32'hd4ef3085, 32'h04881d05,
         32'hd9d4d039, 32'he6db99e5, 32'h1fa27cf8, 32'hc4ac5665,
         32'hf4292244, 32'h432aff97, 32'hab9423a7, 32'hfc93a039,
         32'h655b59c3, 32'h8f0ccc92, 32'hffeff47d, 32'h85845dd1,
         32'h6fa87e4f, 32'hfe2ce6e0, 32'ha3014314, 32'h4e0811a1,
         32'hf7537e82, 32'hbd3af235, 32'h2ad7d2bb, 32'heb86d391
     };
 
    
    
    

  end

  else if(btnpr) begin
    
    
    if (hashfin == 1) begin
//      if (rehash == passwd_hash) begin
//        row_A[127:64] <= "Passwd: "; 
//        row_B[127:80] <= "Time: ";
//        row_B[23:0] <= " ms";
//        row_A[63: 0] <= {msg[0], msg[1], msg[2], msg[3], msg[4], msg[5], msg[6], msg[7]};
//        //row_B[79:24] <= {timecount/100000/1000000+"0", timecount/100000/100000%10+"0", timecount/1000000000%10+"0", timecount/100000000%10+"0", timecount/10000000%10+"0", timecount/1000000%10+"0", timecount/100000%10+"0"};
        
//      end

      if (rehash != passwd_hash) begin
        brucount <= brucount + 1;
        msg[0] <= (brucount) / 10000000 + "0";
        msg[1] <= ((brucount) / 1000000) % 10 + "0";
        msg[2] <= ((brucount) / 100000) % 10 + "0";
        msg[3] <= ((brucount) / 10000) % 10 + "0";
        msg[4] <= ((brucount) / 1000) % 10 + "0";
        msg[5] <= ((brucount) / 100) % 10 + "0";
        msg[6] <= ((brucount) / 10) % 10 + "0";
        msg[7] <= ((brucount) / 1) % 10 + "0";
        msg[8] <= 128;
        msg[56]<= 64;

        h0 <= 32'h67452301;
        h1 <= 32'hEFCDAB89;
        h2 <= 32'h98BADCFE;
        h3 <= 32'h10325476;
        hashfin <= 0;
        forbeg <= 0;

      end
      
    end

    else if (hashfin == 0) begin
      if (forbeg == 0) begin
        
        www[0] <={msg[3],  msg[2],  msg[1],  msg[0]};   
        www[1] <={msg[7],  msg[6],  msg[5],  msg[4]};   
        www[2] <={msg[11], msg[10], msg[9],  msg[8]};
        www[3] <= {msg[12], msg[13], msg[14], msg[15]};
        www[4] <= {msg[16], msg[17], msg[18], msg[19]};
        www[5] <= {msg[20], msg[21], msg[22], msg[23]};
        www[6] <= {msg[24], msg[25], msg[26], msg[27]};
        www[7] <= {msg[28], msg[29], msg[30], msg[31]};
        www[8] <= {msg[32], msg[33], msg[34], msg[35]};
        www[9] <= {msg[36], msg[37], msg[38], msg[39]};
        www[10] <= {msg[40], msg[41], msg[42], msg[43]};
        www[11] <= {msg[44], msg[45], msg[46], msg[47]};
        www[12] <= {msg[48], msg[49], msg[50], msg[51]};
        www[13] <= {msg[52], msg[53], msg[54], msg[55]};
        www[14]<={msg[59], msg[58], msg[57], msg[56]}; 
        www[15]<={msg[60], msg[61], msg[62], msg[63]}; 

        a <= h0;
        b <= h1;
        c <= h2;
        d <= h3;
        i <= 0;
        ifend <= 0;
        forbeg <= 1;
        forend <= 0;

      end

      else if (forbeg == 1 && i < 64) begin
        if (ifend == 0) begin

          if (i < 16) begin
            f <= (b & c) | ((~b) & d);
            g <= i;
            ifend <= 1;
          end
          else if (i < 32) begin
            f <= (d & b) | ((~d) & c);
            g <= (5*i + 1) % 16;
            ifend <= 1;
          end
          else if (i < 48) begin
            f <= b ^ c ^ d;
            g <= (3*i + 5) % 16; 
            ifend <= 1;
          end
          else if (i < 64)begin
            f <= c ^ (b | (~d));
            g <= (7*i) % 16;
            ifend <= 1;
          end

        end
        else if (ifend == 1) begin
          d <= c;
          c <= b;
          b <= b + (((a + f + k[i] + www[g]) << r[i]) | ((a + f + k[i] + www[g]) >> (32 - r[i])));
          a <= d;
          i <= i + 1;
          ifend <= 0;
        end
      end

      else if (i == 64 && forend == 0) begin
        h0 <= a + h0;
        h1 <= b + h1;
        h2 <= c + h2;
        h3 <= d + h3;
        forend <= 1;
      end

      else if (forend == 1) begin
        rehash[127:96] <= {h0[7:0], h0[15:8], h0[23:16], h0[31:24]};
        rehash[95:64] <= {h1[7:0], h1[15:8], h1[23:16], h1[31:24]};
        rehash[63:32] <= {h2[7:0], h2[15:8], h2[23:16], h2[31:24]};
        rehash[31: 0] <= { h3[7:0], h3[15:8], h3[23:16], h3[31:24] };
        
        hashfin <= 1;
      end

    end


  end
end








endmodule
