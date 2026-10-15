class Monitor;
    virtual fifo_if vif;
    mailbox #(FifoObservation) mon2scb;

    function new(virtual fifo_if vif, mailbox #(FifoObservation) mon2scb );
        this.vif = vif;
        this.mon2scb = mon2scb;
    endfunction

   task run();
    FifoObservation obs;

    forever begin
        obs = new();
        @(posedge vif.clk);

        obs.wr = vif.write;
        obs.rd = vif.read;
        obs.rst = vif.rst;
        obs.din = vif.din;
        obs.full_before  = vif.full;
        obs.empty_before = vif.empty;        
        
        @(negedge vif.clk);
        obs.dout = vif.dout;
        obs.full_after = vif.full;
        obs.empty_after = vif.empty;

        mon2scb.put(obs);
         end
endtask


endclass
