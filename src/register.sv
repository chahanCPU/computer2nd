`timescale 1ns / 1ps

module forward
	(input wire [31:0] s,
	input wire [5:0] rs,
	input wire [31:0] t,
	input wire [5:0] rt,
	input wire [31:0] d,
	input wire [1:0] rw,
	input wire [4:0] rd,
	output wire [31:0] fs,
	output wire [31:0] ft
);

	assign fs =
		(rw != 2'b0 && rw[1] == rs[5] && rd[4:0] == rs[4:0]) ? d : s;
	assign ft = 
		(rw != 2'b0 && rw[1] == rt[5] && rd[4:0] == rt[4:0]) ? d : t;

endmodule

module fdreg
	(input wire clk,
	input wire rstn,
	input wire [1:0] update,
	input wire [31:0] f_pc,
	input wire [31:0] f_inst,
	output logic [31:0] fd_pc,
	output logic [31:0] fd_inst
);

	always @(posedge clk) begin
		if(~rstn) begin
			fd_pc <= 32'b0;
			fd_inst <= 1;
		end
		else begin
			if(update == 2'b01) begin
				fd_pc <= f_pc;
				fd_inst <= f_inst;
			end
			else if(update == 2'b10) begin
				fd_pc <= 32'b0;
				fd_inst <= 1;
			end
		end
	end
endmodule


module dereg
	(input wire clk,
	input wire rstn,
	input wire [1:0] update,

	input wire [5:0] d_instr,
	input wire [1:0] d_op_type,
	input wire [31:0] d_s,
	input wire [5:0] d_rs,
	input wire [31:0] d_t,
	input wire [5:0] d_rt,
	input wire [31:0] d_imm,
	input wire d_branch,
	input wire d_jump,
	input wire [1:0] d_rw,
	input wire d_is_jr,
	input wire d_stop,
	input wire [4:0] d_rd,
	input wire [4:0] d_wait_time,
	input wire [31:0] d_pc,
	input wire [31:0] d_npc,

	output logic [5:0] de_instr,
	output logic [1:0] de_op_type,
	output logic [31:0] de_s,
	output logic [5:0] de_rs,
	output logic [31:0] de_t,
	output logic [5:0] de_rt,
	output logic [31:0] de_imm,
	output logic de_branch,
	output logic de_jump,
	output logic [1:0] de_rw,
	output logic de_is_jr,
	output logic de_stop,
	output logic [4:0] de_rd,
	output logic [4:0] de_wait_time,
	output logic [31:0] de_pc,
	output logic [31:0] de_npc
);

	always @(posedge clk) begin
		if(~rstn) begin
			de_instr <= 1;
			de_op_type <= 2'b01;
			de_s <= 0;
			de_rs <= 0;
			de_t <= 0;
			de_rt <= 0;
			de_imm <= 0;
			de_branch <= 0;
			de_jump <= 0;
			de_rw <= 0;
			de_is_jr <= 0;
			de_stop <= 0;
			de_rd <= 0;
			de_wait_time <= 0;
			de_pc <= 0;
			de_npc <= 0;
		end
		else begin
			if(update == 2'b01) begin
				de_instr <= d_instr;
				de_op_type <= d_op_type;
				de_s <= d_s;
				de_rs <= d_rs;
				de_t <= d_t;
				de_rt <= d_rt;
				de_imm <= d_imm;
				de_branch <= d_branch;
				de_jump <= d_jump;
				de_rw <= d_rw;
				de_is_jr <= d_is_jr;
				de_stop <= d_stop;
				de_rd <= d_rd;
				de_wait_time <= d_wait_time;
				de_pc <= d_pc;
				de_npc <= d_npc;
			end
			else if(update == 2'b10) begin
				de_instr <= 1;
				de_op_type <= 2'b01;
				de_s <= 0;
				de_rs <= 0;
				de_t <= 0;
				de_rt <= 0;
				de_imm <= 0;
				de_branch <= 0;
				de_jump <= 0;
				de_rw <= 0;
				de_is_jr <= 0;
				de_stop <= 0;
				de_rd <= 0;
				de_wait_time <= 0;
				de_pc <= 0;
				de_npc <= 0;
			end
		end
	end
endmodule


module ewreg
	(input wire clk,
	input wire rstn,
	input wire [1:0] update,

	input wire e_is_jr,
	input wire e_branch,
	input wire [31:0] e_npc,
	input wire [31:0] e_d,
	input wire [1:0] e_rw,
	input wire [4:0] e_rd,

	output logic ew_is_jr,
	output logic ew_branch,
	output logic [31:0] ew_npc,
	output logic [31:0] ew_d,
	output logic [1:0] ew_rw,
	output logic [4:0] ew_rd
);

	always @(posedge clk) begin
		if(~rstn) begin
			ew_is_jr <= 0;
			ew_branch <= 0;
			ew_npc <= 0;
			ew_d <= 0;
			ew_rw <= 0;
			ew_rd <= 0;
		end
		else begin
			if(update == 2'b01) begin
				ew_is_jr <= e_is_jr;
				ew_branch <= e_branch;
				ew_npc <= e_npc;
				ew_d <= e_d;
				ew_rw <= e_rw;
				ew_rd <= e_rd;
			end
			else if(update == 2'b10) begin
				ew_is_jr <= 0;
				ew_branch <= 0;
				ew_npc <= 0;
				ew_d <= 0;
				ew_rw <= 0;
				ew_rd <= 0;
			end
		end
	end
endmodule

`default_nettype wire
