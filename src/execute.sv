`timescale 1ns / 1ps

module execute #( parameter CLK_PER_HALF_BIT = 434, parameter INST_SIZE = 10, parameter BRAM_SIZE = 18)
	(input wire clk,
	input wire rstn,
	input wire rxd,
	input wire txd,
	input wire [31:0] pc,
	input wire [5:0] instr,
	input wire [1:0] op_type,
	input wire [31:0] s,
	input wire [31:0] t,
	input wire [31:0] imm,
	input wire branch,
	input wire jump,
	input wire is_jr,
	input wire start,
	input wire [2:0] mode,
	// output logic [31:0] d,
	output wire [31:0] d,
	output wire [31:0] npc,
	output logic uart_state, //if on, busy
	output wire aa_recieved,
	output logic aa_sent
);


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


	wire [7:0] 			 rdata;
    wire 			 rx_ready;
    wire 			 ferr;
	wire wea;
	wire [4:0] h;

	wire [31:0] douta;
	wire [31:0] addra;
	wire [31:0] bpc;

	logic uart_state_reg;

	assign uart_state = 
		(start && op_type == 2'b0 && (instr == OP_OUT || instr == OP_IN)) 
		|| uart_state_reg;

	localparam RX_SIZE = 14;
	logic [31:0] rxbuffer[(2**RX_SIZE)-1:0];

	logic [RX_SIZE-1:0] rxbot;
	logic [RX_SIZE-1:0] rxtop;


    uart_rx #(CLK_PER_HALF_BIT) rx(rdata, rx_ready, ferr, rxd, clk, rstn);
	logic [7:0] op_in_out;
	// assign op_in_out = rxbuffer[rxbot];


	assign aa_recieved = rx_ready && rdata == 8'b10101010;

	parameter TX_SIZE = 12;
	logic [8:0] txbuffer[TX_SIZE**2-1:0];

	logic [TX_SIZE-1:0] txbot;
	logic [TX_SIZE-1:0] txtop;
	logic txwait;

	reg 				 tx_start;
	wire 			 tx_busy;


	uart_tx #(CLK_PER_HALF_BIT) tx(txbuffer[txbot], tx_start, tx_busy, txd, clk, rstn);


	assign wea = (op_type == 2'b0 && (instr == OP_SW || instr == OP_SW_S));
	assign addra = s + imm;
	assign h = imm[10:6];

	assign bpc = ((pc & 32'hf0000000) | (imm << 2));
	assign npc = is_jr ? d
				: jump ? bpc
				: (branch && d == 32'b1) ? bpc
				: pc + 4;

	BRAM BRAM (
		.addra (addra[BRAM_SIZE+1:2]),
		.dina (t),
		.wea (wea),
		.clka (clk),
		.douta (douta)
	);


	logic [31:0] fpu_add_out;
	logic fpu_add_ovf;
	logic [31:0] fpu_sub_out;
	logic fpu_sub_ovf;
	logic [31:0] fpu_mul_out;
	logic fpu_mul_ovf;
	logic [31:0] fpu_inv_out;
	// logic [31:0] fpu_abs_out;
	// logic [31:0] fpu_neg_out;
	logic [31:0] fpu_sqrt_out;
	logic [31:0] fpu_eq_out;
	logic [31:0] fpu_lt_out;
	logic [31:0] fpu_le_out;
	logic [31:0] fpu_ftoi_out;
	logic [31:0] fpu_itof_out;

	fadd faddo (s, t, fpu_add_out, fpu_add_ovf);
	fsub fsubo (s, t, fpu_sub_out, fpu_sub_ovf);
	fmul fmulo (s, t, fpu_mul_out, fpu_mul_ovf);
	finv finvo (s, fpu_inv_out);
	// fabs fabso (s, fpu_abs_out);
	// fneg fnego (s, fpu_neg_out);
	// fsqrt fsqrto (s, clk, rstn, fpu_sqrt_out);
	fsqrt fsqrto (s, fpu_sqrt_out);
	feq feqo (s, t, fpu_eq_out);
	flt flto (s, t, fpu_lt_out);
	fle fleo (s, t, fpu_le_out);
	ftoi ftoio (s, fpu_ftoi_out);
	itof itofo (s, fpu_itof_out);

	// logic [31:0] tmp_d;
	assign d = 
		op_type == 2'b01 ?
			instr == FUNC_ADD ? s + t
			: instr == FUNC_SUB ? s - t
			: instr == FUNC_MULT ? s * t
			: instr == FUNC_DIV ? s / t
			: instr == FUNC_AND ? s & t
			: instr == FUNC_OR ? s | t
			: instr == FUNC_XOR ? s ^ t
			: instr == FUNC_SLT ? $signed(s) < $signed(t)
			: instr == FUNC_SLL ? t << h
			: instr == FUNC_SLLV ? t << s
			: instr == FUNC_SRL ? t >> h
			: instr == FUNC_SRLV ? t >> s
			: 32'b0
		: op_type == 2'b10 ?
			instr == FPU_ADD ? fpu_add_out
			: instr == FPU_SUB ? fpu_sub_out
			: instr == FPU_MUL ? fpu_mul_out
			: instr == FPU_INV ? fpu_inv_out
			: instr == FPU_NEG ? s ^ (32'h80000000)
			: instr == FPU_SQRT ? fpu_sqrt_out
			: instr == FPU_EQ ? fpu_eq_out
			: instr == FPU_LT ? fpu_lt_out
			: instr == FPU_LE ? fpu_le_out
			: instr == FPU_FTOI ? fpu_ftoi_out
			: instr == FPU_ITOF ? fpu_itof_out
			: 32'b0
		: op_type == 2'b00 ? 
			instr == OP_ADDI ? s + imm
			: instr == OP_ANDI ? s & imm
			: instr == OP_ORI ? s | imm
			: instr == OP_XORI ? s ^ {16'b0, imm[15:0]}
			: instr == OP_SLTI ? $signed(s) < $signed(imm)
			: instr == OP_LUI ? (imm << 16)
			: instr == OP_LW ? douta
			: instr == OP_LW_S ? douta
			: instr == OP_JAL ? s
			: instr == OP_IN ? op_in_out
			: 32'b0
		: 32'b0;

	always @(posedge clk) begin
		if(~rstn) begin
			rxbot <= 0;
			rxtop <= 0;
			uart_state_reg <= 0;

			txbot <= 0;
			txtop <= 0;
			txwait <= 0;
			aa_sent <= 0;
			op_in_out <= 0;
		end
		else begin

			//UART OPERATION
			if(mode == 1) begin // for LOAD
				if(aa_sent == 0) begin
					if(txtop == 0) begin
						txbuffer[txtop] <= 8'b10101010;
						txtop <= txtop + 1;
					end
					else begin
						if(~tx_busy) begin
							aa_sent <= 1;
						end
					end
				end
			end

			//for EXEC
			if(mode == 2 && rx_ready) begin
				rxbuffer[rxtop] <= {24'b0, rdata};
				rxtop <= rxtop + 1;
			end


			if(txwait == 1) begin
				tx_start <= 0;
				txbot <= txbot + 1;
				txwait <= 0;
			end
			else begin
				if (~tx_busy && txtop != txbot) begin
					tx_start <= 1;
					txwait <= 1;
				end
			end


			if(op_type == 2'b00 && instr == OP_IN) begin
				if(uart_state_reg == 0) begin
					if(start == 1) begin
						uart_state_reg <= 1;
					end
				end
				else begin
					if(rxbot != rxtop) begin
						op_in_out <= rxbuffer[rxbot];
						rxbot <= rxbot + 1;
						uart_state_reg <= 0;
					end
				end
			end
			else if(op_type == 2'b00 && instr == OP_OUT) begin
				if(uart_state_reg == 0) begin
					if(start == 1) begin
						uart_state_reg <= 1;
					end
				end
				else begin
					txbuffer[txtop] <= s[7:0];
					txtop <= txtop + 1;
					uart_state_reg <= 0;
				end
			end
		end
	end

endmodule
`default_nettype wire
