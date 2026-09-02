`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 02.09.2026 04:24:08
// Design Name: 
// Module Name: multi-cycle_tb
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////


module datapath_tb;
 
    localparam RESET_VEC = 32'h8000_0000;
 
    logic clk = 0;
    logic rst;
 
    always #5 clk = ~clk;
 
    datapath #(.RESET_VEC(RESET_VEC)) dut (.clk(clk), .rst(rst));
 
    // ---------------------------------------------------------------------
    //   0x80000000  addi x1, x0, 5     x1 = 5
    //   0x80000004  addi x2, x0, 10    x2 = 10
    //   0x80000008  jal  x0, 0         spin
    // ---------------------------------------------------------------------
    initial begin
        for (int i = 0; i < 64; i++)   dut.reg_d.regs[i]        = '0;
        for (int i = 0; i < 4096; i++) dut.if_fetch.mem_d.mem[i] = 32'h00000013;
 
        dut.if_fetch.mem_d.mem[0] = 32'h00500093;  // addi x1, x0, 5
        dut.if_fetch.mem_d.mem[1] = 32'h00A00113;  // addi x2, x0, 10
        dut.if_fetch.mem_d.mem[2] = 32'h0000006F;  // jal  x0, 0
    end
 
    // ---------------------------------------------------------------------
    // Trace
    // ---------------------------------------------------------------------
    string st;
    always_comb begin
        case (dut.current_state)
            3'b000: st = "IF ";
            3'b001: st = "ID ";
            3'b010: st = "EX ";
            3'b011: st = "MEM";
            3'b100: st = "WB ";
            default: st = "???";
        endcase
    end
 
    int cyc = 0;
    always @(posedge clk) begin
        if (!rst) begin
            $display("  cyc %2d  %s  if_pc=%h  id_inst=%h  we=%b  rd_addr=%0d  rd_in=%h",
                     cyc, st, dut.if_pc, dut.id_inst, dut.we,
                     dut.wb_rd_addr, dut.wb_rd_in);
            cyc++;
        end
    end
 
    // ---------------------------------------------------------------------
    // Run
    // ---------------------------------------------------------------------
    int errors = 0;
 
    task check(input string name, input logic [31:0] got, input logic [31:0] exp);
        if (got !== exp) begin
            $display("  FAIL  %s = %h, expected %h", name, got, exp);
            errors++;
        end else begin
            $display("  ok    %s = %h", name, got);
        end
    endtask
 
    initial begin
        rst = 1;
        repeat (3) @(posedge clk);
        @(negedge clk);
        rst = 0;
 
        $display("--- trace ---");
        repeat (30) @(posedge clk);
        @(negedge clk);
 
        $display("--- checks ---");
        check("x1", dut.reg_d.regs[1], 32'd5);
        check("x2", dut.reg_d.regs[2], 32'd10);
 
        if (errors == 0) $display("--- PASS ---");
        else             $display("--- %0d FAILURES ---", errors);
 
        $finish;
    end
 
endmodule

