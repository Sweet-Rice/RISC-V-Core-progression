`timescale 1ns / 1ps

// Boots the core through memory_arr's real $readmemh("program.mem", mem)
// path and checks the resulting UART waveform. This testbench deliberately
// does not write the DUT's instruction memory.
module program_mem_tb;

    localparam logic [31:0] RESET_VEC = 32'h8000_0000;
    localparam int CLK_PERIOD_NS = 10;
    localparam int UART_RATE = 100_000_000 / 115200;
    localparam int UART_BIT_NS = UART_RATE * CLK_PERIOD_NS;
    localparam int EXPECTED_LEN = 15;

    logic clk = 1'b0;
    logic rst = 1'b1;
    logic tx;
    logic illegal_out;
    logic [31:0] if_pc;

    string expected = "Hello, world!\r\n";
    logic [7:0] received [0:EXPECTED_LEN-1];
    logic [7:0] rx_byte;
    int rx_count = 0;
    int errors = 0;

    always #(CLK_PERIOD_NS / 2) clk = ~clk;

    datapath #(.RESET_VEC(RESET_VEC)) dut (
        .clk(clk),
        .rst(rst),
        .tx(tx),
        .illegal_out(illegal_out),
        .if_pc(if_pc)
    );

    // Sample each UART data bit in its center. The falling edge is the start
    // bit; the first loop sample occurs 1.5 bit periods later.
    initial begin : uart_receiver
        forever begin
            @(negedge tx);
            #(UART_BIT_NS / 2);

            for (int bit_index = 0; bit_index < 8; bit_index++) begin
                #UART_BIT_NS;
                rx_byte[bit_index] = tx;
            end

            #UART_BIT_NS;
            if (tx !== 1'b1) begin
                $error("UART stop bit was not high");
                errors++;
            end

            if (rx_count < EXPECTED_LEN)
                received[rx_count] = rx_byte;

            $display("UART[%0d] = 0x%02h '%c'", rx_count, rx_byte, rx_byte);
            rx_count++;
        end
    end

    initial begin : test
        // Wait past time zero so memory_arr's initial block has executed.
        #1;
        if (dut.if_fetch.mem_d.mem[0] !== 32'h10000337)
            $fatal(1, "program.mem was not loaded: imem[0] = %h",
                   dut.if_fetch.mem_d.mem[0]);

        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 1'b0;

        fork : completion_or_timeout
            begin
                wait (rx_count == EXPECTED_LEN);
            end
            begin
                #2_000_000;
                $fatal(1, "Timeout: received %0d of %0d UART bytes",
                       rx_count, EXPECTED_LEN);
            end
        join_any
        disable completion_or_timeout;

        for (int index = 0; index < EXPECTED_LEN; index++) begin
            if (received[index] !== expected[index]) begin
                $error("Byte %0d was 0x%02h, expected 0x%02h",
                       index, received[index], expected[index]);
                errors++;
            end
        end

        if (illegal_out !== 1'b0) begin
            $error("Core asserted illegal_out");
            errors++;
        end

        if (errors == 0)
            $display("PASS: program.mem transmitted %0d correct bytes", EXPECTED_LEN);
        else
            $fatal(1, "FAIL: %0d error(s)", errors);

        $finish;
    end

endmodule
