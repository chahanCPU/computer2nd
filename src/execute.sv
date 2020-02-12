`timescale 1ns / 1ps

import constant::*;

module execute #( parameter CLK_PER_HALF_BIT = 434)
	(input wire clk,
	input wire rstn,
	input wire rxd,
	input wire txd,
	input wire [31:0] pc,
	input wire [5:0] instr,
	input wire [1:0] op_type,
	input wire [31:0] de_s,
	input wire [5:0] de_rs,
	input wire [31:0] de_t,
	input wire [5:0] de_rt,
	input wire [31:0] ew_d,
	input wire [1:0] ew_rw,
	input wire [4:0] ew_rd,
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

	wire [31:0] s;
	wire [31:0] t;

	forward _forward(
		.s(de_s),
		.rs(de_rs),
		.t(de_t),
		.rt(de_rt),
		.d(ew_d),
		.rw(ew_rw),
		.rd(ew_rd),
		.fs(s),
		.ft(t));

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
		(start && op_type == 2'b00 && (instr == OP_OUT || instr == OP_IN)) 
		|| uart_state_reg;

	localparam RX_SIZE = 11;
	// (* ram_style = "distributed" *) logic [7:0] rxbuffer[(2**RX_SIZE)-1:0];


	logic [RX_SIZE-1:0] rxbot;
	logic [RX_SIZE-1:0] rxtop;
	logic rxwea;
	logic [7:0] rxout;
	logic [31:0] op_in_out;
	logic [2:0] rxlatancy;

	UART_BRAM _RX(
		.addra(rxtop),
		.clka(clk),
		.dina(rdata),
		.wea(rxwea),
		.addrb(rxbot),
		.clkb(clk),
		.doutb(rxout)
	);

    uart_rx #(CLK_PER_HALF_BIT) rx(rdata, rx_ready, ferr, rxd, clk, rstn);
	// assign op_in_out = rxbuffer[rxbot];


	assign aa_recieved = rx_ready && rdata == 8'b10101010;

	parameter TX_SIZE = 11;
	logic [7:0] odata;
	(* ram_style = "distributed" *) logic [7:0] txbuffer[(2**TX_SIZE)-1:0];

	logic [TX_SIZE-1:0] txbot;
	logic [TX_SIZE-1:0] txtop;


	reg 				 tx_start;
	wire 			 tx_busy;


	uart_tx #(CLK_PER_HALF_BIT) tx(odata, tx_start, tx_busy, txd, clk, rstn);


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
	finv finvo (s, clk, rstn, fpu_inv_out);
	// finv finvo (s, fpu_inv_out);
	// fabs fabso (s, fpu_abs_out);
	// fneg fnego (s, fpu_neg_out);
	fsqrt fsqrto (s, clk, rstn, fpu_sqrt_out);
	// fsqrt fsqrto (s, fpu_sqrt_out);
	feq feqo (s, t, fpu_eq_out);
	flt flto (s, t, fpu_lt_out);
	fle fleo (s, t, fpu_le_out);
	ftoi ftoio (s, fpu_ftoi_out);
	itof itofo (s, fpu_itof_out);

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
			aa_sent <= 0;
			op_in_out <= 0;
			odata <= 0;
			rxwea <= 0;
			rxlatancy <= 0;
		end
		else begin

			//UART OPERATION
			if(mode == 1) begin // for LOAD
				if(aa_sent == 0) begin
					if(txtop == 0) begin
						txbuffer[txtop] <= 8'b10101010;
						txtop <= 1;
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
				// rxbuffer[rxtop] <= {24'b0, rdata};
				rxtop <= rxtop + 1;
				rxwea <= 1;
			end
			else begin
				rxwea <= 0;
			end


			if(tx_start == 1) begin
				tx_start <= 0;
			end
			else begin
				if (~tx_busy && txtop != txbot) begin
					tx_start <= 1;
					odata <= txbuffer[txbot];
					txbot <= txbot + 1;
				end
			end


			if(op_type == 2'b00 && instr == OP_IN) begin
				if(uart_state_reg == 0) begin
					if(start == 1) begin
						uart_state_reg <= 1;
						rxlatancy <= 2'b00;
					end
				end
				else begin
					if(rxbot != rxtop || rxlatancy) begin
						if(rxlatancy == 0) begin
							rxbot <= rxbot + 1;
						end
						if(rxlatancy == 3'b11) begin
							op_in_out <= {24'b0, rxout};
							uart_state_reg <= 0;
						end
						if(rxlatancy <= 3'b11) begin
							rxlatancy <= rxlatancy + 1;
						end
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
					if(txtop + {{(TX_SIZE-1){1'b0}}, 1'b1} != txbot) begin
						txbuffer[txtop] <= s[7:0];
						txtop <= txtop + 1;
						uart_state_reg <= 0;
					end
				end
			end
		end
	end

endmodule
`default_nettype wire
