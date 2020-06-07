module Rom(clk, reset, chipSelect, address, data);

  // 16Kb
  reg [7:0] rom[0:0];
  
  // when chip selected
  // output the data in the ROM
  // otherwise let if float
  assign data = chipSelect ? rom[address] : 8'bz;

  // inline assembly
  // directly compiled into ROM
`ifdef EXT_INLINE_ASM
  initial begin
    rom = '{
      __asm

.arch	Beaker8
.org	0
.len	1

Boot:	halt

      __endasm
    };
  end
`endif
  
endmodule;