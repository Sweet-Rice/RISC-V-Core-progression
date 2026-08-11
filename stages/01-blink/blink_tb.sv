`timescale 1ns / 1ps

// Self-checking testbench for the LED blinker.
// This file is simulation-only; it does not become hardware.
module blink_tb;

    // Use five cycles in simulation instead of waiting 50,000,000 cycles.
    localparam integer HALF_PERIOD_CYCLES = 5;

    logic clk;
    logic rst_n;
    logic led;

    integer cycle;
    integer errors;
    logic expected_led;

    blink #(
        .HALF_PERIOD_CYCLES(HALF_PERIOD_CYCLES)
    ) dut (
        .clk   (clk),
        .rst_n (rst_n),
        .led   (led)
    );

    // A 10 ns clock period represents the board's 100 MHz clock.
    initial clk = 0;
    always #5 clk = ~clk;

    initial begin
        errors       = 0;
        expected_led = 0;
        rst_n        = 0;

        // Hold reset for two rising clock edges. Sample 1 ps after the edge
        // so the design's registered outputs have finished updating.
        repeat (2) @(posedge clk);
        #1ps;
        if (led !== 0) begin
            $error("LED was not off during reset");
            errors = errors + 1;
        end

        // Reset is active-low, so setting rst_n to 1 starts the blinker.
        @(negedge clk);
        rst_n = 1;

        // Check four LED transitions, one sample per clock cycle.
        for (cycle = 1; cycle <= 4 * HALF_PERIOD_CYCLES; cycle = cycle + 1) begin
            @(posedge clk);
            #1ps;

            if ((cycle % HALF_PERIOD_CYCLES) == 0)
                expected_led = ~expected_led;

            if (led !== expected_led) begin
                $error("Cycle %0d: led=%0b, expected=%0b",
                       cycle, led, expected_led);
                errors = errors + 1;
            end
        end

        // Reassert reset and confirm that it clears the LED.
        @(negedge clk);
        rst_n = 0;
        @(posedge clk);
        #1ps;
        if (led !== 0) begin
            $error("LED did not turn off when reset was reasserted");
            errors = errors + 1;
        end

        if (errors == 0)
            $display("PASS: reset works and the LED toggles every %0d cycles",
                     HALF_PERIOD_CYCLES);
        else
            $display("FAIL: %0d error(s)", errors);

        $finish;
    end

endmodule
