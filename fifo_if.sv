interface fifo_if;
   logic clk, rst;
   logic write, read;
   logic [7:0] din, dout;
   logic full, empty;
endinterface    
