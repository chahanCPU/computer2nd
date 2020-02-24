`timescale 1ns / 1ps

import constant::*;

module decode
	(input wire clk,
	input wire rstn,
	input wire [31:0] pc,
	input wire [31:0] inst,
	input wire ew_taken,
	input wire ew_branch,
	input wire start,
	input wire [1:0] rwin,
	input wire [31:0] dtowrite,
	input wire [5:0] rdin,
	output wire [3:0] instr,
	input wire [3:0] de_instr,
	output wire [1:0] op_type,
	input wire [1:0] de_op_type,
	output wire [31:0] s,
	output wire [6:0] rs,
	output wire [31:0] t,
	output wire [6:0] rt,
	output wire [31:0] imm,
	output wire branch,
	output wire jump,
	output wire [1:0] rw,
	output wire is_jr,
	output wire stop,
	output wire [5:0] rd,
	output wire [31:0] npc,
	output wire [4:0] wait_time,
	output wire [31:0] omo
);



	logic [1:0] pred;

	logic [31:0] tmp_s;
	logic [31:0] tmp_t;
	wire [31:0] sw;
	wire [31:0] tw;
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
	logic do_nothing;
	assign do_nothing = op_type == 2'b01 && inst[3:0] == FUNC_NOTHING;

	(* ram_style = "distributed" *) reg [63:0][31:0] gpr = {32'b0, 32'hf4240, 32'h20, {61{32'b0}}};
	(* ram_style = "distributed" *) reg [63:0][31:0] fpr = {64{32'b0}};

	assign omo = gpr[29];

	assign instr = inst[31:28] == OP_SPECIAL ? inst[3:0]
					: inst[31:28] == OP_FPU ? inst[3:0]
					: inst[31:28];

	assign op_type = inst[31:28] == OP_SPECIAL ? 2'b01 
					: inst[31:28] == OP_FPU ? 2'b10
					: 2'b00;
	//31:28 27:22 21:16 15:0
	//31:28 27:22 21:16 15:10 9:4 3:0

	assign tmp_s = (inst[31:28] == OP_JAL) ? pc + 4 : inst[31:28] == OP_FPU 
			? (inst[3:0] == FPU_ITOF ? gpr[inst[27:22]] : fpr[inst[27:22]])
			: (inst[31:28] == OP_BEQ_S || inst[31:28] == OP_BLE_S) ? fpr[inst[27:22]]
			: gpr[inst[27:22]];
	
	assign rs = (inst[31:28] == OP_JAL) ? 7'b0 : inst[31:28] == OP_FPU
		? (inst[3:0] == FPU_ITOF ? {1'b0, inst[27:22]} : {1'b1, inst[27:22]})
		: (inst[31:28] == OP_BEQ_S || inst[31:28] == OP_BLE_S) ? {1'b1, inst[27:22]}
		: {1'b0, inst[27:22]};

	assign tmp_t = inst[31:28] == OP_SW_S ? fpr[inst[21:16]] :
		inst[31:28] == OP_FPU ? fpr[inst[21:16]] : 
		inst[31:28] == OP_LUI && inst[27] ? fpr[inst[21:16]] :
		inst[31:28] == OP_LI && inst[27] ? fpr[inst[21:16]] :
		(inst[31:28] == OP_BEQ_S || inst[31:28] == OP_BLE_S) ? fpr[inst[21:16]] :
		gpr[inst[21:16]];

	assign rt = inst[31:28] == OP_SW_S ? {1'b1, inst[21:16]} :
		inst[31:28] == OP_FPU ? {1'b1, inst[21:16]} : 
		inst[31:28] == OP_LUI && inst[27] ? {1'b1, inst[21:16]} :
		inst[31:28] == OP_LI && inst[27] ? {1'b1, inst[21:16]} :
		(inst[31:28] == OP_BEQ_S || inst[31:28] == OP_BLE_S) ? {1'b1, inst[21:16]} :
		{1'b0, inst[21:16]};

	assign imm = inst[31:28] == OP_J ? {16'b0, inst[15:0]}
				: inst[31:28] == OP_JAL ? {16'b0, inst[15:0]}
				: inst[31:28] == OP_LUI ? {16'b0, inst[15:0]}
				: (inst[31:28] == OP_LI && inst[27]) ? {16'b0, inst[15:0]}
				: inst[31:28] == OP_LA ? {16'b0, inst[15:0]}
				: inst[31:28] == OP_BEQ ? {16'b0, inst[15:0]}
				: inst[31:28] == OP_BLE ? {16'b0, inst[15:0]}
				: inst[31:28] == OP_BEQ_S ? {16'b0, inst[15:0]}
				: inst[31:28] == OP_BLE_S ? {16'b0, inst[15:0]}
				: {{16{inst[15]}}, inst[15:0]};

	assign branch = (inst[31:28] == OP_BEQ || inst[31:28] == OP_BEQ_S ||
				inst[31:28] == OP_BLE || inst[31:28] == OP_BLE_S);

	assign jump = (inst[31:28] == OP_J || inst[31:28] == OP_JAL);


	assign rw = (inst[31:28] == OP_SW || inst[31:28] == OP_SW_S
						|| inst[31:28] == OP_BEQ || inst[31:28] == OP_BEQ_S
						|| inst[31:28] == OP_BLE || inst[31:28] == OP_BLE_S
						|| (inst[31:28] == OP_SPECIAL && inst[3:0] == FUNC_OUT) 
						|| (inst[31:28] == OP_SPECIAL && inst[3:0] == FUNC_OUTINT) 
						|| inst[31:28] == OP_J
						|| is_jr || do_nothing) ? 2'b00
					: (inst[31:28] == OP_FPU && inst[3:0] == FPU_FTOI) ? 2'b01
					: (inst[31:28] == OP_LUI && inst[27]) ? 2'b10
					: (inst[31:28] == OP_LI && inst[27]) ? 2'b10
					: (inst[31:28] == OP_FPU || inst[31:28] == OP_LW_S) ? 2'b10
					: 2'b01;

	assign is_jr  = (inst[31:28] == OP_SPECIAL && inst[3:0] == FUNC_JR);

	assign stop = (inst[31:28] == OP_SPECIAL && inst[3:0] == FUNC_NOOP);


	assign rd = (inst[31:28] == OP_ADDI || 
				inst[31:28] == OP_LUI || inst[31:28] == OP_LI || inst[31:28] == OP_LA ||
				(inst[31:28] == OP_SPECIAL && inst[3:0] == FUNC_MV) ||
				(inst[31:28] == OP_FPU && inst[3:0] == FPU_MV_S) ||
				inst[31:28] == OP_LW || inst[31:28] == OP_LW_S) ? inst[21:16]
				: inst[31:28] == OP_JAL ? 6'b111111
				: (inst[31:28] == OP_SPECIAL && inst[3:0] == FUNC_IN) ? inst[27:22]
				: inst[15:10];
	assign wait_time = 
		  (inst[31:28] == OP_LW || inst[31:28] == OP_LW_S) ? 5'b00011
		: (inst[31:28] == OP_SW || inst[31:28] == OP_SW_S) ? 5'b00001
		: (inst[31:28] == OP_FPU && inst[3:0] == FPU_ADD)  ? 5'b00100
		: (inst[31:28] == OP_FPU && inst[3:0] == FPU_MUL)  ? 5'b00101
		: (inst[31:28] == OP_FPU && inst[3:0] == FPU_SUB)  ? 5'b00100
		: (inst[31:28] == OP_FPU && inst[3:0] == FPU_INV)  ? 5'b11111
		: (inst[31:28] == OP_FPU && inst[3:0] == FPU_SQRT)  ? 5'b11111
		: (inst[31:28] == OP_FPU && inst[3:0] == FPU_NEG) ? 5'b00000
		: (inst[31:28] == OP_FPU && inst[3:0] == FPU_ABS) ? 5'b00000
		: (inst[31:28] == OP_FPU && inst[3:0] == FPU_MV_S) ? 5'b00000
		: (inst[31:28] == OP_FPU) ? 5'b00001
		: (inst[31:28] == OP_BLE_S) ? 5'b00001
		: (inst[31:28] == OP_BEQ_S) ? 5'b00001
		: (inst[31:28] == OP_SPECIAL && inst[3:0] == FUNC_MULT) ? 5'b00101
		: (inst[31:28] == OP_SPECIAL && inst[3:0] == FUNC_DIV) ? 5'b11111
		: 5'b00000;

	assign bpc = ((pc & 32'hf0000000) | (imm << 2));
	assign npc = jump ? bpc
				// : (branch && pred[1]) ? bpc
				: is_jr ? gpr[inst[27:22]]
				: pc + 4;
	
	always @(posedge clk) begin
		if(~rstn) begin
			pred <= 2'b00;
		end
		else begin
			// s <= sw;
			// t <= tw;
			if(start && ew_branch) begin
				if(ew_taken && pred != 2'b11) begin
					pred <= pred + 2'b1;
				end
				else if(!ew_taken && pred != 2'b00) begin
					pred <= pred - 2'b1;
				end
			end

			if(rwin == 2'b01) begin
				gpr[rdin] <= dtowrite;
			end
			else if (rwin == 2'b10) begin
				fpr[rdin] <= dtowrite;
			end
		end
	end
endmodule

