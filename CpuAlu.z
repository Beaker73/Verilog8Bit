`ifndef CPU_ALU_V
`define CPU_ALU_V

`include "CpuAlu.z"

parameter ALUOP_ADD  = 5'b00000;
parameter ALUOP_SUB  = 5'b00001;
parameter ALUOP_MUL  = 5'b00010;
parameter ALUOP_DIV  = 5'b00011;
parameter ALUOP_ADDC = 5'b10000;
parameter ALUOP_SUBC = 5'b10001;
parameter ALUOP_MULC = 5'b10010;
parameter ALUOP_DIVC = 5'b10011;

parameter ALUOP_AND  = 5'b00100;
parameter ALUOP_OR   = 5'b00101;
parameter ALUOP_XOR  = 5'b00110;
parameter ALUOP_NOT  = 5'b00111;

parameter ALUOP_LSL  = 5'b01100;
parameter ALUOP_LSR  = 5'b01101;
parameter ALUOP_ASL  = 5'b01110;
parameter ALUOP_ASR  = 5'b01111;
parameter ALUOP_RL   = 5'b11100;
parameter ALUOP_RR   = 5'b11101;
parameter ALUOP_RLC  = 5'b11110;
parameter ALUOP_RRC  = 5'b11111;

parameter ALUF_ZERO  = 0;
parameter ALUF_CARRY = 1;
parameter ALUF_SIGN  = 2;

module CpuAlu(operation, flagsIn, leftOperand, rightOperand, resultOut, flagsOut);

  input [4:0] operation;
  input [3:0] flagsIn;
  input [7:0] leftOperand;
  input [7:0] rightOperand;
  output [7:0] resultOut;
  output [3:0] flagsOut;

  wire [3:0] flags;
  wire carry;
  wire [8:0] result;
  
  always @(*) begin
    
    flags = flagsIn;
    carry = operation[4] == 1'b1 ? flags[ALUF_CARRY] : 1'b0;
    
    case(operation)
      
      // math
      ALUOP_ADD,
      ALUOP_ADDC: begin
        result = { 8'b0, carry } + { 1'b0, leftOperand } + { 1'b0, rightOperand };
        flags[ALUF_ZERO] = result == 0;
        flags[ALUF_CARRY] = result[8];
        flags[ALUF_SIGN] = result[7];
      end
      
      ALUOP_SUB,
      ALUOP_SUBC: begin
        result = { 1'b0, leftOperand } - { 7'b0, carry } - { 1'b0, rightOperand };
        flags[ALUF_ZERO] = result == 0;
        flags[ALUF_CARRY] = result[8];
        flags[ALUF_SIGN] = result[7];
      end
      
      // logic
      ALUOP_AND: result = { carry, leftOperand & rightOperand };
      ALUOP_OR:  result = { carry, leftOperand | rightOperand };
      ALUOP_XOR: result = { carry, leftOperand ^ rightOperand };
      ALUOP_NOT: result = { carry, ~leftOperand };

      // shifts
      ALUOP_LSL: result = { carry, leftOperand[6:0], 1'b0 };
      ALUOP_LSR: result = { carry, 1'b0, leftOperand[7:1] };
      ALUOP_ASL: result = { carry, leftOperand[6:0], 1'b0 }; 
      ALUOP_ASR: result = { carry, leftOperand[7], leftOperand[7:1] };
      ALUOP_RL:  result = { carry, leftOperand[6:0], leftOperand[7] };
      ALUOP_RR:  result = { carry, leftOperand[0], leftOperand[7:1] };
      ALUOP_RLC: begin
        result = { leftOperand[7:0], carry };
        carry = leftOperand[7];
      end
      ALUOP_RRC: begin
        result = { leftOperand[0], carry, leftOperand[7:1] };
        carry = leftOperand[7];
      end
      
      default:;
      
    endcase;
  end
  
  assign resultOut = result[7:0];
  assign flagsOut = flags;

endmodule

`endif
