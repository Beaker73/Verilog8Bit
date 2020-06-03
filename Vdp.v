`ifndef VDP_H
`define VDP_H

`include "SyncGenerator.v";
`include "Ram.v"

module Vdp(clk, reset, hSync, vSync, rgb);

  input clk, reset;
  output hSync, vSync;
  output [3:0] rgb;

  //
  // Sync Generator
  //
  wire [8:0]xPos, yPos;
  wire isActive;
  SyncGenerator sync(
    .clk(clk), .reset(reset),
    .hShift(4'd8), .vShift(4'd8),
    .hSync(hSync), .vSync(vSync),
    .xPos(xPos), .yPos(yPos), .isActive(isActive)
  );
  
  //
  // Video RAM, 64Kb
  //
  wire [15:0] address;
  wire [7:0] data = 8'bzzzzzzzz;
  Ram #(16) vram(
    .clk(clk), .reset(reset), .chipSelect(isActive), .writeEnabled(0),
    .address(address), .data(data)
  );

  assign address = { yPos[7:0], xPos[7:0] };
  assign rgb = isActive ? data[3:0] : 4'b1100;

endmodule

`endif