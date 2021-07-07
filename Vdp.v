`ifndef VDP_H
`define VDP_H

`include "Ram.v"
`include "Vdp.v"
`include "SyncGenerator.v";

module Vdp(clk, reset, hSync, vSync, rgb);

  parameter RamBits = 16; // default 16 bits, 64Kb
  
  input clk, reset;
  output hSync, vSync;
  output [7:0] rgb;
  
  wire [8:0]xPos, yPos;
  wire isActive;
  
  wire [RamBits-1:0] address;
  wire [7:0] ramDataWrite = 8'b0;
  wire [7:0] ramDataRead;
  
  Ram #(.Bits(RamBits)) ram(
    .clk(clk), .reset(reset), .writeEnabled(0),
    .address(address), .dataIn(ramDataWrite), .dataOut(ramDataRead)
  );
  
  // init default palette
  reg [7:0] palette[16];
  always @(posedge reset) begin
    palette[00] <= 8'b000_000_00; // 000000
    palette[01] <= 8'b001_001_01; // 1D2B53
    palette[02] <= 8'b011_001_01; // 7E2553
    palette[03] <= 8'b000_100_01; // 008751
    palette[04] <= 8'b101_010_00; // AB5236
    palette[05] <= 8'b011_011_01; // 5F574F
    palette[06] <= 8'b110_110_11; // C2C3C7
    palette[07] <= 8'b111_111_11; // FFF1E8
    palette[08] <= 8'b111_000_01; // FF004D
    palette[09] <= 8'b111_101_00; // FFA300
    palette[10] <= 8'b111_111_00; // FFEC27
    palette[11] <= 8'b000_111_01; // 00E436
    palette[12] <= 8'b001_101_11; // 29ADFF
    palette[13] <= 8'b100_011_10; // 83769C
    palette[14] <= 8'b111_011_10; // FF77A8
    palette[15] <= 8'b111_110_10; // FFCCAA
  end
  
  // vdp registers
  reg [7:0] regs[8];
  
  always @(posedge reset) begin
    regs[0] <= {4'b0000, 4'h2}; // 7-4: border colour 3-0: screen mode
    regs[1] <= 8'b0;
    regs[2] <= 8'b0;
    regs[3] <= 8'b0;
    regs[4] <= 8'b0;
    regs[5] <= 8'b0;
    regs[6] <= 8'b0;
    regs[7] <= 8'b0;
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
  
  wire [3:0] color = backCol;
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
    // attr map @ 0400-04ff 255 bytes  (7 fliph 6 flipv 1-0 palette id)
    // palt map @ 0600-063f (rrrgggbb * 16 * 4) = 64 bytes
    // pixl map @ 2000-3fff (4*8*256 bytes) 8192 bytes
    else if(scrMode == 2)
    begin
      reg [7:0] char;
      //   aa
      //        ad
      // 0 ca
      // 1 a0	cd
      // -----------------
      // 2 	d0	p0
      // 3 a1		p1
      // 4	d1	p2
      // 5 a2		p3
      // 6 aa	d2	p4
      // 7 a3	ad	p5
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

  
  assign color = active[delay]
    ? x[0] == delay[0] ? pixel[7:4] : pixel[3:0]
    : backCol;
  
  assign rgb = palette[color];
  
endmodule

`endif