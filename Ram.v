`ifndef RAM_H
`define RAM_H

module Ram(clk, reset, address, dataIn, dataOut);
  
  parameter Bits = 16; // default 16 bits, 64Kb

  input clk, reset;
  input [Bits-1:0] address;
  input [7:0] dataIn;
  output [7:0] dataOut;
  
  // memory storage
  reg [7:0] memory [0:(1 << Bits)-1];
  
  
  always @(posedge clk) begin
    if( writeEnabled)
      memory[address] <= dataIn;
  end
  
  assign dataOut = memory[address];

endmodule;

`endif