`ifndef SYNCGENERATOR_V
`define SYNCGENERATOR_V

`include "Ram.v"

module SyncGenerator(clk, reset, hShift, vShift, hSync, vSync, xPos, yPos, isActive);
 
  // 4857480 Hz
  // 262 Lines, 309 Cycles per Line, 60 frames p/sec.
  input clk, reset;
  input [3:0] hShift, vShift;
  output hSync, vSync, isActive;
  output signed [8:0] xPos, yPos;

  reg [8:0] line = 0;
  reg [8:0] column = 0;
  
  reg [8:0] xPos = 0;
  reg [8:0] yPos = 0;
  
  // these compute the NEXT position
  always @(posedge clk)
  begin
    column <= column + 1;

    // compute position
    if(column == 309) 
    begin
      column <= 0;
      line <= line + 1;
      if(line == 262) 
      begin
        line <= 0;
      end
    end
  end
  
  // determine h sync and v sync
  assign vSync = line < 3;
  assign hSync = column > (309-23);
  
  // compute the pixel position based on configured shift and the borders
  assign xPos = column - 8'd9 - { 5'b0, hShift };
  assign yPos = line - 8'd26 - { 5'b0, vShift };
  
  // check if inside the pixel active region
  assign isActive = xPos[8] == 0 && yPos[8] == 0 && yPos < 192;
  
endmodule;

`endif