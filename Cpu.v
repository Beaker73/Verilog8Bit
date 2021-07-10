`ifndef CPU_V
`define CPU_V


`include "CpuAlu.z"

parameter OP_DI        = 8'b11100100;
parameter OP_JUMP      = 8'b11101000;
parameter OP_JUMP_ADDR = 8'b11101001;


module Cpu(clk, reset, address, dataIn, dataOut);

  input clk, reset;
  output [15:0] address;
  input [7:0] dataIn;
  output [7:0] dataOut;
  
  assign address = 16'd0;
  assign dataOut = 8'd0;
  
  reg [15:0] sp = 16'h0000;
  reg [15:0] pc = 16'h0000;
  reg [3:0] flags = 4'b0000;
  reg interrupt = 0;
  
  wire [3:0] aluFlagsOut;
  wire [7:0] aluResult;
  CpuAlu alu(
    .operation(ALUOP_ADD), 
    .flagsIn(flags), .leftOperand(0), .rightOperand(0), 
    .resultOut(aluResult), .flagsOut(aluFlagsOut)
  );

  reg [7:0] data[4];
  reg [1:0] dix = 0;
  reg isRequested = 0;
  
  always @(posedge clk) begin
    
    if(reset)
    begin
      sp <= 16'h0000;
      pc <= 16'h0000;
      flags <= 4'b0000;
      interrupt <= 0;
    end
    else
    begin
        
      address <= pc;
      isRequested <= 1;
      pc <= pc + 1;
      if(isRequested) begin
        data[dix] <= dataIn;
        dix <= dix + 1;
      end
      
      if(dix> 0) begin
        case(data[0])
          
          OP_DI: begin
            interrupt <= 0;
            dix <= 0;
          end
          
          OP_JUMP_ADDR: begin
            if(dix == 3) begin
              pc <= { data[1], data[2] };
              dix <= 0;
            end
          end
          
          default: begin
            // unknown so ignore invalid opcode (like a nop)
            dix <= 0;
          end
          
        endcase
      end

    end
    
  end
  
  
endmodule

module Cpu_top(clk, reset, address, data);
  
  input clk;
  input reset;
  output [15:0] address;
  output [7:0] data;
  
  wire [7:0] dataIn = 0;
  
  Cpu cpu(
    .clk(clk), .reset(reset),
    .address(address), .dataIn(dataIn), .dataOut(data)
  );
  
endmodule;


`endif
