/** @module : RISC_V_Core
 *  @author : Adaptive & Secure Computing Systems (ASCS) Laboratory
 
 *  Copyright (c) 2018 BRISC-V (ASCS/ECE/BU)
 *  Permission is hereby granted, free of charge, to any person obtaining a copy
 *  of this software and associated documentation files (the "Software"), to deal
 *  in the Software without restriction, including without limitation the rights
 *  to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
 *  copies of the Software, and to permit persons to whom the Software is
 *  furnished to do so, subject to the following conditions:
 *  The above copyright notice and this permission notice shall be included in
 *  all copies or substantial portions of the Software.

 *  THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
 *  IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
 *  FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
 *  AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
 *  LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
 *  OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
 *  THE SOFTWARE.
 *
 */

module RISC_V_Core #(parameter CORE = 0, DATA_WIDTH = 32, INDEX_BITS = 6, 
                     OFFSET_BITS = 3, ADDRESS_BITS = 20)(
    clock, 
    reset, 
    start,
    prog_address, 
      
    from_peripheral,
    from_peripheral_data, 
    from_peripheral_valid, 
    to_peripheral,
    to_peripheral_data, 
    to_peripheral_valid,
            
    report 
); 

input  clock, reset, start; 
input  [ADDRESS_BITS - 1:0]  prog_address; 

// For I/O funstions
input  [1:0]   from_peripheral;
input  [31:0]  from_peripheral_data; 
input          from_peripheral_valid;
output [1:0]   to_peripheral;
output [31:0]  to_peripheral_data; 
output         to_peripheral_valid;

input  report; // performance reporting

wire [31:0]  instruction;
wire [ADDRESS_BITS-1: 0] inst_PC;
wire i_valid, i_ready;
wire d_valid, d_ready;

wire [ADDRESS_BITS-1: 0] JAL_target;   
wire [ADDRESS_BITS-1: 0] JALR_target;   
wire [ADDRESS_BITS-1: 0] branch_target; 

wire  write;
wire  [4:0]  write_reg;    
wire  [DATA_WIDTH-1:0] write_data; 

wire [DATA_WIDTH-1:0]  rs1_data; 
wire [DATA_WIDTH-1:0]  rs2_data;
wire [4:0]   rd;  

wire [6:0]  opcode;
wire [6:0]  funct7; 
wire [2:0]  funct3;

wire memRead; 
wire memtoReg;
wire [2:0] ALUOp;
wire branch_op;
wire [1:0] next_PC_sel;
wire [1:0] operand_A_sel; 
wire operand_B_sel; 
wire [1:0] extend_sel; 
wire [DATA_WIDTH-1:0]  extend_imm;
    
wire memWrite;
wire regWrite;

wire branch;
wire [DATA_WIDTH-1:0]   ALU_result; 

wire ALU_branch; 
wire zero; // Have not done anything with this signal

wire [DATA_WIDTH-1:0]    memory_data;
wire [ADDRESS_BITS-1: 0] memory_addr; // To use to check the address coming out the memory stage

reg  [1:0]   to_peripheral;
reg  [31:0]  to_peripheral_data; 
reg          to_peripheral_valid;

wire stall;

wire [4:0] read_reg_a;
wire [4:0] read_reg_b;
wire [1:0] next_PC_sel_f;
wire [1:0] next_PC_sel_1;
wire fetch_stalled;
wire [ADDRESS_BITS-1:0] JALR_target_f;
wire branch_f;
fetch_unit #(CORE, DATA_WIDTH, INDEX_BITS, OFFSET_BITS, ADDRESS_BITS) IF (
        .clock(clock), 
        .reset(reset), 
        .start(start), 
        .stall(stall),
        
        .PC_select(next_PC_sel_f),
        .PC_select_jal(next_PC_sel_1),
        .program_address(prog_address), 
        .JAL_target(JAL_target),
        .JALR_target(JALR_target_f),
        .branch(branch_f), 
        .branch_target(branch_target), 
        
        .instruction(instruction), 
        .inst_PC(inst_PC),
        .valid(i_valid),
        .ready(i_ready),
        .fetch_stalled(fetch_stalled),
        
        .report(report)
);

delay #(ADDRESS_BITS) pipeline_jalr_target (JALR_target, JALR_target_f, clock);
delay #(1) pipeline_branch (branch, branch_f, clock);

wire [31:0] instruction_d;
StallUnit stall_unit (
    .clk(clock),
    .start(start),

    .reg_src_a(instruction[24:20]),
    .reg_src_b(instruction[19:15]),
    .reg_dest(instruction[11:7]),

    .mem_src(ALU_result),
    .mem_dest(ALU_result),

    .opcode(instruction[6:0]), 
    .stall(stall)
);

wire [ADDRESS_BITS-1:0] inst_PC_d;
wire fetch_stalled_d;
delay #(33 + ADDRESS_BITS) pipeline_d (
    .clk(clock),
    .in({instruction, inst_PC, fetch_stalled}),
    .out({instruction_d, inst_PC_d, fetch_stalled_d})
);
      
decode_unit #(CORE, ADDRESS_BITS) ID (
        .clock(clock), 
        .reset(reset),  
        
        .instruction(instruction_d), 
        .PC(inst_PC_d),
        .extend_sel(extend_sel),
        .write(write), 
        .write_reg(write_reg), 
        .write_data(write_data), 
      
        .opcode(opcode), 
        .funct3(funct3), 
        .funct7(funct7),
        .read_reg_a(read_reg_a),
        .read_reg_b(read_reg_b),
        .rs1_data(rs1_data), 
        .rs2_data(rs2_data), 
        .rd(rd), 
 
        .extend_imm(extend_imm),
        .branch_target(branch_target), 
        .JAL_target(JAL_target),
        
        .report(report)
); 

control_unit #(CORE) CU (
        .clock(clock), 
        .reset(reset),
        .stall(fetch_stalled_d),
        
        .opcode(opcode),
        .branch_op(branch_op), 
        .memRead(memRead), 
        .memtoReg(memtoReg), 
        .ALUOp(ALUOp), 
        .memWrite(memWrite), 
        .next_PC_sel(next_PC_sel), 
        .operand_A_sel(operand_A_sel), 
        .operand_B_sel(operand_B_sel),
        .extend_sel(extend_sel),        
        .regWrite(regWrite), 
        
        .report(report)
);

delay #(2) pipeline_pcsel1 (next_PC_sel, next_PC_sel_1, clock);
delay #(2) pipeline_pcsel2 (next_PC_sel_1, next_PC_sel_f, clock);

wire [ADDRESS_BITS-1:0] inst_PC_e;
wire [2:0] funct3_e;
wire [6:0] funct7_e;
wire [DATA_WIDTH-1:0] rs1_data_e;
wire [DATA_WIDTH-1:0] rs2_data_e;
wire [4:0] rd_e;
wire [4:0] regSrc_1_e;
wire [4:0] regSrc_2_e;
wire [DATA_WIDTH-1:0] extend_imm_e;
delay #(25 + ADDRESS_BITS + (3*DATA_WIDTH)) pipeline_e1 (
    .clk(clock),
    .in({inst_PC_d, funct3, funct7, rs1_data, rs2_data, rd, extend_imm, read_reg_a, read_reg_b}),
    .out({inst_PC_e, funct3_e, funct7_e, rs1_data_e, rs2_data_e, rd_e, extend_imm_e, regSrc_1_e, regSrc_2_e})
);

wire branch_op_e;
wire memRead_e;
wire [2:0] ALUOp_e;
wire memWrite_e;
wire [1:0] operand_A_sel_e;
wire operand_B_sel_e;
wire regWrite_e;
delay #(10) pipeline_e2 (
    .clk(clock),
    .in({branch_op, memRead, ALUOp, memWrite, operand_A_sel, operand_B_sel, regWrite}),
    .out({branch_op_e, memRead_e, ALUOp_e, memWrite_e, operand_A_sel_e, operand_B_sel_e, regWrite_e})
);

wire [4:0] rd_m;
wire [DATA_WIDTH-1:0] ALU_result_m;
wire regWrite_m;
execution_unit #(CORE, DATA_WIDTH, ADDRESS_BITS) EU (
        .clock(clock), 
        .reset(reset), 
        
        .ALU_Operation(ALUOp_e), 
        .funct3(funct3_e), 
        .funct7(funct7_e),
        .branch_op(branch_op_e),
        .PC(inst_PC_e), 
        .ALU_ASrc(operand_A_sel_e),
        .ALU_BSrc(operand_B_sel_e),
        .regRead_1(rs1_data_e), 
        .regSrc_1(regSrc_1_e),
        .regRead_2(rs2_data_e), 
        .regSrc_2(regSrc_2_e),

        .regRead_w(write_data),
        .regDest_w(write_reg),
        .regEn_w(write),

        .regRead_m(ALU_result_m),
        .regDest_m(rd_m),
        .regEn_m(regWrite_m),

        .extend(extend_imm_e), 
        .ALU_result(ALU_result), 
        .zero(zero), 
        .branch(branch),
        .JALR_target(JALR_target),
        
        .report(report)
);

wire memRead_m;
wire memWrite_m;
wire [ADDRESS_BITS-1:0] generated_addr;
wire [DATA_WIDTH-1:0] rs2_data_m;
wire [4:0] regSrc_2_m;
delay #((2*DATA_WIDTH) + 13) pipeline_m (
    .clk(clock),
    .in({ALU_result, memRead_e, memWrite_e, rs2_data_e, regWrite_e, rd_e, regSrc_2_e}),
    .out({ALU_result_m, memRead_m, memWrite_m, rs2_data_m, regWrite_m, rd_m, regSrc_2_m})
);

assign generated_addr = ALU_result_m; // the case the address is not 32-bit

memory_unit #(CORE, DATA_WIDTH, INDEX_BITS, OFFSET_BITS, ADDRESS_BITS) MU (
        .clock(clock), 
        .reset(reset), 
        
        .load(memRead_m), 
        .store(memWrite_m),
        .address(generated_addr), 
        .rs2_src(regSrc_2_m),
        .rs2_forward(write_data),
        .reg_dest_w(write_reg),
        .reg_en_w(write),
        .store_data(rs2_data_m),
        .data_addr(memory_addr), 
        .load_data(memory_data),
        .valid(d_valid),
        .ready(d_ready),
        
        .report(report)
); 

wire regWrite_w;
wire memRead_w;
wire [4:0] rd_w;
wire [DATA_WIDTH-1:0] ALU_result_w;
wire [DATA_WIDTH-1:0] memory_data_w;
delay #((2*DATA_WIDTH) + 7) pipeline_w (
    .clk(clock),
    .in({regWrite_m, memRead_m, rd_m, ALU_result_m, memory_data}),
    .out({regWrite_w, memRead_w, rd_w, ALU_result_w, memory_data_w})
);

writeback_unit #(CORE, DATA_WIDTH) WB (
        .clock(clock), 
        .reset(reset),   
        
        .opWrite(regWrite_w),
        .opSel(memRead_w), 
        .opReg(rd_w), 
        .ALU_Result(ALU_result_w), 
        .memory_data(memory_data_w), 
        .write(write), 
        .write_reg(write_reg), 
        .write_data(write_data), 
        
        .report(report)
); 

//Registers s1-s11 [$9,$x18-$x27] are saved across calls ... Using s1-s9 [$9,x18-x25] for final results
always @ (posedge clock) begin        
         if (write && (((write_reg >= 18) && (write_reg <= 25))|| (write_reg == 9)))  begin
              to_peripheral       <= 0;
              to_peripheral_data  <= write_data; 
              to_peripheral_valid <= 1;
              $display (" Core [%d] Register [%d] Value = %d", CORE, write_reg, write_data);
        end
         else to_peripheral_valid <= 0;  
end
    
endmodule
