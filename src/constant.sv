package constant;
	parameter INST_SIZE = 15;
	parameter BRAM_SIZE = 19;
	parameter OP_SPECIAL = 6'b000000;
	parameter OP_FPU = 6'b010001;
	parameter OP_LW = 6'b100011;
	parameter OP_SW = 6'b101011;
	parameter OP_ADDI = 6'b001000;
	parameter OP_ANDI = 6'b001100;
	parameter OP_ORI = 6'b001101;
	parameter OP_XORI = 6'b001110;
	parameter OP_SLTI = 6'b001010;
	parameter OP_LUI = 6'b001111;
	parameter OP_BEQ = 6'b000100;
	parameter OP_BGTZ = 6'b000111;
	parameter OP_BLEZ = 6'b000110;
	parameter OP_BNE = 6'b000101;
	parameter OP_J = 6'b000010;
	parameter OP_JAL = 6'b000011;
	parameter OP_NOOP = 6'b111110;
	parameter OP_IN = 6'b111110;
	parameter OP_OUT = 6'b111111;

	parameter OP_LUI_S = 6'b011111;
	parameter OP_LW_S = 6'b110001;
	parameter OP_SW_S = 6'b111001;


	parameter FUNC_ADD = 6'b100000;
	parameter FUNC_SUB = 6'b100010;
	parameter FUNC_MULT = 6'b011000;
	parameter FUNC_DIV = 6'b011010;
	parameter FUNC_AND = 6'b100100;
	parameter FUNC_OR  = 6'b100101;
	parameter FUNC_XOR  = 6'b100110;
	parameter FUNC_SLT  = 6'b101010;
	parameter FUNC_SLL  = 6'b000000; //change!!!!
	parameter FUNC_SLLV = 6'b000100;
	parameter FUNC_SRL  = 6'b000010;
	parameter FUNC_SRLV = 6'b000110;
	parameter FUNC_JR = 6'b001000;

	parameter FPU_ADD = 6'b000000;
	parameter FPU_SUB = 6'b000001;
	parameter FPU_MUL = 6'b000010;
	parameter FPU_INV = 6'b000011;
	parameter FPU_ABS = 6'b000101;
	parameter FPU_NEG = 6'b000111;
	parameter FPU_SQRT = 6'b000100;
	parameter FPU_EQ = 6'b110010;
	parameter FPU_LT = 6'b110100;
	parameter FPU_LE = 6'b110110;
	parameter FPU_FTOI = 6'b001000;
	parameter FPU_ITOF = 6'b001001;
endpackage
