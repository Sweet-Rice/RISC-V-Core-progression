`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 17.08.2026 00:56:57
// Design Name: 
// Module Name: immgen_tb
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




module immgen_tb;
  
  int checks; int errors;
  logic [31:0] imm, inst;
  int fixed_array[10];
  
  
  // instantiate DUT with named ports
  immgen #(32) dut (.inst(inst), .imm(imm));
  
  
  
  
  task automatic op_check (
  input logic [25:0]tin,
  input logic [6:0]topcode);
  
  logic[31:0] tinst, i_exp, s_exp, b_exp, u_exp, j_exp;
  
  tinst = {tin, topcode};
  
  i_exp = {{21{tinst[31]}},tinst[30:25],tinst[24:21],tinst[20]};
  
  s_exp = {{21{tinst[31]}},tinst[30:25],tinst[11:8],tinst[7]};
  
  b_exp = {{20{tinst[31]}},tinst[7], tinst[30:25],tinst[11:8],1'b0};
  
  u_exp = {tinst[31],tinst[30:20],tinst[19:12],{12{1'b0}}};
  
  j_exp = {{12{tinst[31]}},tinst[19:12],tinst[20], tinst[30:25], tinst[24:21],1'b0};
  
  
  
  
  fixed_array = '{
  7'b0110111,
  7'b0010111,
  7'b1101111,
  7'b1100111,
  7'b1100011,
  7'b0000011,
  7'b0100011,
  7'b0010011,
  7'b0001111,
  7'b1110011
  };
  
  // I S B U J
  
  //I first i guess?
  inst = tinst;
  
  #1;
  if (topcode inside {
  7'b1100111,
  7'b0000011,
  7'b0010011, 
  7'b0001111,
  7'b1110011
  }
  ) begin
  if (imm != i_exp) begin
  $display("FAIL: I-type bad  imm. imm=%b, expected=%b", imm, i_exp);
  errors++;
  end
  checks++;
  end
  
  // S
  
  if (topcode == 
  7'b0100011
  )begin
  if (imm != s_exp) begin
  $display("FAIL: S-type bad  imm. imm=%b, expected=%b", imm, s_exp);
  errors++;
  end
  checks++;
  end
  
  //B
  if (topcode == 7'b1100011) begin
  
  if (imm != b_exp) begin
  $display("FAIL: B-type bad  imm. imm=%b, expected=%b", imm, b_exp);
  errors++;
  end
  checks++;
  
  end
  
  //U
  
  if (topcode inside {7'b0110111 , 7'b0010111}) begin
  if (imm != u_exp) begin
  $display("FAIL: U-type bad  imm. imm=%b, expected=%b", imm, u_exp);
  errors++;
  end
  checks++;
  end
  
  //J
  
  if (topcode == 7'b1101111) begin
  if (imm != j_exp) begin
  $display("FAIL: J-type bad  imm. imm=%b, expected=%b", imm, j_exp);
  errors++;
  end
  checks++;
  
  end
  endtask
  
  
  
  
  integer op;
  logic [25:0] r;
  
  
  initial begin
  int fixed_array[10];
  fixed_array = '{
  7'b0110111,
  7'b0010111,
  7'b1101111,
  7'b1100111,
  7'b1100011,
  7'b0000011,
  7'b0100011,
  7'b0010011,
  7'b0001111,
  7'b1110011
  };
  
      for (int i = 0; i < 2000; i++) begin
      r = 26'($urandom());
      op = $urandom_range(0,9);
      op_check(r ,fixed_array[op]);
      end
      
      
      $display("=== %0d checks, %0d errors ===", checks, errors);
        if (errors == 0)
            $display("PASS");
        else
            $display("FAIL");
        $finish;
  end
  //ignoring R on purpose guys dw
  
endmodule
    
    
