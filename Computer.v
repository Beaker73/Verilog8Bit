`ifndef COMPUTER_V
`define COMPUTER_V

`include "Rom.v"
`include "Ram.v"
`include "Cpu.v"
`include "CpuAlu.v"
`include "Vdp.v"
`include "SyncGenerator.v";

`ifdef BANAAN
`include "Beaker8.json";
`endif

module top(clk, reset, hsync, vsync, rgb);

  input clk, reset;
  output hsync, vsync;
  output [31:0] rgb;
  
  wire [7:0] rgb8;
  
  Vdp vdp(
    .clk(clk), .reset(reset),
    .hSync(hsync), .vSync(vsync), .rgb(rgb8)
  );

  wire read, write;
  wire [7:0] dataIn, dataOut;
  wire [15:0] address;

  Cpu cpu(
    .clk(clk), .reset(reset), .read(read), .write(write),
    .address(address),
    .dataIn(dataOut), .dataOut(dataIn)
  );

  wire [7:0] ramDataOut;
  Ram ram(
    .clk(clk), .reset(reset),
    .writeEnabled(write && address[15:14] != 2'b00),
    .address(address),
    .dataIn(dataIn), .dataOut(ramDataOut)
  );
  
  wire [7:0] romDataOut;
  Rom rom(
    .clk(clk), .reset(reset), .chipSelect(address[15:14] == 2'b00),
    .address(address[13:0]),
    .data(romDataOut)
  );
  
  assign dataOut = address[15:14] == 2'b00 ? romDataOut : ramDataOut;
 
  
  // convert internal rgb to external rgb
  wire [7:0] r = { rgb8[7:5], rgb8[7:5], rgb8[7:6] };
  wire [7:0] g = { rgb8[4:2], rgb8[4:2], rgb8[4:3] };
  wire [7:0] b = { rgb8[1:0], rgb8[1:0], rgb8[1:0], rgb8[1:0] };
  assign rgb = { 8'hff, b, g, r };
  
endmodule

`endif