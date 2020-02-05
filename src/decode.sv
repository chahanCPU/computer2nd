`timescale 1ns / 1ps

module decode #( parameter CLK_PER_HALF_BIT = 434, parameter INST_SIZE = 10, parameter BRAM_SIZE = 18)
	(input wire clk,
	input wire rstn,
	input wire [31:0] pc,
	input wire [31:0] inst,
	input wire [1:0] rwin,
	input wire [31:0] dtowrite,
	input wire [4:0] rdin,
	output wire [5:0] instr,
	output wire [1:0] op_type,
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
	output wire [4:0] wait_time
);


	localparam OP_SPECIAL = 6'b000000;
	localparam OP_FPU = 6'b010001;
	localparam OP_LW = 6'b100011;
	localparam OP_SW = 6'b101011;
	localparam OP_ADDI = 6'b001000;
	localparam OP_ANDI = 6'b001100;
	localparam OP_ORI = 6'b001101;
	localparam OP_XORI = 6'b001110;
	localparam OP_SLTI = 6'b001010;
	localparam OP_LUI = 6'b001111;
	localparam OP_BEQ = 6'b000100;
	localparam OP_BGTZ = 6'b000111;
	localparam OP_BLEZ = 6'b000110;
	localparam OP_BNE = 6'b000101;
	localparam OP_J = 6'b000010;
	localparam OP_JAL = 6'b000011;
	localparam OP_NOOP = 6'b111110;
	localparam OP_IN = 6'b111110;
	localparam OP_OUT = 6'b111111;

	localparam OP_LUI_S = 6'b011111;
	localparam OP_LW_S = 6'b110001;
	localparam OP_SW_S = 6'b111001;


	localparam FUNC_ADD = 6'b100000;
	localparam FUNC_SUB = 6'b100010;
	localparam FUNC_MULT = 6'b011000;
	localparam FUNC_DIV = 6'b011010;
	localparam FUNC_AND = 6'b100100;
	localparam FUNC_OR  = 6'b100101;
	localparam FUNC_XOR  = 6'b100110;
	localparam FUNC_SLT  = 6'b101010;
	localparam FUNC_SLL  = 6'b000000; //change!!!!
	localparam FUNC_SLLV = 6'b000100;
	localparam FUNC_SRL  = 6'b000010;
	localparam FUNC_SRLV = 6'b000110;
	localparam FUNC_JR = 6'b001000;

	localparam FPU_ADD = 6'b000000;
	localparam FPU_SUB = 6'b000001;
	localparam FPU_MUL = 6'b000010;
	localparam FPU_INV = 6'b000011;
	localparam FPU_ABS = 6'b000101;
	localparam FPU_NEG = 6'b000111;
	localparam FPU_SQRT = 6'b000100;
	localparam FPU_EQ = 6'b110010;
	localparam FPU_LT = 6'b110100;
	localparam FPU_LE = 6'b110110;
	localparam FPU_FTOI = 6'b001000;
	localparam FPU_ITOF = 6'b001001;

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
	
	always @(posedge clk) begin
		if(rwin == 2'b01) begin
			gpr[rdin] <= dtowrite;
		end
		else if (rwin == 2'b10) begin
			fpr[rdin] <= dtowrite;
		end
	end
endmodule

