module fifo (
    input  logic       clk,
    input  logic       rst,
    input  logic       write,
    input  logic       read,
    input  logic [7:0] din,

    output logic [7:0] dout,
    output logic       full,
    output logic       empty
);

    // Internal storage
    logic [7:0] mem [0:15];

    // Pointers and occupancy counter
    logic [3:0] wr_ptr;
    logic [3:0] rd_ptr;
    logic [4:0] count;

    // FIFO status
    assign full  = (count == 5'd16);
    assign empty = (count == 5'd0);

    // Sequential FIFO operation
    always_ff @(posedge clk) begin

        if (rst) begin
            wr_ptr <= 4'd0;
            rd_ptr <= 4'd0;
            count  <= 5'd0;
        end

        else if (write && !full) begin
            mem[wr_ptr] <= din;
            wr_ptr     <= wr_ptr + 1'b1;
            count      <= count + 1'b1;
        end

        else if (read && !empty) begin
            dout   <= mem[rd_ptr];
            rd_ptr <= rd_ptr + 1'b1;
            count  <= count - 1'b1;
        end

    end

endmodule
