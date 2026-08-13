`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 12.08.2026 23:11:00
// Design Name: 
// Module Name: alu_tb
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


module alu_tb;

    localparam int W = 32;
    localparam int RANDOM_VECTORS = 2000;
    
    logic [W-1:0] a, b, result;
    logic [3:0] op;
    
    int errors = 0;
    int checks = 0;
    
    alu #(W) dut (a, b, op, result);
    
    
    //source of truth
    function automatic logic [W-1:0] model (
        input logic [W-1:0] ta, tb,
        input logic [3:0] top
        ); 
        logic [$clog2(W)-1:0] sh;
        sh = tb[$clog2(W)-1:0];
            case (top)
                4'b0000: return ta + tb;                                    // add
                4'b1000: return ta - tb;                                    // sub
                4'b0001: return ta << sh;                                   // sll
                4'b0010: return {{W-1{1'b0}}, $signed(ta) < $signed(tb)};   // slt
                4'b0011: return {{W-1{1'b0}}, ta < tb};                     // sltu
                4'b0100: return ta ^ tb;                                    // xor
                4'b0101: return ta >> sh;                                   // srl
                4'b1101: return ($signed(ta) >>> sh);                       // sra
                4'b0110: return ta | tb;                                    // or
                4'b0111: return ta & tb;                                    // and
                default: return '1;
            endcase
        
        endfunction
    //strings
     function automatic string opname(input logic [3:0] top);
        case (top)
            4'b0000: return "add ";
            4'b1000: return "sub ";
            4'b0001: return "sll ";
            4'b0010: return "slt ";
            4'b0011: return "sltu";
            4'b0100: return "xor ";
            4'b0101: return "srl ";
            4'b1101: return "sra ";
            4'b0110: return "or  ";
            4'b0111: return "and ";
            default: return "----";
        endcase
    endfunction
    //surgical
    task automatic check(
        input logic [W-1:0] ta, tb,
        input logic [3:0]   top,
        input string        label
        );
        logic [W-1:0] expected;
        a = ta; b = tb; op = top;
        #1;
        expected = model(ta, tb, top);
        checks++;
        if (result !== expected) begin
            errors++;
            $display("FAIL  %s  op=%b  a=%h  b=%h   got=%h  exp=%h   [%s]",
                     opname(top), top, ta, tb, result, expected, label);
        end
    endtask
    //broad
    task automatic sweep(input logic [W-1:0] ta, tb, input string label);
        check(ta, tb, 4'b0000, label);
        check(ta, tb, 4'b1000, label);
        check(ta, tb, 4'b0001, label);
        check(ta, tb, 4'b0010, label);
        check(ta, tb, 4'b0011, label);
        check(ta, tb, 4'b0100, label);
        check(ta, tb, 4'b0101, label);
        check(ta, tb, 4'b1101, label);
        check(ta, tb, 4'b0110, label);
        check(ta, tb, 4'b0111, label);
    endtask
    
    logic [W-1:0] ra, rb;
    logic [3:0]   rop;
    //go
    initial begin
        $display("ALU testbench, W=%0d", W);
 
        // praying nothing breaks for trivial intended cases
        sweep('0, '0, "zeroes/zeroes");
        sweep('1, '0, "ones/zeroes");
        sweep('0, '1, "zeroes/ones");
        sweep('1, '1, "ones/ones");
 
        // praying nothing breaks along shifts
        
        check({{W-1{1'b0}}, 1'b1}, '0, 4'b0001, "sll by 0");
        check({{W-1{1'b0}}, 1'b1}, W-1, 4'b0001, "sll by W-1");
        check({1'b1, {W-1{1'b0}}}, '0, 4'b0101, "srl by 0");
        check({1'b1, {W-1{1'b0}}}, W-1, 4'b0101, "srl by W-1");
        check({1'b1, {W-1{1'b0}}}, W-1, 4'b1101, "sra by W-1, negative");
        // really redundant test, but supposed to catch if shifter tries anything higher than b bits
        check('1, {{W-$clog2(W){1'b1}}, {$clog2(W){1'b0}}}, 4'b0001, "sll, high b bits ignored");
        check('1, {{W-$clog2(W){1'b1}}, {$clog2(W){1'b0}}}, 4'b0101, "srl, high b bits ignored");
 
        // make sure sra is actually arithmetic
        check({1'b0, {W-1{1'b1}}}, 4, 4'b1101, "sra positive, must zero fill");
        check({1'b1, {W-1{1'b0}}}, 4, 4'b1101, "sra negative, must one fill");
        check('1, 4, 4'b1101, "sra all-ones stays all ones");
 
        // pray that slt and sltu are not the same
        check('1, {{W-1{1'b0}}, 1'b1}, 4'b0010, "slt  -1 < 1  true");
        check('1, {{W-1{1'b0}}, 1'b1}, 4'b0011, "sltu max < 1 false");
 
        // pray slt still works when overflow flips the signage. making sure slt catches wrapping
        check({1'b1, {W-1{1'b0}}}, {{W-1{1'b0}}, 1'b1}, 4'b0010, "slt  min < 1, overflow");
        check({{W-1{1'b0}}, 1'b1}, {1'b1, {W-1{1'b0}}}, 4'b0010, "slt  1 < min, overflow");
        check({1'b0, {W-1{1'b1}}}, {1'b1, {W-1{1'b0}}}, 4'b0010, "slt  max < min");
        check({1'b1, {W-1{1'b0}}}, {1'b0, {W-1{1'b1}}}, 4'b0010, "slt  min < max");
 
        // make sure equal = zero
        sweep({1'b1, {W-1{1'b0}}}, {1'b1, {W-1{1'b0}}}, "min/min");
        sweep({1'b0, {W-1{1'b1}}}, {1'b0, {W-1{1'b1}}}, "max/max");
 
        // make sure this wraps instead of... im not sure how else this would wrap. riscv makes this kinda easy
        check({1'b0, {W-1{1'b1}}}, {{W-1{1'b0}}, 1'b1}, 4'b0000, "add max+1 wraps");
        check({1'b1, {W-1{1'b0}}}, {{W-1{1'b0}}, 1'b1}, 4'b1000, "sub min-1 wraps");
        check('0,                  {{W-1{1'b0}}, 1'b1}, 4'b1000, "sub 0-1");
 
        // pray none of this works. fake ops RIGHT NOW. but actually the alu should never get these 
        check('1, '1, 4'b1001, "undefined 1001");
        check('1, '1, 4'b1010, "undefined 1010");
        check('1, '1, 4'b1011, "undefined 1011");
        check('1, '1, 4'b1100, "undefined 1100");
        check('1, '1, 4'b1110, "undefined 1110");
        check('1, '1, 4'b1111, "undefined 1111");
 
        $display("surgical done: %0d checks, %0d errors", checks, errors);
 
        // WOWOWOWOW spoofing time
        for (int i = 0; i < RANDOM_VECTORS; i++) begin
            ra = {$urandom, $urandom};
            rb = {$urandom, $urandom};
 
            // a third of these should go really teensy
            if (i % 3 == 0) begin
                ra = ra & 32'h0000_001F;
                rb = rb & 32'h0000_001F;
            end else if (i % 7 == 0) begin
            //a seventh of these should explode
                ra = (i % 2) ? '1 : {1'b1, {W-1{1'b0}}};
            end
 
            sweep(ra, rb, "random");
 
            // hit some stupid stuff occasionally
            rop = $urandom_range(0, 15);
            check(ra, rb, rop, "random op");
        end
 
        // -------- summary
        $display("=== %0d checks, %0d errors ===", checks, errors);
        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    end
 
endmodule
    
    
