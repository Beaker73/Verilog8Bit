`ifndef VDP_H
`define VDP_H

`include "SyncGenerator.v";
`include "Ram.v"

module Vdp(clk, reset, hSync, vSync, rgb);

  input clk, reset;
  output hSync, vSync;
  output [3:0] rgb;

  //
  // sync generator
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
  wire vWriteEnabled = 0;
  wire [15:0] vAddress = 0;
  wire [7:0] vDataWrite = 0, vDataRead = 0;
  Ram #(16) vram(
    .clk(clk), .reset(reset), .writeEnabled(vWriteEnabled),
    .address(vAddress), .dataIn(vDataWrite), .dataOut(vDataRead)
  );
  
  assign rgb = isActive ? 4'b0100 : 4'b1100;

endmodule

`endif