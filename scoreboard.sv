class Scoreboard;
  mailbox #(FifoObservation) obs_mbx;

  logic [7:0] expected_q[$];
  int check_count = 0;
  int error_count = 0;
  int reset_nonempty_count = 0;
  int unsigned wr_pos = 0;
  int unsigned rd_pos = 0;
  logic [1:0] prev_op = 2'b00;
  logic prev_rst = 0;

  covergroup fifo_cg with function sample (
      int unsigned occupancy,
      logic [1:0] op,
      logic [7:0] data_in,
      logic rst,
      int reset_kind,
      int wrap_kind,
      int b2b_kind
  );
    option.per_instance = 1;

    cp_operation: coverpoint op iff (!rst) {
      bins idle = {2'b00}; bins read = {2'b01}; bins write = {2'b10};
    }

    cp_occupancy: coverpoint occupancy iff (!rst) {
      bins empty = {0};
      bins one = {1};
      bins middle = {[2 : 14]};
      bins almost_full = {15};
      bins full = {16};
    }

    operation_x_occupancy: cross cp_operation, cp_occupancy;

    cp_write_data: coverpoint data_in iff (!rst && op == 2'b10 && occupancy < 16) {
      bins zero = {8'h00}; bins max = {8'hFF}; bins others = {[8'h01 : 8'hFE]};
    }

    cp_reset: coverpoint reset_kind iff (reset_kind != 0) {
      bins reset_empty = {1}; bins reset_nonempty = {2};
    }

    cp_wrap: coverpoint wrap_kind iff (!rst) {bins write_wrap = {1}; bins read_wrap = {2};}

    cp_b2b: coverpoint b2b_kind iff (!rst) {
      bins ww = {1}; bins rr = {2}; bins wr = {3}; bins rw = {4};
    }
  endgroup


  function new(mailbox#(FifoObservation) obs_mbx);
    this.obs_mbx = obs_mbx;
    fifo_cg      = new();
  endfunction

  task run();
    FifoObservation obs;
    logic [7:0] expected;
    int unsigned occupancy;
    logic [1:0] op;
    bit write_accept, read_accept;
    int reset_kind, wrap_kind, b2b_kind;

    forever begin
      obs_mbx.get(obs);

      op           = {obs.wr, obs.rd};
      occupancy    = expected_q.size();

      write_accept = !obs.rst && op == 2'b10 && occupancy < 16;
      read_accept  = !obs.rst && op == 2'b01 && occupancy > 0;

      reset_kind   = 0;

      if (obs.rst && !prev_rst) begin
        if (occupancy == 0) reset_kind = 1;
        else reset_kind = 2;
      end
      wrap_kind = 0;

      if (write_accept && wr_pos == 15) wrap_kind = 1;
      else if (read_accept && rd_pos == 15) wrap_kind = 2;

      b2b_kind = 0;

      if (!obs.rst) begin
        case ({
          prev_op, op
        })
          4'b1010: b2b_kind = 1;
          4'b0101: b2b_kind = 2;
          4'b1001: b2b_kind = 3;
          4'b0110: b2b_kind = 4;
          default: b2b_kind = 0;
        endcase
      end

      fifo_cg.sample(occupancy, op, obs.din, obs.rst, reset_kind, wrap_kind, b2b_kind);

      check_count++;
      if (obs.full_before !== (expected_q.size() == 16)) begin
        error_count++;
        $error("FULL BEFORE mismatch: expected=%b actual=%b", (expected_q.size() == 16),
               obs.full_before);
      end

      check_count++;
      if (obs.empty_before !== (expected_q.size() == 0)) begin
        error_count++;
        $error("EMPTY BEFORE mismatch: expected=%b actual=%b", (expected_q.size() == 0),
               obs.empty_before);
      end

      if (obs.rst) begin
        if (expected_q.size() > 0) begin
          reset_nonempty_count++;
          $display("[SCB] RESET detected, occupancy before reset = %0d", expected_q.size());
        end
        wr_pos  = 0;
        rd_pos  = 0;
        prev_op = 2'b00;


        expected_q.delete();
      end else begin
        if (write_accept) wr_pos = (wr_pos + 1) % 16;


        if (read_accept) rd_pos = (rd_pos + 1) % 16;

        prev_op = op;

        if (obs.wr == 1 && expected_q.size() < 16) expected_q.push_back(obs.din);
        else if (obs.rd == 1 && expected_q.size() > 0) begin
          expected = expected_q.pop_front();
          check_count++;
          if (expected !== obs.dout) begin
            error_count++;
            $error("FIFO MISMATCH: expected=%h actual=%h", expected, obs.dout);
          end
        end
      end

      check_count++;
      if (obs.full_after !== (expected_q.size() == 16)) begin
        error_count++;
        $error("FULL AFTER mismatch: expected=%b actual=%b", (expected_q.size() == 16),
               obs.full_after);
      end

      check_count++;
      if (obs.empty_after !== (expected_q.size() == 0)) begin
        error_count++;
        $error("EMPTY AFTER mismatch: expected=%b actual=%b", (expected_q.size() == 0),
               obs.empty_after);
      end
      prev_rst = obs.rst;
    end
  endtask

  function void report();
    $display("-----------------------------------");
    $display("SCOREBOARD SUMMARY");
    $display("Total Checks : %0d", check_count);
    $display("Total Errors : %0d", error_count);

    if (check_count == 0) $display("RESULT: NO CHECKS EXECUTED");
    else if (error_count == 0) $display("RESULT: PASS");
    else $display("RESULT: FAIL");

    $display("Functional Coverage: %0.2f%%", fifo_cg.get_inst_coverage());
    $display("[COV] operation=%0.2f%% occupancy=%0.2f%% cross=%0.2f%% data=%0.2f%%",
             fifo_cg.cp_operation.get_inst_coverage(), fifo_cg.cp_occupancy.get_inst_coverage(),
             fifo_cg.operation_x_occupancy.get_inst_coverage(), fifo_cg.cp_write_data.get_inst_coverage());
    $display("[COV] reset=%0.2f%% wrap=%0.2f%% back_to_back=%0.2f%%",
             fifo_cg.cp_reset.get_inst_coverage(), fifo_cg.cp_wrap.get_inst_coverage(),
             fifo_cg.cp_b2b.get_inst_coverage());

    $display("-----------------------------------");
  endfunction


endclass
