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
  reg [7:0] palette[4][16];
  always @(posedge reset) begin
    // pico 8
    palette[0][00] <= 8'b000_000_00; // 000000
    palette[0][01] <= 8'b001_001_01; // 1D2B53
    palette[0][02] <= 8'b011_001_01; // 7E2553
    palette[0][03] <= 8'b000_100_01; // 008751
    palette[0][04] <= 8'b101_010_00; // AB5236
    palette[0][05] <= 8'b011_011_01; // 5F574F
    palette[0][06] <= 8'b110_110_11; // C2C3C7
    palette[0][07] <= 8'b111_111_11; // FFF1E8
    palette[0][08] <= 8'b111_000_01; // FF004D
    palette[0][09] <= 8'b111_101_00; // FFA300
    palette[0][10] <= 8'b111_111_00; // FFEC27
    palette[0][11] <= 8'b000_111_01; // 00E436
    palette[0][12] <= 8'b001_101_11; // 29ADFF
    palette[0][13] <= 8'b100_011_10; // 83769C
    palette[0][14] <= 8'b111_011_10; // FF77A8
    palette[0][15] <= 8'b111_110_10; // FFCCAA
  end
  
  // vdp registers
  reg [7:0] regs[8];
  
  always @(posedge reset) begin
    regs[0] <= {4'h1, 4'h4}; // 7-4: border colour 3-0: screen mode
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
  wire [8:0]x6 = xPos-6;
  
  // delayed active signal based on screen mode
  wire [2:0]delay =
  	scrMode == 0 ? 0
     :	scrMode == 1 ? 2
     :  scrMode == 2 ? 7
     :	scrMode == 3 ? 2
     :  scrMode == 4 ? 6
     :  0;
  
  SyncGenerator sync(
    .clk(clk), .reset(reset),
    .hShift(4'd10 - delay), .vShift(4'd8),
    .hSync(hSync), .vSync(vSync),
    .xPos(xPos), .yPos(yPos), .isActive(isActive)
  );
  
  wire [3:0] color = backCol;
  reg [7:0] pixel, trgb;
  reg [1:0] pal = 2'd0; // the active palette index
  
  always @(posedge clk) begin
    
    // screen mode 0, is a virtual screenmode where everything is off
    if(scrMode == 0) begin
      pixel <= { backCol, backCol };
      pal <= 0;
    end
    
    // screen mode 1, is a direct pixel map from memory onto screen
    // every byte contains 2 pixels
    // pixel map @ 0000-5fff (256/2*192) = 24576 bytes
    else if(scrMode == 1)
    begin
      if(active[0] && x[0] == 1)
        address <= { 1'b0, y[7:0], x[7:1]};
      if(active[1])
      begin
        pixel <= ramDataRead;
        pal <= 0;
      end
    end
    
    // screen mode 2, is a charachter map of 32x24 characters
    // char map @ 0000-05ff ((char, attr) x 32 x 24 bytes) 1536 bytes
    // palt map @ 0600-063f (4 x 16 x rrrgggbb) = 64 bytes
    // pixl map @ 2000-3fff (4 x 8 x 256 bytes) 8192 bytes
    else if(scrMode == 2)
    begin
      reg [7:0] charBuf, char, attrBuf, attr;
      
      /** screen 2 pipeline
      
      scr pixel                   | 0 1 2 3 4 5 6 7 | 0 1 2 3 4 5 6 7 |
      	                          |                 |                 |
      set addr        c   a     0 |   2 c 4 a 6   0 |   2 c 4 a 6   0 |
      read data         c   a     | 0   2 c 4 a 6   | 0   2 c 4 a 6   |
      copy buff               x   |               x |               x |
                                  |                 |                 |
      sync clock      0 1 2 3 4 5 | 6 7 0 1 2 3 4 5 | 6 7
      
      **/
      
      // get char (address even, data odd)
      if(active[0] && x[2:0] == 0)
        address <= { 5'b00000, y[7:3], x[7:3], 1'b0};
      if(active[1] && x[2:0] == 1)
        charBuf <= ramDataRead;
      
      // get attributes every char (address even, data odd)
      if(active[2] && x[2:0] == 2) begin
        address <= { 5'b00000, y[7:3], x[7:3], 1'b1};
      end
      if(active[3] && x[2:0] == 3)
        attrBuf <= ramDataRead;
      
      // activate buffered data
      if(active[4] && x[2:0] == 4)
      begin
        char <= charBuf;
        attr <= attrBuf;
      end
      
      // get pixel every nibble (address odd, data even)
      if(active[5] && x[0] == 1) begin
        // the address of the pixel to retrieve depends on the flip bits
        address <= { 3'b001, char, 
                    attr[6] ? ~y[2:0] : y[2:0], 
                    attr[7] ? ~x6[2:1] : x6[2:1] };
      end
      if(active[6] && x[0] == 0)
      begin
        // the byte contains 2 nibbles, if h flip is set, those must be swapped
        pixel <= attr[7] ? { ramDataRead[3:0], ramDataRead[7:4] } : ramDataRead;
        pal <= attr[1:0];
      end
    end
    
    // screen mode 3, is a direct pixel map from memory onto screen
    // every byte contains 1 rgb pixels (rrrgggbb)
    // pixel map @ 0000-bfff (256x192) = 49152 bytes
    else if( scrMode == 3 ) begin
      if(active[0])
        address <= { y[7:0], x[7:0]};
      if(active[1])
        trgb <= ramDataRead;
    end
    
    // screen mode 4, is a text only screen where chars are 6x8
    // allowing for 40x24 instead of 32x24
    // char map @ 0000-07df ((char, colour) x 42 x 24 bytes) 2016 bytes
    // pixl map @ 2000-3fff (1 x 8 x 256 bytes) 2048 bytes
    else if(scrMode == 4) begin
      
      reg [7:0] char, clrBuf, clr, pattern;
      reg [2:0] mod;
      reg [5:0] mx;
      reg [4:0] my;
      
      /** screen 4 pipeline
      
      scr pixel                   | 0 1 2 3 4 5 | 0 1 2 3 4 5 |
      	                          |             |             |
      set addr        c   a   p   | c   a   p   | c   a   p   |
      read data         c   a   p |   c   a   p |   c   a   p |
      copy buff                 x |           x |           x |
                                  |             |             |
      sync clock      0 1 2 3 4 5 | 6 7 0 1 2 3 | 6 7
      
      **/
      
      // initialize
      if(isActive && xPos == 0) begin
        mod <= 0;
        mx <= 0;
        if(yPos == 0)
       	  my <= 0;
      end
      
      // tick
      if(active != 0) begin
        mod <= mod == 5 ? 0 : mod + 1;
        mx <= mod == 5 ? mx + 1 : mx;
        my <= mod == 5 && mx == 41 && yPos[2:0] == 7 ? my + 1 : my;
      end
        
      // get char (address even, data odd)
      if(active[0] && mod == 0)
        address <= { 4'b0000, my, mx, 1'b0}; // 42*2*23+0
      if(active[1] && mod == 1)
        char <= ramDataRead;
      
      // get colors (address even, data odd)
      if(active[2] && mod == 2)
        address <= { 4'b0000, my, mx, 1'b1};
      if(active[3] && mod == 3)
        clrBuf <= ramDataRead;
      
      // activate buffered data and get pattern to output
      if(active[4] && mod == 4)
        address <= { 5'b00100, char, y[2:0] };
      if(active[5] && mod == 5)
      begin
        clr <= clrBuf;
        pattern <= ramDataRead;
      end
      
      // output 1 bit of pattern every tick
      if(active[6])
        if(xPos >= 260) // 252 + 6
          trgb <= palette[0][backCol];
        else
          trgb <= palette[0][ pattern[7-mod] ? clr[3:0] : clr[7:4]];
    end
    
  end
  
  assign color = x[0] == delay[0] ? pixel[7:4] : pixel[3:0];
  assign rgb = { active[delay] ? ( scrMode == 3 || scrMode == 4 ? trgb : palette[pal][color] ) : palette[0][backCol] };
  
endmodule

`endif