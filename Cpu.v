`ifndef CPU_V
`define CPU_V


`include "CpuAlu.z"

parameter OP_NOP       = 8'b11100000;
parameter OP_HALT      = 8'b11100001;
parameter OP_BREAK     = 8'b11100010;
parameter OP_DI        = 8'b11100100;
parameter OP_EI        = 8'b11100101;
parameter OP_JUMP      = 8'b11101000;
parameter OP_JUMP_ADDR = 8'b11101001;
parameter OP_CALL      = 8'b11101010;
parameter OP_CALL_ADDR = 8'b11101011;
parameter OP_RET       = 8'b11111000;

parameter IO_NONE = 2'b00;
parameter IO_READ = 2'b10;
parameter IO_WRITE = 2'b01;

module Cpu(
  input clk, reset,
  output read, write, 
  output [15:0] address,
  input [7:0] dataIn, 
  output [7:0] dataOut
);
  
  assign address = 16'd0;
  assign dataOut = 8'd0;
  
  reg [15:0] sp = 16'h0000;
  reg [15:0] pc = 16'h0000;
  reg [3:0] flags = 4'b0000;
  reg interrupt = 0;
  reg [1:0] io = 2'0;
  
  wire [3:0] aluFlagsOut;
  wire [7:0] aluResult;

  always @(posedge clk) begin
    if(reset) begin
      pc <= 0;
      sp <= 0;
      io <= 0;
      interrupt <= 0;
      data[0] <= 64'0;
      data[1] <= 64'0;
      data[2] <= 64'0;
      data[3] <= 64'0;
      data[4] <= 64'0;
      data[5] <= 64'0;
      data[6] <= 64'0;
      data[7] <= 64'0;
    end
  end
 
  CpuAlu alu(
    .operation(ALUOP_ADD), 
    .flagsIn(flags), .leftOperand(0), .rightOperand(0), 
    .resultOut(aluResult), .flagsOut(aluFlagsOut)
  );
  
  // 15:0     16 bits / 2 bytes    address of command
  // 23:16    8  bits / 1 byte     instruction
  
  // 61:58	     		   step: 0000-requested instr, 0001-instruction
  // 62				   MUST read data
  // 63                            is valid

  wire [63:0] data[15];
  wire mustReadInstruction = data[0][62] == 1 && data[0][61:58] == 4'b0000; // must read && requested instruction
  wire canRequestInstruction = 1;
  
  always @(posedge clk) begin
    if(!reset) begin
      
      // STEP 0 - Request Next Instruction
      if(canRequestInstruction) begin
        address <= pc; 			// request instruction
        io <= IO_WRITE;
        data[0][63:58] <= 6'b110000;	// valid: true, must read, content: 00 requested instruction, 
        data[0][15:0] <= pc;		// store sp of instruction in pipeline
        pc <= pc + 1;
      end
      
      // STEP 1 - Must Read Next Instruction
      if(mustReadInstruction) begin
        
        case(dataIn)
          // the 1 byte instructions can now be executed
          'he0: begin // NOP
            data[1] <= 64'0;     // no more steps
          end
          'he1: begin // HALT
            pc <= data[0][15:0]; // get pc of this instruction and set PC to it
            data[0][63] <= 0;    // invalidate already read data, we are branching
            data[1] <= 64'0;     // no more steps
          end
          
          // multi byte instruction, needs more from PC
          'he9: begin
            data[1] <= { data[0][63:62], 4'b0001, 34'd0, dataIn, data[0][15:0] };
          end
            
          // not implemented, handle as NOP
          default: begin
            data[1] <= 63'0;
          end
            
        endcase
      end
      
    end
  end
  
  assign read = io[0];
  assign write = io[1];
  
endmodule



module Cpu_top(clk, reset, address, dataIn, dataOut);
  
  input clk, reset;
  output [15:0] address;
  output  [7:0] dataIn;
  output [7:0] dataOut;

  wire read, write;
  
  TestRom rom(
    .clk(clk), .reset(reset), .chipSelect(address[15:14] == 2'b00),
    .address(address[13:0]),
    .data(dataIn)
  );
  
  Cpu cpu(
    .clk(clk), .reset(reset), .read(read), .write(write),
    .address(address),
    .dataOut(dataOut), .dataIn(dataIn)
  );
  
endmodule;

module TestRom(clk, reset, chipSelect, address, data);

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

        nop
        nop
boot:   halt
        const.2
        nop
        nop
        nop
        jump boot
      
      __endasm
    };
`endif
  end
  
endmodule;

`endif