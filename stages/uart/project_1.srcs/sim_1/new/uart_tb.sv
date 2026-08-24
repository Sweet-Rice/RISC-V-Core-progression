`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 24.08.2026 04:15:24
// Design Name: 
// Module Name: uart_tb
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


module uart_tb;

    logic clk = 0;
    logic rst = 1;
    logic [7:0] data_in;
    logic start = 0;
    
    logic busy;
    logic tx;
    
    uart dut (
    .clk(clk), .rst(rst), .data_in(data_in),
    .start(start), .busy(busy), .tx(tx));
    
    always #5 clk = ~clk;
    
    string msg = "Hello World!\n";
    
    initial begin  
        repeat (2) @(posedge clk);
        rst = 0;
        
        for (int i = 0; i< msg.len(); i++) begin
         @(negedge clk);
         while(busy) @(negedge clk);
         
         data_in = msg[i];
         start = 1;
         
         @(negedge clk);
         start = 0;
         
         while (busy) @(negedge clk);
         
         $display("%c", msg[i]);
         
         end
        
         
         $finish;
         end
    
    endmodule