`ifndef CPU_V
`define CPU_V

module Cpu(clk, reset, address, dataIn, dataOut);

  input clk, reset;
  output [15:0] address;
  input [7:0] dataIn;
  output [7:0] dataOut;
  
  assign address = 16'd0;
  assign dataOut = 8'd0;

endmodule

`endif
