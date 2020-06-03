`ifndef VDP_H
`define VDP_H

`include "Ram.v"
`include "Vdp.v"
`include "SyncGenerator.v";

module Vdp(clk, reset, hSync, vSync, rgb);

  input clk, reset;
  output hSync, vSync;
  output [3:0] rgb;
  
  wire [8:0]xPos, yPos;
  wire isActive;
  
  SyncGenerator sync(
    .clk(clk), .reset(reset),
    .hShift(4'd8), .vShift(4'd8),
    .hSync(hSync), .vSync(vSync),
    .xPos(xPos), .yPos(yPos), .isActive(isActive)
  );
  
  assign rgb = isActive ? 4'b0100 : 4'b1100;

endmodule

`endif