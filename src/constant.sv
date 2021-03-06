package constant;
	parameter INST_SIZE = 14;
	parameter BRAM_SIZE = 19;
	parameter TX_SIZE = 14;
	parameter OP_SPECIAL = 4'b0000;
	parameter OP_FPU = 4'b1000;
	parameter OP_ADDI = 4'b0001;
	parameter OP_LW = 4'b0010;
	parameter OP_SW = 4'b0011;
	parameter OP_BEQ = 4'b0100;
	parameter OP_BLE = 4'b0101;
	parameter OP_LUI = 4'b0110;
	parameter OP_LI = 4'b0111;
	parameter OP_J = 4'b1001;
	parameter OP_JAL = 4'b1010;
	parameter OP_LA = 4'b1011;
	parameter OP_BEQ_S = 4'b1100;
	parameter OP_BLE_S = 4'b1101;
	parameter OP_LW_S = 4'b1110;
	parameter OP_SW_S = 4'b1111;

	parameter FUNC_ADD = 4'b0000;
	parameter FUNC_SUB = 4'b0001;
	parameter FUNC_MULT = 4'b0010;
	parameter FUNC_DIV = 4'b0011;
	parameter FUNC_SLL  = 4'b0100;
	parameter FUNC_SRA  = 4'b0101;
	parameter FUNC_MV  = 4'b0111;
	parameter FUNC_IN  = 4'b1000;
	parameter FUNC_OUT  = 4'b1001;
	parameter FUNC_OUTINT  = 4'b1010;
	parameter FUNC_JR  = 4'b1100;
	parameter FUNC_NOOP  = 4'b1110;
	parameter FUNC_NOTHING = 4'b1111;

	parameter FPU_ADD = 4'b0000;
	parameter FPU_SUB = 4'b0001;
	parameter FPU_MUL = 4'b0010;
	parameter FPU_INV = 4'b0011;
	parameter FPU_SQRT = 4'b0100;
	parameter FPU_ABS = 4'b0101;
	parameter FPU_NEG = 4'b0111;
	parameter FPU_FTOI = 4'b1000;
	parameter FPU_ITOF = 4'b1001;
	parameter FPU_MV_S = 4'b1111;
endpackage
