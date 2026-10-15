`ifndef TRANSACTION_SV
`define TRANSACTION_SV

class Transaction;
  rand bit wr, r;
  rand byte unsigned din;

  constraint c_rw_mutex {!(wr && r);}

  function void display(string tag = "Transaction");
    $display("[%0t] [%s] wr=%0b, r=%0b, din=8'h%02x (%0d)", $time, tag, wr, r, din, din);
  endfunction
endclass

`endif
