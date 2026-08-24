`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 23.08.2026 23:15:01
// Design Name: 
// Module Name: load_store
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


module load_store #(parameter W = 32, D = 4096)(
input logic [W-1:0] addr,
input logic [2:0] funct3,
input logic is_store, 
input logic rst, mem_valid, clk,
input logic [W-1:0] d_in,
output logic [W-1:0] d_out, 
output logic mem_ready, mem_misaligned
    );
    //if we separate the actions for store and load, we can get single cycle store
    //and double cycle load. load needs to stall, and we design an outstanding state system
    // that should help with maintaining state and may assist in a future pipelining endeavor.

    (* ram_style = "block" *)
    logic [W-1:0] mem [D-1:0];
    localparam AW = $clog2(D);
    
    logic [AW-1:0] word_addr;
    logic [W-1:0] raw;
    assign word_addr = addr[AW+1:2]; //byte addressed
    logic load_pending;
    assign mem_ready = (mem_valid && is_store) || load_pending;

    logic [2:0] funct3_q;
    logic [1:0] offset_q;   
   
   
       always_ff @(posedge clk) begin
       
        if (rst) begin
            load_pending <= 1'b0;
           
        end else begin
            
                if (mem_valid && is_store && ~mem_misaligned) begin
                
                    //access
                    case (funct3)
                        3'b000: begin
                            case (addr[1:0]) //SB
                                2'b00: mem[word_addr][7:0] <= d_in[7:0]; 
                                2'b01: mem[word_addr][15:8] <= d_in[7:0]; 
                                2'b10: mem[word_addr][23:16] <= d_in[7:0]; 
                                2'b11: mem[word_addr][31:24] <= d_in[7:0];
                            endcase 
                        end
                        3'b001: begin
                            case (addr[1:0]) //SH
                                2'b00:mem[word_addr][15:0] <= d_in[15:0];
                                2'b10:mem[word_addr][31:16] <=d_in[15:0];
                                //intentional miss here. we dont want to store a misaligned val
                            endcase 
                        end
                        3'b010: begin //SW
                            if (addr[1:0] == 2'b00)mem[word_addr] <= d_in;
                        end
                    endcase
               
            end
            if (mem_valid && !is_store && !load_pending) begin
                //here lives logic for the load state
                if (!mem_misaligned)raw <= mem[word_addr];
                funct3_q <=funct3;
                offset_q <= addr[1:0];
                load_pending <=1'b1;
            end 
            else if (load_pending) begin
                load_pending <= 1'b0;
            end
        end
       end
       
    always_comb begin
     mem_misaligned = 1'b0;
        
        if (mem_valid) begin
            case (funct3)
                3'b000, 3'b100: mem_misaligned = 1'b0; //SB. LB, LBU
                3'b001, 3'b101: mem_misaligned = addr[0]; //SH, LH, LHU
                3'b010: mem_misaligned = |addr[1:0]; //LW
                
            endcase
        end
    
    end
    always_comb begin
        d_out = '0;
       
        case (funct3_q)
            3'b000:begin // LB
                case (offset_q)
                    2'b00: d_out = {{24{raw[7]}}, raw[7:0]};
                    2'b01: d_out = {{24{raw[15]}}, raw[15:8]};
                    2'b10: d_out = {{24{raw[23]}}, raw[23:16]};
                    2'b11: d_out = {{24{raw[31]}}, raw[31:24]};
                endcase
                
                end
            3'b001: begin // LH
                    case (offset_q)
                        2'b00: d_out = {{16{raw[15]}}, raw[15:0]};
                        2'b10: d_out = {{16{raw[31]}}, raw[31:16]};
                        default: begin
                        d_out = '0; // misaligned
                        
                        end
                    endcase
                end
        
                3'b010: begin // LW
                    d_out = raw;
                end
        
                3'b100: begin // LBU
                    case (offset_q)
                        2'b00: d_out = {24'b0, raw[7:0]};
                        2'b01: d_out = {24'b0, raw[15:8]};
                        2'b10: d_out = {24'b0, raw[23:16]};
                        2'b11: d_out = {24'b0, raw[31:24]};
                    endcase
                    
                end
        
                3'b101: begin // LHU
                    case (offset_q)
                        2'b00: d_out = {16'b0, raw[15:0]};
                        2'b10: d_out = {16'b0, raw[31:16]};
                        default: begin
                        
                        d_out = '0; 
                        end
                    endcase
                end
            endcase           
            end 
        
endmodule
