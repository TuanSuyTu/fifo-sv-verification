`timescale 1ns / 1ps
module tb_fifo;
  string testname;

  fifo_if vif ();

  fifo dut (
      .clk  (vif.clk),
      .rst  (vif.rst),
      .write(vif.write),
      .read (vif.read),
      .din  (vif.din),
      .dout (vif.dout),
      .full (vif.full),
      .empty(vif.empty)
  );

  initial vif.clk = 0;

  always #5 vif.clk = ~vif.clk;

  mailbox #(Transaction) mbx = new();
  mailbox #(FifoObservation) obs_mbx = new();

  Generator gen;
  Driver drv;
  Monitor mon;
  Scoreboard scb;

  // Reset DUT state while retaining scoreboard counters and coverage bins.
  task reset_fifo();
    @(negedge vif.clk);
    vif.write = 0;
    vif.read = 0;
    vif.rst = 1;
    repeat (2) @(negedge vif.clk);
    vif.rst = 0;
  endtask

  task run_test(input string name);
    int reset_count_before;
    reset_count_before = scb.reset_nonempty_count;
    $display("[TB] Starting scenario: %s", name);
    case (name)

      "FULL": begin
        drv.count = 33;
        fork
          gen.run_full_test();
          drv.run();
        join
      end

      "EMPTY": begin
        drv.count = 4;
        fork
          gen.run_empty_test();
          drv.run();
        join
      end

      "WRAP": begin
        drv.count = 36;
        fork
          gen.run_wrap_test();
          drv.run();
        join
      end

      "RESET": begin
        drv.count = 3;
        fork
          gen.run_reset_pre();
          drv.run();
        join

        reset_fifo();

        drv.count = 3;
        fork
          gen.run_reset_post();
          drv.run();
        join
      end

      "RESET_EMPTY": begin
        reset_fifo();
      end

      "CLOSURE": begin
        drv.count = 38;
        fork
          gen.run_closure_test();
          drv.run();
        join
      end

      "RANDOM": begin
        drv.count = 200;
        fork
          gen.run(200);
          drv.run();
        join
      end

      default: $fatal(1, "Unknown testcase: %s", name);

    endcase

    // Let the last observation reach the scoreboard before checking completion.
    @(posedge vif.clk);
    #1;
    if (name == "RESET" && scb.reset_nonempty_count != reset_count_before + 1)
      $fatal(1, "RESET NONEMPTY TEST FAILED");
    $display("[TB] Completed scenario: %s", name);
  endtask

  initial begin

    vif.rst   = 1;
    vif.write = 0;
    vif.read  = 0;
    vif.din   = 0;

    repeat (2) @(negedge vif.clk);
    vif.rst = 0;

    gen     = new(mbx);
    drv     = new(vif, mbx, 3);
    mon     = new(vif, obs_mbx);
    scb     = new(obs_mbx);

    // Keep observation and checking active while stimulus runs.
    fork
      mon.run();
      scb.run();
    join_none

    if (!$value$plusargs("TEST=%s", testname)) testname = "FULL";

    $display("[TB] Running testcase: %s", testname);

    if (testname == "SUITE") begin
      run_test("FULL");
      reset_fifo();
      run_test("EMPTY");
      reset_fifo();
      run_test("WRAP");
      reset_fifo();
      run_test("RESET");
      reset_fifo();
      run_test("RESET_EMPTY");
      reset_fifo();
      run_test("CLOSURE");
      reset_fifo();
      run_test("RANDOM");
    end else begin
      run_test(testname);
    end

    scb.report();
    if (scb.check_count == 0 || scb.error_count != 0) $fatal(1, "TEST %s FAILED", testname);

    if (testname == "SUITE" && scb.fifo_cg.get_inst_coverage() < 100.0)
      $fatal(1, "SUITE COVERAGE INCOMPLETE: %0.2f%%", scb.fifo_cg.get_inst_coverage());

    $display("[TB] TEST %s PASSED", testname);
    $finish;
  end

  a_reset :
  assert property (@(posedge vif.clk) vif.rst |=> (vif.empty === 1 && vif.full === 0))
  else $error("SVA RESET FAILED");

  a_tb_mutex :
  assert property (@(posedge vif.clk) !(vif.write && vif.read))
  else $error("ERROR: WRITE AND READ TOGETHER");

  a_read_empty :
  assert property (@(posedge vif.clk) (!vif.rst && vif.read && vif.empty) |=> vif.empty == 1)
  else $error("ERROR: SVA READ-EMPTY FAILED");

  c_reset_nonempty :
  cover property (@(posedge vif.clk) vif.rst && !vif.empty)
    $display("[SVA COVER] Reset while FIFO nonempty");

  c_read_empty :
  cover property (@(posedge vif.clk) !vif.rst && vif.read && vif.empty)
    $display("[SVA COVER] READ while EMPTY");

endmodule

