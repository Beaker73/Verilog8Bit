`ifndef RAM_H
`define RAM_H

module Ram(clk, reset, writeEnabled, address, dataIn, dataOut);
  
  parameter Bits = 16; // default 16 bits, 64Kb

  input clk, reset, writeEnabled;
  input [Bits-1:0] address;
  input [7:0] dataIn;
  output [7:0] dataOut;
  
  // memory storage
  reg [7:0] memory [0:(1 << Bits)-1];
  
  initial begin
    integer i, j, k;
    
    for(i = 0; i < 256; i++) begin
      for(j = 0; j < 256; j++) begin
        memory[{j[7:0],i[7:0]}] = i[7:0];
      end
    end
    
    memory[0] = 8'h00;
    memory[1] = { /* flip h */ 1'b0, /* flip v */ 1'b0, 4'b0000, /* palette id */ 2'b00 }; 
    memory[2] = 8'h00;
    memory[3] = { /* flip h */ 1'b1, /* flip v */ 1'b0, 4'b0000, /* palette id */ 2'b01 }; 
    memory[4] = 8'h00;
    memory[5] = { /* flip h */ 1'b0, /* flip v */ 1'b1, 4'b0000, /* palette id */ 2'b10 }; 
    memory[6] = 8'h00;
    memory[7] = { /* flip h */ 1'b1, /* flip v */ 1'b1, 4'b0000, /* palette id */ 2'b11 }; 

    memory[8192+00] = 8'h0e;
    memory[8192+01] = 8'h80;
    memory[8192+02] = 8'h88;
    memory[8192+03] = 8'h00;

    memory[8192+04] = 8'he6;
    memory[8192+05] = 8'h78;
    memory[8192+06] = 8'h88;
    memory[8192+07] = 8'h80;

    memory[8192+08] = 8'he7;
    memory[8192+09] = 8'h88;
    memory[8192+10] = 8'h88;
    memory[8192+11] = 8'h80;

    memory[8192+12] = 8'h8e;
    memory[8192+13] = 8'h88;
    memory[8192+14] = 8'h88;
    memory[8192+15] = 8'h80;

    memory[8192+16] = 8'h08;
    memory[8192+17] = 8'he8;
    memory[8192+18] = 8'h88;
    memory[8192+19] = 8'h00;

    memory[8192+20] = 8'h00;
    memory[8192+21] = 8'h88;
    memory[8192+22] = 8'h80;
    memory[8192+23] = 8'h00;

    memory[8192+24] = 8'h00;
    memory[8192+25] = 8'h08;
    memory[8192+26] = 8'h00;
    memory[8192+27] = 8'h00;

    memory[8192+28] = 8'h00;
    memory[8192+29] = 8'h00;
    memory[8192+30] = 8'h00;
    memory[8192+31] = 8'h00;
    
    for(i = 0; i < 16; i++) begin
      for(k = 0; k < 4; k++) begin
        memory[(k+1)*64+i*2+0] = i[7:0] + 1;
        memory[(k+1)*64+i*2+1] = { 4'b0, k[1:0], k[1:0] };
      end
      for(j = 0; j < 32; j++) begin
        memory[8192+32+i*32+j] = { i[3:0], i[3:0] };
      end
    end

end
  
  always @(posedge clk) begin
    if( writeEnabled)
      memory[address] <= dataIn;
  end
  
  assign dataOut = memory[address];

endmodule;

`endif