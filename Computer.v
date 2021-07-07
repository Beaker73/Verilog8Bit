`ifndef COMPUTER_H
`define COMPUTER_H

`include "Ram.v"
`include "Vdp.v"
`include "SyncGenerator.v";

module top(clk, reset, hsync, vsync, rgb);

  input clk, reset;
  output hsync, vsync;
  output [31:0] rgb;
  
  wire [7:0] rgb8;
  
  Vdp vdp(
    .clk(clk), .reset(reset),
    .hSync(hsync), .vSync(vsync), .rgb(rgb8)
  );

  assign rgb = {
    8'hff, 
    rgb8[1:0], rgb8[1:0], rgb8[1:0], rgb8[1:0], // b
    rgb8[4:2], rgb8[4:2], rgb8[4:3], // g
    rgb8[7:5], rgb8[7:5], rgb8[7:6]  // r
  };
  
endmodule

`endif