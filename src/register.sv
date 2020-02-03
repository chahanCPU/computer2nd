`timescale 1ns / 1ps

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
			fd_pc <= 0;
			fd_inst <= 0;
		end
		else begin
			if(update == 2'b01) begin
				fd_pc <= f_pc;
				fd_inst <= f_inst;
			end
			else if(update == 2'b10) begin
				fd_pc <= 0;
				fd_inst <= 0;
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
	input wire [31:0] d_t,
	input wire [31:0] d_imm,
	input wire d_branch,
	input wire d_jump,
	input wire [1:0] d_rw,
	input wire d_is_jr,
	input wire d_stop,
	input wire [4:0] d_rd,
	input wire [31:0] d_pc,

	output logic [5:0] de_instr,
	output logic [1:0] de_op_type,
	output logic [31:0] de_s,
	output logic [31:0] de_t,
	output logic [31:0] de_imm,
	output logic de_branch,
	output logic de_jump,
	output logic [1:0] de_rw,
	output logic de_is_jr,
	output logic de_stop,
	output logic [4:0] de_rd,
	output logic [31:0] de_pc
);

	always @(posedge clk) begin
		if(~rstn) begin
			de_instr <= 0;
			de_op_type <= 1;
			de_s <= 0;
			de_t <= 0;
			de_imm <= 0;
			de_branch <= 0;
			de_jump <= 0;
			de_rw <= 0;
			de_is_jr <= 0;
			de_stop <= 0;
			de_rd <= 0;
			de_pc <= 0;
		end
		else begin
			if(update == 2'b01) begin
				de_instr <= d_instr;
				de_op_type <= d_op_type;
				de_s <= d_s;
				de_t <= d_t;
				de_imm <= d_imm;
				de_branch <= d_branch;
				de_jump <= d_jump;
				de_rw <= d_rw;
				de_is_jr <= d_is_jr;
				de_stop <= d_stop;
				de_rd <= d_rd;
				de_pc <= d_pc;
			end
			else if(update == 2'b10) begin
				de_instr <= 0;
				de_op_type <= 1;
				de_s <= 0;
				de_t <= 0;
				de_imm <= 0;
				de_branch <= 0;
				de_jump <= 0;
				de_rw <= 0;
				de_is_jr <= 0;
				de_stop <= 0;
				de_rd <= 0;
				de_pc <= 0;
			end
		end
	end
endmodule


module ewreg
	(input wire clk,
	input wire rstn,
	input wire [1:0] update,

	input wire [31:0] e_d,
	input wire [1:0] e_rw,
	input wire [4:0] e_rd,

	output logic [31:0] ew_d,
	output logic [1:0] ew_rw,
	output logic [4:0] ew_rd
);

	always @(posedge clk) begin
		if(~rstn) begin
			ew_d <= 0;
			ew_rw <= 0;
			ew_rd <= 0;
		end
		else begin
			if(update == 2'b01) begin
				ew_d <= e_d;
				ew_rw <= e_rw;
				ew_rd <= e_rd;
			end
			else if(update == 2'b10) begin
				ew_d <= 0;
				ew_rw <= 0;
				ew_rd <= 0;
			end
		end
	end
endmodule

`default_nettype wire
