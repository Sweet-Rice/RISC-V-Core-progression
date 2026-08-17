`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.08.2026 01:40:38
// Design Name: 
// Module Name: immgen
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


module immgen #(parameter W = 32)(
input logic [31:0] inst,
output logic [31:0] imm
    );
    
    always_comb begin
        imm[31:11]={21{inst[31]}};
        imm[4:1]=inst[24:21];
        imm[10:5]=inst[30:25];
        
        unique if (inst[5:0]==6'b100011) begin
            //instantiate S and B
            imm[4:1] = inst[11:8];
                
            if (inst[6:4]==3'b110) begin
                //instantiate B
                imm[0]=0;
                imm[11]=inst[7];
            end else
                //instantiate S
                imm[0]=inst[7];
        
        
        
        end else if (inst[4:2]==3'b101) begin
            //instantiate U
            imm[30:12]=inst[30:12];
            imm[11:0]='0;
        
        end else begin
        
            unique if (inst[5:3]==3'b101) begin
                //instantiate J
                imm[0]=0;
                imm[11]=inst[20];
                imm[19:12]=inst[19:12];
                
            end else
                //instantiate I
                imm[0]=inst[20];
        end 

    
    end
    
    
    
    
    
    
endmodule
