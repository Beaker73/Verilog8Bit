`ifndef ROM_V
`define ROM_V

`ifdef BANAAN
`include "Beaker8.json";
`endif

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
  initial begin
`ifdef EXT_INLINE_ASM    
    romData = '{
      __asm

.arch   Beaker8
.org    0
.len    0x4000

.define vramWrite $00
.define vramRead $01

.define	vdpReg0 $40
.define vdpReg1 $41
.define vdpReg2 $42
      

boot:   di
        jump Init

init:   call setTextMode
        halt
        
setTextMode:
;       // set vdp0  border 1, mode 4 (Text)      
        send vdpReg0, $14
        const.w $2000         ;// length
	const.w.0             ;// address
        call clrVram
        ret
     
;       // w  length
;       // w  address
clrVram:       
;       // send address to vdp
        send vdpReg1
        send vdpReg2

;       // send 0 to vram
_loop:
        const.0
        send vramWrite
        djr.w.nz _loop
        ret 
      
        little Init ; // using var with little endianess config generates 0400 OK
        big    Init ; // using var with big endianess config generates 0004 OK
        auto   Init ; // using var without endianess config. expect ? generates 0400 LITTLE

        little $0020; // using var with endianess config. expect 2000, generates 2000 OK
        big    $0020; // using var with big config. expect 0020, generates 0020 OK
        auto   $0020; // using var without endianess config. expect ? generates 0020 BIG
      
      __endasm
    };
`endif
  end
  
endmodule;

`endif