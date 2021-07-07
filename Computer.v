`ifndef COMPUTER_H
`define COMPUTER_H

`include "Ram.v"
`include "Vdp.v"
`include "SyncGenerator.v";

module top(clk, reset, hsync, vsync, rgb);

  input clk, reset;
  output hsync, vsync;
  output [31:0] rgb;
  
  wire [3:0] rgbidx;
  
  Vdp vdp(
    .clk(clk), .reset(reset),
    .hSync(hsync), .vSync(vsync), .rgb(rgbidx)
  );

  reg [31:0] rgbhex = 32'hff000000;
  always @(posedge clk) begin
    if(rgbidx == 4'b0000) rgbhex[23:0] <= 24'h000000;
    if(rgbidx == 4'b0001) rgbhex[23:0] <= 24'h2B531D;
    if(rgbidx == 4'b0010) rgbhex[23:0] <= 24'h25537E;
    if(rgbidx == 4'b0011) rgbhex[23:0] <= 24'h875100;
    if(rgbidx == 4'b0100) rgbhex[23:0] <= 24'h5236AB;
    if(rgbidx == 4'b0101) rgbhex[23:0] <= 24'h574F5F;
    if(rgbidx == 4'b0110) rgbhex[23:0] <= 24'hC3C7C2;
    if(rgbidx == 4'b0111) rgbhex[23:0] <= 24'hF1E8FF;
    if(rgbidx == 4'b1000) rgbhex[23:0] <= 24'h004DFF;
    if(rgbidx == 4'b1001) rgbhex[23:0] <= 24'hA300FF;
    if(rgbidx == 4'b1010) rgbhex[23:0] <= 24'hEC27FF;
    if(rgbidx == 4'b1011) rgbhex[23:0] <= 24'hE43600;
    if(rgbidx == 4'b1100) rgbhex[23:0] <= 24'hADFF29;
    if(rgbidx == 4'b1101) rgbhex[23:0] <= 24'h769C83;
    if(rgbidx == 4'b1110) rgbhex[23:0] <= 24'h77A8FF;
    if(rgbidx == 4'b1111) rgbhex[23:0] <= 24'hCCAAFF;
  end

  assign rgb = rgbhex;
  
endmodule

`endif