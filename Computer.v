`ifndef COMPUTER_H
`define COMPUTER_H

`include "Cpu.v";
`include "Rom.v"
`include "Ram.v";
`include "Vdp.v";
`include "SyncGenerator.v";

//`include "Beaker8.json"

module top(clk, reset, hsync, vsync, rgb);

  input clk, reset;
  output hsync, vsync;
  output [3:0] rgb;
  
  // bus wires
  wire [15:0] address;
  reg [7:0] data;
  
  wire selectRom = address[15:14] == 2'b00;
  Rom rom(
    .clk(clk), .reset(reset), .chipSelect(selectRom),
    .address(address[13:0]), .data(data)
  );

  Cpu cpu(
    .clk(clk), .reset(reset),
    .address(address), .data(data)
  );

  // [FFF0-FFFF] VDP Register mapping
  
  Vdp vdp(
    .clk(clk), .reset(reset),
    .hSync(hsync), .vSync(vsync), .rgb(rgb)
  );
 

endmodule

`endif