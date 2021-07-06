`ifndef VDP_H
`define VDP_H

`include "Ram.v"
`include "Vdp.v"
`include "sync-generator.v";

module Vdp(clk, reset, hSync, vSync, rgb);

  parameter RamBits = 16; // default 16 bits, 64Kb
  
  input clk, reset;
  output hSync, vSync;
  output [3:0] rgb;
  
  wire [8:0]xPos, yPos;
  wire isActive;
  
  wire [RamBits-1:0] address;
  wire [7:0] ramDataWrite = 8'b0;
  wire [7:0] ramDataRead;
  
  Ram #(.Bits(RamBits)) ram(
    .clk(clk), .reset(reset), .writeEnabled(0),
    .address(address), .dataIn(ramDataWrite), .dataOut(ramDataRead)
  );
  
  // vdp registers
  reg [7:0] regs[8];
  
  always @(posedge clk) begin
    if(reset) begin
      regs[0] <= {4'b0000, 4'h2}; // 7-4: border colour 3-0: screen mode
      regs[1] <= 8'b0;
      regs[2] <= 8'b0;
      regs[3] <= 8'b0;
      regs[4] <= 8'b0;
      regs[5] <= 8'b0;
      regs[6] <= 8'b0;
      regs[7] <= 8'b0;
    end
  end
  
  wire [3:0] backCol = regs[0][7:4];
  wire [3:0] scrMode = regs[0][3:0];
  

  
  // delay 'line' for the active signal 
  reg [7:0]active;
  always @(posedge clk)
    active <= { active[6:0], isActive };
  wire [8:0]x = xPos-1;
  wire [8:0]y = yPos;
  
  // delayed active signal based on screen mode
  wire [2:0]delay =
  	scrMode == 0 ? 0
     :	scrMode == 1 ? 2
     :  scrMode == 2 ? 3
     :  0;
  
  SyncGenerator sync(
    .clk(clk), .reset(reset),
    .hShift(4'd10 - delay), .vShift(4'd8),
    .hSync(hSync), .vSync(vSync),
    .xPos(xPos), .yPos(yPos), .isActive(isActive)
  );
  
  assign rgb = backCol;
  reg [7:0] pixel;
  
  always @(posedge clk) begin
    
    // screen mode 0, is a virtual screenmode where everything is off
    if(scrMode == 0)
      pixel <= { backCol, backCol };
    
    // screen mode 1, is a direct pixel map from memory onto screen
    // every byte contains 2 pixels
    // pixel map @ 0000-5fff (256/2*192) = 24576 bytes
    else if(scrMode == 1)
    begin
      if(active[0] && x[0] == 1)
        address <= { 1'b0, y[7:0], x[7:1]};
      if(active[1])
          pixel <= ramDataRead;
    end
    
    // screen mode 2, is a charachter map of 32x24 characters
    // char map @ 0000-02ff (32x24 bytes) 768 bytes
    // col  map @ 2000-4000 (4*8*256 bytes) 8192 bytes
    else if(scrMode == 2)
    begin
      reg [7:0] char;
      
      // 0 ca
      // 1 a0	cd
      // -----------------
      // 2 	d0	p0
      // 3 a1		p1
      // 4	d1	p2
      // 5 a2		p3
      // 6	d2	p4
      // 7 a3		p5
      // 8 ca	d3	p6
      // 9 a0	cd	p7
      // -----------------
      // a      d0	p0
      // b a1           p1
      if(active[0] && x[2:0] == 0)
        address <= { 6'b0, y[7:3], x[7:3]};
      if(active[1] && x[2:0] == 1)
      begin
        char <= ramDataRead;
        // char will not be available until next clock
        // so write address using ramdataread for this first one
        address <= { 3'b001, ramDataRead, y[2:0], x[2:1] };
      end
      if(active[1] && x[0] == 1 && x[2:0] != 1)
        address <= { 3'b001, char, y[2:0], x[2:1] };
      if(active[2] && x[0] == 0)
        pixel <= ramDataRead;

    end
    
  end

  
  assign rgb = active[delay]
    ? x[0] == delay[0] ? pixel[7:4] : pixel[3:0]
    : backCol;
  
endmodule

`endif