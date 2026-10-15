class Driver;
  mailbox #(Transaction) mbx;
  virtual fifo_if vif;
  int count;

  function new(virtual fifo_if vif, mailbox#(Transaction) mbx, int count);
    this.mbx   = mbx;
    this.vif   = vif;
    this.count = count;

  endfunction

  task run();
    Transaction tr;

    repeat (count) begin
      mbx.get(tr);

      @(negedge vif.clk);
      vif.write = tr.wr;
      vif.read  = tr.r;
      vif.din   = tr.din;

      tr.display("DRV");
    end

    @(negedge vif.clk);
    vif.write = 0;
    vif.read  = 0;


  endtask
endclass
