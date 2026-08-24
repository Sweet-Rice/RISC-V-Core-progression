`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// decoder_tb.sv
//
// Acts as instruction memory for the core: watches pc_out, drives inst.
// Exercises arithmetic and the load/store + stall path.
//
// Data memory lives inside the load_store instance, so there is no address
// decode to worry about here -- imem and dmem are separate arrays.
//////////////////////////////////////////////////////////////////////////////////

module decoder_tb;

    localparam W          = 32;
    localparam D          = 64;      // register file depth
    localparam DMEM_WORDS = 4096;    // must match load_store's D
    localparam RESET_VEC  = 32'h8000_0000;
    localparam MEM_WORDS  = 16;

    logic clk = 0;
    logic rst;
    logic [31:0] inst;

    logic [3:0]  alu_ctrl;
    logic [31:0] pc_out;
    logic        illegal_out;

    always #5 clk = ~clk;   // 100 MHz

    decoder #(.W(W), .D(D), .R(32), .RESET_VEC(RESET_VEC)) dut (
        .clk(clk), .rst(rst), .inst(inst),
        .alu_ctrl(alu_ctrl), .pc_out(pc_out), .illegal_out(illegal_out)
    );

    // ---------------------------------------------------------------------
    // Program
    //
    //  0x80000000  addi x1, x0, 256     x1 = 0x100 (data base)
    //  0x80000004  addi x2, x0, 42      x2 = 42
    //  0x80000008  sw   x2, 0(x1)       store word            <- 1 cycle
    //  0x8000000C  lw   x3, 0(x1)       x3 = 42               <- STALLS
    //  0x80000010  addi x4, x0, -1      x4 = 0xFFFFFFFF
    //  0x80000014  sb   x4, 4(x1)       store byte 0xFF       <- 1 cycle
    //  0x80000018  lb   x5, 4(x1)       x5 = -1  (sign ext)   <- STALLS
    //  0x8000001C  lbu  x6, 4(x1)       x6 = 255 (zero ext)   <- STALLS
    //  0x80000020  add  x7, x3, x2      x7 = 84  (uses loaded value)
    //  0x80000024  jal  x0, 0           spin
    // ---------------------------------------------------------------------
    logic [31:0] imem [0:MEM_WORDS-1];

    initial begin
        imem[0]  = 32'h10000093;  // addi x1, x0, 256
        imem[1]  = 32'h02A00113;  // addi x2, x0, 42
        imem[2]  = 32'h0020A023;  // sw   x2, 0(x1)
        imem[3]  = 32'h0000A183;  // lw   x3, 0(x1)
        imem[4]  = 32'hFFF00213;  // addi x4, x0, -1
        imem[5]  = 32'h00408223;  // sb   x4, 4(x1)
        imem[6]  = 32'h00408283;  // lb   x5, 4(x1)
        imem[7]  = 32'h0040C303;  // lbu  x6, 4(x1)
        imem[8]  = 32'h002183B3;  // add  x7, x3, x2
        imem[9]  = 32'h0000006F;  // jal  x0, 0   (spin)
        for (int i = 10; i < MEM_WORDS; i++) imem[i] = 32'h00000013; // nop
    end

    // Clear register file and data memory -- both power up as X in sim.
    initial begin
        for (int i = 0; i < D; i++)          dut.reg_d.regs[i] = '0;
        for (int i = 0; i < DMEM_WORDS; i++) dut.ls.mem[i]     = '0;
    end

    // Combinational fetch off the address the core is presenting.
    logic [31:0] word_index;
    assign word_index = (pc_out - RESET_VEC) >> 2;
    assign inst = (word_index < MEM_WORDS) ? imem[word_index] : 32'h00000013;

    // ---------------------------------------------------------------------
    // Trace -- the stall column is the interesting one
    // ---------------------------------------------------------------------
    string mnemonic;
    always_comb begin
        case (inst)
            32'h10000093: mnemonic = "addi x1, x0, 256";
            32'h02A00113: mnemonic = "addi x2, x0, 42";
            32'h0020A023: mnemonic = "sw   x2, 0(x1)";
            32'h0000A183: mnemonic = "lw   x3, 0(x1)";
            32'hFFF00213: mnemonic = "addi x4, x0, -1";
            32'h00408223: mnemonic = "sb   x4, 4(x1)";
            32'h00408283: mnemonic = "lb   x5, 4(x1)";
            32'h0040C303: mnemonic = "lbu  x6, 4(x1)";
            32'h002183B3: mnemonic = "add  x7, x3, x2";
            32'h0000006F: mnemonic = "jal  x0, 0  (spin)";
            32'h00000013: mnemonic = "nop";
            default:      mnemonic = "???";
        endcase
    end

    int cycle = 0;
    always @(posedge clk) begin
        if (!rst) begin
            $display("  cyc %0d  pc=%h  stall=%b  ready=%b  pend=%b  misal=%b  | %s",
                     cycle, pc_out, dut.stall, dut.mem_ready,
                     dut.ls.load_pending, dut.mem_misaligned, mnemonic);
            cycle++;
        end
    end

    // ---------------------------------------------------------------------
    // Checks
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
        repeat (2) @(posedge clk);
        @(negedge clk);
        rst = 0;

        $display("--- trace ---");
        repeat (18) @(posedge clk);
        @(negedge clk);

        $display("--- checks ---");
        check("x1  (base addr)",  dut.reg_d.regs[1], 32'h0000_0100);
        check("x2  (42)",         dut.reg_d.regs[2], 32'd42);
        check("x3  (lw)",         dut.reg_d.regs[3], 32'd42);
        check("x4  (-1)",         dut.reg_d.regs[4], 32'hFFFF_FFFF);
        check("x5  (lb, signed)", dut.reg_d.regs[5], 32'hFFFF_FFFF);
        check("x6  (lbu, zero)",  dut.reg_d.regs[6], 32'd255);
        check("x7  (x3+x2)",      dut.reg_d.regs[7], 32'd84);
        check("dmem[0x40] (sw)",  dut.ls.mem[32'h40], 32'd42);
        check("dmem[0x41] (sb)",  dut.ls.mem[32'h41], 32'h0000_00FF);
        check("final pc",         pc_out, 32'h8000_0024);
        check("illegal",          {31'b0, illegal_out}, 32'd0);

        if (errors == 0) $display("--- PASS ---");
        else             $display("--- %0d FAILURES ---", errors);

        $finish;
    end

endmodule