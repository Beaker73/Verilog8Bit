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
  // VDP Registers
  // r00    ---DBBBB    BBBB  Border RGB; D  Disabled
  //
  reg [7:0] regs[15:0];
  always @(reset) begin
    regs[0]  = 8'b00011100;
  end
  
  //
  // Video RAM, 64Kb
  //
  wire [15:0] address;
  wire [7:0] data = 8'bzzzzzzzz;
  Ram #(16) vram(
    .clk(clk), .reset(reset), .chipSelect(isActive), .writeEnabled(0),
    .address(address), .data(data)
  );
  
  // 0000-2FFF - 32 columns, 24 rows = 0x300 chars
  // we buffer a single row (32 chars) before the line starts
  //if(xPos < (309-32)) begin
  //  assign address = 
  //end

  assign address = { yPos[7:0], xPos[7:0] };
  wire isEnabled = isActive && regs[0][4] == 1'b0;
  assign rgb = isEnabled ? data[3:0] : regs[0][3:0];

endmodule

`endif