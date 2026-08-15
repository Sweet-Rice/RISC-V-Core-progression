`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 14.08.2026 22:13:14
// Design Name: 
// Module Name: reg_tb
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

/*
module reg_module#(parameter W = 32, D = 64, R = 32)(
input logic clk, we, 
input logic [$clog2(D)-1:0] wr, rd1, rd2, //rd3,
input logic [W-1:0] d_in, output logic [W-1:0] d_out1, d_out2//, d_out3

    );
    */
//////////////////////////////////////////////////////////////////////////////////





module reg_tb;
  logic clk = 0;
  always #5 clk = ~clk;
  int checks; int errors;
  localparam int W = 32;
  localparam int D = 64;
  localparam int R = 32;
  logic we;
  logic [$clog2(D)-1:0] wr, rd1, rd2, rd3;
  logic [W-1:0] d_in, d_out1, d_out2;
  // instantiate DUT with named ports
  
  reg_module #(W, D, R) dut (.clk(clk), .we(we), .wr(wr), .rd1(rd1), .rd2(rd2), .d_in(d_in), .d_out1(d_out1), .d_out2(d_out2));
  
  
  task automatic write_read_nowrite_read(
    input logic [$clog2(D)-1:0] twr,twr2,
    input logic [W-1:0] td_in);
    
    
    
    @(negedge clk);
    
    wr = twr; d_in=td_in; we = 1;
    @(negedge clk);
    rd1 = twr; we=0;
    @(negedge clk);
   
    
    if (d_out1 != td_in) begin
        $display("FAIL: read failed on we=1. wr=%h, d_out1=%h", wr, d_out1);errors++;
    end
    checks++;
    @(negedge clk);
    wr = twr2; we=0; rd1 = twr2;
   @(negedge clk);
    
     if (d_out1 == td_in) begin
        $display("FAIL: write succeeded on we=0. wr=%h, d_out1=%h", wr, d_out1);errors++;
    end
    checks++;
    @(negedge clk);
    
    
    
    
   wr = (twr+5) % D; we = 1;d_in=td_in;
   @(negedge clk);
    rd2=(twr+5) % D;
  @(negedge clk);  
    
    if (d_out2 != td_in) begin
        $display("FAIL: read failed on we=1. wr=%h, d_out2=%h", wr, d_out2);errors++;
    end
    checks++;
   wr = (twr2+5) % D; d_in = 32'hA5A5A5A5; we = 1;
    @(negedge clk);
    @(negedge clk);
    // attempt a suppressed write to the same address
    d_in = td_in; we = 0;
    @(negedge clk);
    @(negedge clk);
    rd2 = (twr2+5) % D;
    @(negedge clk);
    if (d_out2 !== 32'hA5A5A5A5) begin
        $display("FAIL: write succeeded on we=0. wr=%h, d_out2=%h", wr, d_out2);
        errors++;
    end
    checks++;
    @(negedge clk);
     
  
    
    
    
    
    
    
    
    endtask
  
  
  integer i;
logic [$clog2(D)-1:0] a1, a2;
logic [W-1:0] data;
  initial begin
  
  
    
    rd1 = '0;
    rd2 = '0;
    we   = 1;
    d_in = '0;
    for (int j = 0; j < D; j++) begin
        @(negedge clk);
        wr = j[$clog2(D)-1:0];
    end
    @(negedge clk);
    we = 0;
    $display("Register File testbench, W=%0d", W);
    
    @(negedge clk);
    if (d_out1 !== '0) begin
        errors++;
        $display("FAIL: d_out1 bad init. d_out1=%h", d_out1);
        
    end
    
    checks++;
    @(negedge clk);
    if (d_out2 !== '0) begin
        errors++;
        $display("FAIL: d_out2 bad init. d_out2=%h", d_out2);
        
    end
    checks++;
    @(negedge clk);
    


  
  we = 0;
  @(posedge clk);
  
  for (i = 0; i < 200; i++) begin
    a1   = $urandom_range(0, D-1);
    a2   = $urandom_range(0, D-1);
    data = $urandom();
    if (a1 == a2) a2 = (a2 + 1) % D;
    write_read_nowrite_read(a1, a2, data);
  end

   
    
    $display("=== %0d checks, %0d errors ===", checks, errors);
        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
    
  end
endmodule
    
    
