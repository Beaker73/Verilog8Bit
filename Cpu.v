`ifndef CPU_V
`define CPU_V

`include "CpuAlu.v"

typedef enum bit[7:0] {
  
  OP_CONST_B_0   = 8'b00000000,
  OP_CONST_B_1   = 8'b00000001,
  OP_CONST_B_2   = 8'b00000010,
  OP_CONST_B_4   = 8'b00000011,
  OP_CONST_B_8   = 8'b00000100,
  OP_CONST_B_10  = 8'b00000101,
  OP_CONST_B_N   = 8'b00000110,
  OP_CONST_B_255 = 8'b00000111,
  
  OP_NOP       = 8'b11100000,
  OP_HALT      = 8'b11100001,
  OP_BREAK     = 8'b11100010,
  OP_DI        = 8'b11100100,
  OP_EI        = 8'b11100101,
  OP_JUMP      = 8'b11101000,
  OP_JUMP_ADDR = 8'b11101001,
  OP_CALL      = 8'b11101010,
  OP_CALL_ADDR = 8'b11101011,
  OP_RET       = 8'b11111000
} opcode;


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
  
  wire [1:0] cmdLength2;

  
  // step 0 - request instruction - clock tick 0
  wire dataRequested0;
  wire [15:0] address0;
  wire valid0;
  RequestInstruction step0(
    clk, reset, .enable(cmdLength2[1] == 1) /* feedback from decode step */,  pc, // in
    valid0, dataRequested0, address0, pc // out
  );
  
  // step 1 - read instruction - clock tick 1
  wire valid1;
  wire [7:0] cmd1;
  wire [15:0] cmdAddress1;
  ReadInstruction step1(
    clk, reset, .enable(valid0), address0, dataIn, // in
    valid1, cmdAddress1, cmd1 // out
  );
  
  // step 2 - decode the instruction - async
  wire dataOnStack2;
  wire [15:0] cmdAddress2;
  DecodeInstructionAsync step2(
    cmd1, // in
    cmdLength2, dataOnStack2 // out
  );
  
  // step 3 - get data byte 1 - clock tick 2
  wire valid3;
  wire dataRequested3;
  wire [15:0] address3;
  RequestDataByte step3(
    clk, reset, .enable(valid1), cmd1, cmdLength2, dataOnStack2, cmdAddress1,
    valid3, dataRequested3, address3
  );
  
  
  always_comb begin
    
    if(dataRequested3) // data byte 1 - requested
    begin
      io = IO_READ;
      address = address3;
    end
    
    else if(dataRequested0) // command - requested
    begin
      io = IO_READ;
      address = address0;
    end
    
    else
    begin
      io = IO_NONE;
      address = 16'b0;
    end
  
  end
    
  assign read = io[0];
  assign write = io[1];
  
endmodule

module RequestInstruction(
  input clk, reset, enable,
  input [15:0] pcIn,
  
  output valid,
  output dataRequested,
  output [15:0] address,
  output [15:0] pcOut
);

  always @(posedge clk) begin
    if(!reset && enable) begin 
      dataRequested <= 1;
      address <= pcIn;
      pcOut <= pcIn + 1;
      valid <= 1;
    end
    else
      valid <= 0;
  end
  
endmodule;

module ReadInstruction(
  input clk, reset, enable,
  input [15:0] cmdAddressIn,
  input [7:0] dataIn, 
  
  output valid,
  output [15:0] cmdAddressOut, 
  output [7:0] cmdOut
);
  
  always @(posedge clk) begin
    if(!reset && enable) begin
      cmdOut <= dataIn;
      cmdAddressOut <= cmdAddressIn;
      valid <= 1;
    end
    else
      valid <= 0;
  end
  
endmodule;

module DecodeInstructionAsync(
  input [7:0] cmd,

  output [1:0] cmdLength,    // 0: not valid, ignore cmd; 1: 1 byte, 2: 2 bytes, 3: 3 bytes.
  output dataOnStack         // 0: data behind cmd, 1: data on stack
);
  
  always_comb begin
    case(cmd)
      
      OP_CONST_B_0, OP_CONST_B_1, OP_CONST_B_2, OP_CONST_B_4, OP_CONST_B_8, OP_CONST_B_10, OP_CONST_B_255,
      OP_NOP: 
      begin
        cmdLength = 1;   // 1 command byte
        dataOnStack = 0; // data not on stack
      end
      
      OP_CONST_B_N: 
      begin
        cmdLength = 2;   // 1 command byte + 1 data byte
        dataOnStack = 0; // data not on stack
      end
      
      OP_JUMP_ADDR:
      begin
        cmdLength = 3;	 // 1 command byte + 2 data bytes
        dataOnStack = 0; // data not on stack
      end
      
      // any other bytes are invalid
      default: begin
      	cmdLength = 0;   // 0 signal invalid cmd
        dataOnStack = 0;
      end
      
    endcase
  end
  
endmodule;

module RequestDataByte(
  input clk, reset, enable,
  
  input [7:0] cmd, 
  input [1:0] commandLength,
  input dataOnStack,
  input [15:0] commandAddress,
  
  output valid,
  output requested, [15:0] address
);
  
  always @(posedge clk) begin
    if(!reset && enable) begin
      
      // if length > 1 (10 or 11), more data should be retrieved
      if(commandLength[1] == 1) begin
        address <= commandAddress + 1;
        requested <= 1;
      end
      // otherwise no more data needed
      else
        requested <= 0;

      valid <= 1;
    end
    else
      valid <= 0;
  end
  
endmodule;






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