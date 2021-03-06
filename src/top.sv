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

	// localparam FETCH = 0;
	// localparam DECODE = 1;
	// localparam EXECUTE = 2;
	// localparam WRITEREG = 3;
	// localparam STOP = 4;


	localparam STALL = 0;
	localparam LOAD = 1;
	localparam EXEC = 2;
	localparam STOP = 3;

	logic [31:0] pc;
	logic [31:0] f_inst;

	logic [1:0] fd_update;

	logic [31:0] fd_pc;
	logic [31:0] fd_inst;


	logic [3:0] d_instr;
	logic [1:0] d_op_type;
	logic [31:0] d_s;
	logic [6:0] d_rs;
	logic [31:0] d_t;
	logic [6:0] d_rt;
	logic [31:0] d_imm;
	logic d_branch;
	logic d_jump;
	logic [1:0] d_rw;
	logic d_is_jr;
	logic d_stop;
	logic [5:0] d_rd;
	logic [31:0] d_npc;
	logic [4:0] d_wait_time;
	logic [31:0] d_omo;

	logic [1:0] de_update;

	logic [3:0] de_instr;
	logic [1:0] de_op_type;
	logic [31:0] de_s;
	logic [6:0] de_rs;
	logic [31:0] de_t;
	logic [6:0] de_rt;
	logic [31:0] de_imm;
	logic de_branch;
	logic de_jump;
	logic [1:0] de_rw;
	logic de_is_jr;
	logic de_stop;
	logic [5:0] de_rd;
	logic [4:0] de_wait_time;
	logic [31:0] de_pc;
	logic [31:0] de_npc;


	logic [31:0] e_d;
	logic [31:0] e_npc;
	logic e_start;
	logic e_taken;
	logic e_uart_state;
	logic hazard;


	logic ew_branch;
	logic ew_is_jr;
	logic ew_taken;
	logic [31:0] ew_npc;
	logic [31:0] ew_d;
	logic [5:0] ew_rd;
	logic [1:0] ew_rw;

	logic [1:0] ew_update;


	logic [2:0] mode;
	logic [7:0] pipe;
	logic [31:0] inst;
	assign led = d_npc[9:2];

	logic [4:0] latancy;
	logic [2:0] stage;
	logic load_done;

	logic [31:0] stall_counter;


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

	wire npc_stall = (d_jump || d_is_jr) && latancy == 0;
	wire execute_done = latancy >= de_wait_time && e_uart_state == 0 && (~npc_stall);

	assign hazard = (ew_branch || ew_is_jr) && ew_npc != de_pc;

	assign fd_update = 
		mode == EXEC ?
			hazard ? 2'b10 :
			execute_done ? 2'b01 
			: 2'b00
		: 2'b10;

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
		.ew_taken(ew_taken),
		.ew_branch(ew_branch),
		.start(e_start),
		.inst(fd_inst), 
		.rwin(ew_rw), 
		.dtowrite(ew_d), 
		.rdin(ew_rd), 
		.instr(d_instr),
		.de_instr(de_instr),
		.op_type(d_op_type), 
		.de_op_type(de_op_type),
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
		.wait_time(d_wait_time),
		.omo(d_omo)
	);

	assign de_update = 
		mode == EXEC ?  
			hazard ? 2'b10 :
			execute_done ? 
				2'b01 
			: 2'b00
		: 2'b10;

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
		.d_npc(d_npc),

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
		.de_pc(de_pc),
		.de_npc(de_npc)
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
		.hazard(hazard),
		.start(e_start), 
		.d(e_d), 
		.npc(e_npc),
		.taken(e_taken),
		.uart_state(e_uart_state),
		.aa_recieved(aa_recieved),
		.aa_sent(aa_sent)
	);

	assign ew_update = 
		mode == EXEC ?
			hazard ? 2'b10 :
			execute_done ? 
				2'b01 
			: 2'b00
		: 2'b10;

	ewreg _ewreg(
		.clk(clk),
		.rstn(rstn),
		.update(ew_update),
		.e_is_jr(de_is_jr),
		.e_branch(de_branch),
		.e_taken(e_taken),
		.e_npc(e_npc),
		.e_d(e_d),
		.e_rw(de_rw),
		.e_rd(de_rd),

		.ew_is_jr(ew_is_jr),
		.ew_branch(ew_branch),
		.ew_taken(ew_taken),
		.ew_npc(ew_npc),
		.ew_d(ew_d),
		.ew_rw(ew_rw),
		.ew_rd(ew_rd)
	);

   always @(posedge clk) begin
    if (~rstn) begin
		 latancy <= 0;
		 mode <= STALL;
		 stage <= 0;
		 e_start <= 0;
		 pc <= 0;
		 stall_counter <= 0;
	end 
	else begin
		if (mode == STALL) begin
			if (load_done) begin
				mode <= LOAD;
			end
			// if(stall_counter >= 32'd10000) begin
			// 	mode <= LOAD;
			// end
			// stall_counter <= stall_counter + 1;
		end
		else if (mode == LOAD) begin
			if(aa_sent) begin
				mode <= EXEC;
			end
		end
		else if(mode == EXEC) begin
			if(de_stop) mode <= STOP;
			if(hazard) begin
				latancy <= 0;
				pc <= ew_npc;
			end
			else if(execute_done) begin
				latancy <= 0;
				pc <= pc + 4;
			end
			else if(npc_stall) begin
				pc <= d_npc;
			end
			if(latancy < de_wait_time || npc_stall) begin
				latancy <= latancy + 1;
			end
			e_start <= execute_done;
		end
	 end
   end

endmodule

