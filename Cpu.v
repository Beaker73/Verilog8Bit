`ifdef CPU_H
`define CPU_H

module Cpu(clk, reset, address, data);

  input clk, reset;
  output [15:0] address;
  inout [7:0] data;

endmodule

`endif