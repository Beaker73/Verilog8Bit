`ifndef COMPUTER_V
`define COMPUTER_V

`include "Rom.v"
`include "Ram.v"
`include "Cpu.v"
`include "CpuAlu.z"
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

  wire [7:0] dataIn, dataOut;
  wire [15:0] address;

  Ram ram(
    .clk(clk), .reset(reset),
    .writeEnabled(0),
    .address(address),
    .dataIn(dataIn), .dataOut(dataOut)
  );
  
  Rom rom(
    .clk(clk), .reset(reset), .chipSelect(address[15:14] == 2'b00),
    .address(address[13:0]),
    .data(dataOut)
  );
  
  Cpu cpu(
    .clk(clk), .reset(reset),
    .address(address),
    .dataIn(dataOut), .dataOut(dataIn)
  );
  
  wire [7:0] r = { rgb8[7:5], rgb8[7:5], rgb8[7:6] };
  wire [7:0] g = { rgb8[4:2], rgb8[4:2], rgb8[4:3] };
  wire [7:0] b = { rgb8[1:0], rgb8[1:0], rgb8[1:0], rgb8[1:0] };
  
  // convert internal rgb to external rgb
  assign rgb = { 8'hff, b, g, r };
  
endmodule

`endif