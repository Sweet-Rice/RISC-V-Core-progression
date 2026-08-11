`timescale 1ns / 1ps

// Blink the first user LED on an Arty A7-100T.
//
// The board clock produces 100,000,000 rising edges each second.  To make
// one complete blink per second, the LED changes state every 50,000,000
// rising edges: 0.5 seconds on, then 0.5 seconds off.
module blink #(
    parameter integer HALF_PERIOD_CYCLES = 50_000_000
) (
    input  logic clk,
    input  logic rst_n,
    output logic led
);

    // A 26-bit register can count from 0 through 67,108,863, which is
    // enough to reach 49,999,999.
    logic [25:0] counter;

    // Registers update together on each rising edge of the clock.
    always_ff @(posedge clk) begin
        if (!rst_n) begin
            counter <= 0;
            led     <= 0;
        end else if (counter == HALF_PERIOD_CYCLES - 1) begin
            counter <= 0;
            led     <= ~led;
        end else begin
            counter <= counter + 1;
        end
    end

endmodule
