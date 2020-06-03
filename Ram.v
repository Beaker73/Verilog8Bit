`ifndef RAM_H
`define RAM_H

module Ram(clk, reset, chipSelect, writeEnabled, address, data);
  
  parameter Bits = 16; // default 16 bits, 64Kb

  input clk, reset, chipSelect, writeEnabled;
  input [Bits-1:0] address;
  inout [7:0] data;
  
  // memory storage
  reg [7:0] memory [0:(1 << Bits)-1];
  
  
  always @(posedge clk) begin
    if(writeEnabled)
      memory[address] <= data;
  end
  
  assign data = chipSelect && !writeEnabled ? memory[address] : {8{1'bz}};

endmodule;

`endif