`timescale 1ns / 1ps

import constant::*;

module decode
	(input wire clk,
	input wire rstn,
	input wire [31:0] pc,
	input wire [31:0] inst,
	input wire [1:0] rwin,
	input wire [31:0] dtowrite,
	input wire [4:0] rdin,
	output wire [5:0] instr,
	input wire [5:0] de_instr,
	output wire [1:0] op_type,
	input wire [1:0] de_op_type,
	output wire [31:0] s,
	output wire [5:0] rs,
	output wire [31:0] t,
	output wire [5:0] rt,
	output wire [31:0] imm,
	output wire branch,
	output wire jump,
	output wire [1:0] rw,
	output wire is_jr,
	output wire stop,
	output wire [4:0] rd,
	output wire [31:0] npc,
	output wire [4:0] wait_time,
	output wire hazard
);




	logic [31:0] tmp_s;
	logic [31:0] tmp_t;
	logic [31:0] bpc;
	
	forward _forward(
		.s(tmp_s), 
		.rs(rs), 
		.t(tmp_t), 
		.rt(rt), 
		.d(dtowrite), 
		.rw(rwin), 
		.rd(rdin), 
		.fs(s), 
		.ft(t)
	);

	reg [31:0][31:0] gpr = {32'b0, 32'b0, 32'h30, 32'hf4240, {28{32'b0}}};
	reg [31:0][31:0] fpr = {32{32'b0}};

	assign instr = inst[31:26] == OP_SPECIAL ? inst[5:0]
					: inst[31:26] == OP_FPU ? inst[5:0]
					: inst[31:26];

	assign op_type = inst[31:26] == OP_SPECIAL ? 2'b01 
					: inst[31:26] == OP_FPU ? 2'b10
					: 2'b00;

	assign tmp_s = (inst[31:26] == OP_JAL) ? pc + 4 : inst[31:26] == OP_FPU 
			? (inst[5:0] == FPU_ITOF ? gpr[inst[15:11]] : fpr[inst[15:11]])
			: gpr[inst[25:21]];
	
	assign rs = (inst[31:26] == OP_JAL) ? 6'b0 : inst[31:26] == OP_FPU
		? (inst[5:0] == FPU_ITOF ? {1'b0, inst[15:11]} : {1'b1, inst[15:11]})
		: {1'b0, inst[25:21]};

	assign tmp_t = inst[31:26] == OP_SW_S ? fpr[inst[20:16]] :
		inst[31:26] == OP_FPU ? fpr[inst[20:16]] : gpr[inst[20:16]];

	assign rt = inst[31:26] == OP_SW_S ? {1'b1, inst[20:16]} :
		inst[31:26] == OP_FPU ? {1'b1, inst[20:16]} : {1'b0, inst[20:16]};

	assign imm = inst[31:26] == OP_J ? {6'b0, inst[25:0]}
				: inst[31:26] == OP_JAL ? {6'b0, inst[25:0]}
				: inst[31:26] == OP_LUI ? {16'b0, inst[15:0]}
				: inst[31:26] == OP_BEQ ? {16'b0, inst[15:0]}
				: inst[31:26] == OP_BGTZ ? {16'b0, inst[15:0]}
				: inst[31:26] == OP_BLEZ ? {16'b0, inst[15:0]}
				: inst[31:26] == OP_BNE ? {16'b0, inst[15:0]}
				: {{16{inst[15]}}, inst[15:0]};

	assign branch = (inst[31:26] == OP_BEQ || inst[31:26] == OP_BGTZ ||
				inst[31:26] == OP_BLEZ || inst[31:26] == OP_BNE);

	assign jump = (inst[31:26] == OP_J || inst[31:26] == OP_JAL);


	assign rw = (inst[31:26] == OP_SW || inst[31:26] == OP_SW_S
						|| inst[31:26] == OP_BEQ || inst[31:26] == OP_BGTZ
						|| inst[31:26] == OP_BLEZ || inst[31:26] == OP_BNE
						|| inst[31:26] == OP_OUT || inst[31:26] == OP_J
						|| is_jr) ? 2'b00
					: (inst[31:26] == OP_FPU && (inst[5:0] == FPU_FTOI || inst[5:0] == FPU_EQ
					|| inst[5:0] == FPU_LT || inst[5:0] == FPU_LE)) ? 2'b01
					: (inst[31:26] == OP_FPU || inst[31:26] == OP_LW_S) ? 2'b10
					: 2'b01;

	assign is_jr  = (inst[31:26] == OP_SPECIAL && inst[5:0] == FUNC_JR);

	assign stop = (inst[31:26] == OP_SPECIAL && inst[5:0] == OP_NOOP);


	assign rd = (inst[31:26] == OP_ADDI || inst[31:26] == OP_ANDI || 
				inst[31:26] == OP_LUI || inst[31:26] == OP_LW || inst[31:26] == OP_LW_S
				|| inst[31:26] == OP_SLTI || inst[31:26] == OP_XORI || inst[31:26] == OP_ORI) ?
					inst[20:16]
				: inst[31:26] == OP_JAL ? 5'b11111 
				: inst[31:26] == OP_FPU ? inst[10:6]
				: inst[31:26] == OP_IN ? inst[25:21]
				: inst[15:11];
	assign wait_time = 
		  (inst[31:26] == OP_LW || inst[31:26] == OP_LW_S) ? 5'b00001
		: (inst[31:26] == OP_FPU && inst[5:0] == FPU_ADD)  ? 5'b00101
		: (inst[31:26] == OP_FPU && inst[5:0] == FPU_SUB)  ? 5'b00101
		: (inst[31:26] == OP_FPU && inst[5:0] == FPU_INV)  ? 5'b00101
		: (inst[31:26] == OP_FPU && inst[5:0] == FPU_SQRT)  ? 5'b00101
		: 5'b00000;

	assign bpc = ((pc & 32'hf0000000) | (imm << 2));
	assign npc = is_jr ? s
				: jump ? bpc
				: (inst[31:26] == OP_BEQ && s == t) ? bpc
				: (inst[31:26] == OP_BGTZ && s > 0) ? bpc
				: (inst[31:26] == OP_BLEZ && s <= 0) ? bpc
				: (inst[31:26] == OP_BNE && s != t) ? bpc
				: pc + 4;
	
	assign hazard =
		(is_jr || inst[31:26] == OP_BEQ || inst[31:26] == OP_BGTZ
		|| inst[31:26] == OP_BLEZ || inst[31:26] == OP_BNE) &&
			(de_op_type != 2'b01 || de_instr != 6'b0);
	
	always @(posedge clk) begin
		if(rwin == 2'b01) begin
			gpr[rdin] <= dtowrite;
		end
		else if (rwin == 2'b10) begin
			fpr[rdin] <= dtowrite;
		end
	end
endmodule

