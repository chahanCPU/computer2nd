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

	logic [31:0] pc;
	logic [31:0] f_inst;

	logic [1:0] fd_update;

	logic [31:0] fd_pc;
	logic [31:0] fd_inst;


	logic [5:0] d_instr;
	logic [1:0] d_op_type;
	logic [31:0] d_s;
	logic [5:0] d_rs;
	logic [31:0] d_t;
	logic [5:0] d_rt;
	logic [31:0] d_imm;
	logic d_branch;
	logic d_jump;
	logic [1:0] d_rw;
	logic d_is_jr;
	logic d_stop;
	logic [4:0] d_rd;
	logic [31:0] d_npc;
	logic [4:0] d_wait_time;

	logic [1:0] de_update;

	logic [5:0] de_instr;
	logic [1:0] de_op_type;
	logic [31:0] de_s;
	logic [5:0] de_rs;
	logic [31:0] de_t;
	logic [5:0] de_rt;
	logic [31:0] de_imm;
	logic de_branch;
	logic de_jump;
	logic [1:0] de_rw;
	logic de_is_jr;
	logic de_stop;
	logic [4:0] de_rd;
	logic [4:0] de_wait_time;
	logic [31:0] de_pc;


	logic [31:0] e_d;
	logic [31:0] e_npc;
	logic e_start;
	logic e_uart_state;

	logic [31:0] ew_npc;

	logic [31:0] ew_d;
	logic [4:0] ew_rd;
	logic [1:0] ew_rw;
	logic [1:0] ew_update;


	logic [2:0] mode;
	logic [7:0] pipe;
	logic [31:0] inst;
	assign led = pc[7:0] | (mode << 4);

	logic [4:0] latancy;
	logic [2:0] stage;
	logic load_done;


	wire [7:0] 			 rdata;
	wire 			 rx_ready;
	wire 			 ferr;
	uart_rx #(CLK_PER_HALF_BIT) u2(rdata, rx_ready, ferr, rxd, clk, rstn);

	wire aa_recieved;
	wire aa_sent;

	fetch #(CLK_PER_HALF_BIT) _fetch(
		.clk(clk), 
		.mode(mode), 
		.pc(pc), 
		.rstn(rstn), 
		.inst(f_inst), 
		.done(load_done)
	);

	// assign fd_update = !(mode == EXEC && pipe == FETCH && latancy == 0);
	
	assign fd_update = (mode == EXEC && pipe == FETCH) ? 2'b01
		: 2'b00;

	fdreg _fdreg(
		.clk(clk),
		.rstn(rstn),
		.update(fd_update),
		.f_pc(pc),
		.f_inst(f_inst),
		.fd_pc(fd_pc),
		.fd_inst(fd_inst)
	);

	decode _decode(
		.clk(clk), 
		.rstn(rstn), 
		.pc(fd_pc), 
		.inst(fd_inst), 
		.rwin(ew_rw), 
		.dtowrite(ew_d), 
		.rdin(ew_rd), 
		.instr(d_instr),
		.op_type(d_op_type), 
		.s(d_s),
		.rs(d_rs),
		.t(d_t), 
		.rt(d_rt),
		.imm(d_imm), 
		.branch(d_branch), 
		.jump(d_jump), 
		.rw(d_rw), 
		.is_jr(d_is_jr), 
		.stop(d_stop),
		.rd(d_rd),
		.npc(d_npc),
		.wait_time(d_wait_time)
	);

	assign de_update = (mode == EXEC && pipe == DECODE) ? 2'b01
		: 2'b00;

	dereg _dereg(
		.clk(clk),
		.rstn(rstn),
		.update(de_update),
		.d_instr(d_instr),
		.d_op_type(d_op_type),
		.d_s(d_s),
		.d_rs(d_rs),
		.d_t(d_t),
		.d_rt(d_rt),
		.d_imm(d_imm),
		.d_branch(d_branch),
		.d_jump(d_jump),
		.d_rw(d_rw),
		.d_is_jr(d_is_jr),
		.d_stop(d_stop),
		.d_rd(d_rd),
		.d_wait_time(d_wait_time),

		.d_pc(fd_pc),
		.de_instr(de_instr),
		.de_op_type(de_op_type),
		.de_s(de_s),
		.de_rs(de_rs),
		.de_t(de_t),
		.de_rt(de_rt),
		.de_imm(de_imm),
		.de_branch(de_branch),
		.de_jump(de_jump),
		.de_rw(de_rw),
		.de_is_jr(de_is_jr),
		.de_stop(de_stop),
		.de_rd(de_rd),
		.de_wait_time(de_wait_time),
		.de_pc(de_pc)
	);


	execute #(CLK_PER_HALF_BIT) _execute(
		.clk(clk), 
		.rstn(rstn),
		.rxd(rxd), 
		.txd(txd),
		.pc(de_pc), 
		.instr(de_instr),
		.op_type(de_op_type), 
		.de_s(de_s), 
		.de_rs(de_rs), 
		.de_t(de_t), 
		.de_rt(de_rt), 
		.ew_d(ew_d),
		.ew_rw(ew_rw),
		.ew_rd(ew_rd),
		.imm(de_imm), 
		.branch(de_branch), 
		.jump(de_jump),
		.is_jr(de_is_jr), 
		.mode(mode),
		.start(e_start), 
		.d(e_d), 
		.npc(e_npc),
		.uart_state(e_uart_state),
		.aa_recieved(aa_recieved),
		.aa_sent(aa_sent)
	);

	assign ew_update = (mode == EXEC && pipe == FETCH) ? 2'b01
		: 2'b10;

	ewreg _ewreg(
		.clk(clk),
		.rstn(rstn),
		.update(ew_update),
		.e_d(e_d),
		.e_rw(de_rw),
		.e_rd(de_rd),
		.ew_d(ew_d),
		.ew_rw(ew_rw),
		.ew_rd(ew_rd)
	);

   always @(posedge clk) begin
    if (~rstn) begin
		 pc <= 0;
		 latancy <= 0;
		 mode <= STALL;
		 pipe <= FETCH;
		 stage <= 0;
		 e_start <= 0;
	end 
	else begin
		if (mode == STALL) begin
			if (aa_recieved) begin
				mode <= LOAD;
			end
		end
		else if (mode == LOAD) begin
			if(load_done && aa_sent) begin
				mode <= EXEC;
			end
		end
		else begin
			if(pipe == FETCH) begin
				pipe <= DECODE;
			end
			else if(pipe == DECODE) begin
				e_start <= 1;
				pc <= d_npc;
				pipe <= EXECUTE;
			end
			else if(pipe == EXECUTE) begin
				if(latancy == 0) begin
					e_start <= 0;
				end
				if(latancy == de_wait_time) begin
					if(e_uart_state == 0) begin
						latancy <= 0;
						pipe <= WRITEREG;
					end
				end
				else if(latancy < de_wait_time) begin
					latancy <= latancy + 1;
				end
			end
			else if(pipe == WRITEREG) begin
				if(de_stop) pipe <= STOP;
				else pipe <= FETCH;
			end
		end
	 end
   end

endmodule

