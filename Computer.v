`ifndef COMPUTER_H
`define COMPUTER_H

`include "Ram.v"
`include "Vdp.v"
`include "SyncGenerator.v";

module top(clk, reset, hsync, vsync, rgb);

  input clk, reset;
  output hsync, vsync;
  output [3:0] rgb;
  
  Vdp vdp(
    .clk(clk), .reset(reset),
    .hSync(hsync), .vSync(vsync), .rgb(rgb)
  );

endmodule

`endif