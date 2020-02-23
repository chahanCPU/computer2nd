`timescale 1ns / 1ps

import constant::*;

module execute #( parameter CLK_PER_HALF_BIT = 434)
	(input wire clk,
	input wire rstn,
	input wire rxd,
	input wire txd,
	input wire [31:0] pc,
	input wire [3:0] instr,
	input wire [1:0] op_type,
	input wire [31:0] de_s,
	input wire [6:0] de_rs,
	input wire [31:0] de_t,
	input wire [6:0] de_rt,
	input wire [31:0] ew_d,
	input wire [1:0] ew_rw,
	input wire [5:0] ew_rd,
	input wire [31:0] imm,
	input wire branch,
	input wire jump,
	input wire is_jr,
	input wire start,
	input wire [2:0] mode,
	input wire hazard,
	// output logic [31:0] d,
	output wire [31:0] d,
	output wire [31:0] npc,
	output wire taken,
	output logic uart_state, //if on, busy
	output wire aa_recieved,
	output logic aa_sent
);

	logic [31:0] s;
	logic [31:0] t;
	wire [31:0] sw;
	wire [31:0] tw;

	forward _forward(
		.s(de_s),
		.rs(de_rs),
		.t(de_t),
		.rt(de_rt),
		.d(ew_d),
		.rw(ew_rw),
		.rd(ew_rd),
		.fs(sw),
		.ft(tw));

	wire [7:0] 			 rdata;
    wire 			 rx_ready;
    wire 			 ferr;
	wire wea;
	wire [4:0] h;

	wire [31:0] douta;
	wire [31:0] bpc;

	logic uart_state_reg;

	assign uart_state = 
		(start && op_type == 2'b01 && (instr == FUNC_OUT || instr == FUNC_IN || instr == FUNC_OUTINT)) 
		|| uart_state_reg;

	localparam RX_SIZE = 11;


	logic [RX_SIZE-1:0] rxbot;
	logic [RX_SIZE-1:0] rxtop;
	logic rxwea;
	logic [7:0] rxout;
	logic [31:0] op_in_out;
	logic [2:0] rxlatancy;

	UART_RX_BRAM _RX(
		.addra(rxtop),
		.clka(clk),
		.dina(rdata),
		.wea(rxwea),
		.addrb(rxbot),
		.clkb(clk),
		.doutb(rxout)
	);

    uart_rx #(CLK_PER_HALF_BIT) rx(rdata, rx_ready, ferr, rxd, clk, rstn);


	assign aa_recieved = rx_ready && rdata == 8'b10101010;

	logic [7:0] odata;

	logic [TX_SIZE-1:0] txbot;
	logic [TX_SIZE-1:0] txtop;
	logic txwea;
	logic [7:0] txin;
	logic [7:0] txout;
	logic [2:0] txlatancy;


	UART_TX_BRAM _TX(
		.addra(txtop),
		.clka(clk),
		.dina(txin),
		.wea(txwea),
		.addrb(txbot),
		.clkb(clk),
		.doutb(txout)
	);


	reg 				 tx_start;
	wire 			 tx_busy;


	uart_tx #(CLK_PER_HALF_BIT) tx(odata, tx_start, tx_busy, txd, clk, rstn);


	assign wea = (op_type == 2'b0 && (instr == OP_SW || instr == OP_SW_S) && !start);
	// assign addra = s + imm;
	assign h = imm[9:5];

	assign bpc = ((pc & 32'hf0000000) | (imm << 2));
	// assign npc = is_jr ? d
	// 			: jump ? bpc
	// 			: (branch && d == 32'b1) ? bpc
	// 			: pc + 4;

	logic [7:0] outint_s;
	logic [23:0] outint_reg;
	logic [3:0] outint_state;
	logic outint_lz;

	logic [31:0] fpu_eq_out;
	logic [31:0] fpu_lt_out;
	logic [31:0] fpu_le_out;

	assign taken = 
		(op_type == 2'b00 && instr == OP_BEQ && sw == tw) ||
		(op_type == 2'b00 && instr == OP_BLE && $signed(sw) <= $signed(tw)) ||
		(op_type == 2'b00 && instr == OP_BEQ_S && fpu_eq_out) ||
		(op_type == 2'b00 && instr == OP_BLE_S && fpu_le_out);

	assign npc = is_jr ? sw
				: jump ? bpc
				: taken ? bpc
				: pc + 4;

	logic [BRAM_SIZE-1:0] addra_reg;
	logic [31:0] addra;
	assign addra = sw + imm;

	BRAM BRAM (
		.addra (addra_reg),
		.dina (t),
		.wea (wea),
		.clka (clk),
		.douta (douta)
	);

	logic [31:0] mul_out;
	logic [63:0] div_out;
	logic div_valid;


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
	logic [31:0] fpu_ftoi_out;
	logic [31:0] fpu_itof_out;

	MUL32_32 _MUL(
		.CLK(clk), 
		.A(s), 
		.B(t),
		.P(mul_out)
	);
	
	DIV32 _DIV(
		.s_axis_divisor_tdata(t),
		.s_axis_divisor_tvalid(1'b1),
		.s_axis_dividend_tdata(s),
		.s_axis_dividend_tvalid(1'b1),
		.aclk(clk),
		.m_axis_dout_tdata(div_out),
		.m_axis_dout_tvalid(div_valid)
	);


	fadd faddo (s, t, clk, rstn, fpu_add_out, fpu_add_ovf);
	fsub fsubo (s, t, clk, rstn, fpu_sub_out, fpu_sub_ovf);
	fmul fmulo (s, t, clk, rstn, fpu_mul_out, fpu_mul_ovf);
	finv finvo (s, clk, rstn, fpu_inv_out);
	fsqrt fsqrto (s, clk, rstn, fpu_sqrt_out);
	// fmul_old fmulo (s, t, fpu_mul_out, fpu_mul_ovf);
	// finv_old finvo (s, fpu_inv_out);
	// fsqrt_old fsqrto (s, fpu_sqrt_out);
	// fsqrt fsqrto (s, fpu_sqrt_out);
	// finv finvo (s, fpu_inv_out);
	// fabs fabso (s, fpu_abs_out);
	// fneg fnego (s, fpu_neg_out);
	feq feqo (s, t, fpu_eq_out);
	flt flto (s, t, fpu_lt_out);
	fle fleo (s, t, fpu_le_out);
	ftoi ftoio (s, fpu_ftoi_out);
	itof itofo (s, fpu_itof_out);

	assign d = 
		op_type == 2'b01 ?
			instr == FUNC_ADD ? sw + tw
			: instr == FUNC_SUB ? sw - tw
			: instr == FUNC_MULT ? mul_out
			: instr == FUNC_DIV ? div_out[63:32]
			// : instr == FUNC_MULT ? s * t
			// : instr == FUNC_DIV ? s / t
			: instr == FUNC_SLL ? tw << h
			: instr == FUNC_SRA ? tw >> h
			: instr == FUNC_MV ? sw
			: instr == FUNC_IN ? op_in_out
			: 32'b0
		: op_type == 2'b10 ?
			instr == FPU_ADD ? fpu_add_out
			: instr == FPU_SUB ? fpu_sub_out
			: instr == FPU_MUL ? fpu_mul_out
			: instr == FPU_INV ? fpu_inv_out
			: instr == FPU_NEG ? sw ^ (32'h80000000)
			: instr == FPU_ABS ? sw & (32'h7fffffff)
			: instr == FPU_SQRT ? fpu_sqrt_out
			: instr == FPU_FTOI ? fpu_ftoi_out
			: instr == FPU_ITOF ? fpu_itof_out
			: instr == FPU_MV_S ? sw
			: 32'b0
		: op_type == 2'b00 ? 
			instr == OP_ADDI ? sw + imm
			: instr == OP_LW ? douta
			: instr == OP_LUI ? (imm << 16)
			: instr == OP_LI ? (de_rs[5] ? (tw | imm) : imm)
			: instr == OP_JAL ? sw
			: instr == OP_LA ? imm << 2
			: instr == OP_LW_S ? douta
			: 32'b0
		: 32'b0;

	always @(posedge clk) begin
		if(~rstn) begin
			rxbot <= 0;
			rxtop <= 0;
			uart_state_reg <= 0;
			tx_start <= 0;

			txbot <= 0;
			txtop <= 0;
			aa_sent <= 0;
			op_in_out <= 0;
			odata <= 0;

			rxwea <= 0;
			rxlatancy <= 0;

			txwea <= 0;
			txlatancy <= 0;
			txin <= 0;
			s <= 0;
			t <= 0;
			addra_reg <= 0;
			outint_s <= 0;
			outint_reg <= 0;
			outint_state <= 0;
			outint_lz <= 0;
		end
		else begin

			//forwarding register
			s <= sw;
			t <= tw;


			addra_reg <= addra[BRAM_SIZE+1:2];

			//UART OPERATION
			if(mode == 1) begin // for LOAD
				if(aa_sent == 0) begin
					if(txlatancy == 0) begin
						tx_start <= 1;
						odata <= 8'b10101010;
						txlatancy <= 1;
					end
					else begin
						tx_start <= 0;
						if(~tx_busy) begin
							aa_sent <= 1;
							txlatancy <= 0;
						end
					end
				end
			end

			if(rxwea) begin
				rxwea <= 0;
			end

			if(txwea) begin
				txwea <= 0;
			end

			//for EXEC
			if(mode == 2 && rx_ready) begin
			rxtop <= rxtop + 1;
			rxwea <= 1;
			end


			if(mode != 1) begin
				if(tx_start == 1) begin
					tx_start <= 0;
					txlatancy = 0;
				end
				else begin
					if ((~tx_busy && txtop != txbot) || txlatancy) begin
						if(txlatancy == 0) begin
							txbot <= txbot + 1;
						end
						if(txlatancy == 3'b11) begin
							tx_start <= 1;
							odata <= txout;
						end
						if(txlatancy <= 3'b11) begin
							txlatancy <= txlatancy + 1;
						end
					end
				end
			end


			if(op_type == 2'b01 && instr == FUNC_IN) begin
				if(uart_state_reg == 0) begin
					if(start == 1 && !hazard) begin
						uart_state_reg <= 1;
						rxlatancy <= 3'b0;
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
			else if(op_type == 2'b01 && instr == FUNC_OUT) begin
				if(uart_state_reg == 0) begin
					if(start == 1 && !hazard) begin
						uart_state_reg <= 1;
					end
				end
				else begin
					if(txtop + {{(TX_SIZE-1){1'b0}}, 1'b1} != txbot) begin
						txin <= s[7:0];
						txtop <= txtop + 1;
						txwea <= 1;
						uart_state_reg <= 0;
					end
				end
			end
			else if(op_type == 2'b01 && instr == FUNC_OUTINT) begin
				if(uart_state_reg == 0) begin
					if(start == 1 && !hazard) begin
						uart_state_reg <= 1;
						outint_state <= 0;
					end
				end
				else begin
					if(outint_state == 0) begin
						outint_s <= s[7:0];
						outint_reg <= 0;
						outint_lz <= 0;
						outint_state <= 1;
					end
					else if(outint_state == 1) begin
						if(8'd100 <= outint_s && outint_s < 8'd200) begin
							outint_reg <= 24'h31;
							outint_s <= outint_s - 8'd100;
							outint_lz <= 1;
						end
						else if(8'd200 <= outint_s) begin
							outint_reg <= 24'h32;
							outint_s <= outint_s - 8'd200;
							outint_lz <= 1;
						end
						outint_state <= 2;
					end
					else if(outint_state == 2) begin
						if(outint_s < 8'd10 && outint_lz) begin
							outint_reg <= (outint_reg << 8) | 24'h30;
						end
						else if(8'd10 <= outint_s && outint_s < 8'd20) begin
							outint_reg <= (outint_reg << 8) | 24'h31;
							outint_s <= outint_s - 8'd10;
						end
						else if(8'd20 <= outint_s && outint_s < 8'd30) begin
							outint_reg <= (outint_reg << 8) | 24'h32;
							outint_s <= outint_s - 8'd20;
						end
						else if(8'd30 <= outint_s && outint_s < 8'd40) begin
							outint_reg <= (outint_reg << 8) | 24'h33;
							outint_s <= outint_s - 8'd30;
						end
						else if(8'd40 <= outint_s && outint_s < 8'd50) begin
							outint_reg <= (outint_reg << 8) | 24'h34;
							outint_s <= outint_s - 8'd40;
						end
						else if(8'd50 <= outint_s && outint_s < 8'd60) begin
							outint_reg <= (outint_reg << 8) | 24'h35;
							outint_s <= outint_s - 8'd50;
						end
						else if(8'd60 <= outint_s && outint_s < 8'd70) begin
							outint_reg <= (outint_reg << 8) | 24'h36;
							outint_s <= outint_s - 8'd60;
						end
						else if(8'd70 <= outint_s && outint_s < 8'd80) begin
							outint_reg <= (outint_reg << 8) | 24'h37;
							outint_s <= outint_s - 8'd70;
						end
						else if(8'd80 <= outint_s && outint_s < 8'd90) begin
							outint_reg <= (outint_reg << 8) | 24'h38;
							outint_s <= outint_s - 8'd80;
						end
						else if(8'd90 <= outint_s) begin
							outint_reg <= (outint_reg << 8) | 24'h39;
							outint_s <= outint_s - 8'd90;
						end
						outint_state <= 3;
					end
					else if(outint_state == 3) begin
						outint_reg <= (outint_reg << 8) | {16'd0, outint_s} | 24'h30;
						outint_state <= 4;
					end
					else if(outint_state >= 4) begin
						if(!outint_state[0]) begin
							if(outint_reg[23:16] == 8'd0) begin
								outint_state <= outint_state + 1;
								outint_reg <= outint_reg << 8;
							end
							else if(txtop + {{(TX_SIZE-1){1'b0}}, 1'b1} != txbot) begin
								txin <= outint_reg[23:16];
								outint_reg <= outint_reg << 8;
								txtop <= txtop + 1;
								txwea <= 1;
								outint_state <= outint_state + 1;
								if(outint_state == 8) begin
									uart_state_reg <= 0;
								end
							end
						end
						else begin
							//txwea <= 0;
							outint_state <= outint_state + 1;
						end
					end
				end
			end
		end
	end

endmodule
`default_nettype wire
