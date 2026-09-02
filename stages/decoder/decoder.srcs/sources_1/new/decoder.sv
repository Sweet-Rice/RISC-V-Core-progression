`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 21.08.2026 21:06:38
// Design Name: 
// Module Name: decoder
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


module decoder #(parameter W = 32, D=64, R=32, ALU_ADD = 4'b0000, RESET_VEC = 32'h8000_0000)(

input logic rst,
input logic [31:0] inst,
input clk,

output logic [3:0] alu_ctrl,
output logic [W-1:0] pc_out,
output logic illegal_out, tx
    );
    
    logic r_we;
    logic [$clog2(D)-1:0]rs1_addr, rs2_addr, rd_addr; //THESE ARE ADDRESSES NOT THE BUSES. DERIVED FROM INST
    logic [W-1:0] rd, rs1, rs2; //THESE ARE THE BUSES. ONLY ASSIGNED BY REGMOD. besides rd ofc
    logic [W-1:0] usable_rs1, usable_rs2;
    
    
    assign rs1_addr = inst[19:15];
    assign rs2_addr = inst[24:20];
    assign rd_addr = inst[11:7];
    
    //preassign the addresses. gate logic in the future so that these arent touched by improper ops.
    
    
    reg_module #(.W(32), .D(64), .R(32)) reg_d (.clk(clk), .we(r_we), 
        .wr(rd_addr), .rd1(rs1_addr), .rd2(rs2_addr),
        .d_in(rd), .d_out1(rs1), .d_out2(rs2));
        
        
    assign usable_rs1 = rs1 & {32{|rs1_addr[4:0]}};
    assign usable_rs2 = rs2 & {32{|rs2_addr[4:0]}};    
    alu_decoder  #(32,ALU_ADD)alu_decoder_d (.inst(inst), .alu_ctrl(alu_ctrl));
    
    // wires for imm sig
    logic [2:0] imm_sig;
    //
    
    
    logic [W-1:0] alu_a, alu_b, result;
    
    alu #(.W(W)) alu_d (.a(alu_a), .b(alu_b), .op(alu_ctrl), .result(result));
    //alu_a
    //alu_b
    //result
    logic [W-1:0] imm_out;
    immgen #(.W(32)) immgen_d (.inst(inst),.imm_sig(imm_sig), .imm(imm_out));
    
    logic [W-1:0] pc;
    logic [W-1:0] usable_pc;
    
    
    logic branch_sig, illegal, illegal_seen, l_s, mem_valid;
    
    logic [W-1:0] mem_addr, mem_out, mem_in;
    logic  mem_ready, is_store, mem_misaligned;
    
    logic stall;
    
    assign mem_valid = l_s;
    assign stall = l_s && ~mem_ready;
    
    
    load_store #(.W(W)) ls 
    (.addr(mem_addr), .funct3(inst[14:12]),
    .is_store(is_store), .rst(rst), .mem_valid(mem_valid), .clk(clk),
    .d_out(mem_out), .d_in(mem_in), .mem_ready(mem_ready), .mem_misaligned(mem_misaligned), .tx(tx));
    
    assign pc_out = pc;
    assign illegal_out = illegal_seen;

    always_comb begin
    
        //default to U
        imm_sig = 3'b000;
        
        //load store stuff
        l_s=1'b0;
        is_store = 1'b0;
        mem_addr = '0;
        mem_in = '0;
        
        //the rest i guess
        illegal = 1'b1;
        r_we = 1'b0;
        branch_sig=1'b0;
        alu_a = '0;
        alu_b = '0;
        rd = '0;
        unique case (inst[6:0])
        //While inst[6:2] would be cheaper, I opted for 6:0 to catch bad ops 
            
            7'b0110111: begin //LUI
                
                imm_sig = 3'b000; // U type
                
                rd = imm_out;
                r_we = 1;
                
                illegal = 1'b0;
            end
            7'b0010111: begin // AUIPC
                
                // U type default
                
                alu_a = pc;
                alu_b = imm_out;
                rd =result;
                r_we = 1;
                
                illegal = 1'b0;
            end
            7'b1101111: begin //JAL
                
                imm_sig = 3'b111; // J type
                
                alu_a=pc;
                alu_b = 4;
                rd = result;
                r_we = 1;
                
                illegal = 1'b0;
            end
            7'b1100111: begin // JALR
                
                imm_sig = 3'b100; // I type
                
                alu_a=pc;
                alu_b = 4;
                rd = result;
                r_we  =1;
                
                illegal = 1'b0;
            end
            7'b1100011: begin //branches
                
                imm_sig = 3'b110; // B type
                
                unique case (inst[14:13])
                    2'b00: begin
                        //beq, bne
                        alu_a = usable_rs1;
                        alu_b = usable_rs2;
                        branch_sig = (~|(result))^inst[12];
                        
                        illegal = 1'b0;
                    end
                    2'b10, 2'b11: begin
                        //blt, bge / bltu, bgeu
                        alu_a=usable_rs1;
                        alu_b=usable_rs2;
                        branch_sig = result[0]^inst[12];
                        
                        illegal = 1'b0;
                                        
                    end
                    //defaults to branchsig = 0, meaning no branch. logic in the pc logic zone
                    
                endcase
            
            end
            7'b0000011: begin // LOAD ops
            imm_sig = 3'b100; // I type
            
            l_s = 1'b1;
            is_store = 1'b0;
            
            alu_a=usable_rs1;
            alu_b=imm_out;
            mem_addr = result;
            
            rd = mem_out;
            r_we = mem_ready && !mem_misaligned;
            
            //i am here
            illegal = 1'b0;
            
            end
            7'b0100011: begin //STORE ops.
            
            imm_sig = 3'b101; // S type
             
            l_s = 1'b1;
            is_store = 1'b1;
            alu_a=usable_rs1;
            alu_b=imm_out;
            
            mem_addr = result;
            mem_in = usable_rs2;
            
            illegal = 1'b0;
            end
            7'b0010011: begin // imm-ops.
            
                imm_sig = 3'b100; // I type
            
                alu_a = usable_rs1;
                alu_b = imm_out;
                rd = result;
                r_we = 1;
                /*    
                3'b000, //ADDI
                3'b010, //SLTI 
                3'b011, //SLTIU
                3'b100, //XORI
                3'b110, //ORI
                3'b111, //ANDI
                3'b001, //SLLI
                3'b101  //SRLI
                //purposefully ignoring garbage func7.
                */
                illegal = 1'b0;
            end
            7'b0110011: begin // register ops
            
            //imm_sig needs to be set explicitly to avoid latching. we default to U
             
             
            alu_a = usable_rs1;
            alu_b = usable_rs2;
            rd = result;
            r_we = 1;
            
            illegal = 1'b0;
            end
            7'b0001111: begin //FENCE, FENCE.TSO, PAUSE
            
            //default to U
            
            
            illegal = 1'b0;
            
            end
            7'b1110011: begin //ECALL, EBREAK
            
            
            
            illegal = 1'b0;
            end 
                
                
                
                
                
        endcase
    
    end
    always_ff@(posedge clk) begin
        //pc logic is the first line per unique case where pc doesnt +4. 
         if (rst) illegal_seen <= 1'b0;
        else if (illegal) illegal_seen<=1'b1;
        else illegal_seen <= 1'b0;
         if (rst) begin
        usable_pc <= RESET_VEC;
        
        end
        else if (!stall) begin
            unique case (inst[6:0]) 
                
                7'b1100111: begin
                usable_pc <=(usable_rs1+imm_out)&~32'd1; //this **should** truncate properly
                
                
                
                end
                
                
                7'b1101111:begin
                usable_pc <= usable_pc + imm_out; //again, **should**
                
                end
                
                7'b1100011: begin
                usable_pc <= usable_pc + (imm_out&{32{branch_sig}}) + (32'd4&{32{~branch_sig}});
                
                end
                
                
                default: usable_pc <= usable_pc + 32'd4;
            endcase
    
        end
        
        
       
    end
    
    assign pc = {usable_pc[W-1:2], 2'b00};
endmodule

module alu_decoder #(parameter W =32, ALU_ADD = 4'b0000) (
    input logic [31:0]inst,
    output logic [3:0] alu_ctrl
    );
    logic is_op, is_opimm, is_shift, use_bit30;
   
    assign is_op     = (inst[6:2] == 5'b01100);
    assign is_opimm  = (inst[6:2] == 5'b00100);
    assign is_shift  = (inst[13:12] == 2'b01);
    assign use_bit30 = is_op | (is_opimm & is_shift);
      
    always_comb begin
        //
        alu_ctrl = ALU_ADD;
        //alu_ctrl[3]=inst[30];
        //op or opimm opcodes
        if (is_op | is_opimm) begin
        alu_ctrl={inst[30] & use_bit30, inst[14:12]};
        end
        //mul goes into its own dedicated unit that isnt the ALU
        
        //branch ops. If beq or bne, hardcode to xor. if any other, shift right to get slt or sltu
        //leaving this for the writeback mux, but bne gets inverted, and alu_ctrl = 1 means to invert its pair.
        else if (inst[6:2] ==5'b11000) begin
            alu_ctrl[3]=inst[30];
            alu_ctrl[2]= ~(|inst[14:13]);
            alu_ctrl[1:0] = inst[14:13];
        end 
        
        
    end


endmodule    


