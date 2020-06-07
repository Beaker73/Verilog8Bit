`ifndef COMPUTER_H
`define COMPUTER_H

`include "Cpu.v";
`include "Rom.v"
`include "Ram.v";
`include "Vdp.v";
`include "SyncGenerator.v";
//iclude "Beaker8.json"

module top(clk, reset, hsync, vsync, rgb);

  input clk, reset;
  output hsync, vsync;
  output [3:0] rgb;
  
  // bus wires
  wire [15:0] address;
  reg [7:0] data;

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