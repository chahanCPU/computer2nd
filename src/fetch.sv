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



	logic [INST_SIZE-1:0] pc_main;

	reg [31:0] inst_mem[(2 ** INST_SIZE - 1) : 0];


	assign inst = inst_mem[pc[INST_SIZE+1:2]];

	logic [INST_SIZE - 1 : 0] addra;
	logic [INST_SIZE - 1 : 0] ppaddra;
	logic [31:0] dina;
	logic [0:0] wea;
	logic [31:0] douta;

	logic [1:0] latancy;

	INST_BRAM _INST_BRAM (
		.addra (addra),
		.dina (dina),
		.wea (wea),
		.clka (clk),
		.douta (douta));

	always @(posedge clk) begin
		if(~rstn) begin
			done <= 0;
			latancy <= 0;
			addra <= 0;
			ppaddra <= 0;
			dina <= 0;
			wea <= 0;
		end
		else begin
			if(mode == LOAD) begin
				if(~done) begin
					if(addra == {INST_SIZE{1'b1}}) begin
						done <= 1;
					end
					if(addra >= 2) begin
						inst_mem[ppaddra] <= douta;
						ppaddra <= ppaddra + 1;
					end
					addra <= addra + 1;
				end
			end
			else begin
				pc_main <= pc[INST_SIZE+1:2];
			end
		end
	end

endmodule
`default_nettype wire
