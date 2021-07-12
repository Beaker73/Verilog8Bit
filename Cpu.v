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

parameter STATE_READCMD  = 3'b000;
parameter STATE_READMEM  = 3'b001;
parameter STATE_WRITEMEM = 3'b010;

parameter IO_NONE = 2'b00;
parameter IO_READ = 2'b10;
parameter IO_WRITE = 2'b01;

module Cpu(clk, reset, read, write, address, dataIn, dataOut);

  input clk, reset;
  output read, write;
  output [15:0] address;
  input [7:0] dataIn;
  output [7:0] dataOut;
  
  assign address = 16'd0;
  assign dataOut = 8'd0;
  
  reg [15:0] sp = 16'h0000;
  reg [15:0] pc = 16'h0000;
  reg [15:0] mp = 16'h0000;
  reg [3:0] flags = 4'b0000;
  reg interrupt = 0;
  
  wire [3:0] aluFlagsOut;
  wire [7:0] aluResult;
  CpuAlu alu(
    .operation(ALUOP_ADD), 
    .flagsIn(flags), .leftOperand(0), .rightOperand(0), 
    .resultOut(aluResult), .flagsOut(aluFlagsOut)
  );

  reg [1:0] cix = 0;
  reg [2:0] state;
  reg [7:0] cmd[4];
  reg [31:0] buffer;
  wire [1:0] io = { read, write };
  reg readRequested = 0;
  
  always @(posedge clk) begin
    
    if(reset)
    begin
      sp <= 16'h0000;
      pc <= 16'h0000;
      flags <= 4'b0000;
      interrupt <= 0;
      state <= STATE_READCMD;
      cmd[0] <= OP_NOP;
      buffer <= 32'0;
    end
    else
    begin

      if(readRequested)
      begin
        cmd[cix] <= dataIn;
        readRequested <= 0;
      end
      
      case(state)
        
        STATE_READCMD: begin
          io <= IO_READ;
          address <= pc;
          readRequested <= 1;
          pc <= pc + 1;
        end
        
        STATE_READMEM: begin
          io <= IO_READ;
          address <= mp;
          readRequested <= 1;
          mp <= mp + 1;
        end
        
        STATE_WRITEMEM: begin
          io <= IO_WRITE;
          address <= mp;
          dataOut <= buffer[7:0];
          buffer[23:0] <= buffer[31:8];
          mp <= mp + 1;
        end

        default:;
        
      endcase;
      
      case(cmd[0])
        
        OP_NOP: begin
          state <= STATE_READCMD;
          cix <= 0;
        end
        
        OP_DI: begin
          interrupt <= 0;
          state <= STATE_READCMD;
          cix <= 0;
        end

        OP_EI: begin
          interrupt <= 1;
          state <= STATE_READCMD;
          cix <= 0;
        end
        
        OP_JUMP: begin
          state <= STATE_READMEM;
          mp <= sp; // read from stack
          sp <= sp + 2; // stack data is removed
          cmd[0] <= OP_JUMP_ADDR;
        end
        
        OP_JUMP_ADDR: begin
          if(cix == 3) begin
            pc <= { cmd[1], cmd[2] };
            state <= STATE_READCMD;
            cix <= 0;
          end
        end

        default: begin
          state <= STATE_READCMD;
          cix <= 0;
        end
        
      endcase;
      
    end      
    
  end
 
  assign read = io[0];
  assign write = io[1];
  
endmodule

module Cpu_top(clk, reset);
  
  input clk, reset;
  
  wire read, write;
  wire [15:0] address;
  reg  [7:0] dataIn = 0;
  wire [7:0] dataOut;
  
  Cpu cpu(
    .clk(clk), .reset(reset), .read(read), .write(write),
    .address(address),
    .dataOut(dataOut), .dataIn(dataIn)
  );
  
endmodule;

`endif
