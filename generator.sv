class Generator;
  mailbox #(Transaction) mbx;

  function new(mailbox#(Transaction) mbx);
    this.mbx = mbx;
  endfunction

  task run(int count);
    Transaction tr;
    repeat (count) begin
      tr = new();
      if (tr.randomize()) begin
        mbx.put(tr);
        tr.display("GEN");
      end else begin
        $fatal(1, "GEN Randomization failed");
      end
    end

  endtask

  task run_full_test();
    Transaction tr;

    // Stage 1: Fill FIFO
    for (int i = 0; i < 16; i++) begin
      tr     = new();
      tr.wr  = 1;
      tr.r   = 0;
      tr.din = i;
      mbx.put(tr);
    end

    //Stage 2: Write 1 more
    tr     = new();
    tr.wr  = 1;
    tr.r   = 0;
    tr.din = 8'hFF;
    mbx.put(tr);

    // Stage 3: 16 READ 
    for (int i = 0; i < 16; i++) begin
      tr    = new();
      tr.r  = 1;
      tr.wr = 0;
      mbx.put(tr);
    end
  endtask

  task run_empty_test();
    Transaction tr;

    for (int i = 0; i < 2; i++) begin
      tr    = new();
      tr.r  = 1;
      tr.wr = 0;
      mbx.put(tr);
    end

    //Write
    tr     = new();
    tr.wr  = 1;
    tr.r   = 0;
    tr.din = 8'hFF;
    mbx.put(tr);

    tr    = new();
    tr.r  = 1;
    tr.wr = 0;
    mbx.put(tr);
  endtask

  task run_wrap_test();
    Transaction tr;

    //Write 00 - 0F
    for (int i = 0; i < 16; i++) begin
      tr     = new();
      tr.wr  = 1;
      tr.r   = 0;
      tr.din = i;
      mbx.put(tr);
    end

    for (int i = 0; i < 14; i++) begin
      tr    = new();
      tr.r  = 1;
      tr.wr = 0;
      mbx.put(tr);
    end

    for (int i = 0; i < 2; i++) begin
      tr     = new();
      tr.wr  = 1;
      tr.r   = 0;
      tr.din = 8'hA0 + i;
      mbx.put(tr);
    end

    for (int i = 0; i < 4; i++) begin
      tr    = new();
      tr.r  = 1;
      tr.wr = 0;
      mbx.put(tr);
    end
  endtask

  task run_reset_pre();
    Transaction tr;

    // WRITE 11, 22, 33
    for (int i = 0; i < 3; i++) begin
      tr    = new();
      tr.wr = 1;
      tr.r  = 0;

      case (i)
        0: tr.din = 8'h11;
        1: tr.din = 8'h22;
        2: tr.din = 8'h33;
      endcase

      mbx.put(tr);
    end
  endtask

  task run_reset_post();
    Transaction tr;

    for (int i = 0; i < 3; i++) begin
      tr = new();

      case (i)
        0: begin
          tr.wr = 0;
          tr.r  = 1;
        end
        1: begin
          tr.wr  = 1;
          tr.r   = 0;
          tr.din = 8'hA5;
        end
        2: begin
          tr.wr = 0;
          tr.r  = 1;
        end
      endcase

      mbx.put(tr);
    end
  endtask

  // Cover idle occupancy bins and accepted READ -> WRITE on consecutive cycles.
  task run_closure_test();
    Transaction tr;

    for (int i = 0; i < 16; i++) begin
      tr = new();
      tr.wr = 1;
      tr.r = 0;
      tr.din = i;
      mbx.put(tr);

      if (i == 0 || i == 1 || i == 14 || i == 15) begin
        tr = new();
        tr.wr = 0;
        tr.r = 0;
        tr.din = 0;
        mbx.put(tr);
      end
    end

    for (int i = 0; i < 16; i++) begin
      tr = new();
      tr.wr = 0;
      tr.r = 1;
      tr.din = 0;
      mbx.put(tr);
    end

    tr = new();
    tr.wr = 1;
    tr.r = 0;
    tr.din = 8'hFF;
    mbx.put(tr);

    tr = new();
    tr.wr = 0;
    tr.r = 1;
    tr.din = 0;
    mbx.put(tr);
  endtask

endclass

