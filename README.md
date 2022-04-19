# 2017 Digital Lab
Porf. Chun-Jen Tsai, National Chiao‐Tung University

## Lab1: Introduction to the EDA Tools
### Goal: Design an 8-bit Multiplier
- In this lab, you must design an 8-bit sequential binary multiplier and use the Vivado Simulator to verify your design
    - You should review your old textbook on Digital Circuit Design by Mano. Some design guideline of the sequential binary multiplier is in section 8.7 of Mano’s book.
    - You must design your multiplier using only adder, shifter, multiplexor, and gate-level operators. You can not use the multiplication operator of Verilog.
    
## Lab 2: Matrix Multiplication Simulation
- In this lab, you will design a circuit to do a 3×3 matrix multiplication on Vivado Simulator.
    - Two register arrays with of 3×3 matrices will be given to you in the sample Verilog simulation project.
    - You must design a Verilog program to compute their multiplication, and print the result from the testbench.
    - You must use no more than 9 multipliers to implement your circuit

## Lab3: Push Button and LED Control
- In this lab, you will use the FPGA development board “Arty” to implement a simple I/O control circuit
    - There are 4 push-buttons and 4 yellow LED lights on the board
    - You must design a synchronous circuit that reads each of the push-button inputs and display different light patterns on the board
    
## Lab 4: UART Communications
- In this lab, you will design a circuit to perform UART I/O. Your circuit will do the following things:
    - Read two decimal number inputs from the UART/JTAG port connected to a PC terminal window. The number ranges from 0 to 65535.
    - Compute the Greatest Common Divider (GCD) of the two numbers, and print the GCD to the UART terminal in hexadecimal format

## Lab 5: Character LCD Control
- In this lab, you will use the sieve algorithm to find all the primes from 2 to 1021, and use the standard 1602 character LCD to display the prime numbers
![](https://i.imgur.com/T0nMcUD.png)
 
## Lab 6: SD Card Reader Circuit
- In this lab, you will design a circuit to read a text file from an SD card, and count the number of occurrence of “the” in the text and print it on the 1602 LCD
    - The number shown shall be a decimal number
    - The search of “the” shall be case insensitive
![](https://i.imgur.com/nJE9ayG.png)


## Lab 7: Matrix Multiplication Circuit Design
- In this lab, you will design a circuit to do 4×4 matrix multiplications.
    - The user press BTN1 to start the circuit
    - The circuit reads two 4×4 matrices from a file on the SD card, perform the multiplication, and print the output matrix through the UART to a terminal window

## Lab 8: Password Cracking
- In this lab, you will design a circuit to guess an 8-digit password scrambled with the MD5 hashing algorithm
    - The password is composed of eight decimal digits coded in ASCII codes
    - The MD5 hash code of the password will be given to you
    - Your circuit must crack it, and display the original password and the time it takes for you to crack the password on the LCD module
## Lab 9: Correlation Filter Design
- In this lab, you will design a correlation filter circuit and use it to detect the presence of a waveform
    - Your circuit has an SRAM that stores a 1-D waveform f[⋅] of 1024 data samples and a 1-D pattern g[⋅] of 64 data samples; each sample in f[⋅] and g[⋅] is an 8-bit signed number
    - When the user hit BTN0, your circuit will compute the cross- correlation function Cfg[⋅] between f[⋅] and g[⋅], and display the maximal value of Cfg[⋅] and its position on the 1602 LCD
    
## Lab 10: VGA Graphic Display
- In this lab, you will implement a circuit that shows some graphics using the VGA video interface; your circuit must do the following things:
    - Animates the moon to move across the picture with green- screen removal
    - Adds fireworks animations to the picture
