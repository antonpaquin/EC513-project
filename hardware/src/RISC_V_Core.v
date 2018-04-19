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

wire pass_fd;
wire pass_de;
wire pass_em;
wire pass_mw;

fetch_unit #(CORE, DATA_WIDTH, INDEX_BITS, OFFSET_BITS, ADDRESS_BITS) IF (
        .clock(clock), 
        .reset(reset), 
        .start(start), 
        .en(pass_mw),
        
        .PC_select(next_PC_sel),
        .program_address(prog_address), 
        .JAL_target(JAL_target),
        .JALR_target(JALR_target),
        .branch(branch), 
        .branch_target(branch_target), 
        
        .instruction(instruction), 
        .inst_PC(inst_PC),
        .valid(i_valid),
        .ready(i_ready),
        
        .report(report)
);

StallUnit stall (
    .clk(clock),
    .start(start),

    .fd(pass_fd),
    .de(pass_de),
    .em(pass_em),
    .mw(pass_mw)
);

wire [31:0] instruction_d;
wire [ADDRESS_BITS-1:0] inst_PC_d;
delay #(32 + ADDRESS_BITS) pipeline_d (
    .clk(clock),
    .en(pass_fd),
    .in({instruction, inst_PC}),
    .out({instruction_d, inst_PC_d})
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


wire [ADDRESS_BITS-1:0] inst_PC_e;
wire [2:0] funct3_e;
wire [6:0] funct7_e;
wire [DATA_WIDTH-1:0] rs1_data_e;
wire [DATA_WIDTH-1:0] rs2_data_e;
wire [4:0] rd_e;
wire [DATA_WIDTH-1:0] extend_imm_e;
delay #(15 + ADDRESS_BITS + (3*DATA_WIDTH)) pipeline_e1 (
    .clk(clock),
    .en(pass_de),
    .in({inst_PC_d, funct3, funct7, rs1_data, rs2_data, rd, extend_imm}),
    .out({inst_PC_e, funct3_e, funct7_e, rs1_data_e, rs2_data_e, rd_e, extend_imm_e})
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
    .en(pass_de),
    .in({branch_op, memRead, ALUOp, memWrite, operand_A_sel, operand_B_sel, regWrite}),
    .out({branch_op_e, memRead_e, ALUOp_e, memWrite_e, operand_A_sel_e, operand_B_sel_e, regWrite_e})
);

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
        .regRead_2(rs2_data_e), 
        .extend(extend_imm_e), 
        .ALU_result(ALU_result), 
        .zero(zero), 
        .branch(branch),
        .JALR_target(JALR_target),
        
        .report(report)
);

wire [DATA_WIDTH-1:0] ALU_result_m;
wire memRead_m;
wire memWrite_m;
wire [DATA_WIDTH-1:0] rs2_data_m;
wire regWrite_m;
wire [4:0] rd_m;
delay #((2*DATA_WIDTH) + 8) pipeline_m (
    .clk(clock),
    .en(pass_em),
    .in({ALU_result, memRead_e, memWrite_e, rs2_data_e, regWrite_e, rd_e}),
    .out({ALU_result_m, memRead_m, memWrite_m, rs2_data_m, regWrite_m, rd_m})
);

wire [ADDRESS_BITS-1:0] generated_addr = ALU_result_m; // the case the address is not 32-bit

memory_unit #(CORE, DATA_WIDTH, INDEX_BITS, OFFSET_BITS, ADDRESS_BITS) MU (
        .clock(clock), 
        .reset(reset), 
        
        .load(memRead_m), 
        .store(memWrite_m),
        .address(generated_addr), 
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
    .en(pass_mw),
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
