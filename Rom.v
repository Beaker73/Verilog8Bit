`ifndef ROM_H
`define ROM_H

module Rom(clk, reset, chipSelect, address, data);

  input clk, reset, chipSelect;
  input [13:0] address;
  output [7:0] data;
  
  // 16Kb
  reg [7:0] romData[16384];
  
  // when chip selected
  // output the data in the ROM
  // otherwise let if float
  assign data = chipSelect ? romData[address] : 8'bz;

  // inline assembly
  // directly compiled into ROM
`ifdef EXT_INLINE_ASM
  initial begin
    romData = '{
      __asm

.arch	Beaker8
.org	0
.len	16384

Boot:	nop
      	nop
        halt

      __endasm
    };
  end
`endif
  
endmodule;

`endif