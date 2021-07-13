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
    end
  end
 
  CpuAlu alu(
    .operation(ALUOP_ADD), 
    .flagsIn(flags), .leftOperand(0), .rightOperand(0), 
    .resultOut(aluResult), .flagsOut(aluFlagsOut)
  );
  
  // 15:0  16 bits / 2 bytes    address of command
  // 39:16 24 bits / 3 bytes    command
  // 41:40  2 bits              command length (1, 2 or 3)
  // 57:42 16 bits / 2 bytes    data read address

  wire [63:0] data[15];
  
  always @(posedge clk) begin
    if(!reset) begin
      
      // STAGE 0 - Output address of instruction to fetch
      if(data[1][41:40] < 2 && data[2][41:40] < 3) begin
        data[0][15:0] <= pc;
        address <= pc;
        io <= IO_READ;
        pc <= pc + 1;
      end
      
      // STAGE 1 - Read the instruction
      data[1] <= data[0];
      data[1][23:16] <= dataIn;
      case(dataIn)
        OP_CALL_ADDR: begin 
          data[1][41:40] <= 2'd3;
          data[1][57:42] <= data[0][15:0]+1;
        end
        default: data[1][41:40] <= 2'd1;
      endcase
        
      // STAGE 2 - Read byte 1 for instruction
      data[2] <= data[1];
      if(data[1][41:40] > 1 ) begin
        address <= data[1][57:42];
        io <= IO_READ;
        data[2][57:42] <= data[1][57:42];
      end
      
      // STAGE 3 - Read byte 2 for instruction
      data[3] <= data[2];
      if(data[2][41:40] > 2 ) begin
        data[3][31:24] <= dataIn;
        address <= data[2][57:42];
        io <= IO_READ;
      end
      
      // STAGE 4 - Execute the instruction
      data[4] <= data[3];
      case(data[3][23:16])
        OP_CALL_ADDR: begin
          pc <= data[3][39:24];
        end
        
        default:;
      endcase

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
boot:   nop
        nop
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