`timescale 1ns / 1ps

import constant::*;

module fetch #( parameter CLK_PER_HALF_BIT = 434)
	(input wire clk,
	input wire [2:0] mode,
	input wire [31:0] pc,
	input wire rstn,
	output wire [31:0] inst,
	output logic done);

	localparam STALL = 0;
	localparam LOAD = 1;
	localparam EXEC = 2;


	logic [INST_SIZE-1:0] addra;
	logic [31:0] dina;
	logic wea;

	assign dina = 0;
	assign wea = 0;
	assign done = 1;
	
	assign addra = pc[INST_SIZE+1:2];

	INST_BRAM _INST_BRAM (
		.addra (addra),
		.dina (dina),
		.wea (wea),
		.clka (clk),
		.douta (inst));


endmodule
`default_nettype wire
