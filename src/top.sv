//todo 
//fix bgtz and etc. add $signed

import constant::*;
`timescale 1ns / 1ps

module top #( parameter CLK_PER_HALF_BIT = 434)

		     (input wire  rxd,
		     output wire txd,
		     input wire  clk,
		     input wire  rstn,
			 output wire [7:0] led);

	// localparam INST_SIZE = 15;
	// localparam BRAM_SIZE = 19;

	localparam FETCH = 0;
	localparam DECODE = 1;
	localparam EXECUTE = 2;
	localparam WRITEREG = 3;
	localparam STOP = 4;


	localparam STALL = 0;
	localparam LOAD = 1;
	localparam EXEC = 2;

	logic [31:0] f_inst;
	logic [31:0] fd_inst;


	logic [5:0] d_instr;
	logic [1:0] d_op_type;
	logic [31:0] d_s;
	logic [31:0] d_t;
	logic [31:0] d_imm;
	logic d_branch;
	logic d_jump;
	logic [1:0] d_rw;
	logic d_is_jr;
	logic d_is_out;
	logic d_stop;
	logic d_is_in;
	logic [4:0] d_rd;

	logic [5:0] de_instr;
	logic [1:0] de_op_type;
	logic [31:0] de_s;
	logic [31:0] de_t;
	logic [31:0] de_imm;
	logic de_branch;
	logic de_jump;
	logic [1:0] de_rw;
	logic de_is_jr;
	logic de_is_out;
	logic de_stop;
	logic [4:0] de_rd;

	logic [31:0] e_d;
	logic [31:0] e_npc;
	logic e_in_valid;

	logic [31:0] ew_d;
	logic [31:0] ew_npc;

	logic wd_is_out;
	logic [31:0] w_dtowrite;
	logic [31:0] wd_dtowrite;
	logic [31:0] wd_rdin;
	logic [1:0] wd_rwin;

	logic wd_is_in;

	logic [1:0] mode;
	logic [7:0] pipe;
	logic [31 : 0] pc;
	logic [31:0] inst;
	assign led = pc[7:0] | (mode << 4);

	logic [3:0] latancy;
	logic [2:0] stage;
	logic load_done;


	wire [7:0] 			 rdata;
	wire 			 rx_ready;
	wire 			 ferr;
	uart_rx #(CLK_PER_HALF_BIT) u2(rdata, rx_ready, ferr, rxd, clk, rstn);

	fetch #(CLK_PER_HALF_BIT, INST_SIZE) _fetch(
		.clk(clk), 
		.mode(mode), 
		.pc(pc), 
		.rstn(rstn), 
		.inst(f_inst), 
		.done(load_done)
	);

	decode #(CLK_PER_HALF_BIT, INST_SIZE, BRAM_SIZE) _decode(
		.clk(clk), 
		.rstn(rstn), 
		.pc(pc), 
		.inst(fd_inst), 
		.rwin(wd_rwin), 
		.dtowrite(wd_dtowrite), 
		.rdin(wd_rdin), 
		.instr(d_instr),
		.op_type(d_op_type), 
		.s(d_s), 
		.t(d_t), 
		.imm(d_imm), 
		.branch(d_branch), 
		.jump(d_jump), 
		.rw(d_rw), 
		.is_jr(d_is_jr), 
		.is_out(d_is_out), 
		.stop(d_stop),
		.rd(d_rd), 
		.is_in(d_is_in)
	);


	execute #(CLK_PER_HALF_BIT, INST_SIZE, BRAM_SIZE) _execute(
		.clk(clk), 
		.rstn(rstn),
		.rxd(rxd), 
		.txd(txd),
		.pc(pc), 
		.instr(de_instr),
		.op_type(de_op_type), 
		.s(de_s), 
		.t(de_t), 
		.imm(de_imm), 
		.branch(de_branch), 
		.jump(de_jump),
		.is_jr(de_is_jr), 
		.is_in(wd_is_in), 
		.latancy(latancy), 
		.d(e_d), 
		.npc(e_npc), 
		.in_valid(e_in_valid)
	);

	writereg #(CLK_PER_HALF_BIT, INST_SIZE, BRAM_SIZE) _writereg(
		.clk(clk), 
		.rstn(rstn), 
		.is_out(wd_is_out), 
		.d(ew_d), 
		.rd(de_rd), 
		.dtowrite(w_dtowrite)
	);

   always @(posedge clk) begin
    if (~rstn) begin
		 pc <= 0;
		 latancy <= 0;
		 mode <= STALL;
		 pipe <= FETCH;
		 stage <= 0;
	end 
	else begin
		if (mode == STALL) begin
			if (rx_ready && rdata == 8'b10101010) begin
				mode <= LOAD;
			end
		end
		else if (mode == LOAD) begin
			if(load_done) begin
				mode <= EXEC;
			end
		end
		else begin
			if(pipe == FETCH) begin
				if(latancy == 0) begin
					fd_inst <= f_inst;


					latancy <= 0;
					pipe <= DECODE;
				end
				else latancy <= latancy + 1;
			end
			else if(pipe == DECODE) begin
				if(latancy == 0) begin
					de_instr <= d_instr;
					de_op_type <= d_op_type;
					de_s <= d_s;
					de_t <= d_t;
					de_imm <= d_imm;
					de_branch <= d_branch;
					de_jump <= d_jump;
					de_rw <= d_rw;
					de_is_jr <= d_is_jr;
					de_is_out <= d_is_out;
					de_stop <= d_stop;
					de_rd <= d_rd;


					latancy <= 0;
					pipe <= EXECUTE;
				end
				else latancy <= latancy + 1;
			end
			else if(pipe == EXECUTE) begin
				if(latancy == 5) begin
					if(e_in_valid) begin
						ew_d <= e_d;
						pc <= e_npc;


						latancy <= 0;
						pipe <= WRITEREG;
					end
				end
				else latancy <= latancy + 1;
			end
			else if(pipe == WRITEREG) begin
				if(latancy == 0) begin
					wd_is_out <= de_is_out;
					wd_is_in <= d_is_in;
					wd_dtowrite <= w_dtowrite;
					wd_rwin <= de_rw;
					wd_rdin <= de_rd;
					latancy <= latancy + 1;
				end
				else if (latancy == 1) begin
					wd_rwin <= 2'b0;
					wd_is_out <= 0;
					wd_is_in <= 0;
					latancy <= 0;
					if(de_stop) pipe <= STOP;
					else pipe <= FETCH;
				end
				else latancy <= latancy + 1;
			end
		end
	 end
   end

endmodule

