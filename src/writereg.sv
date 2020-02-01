`timescale 1ns / 1ps

module writereg #( parameter CLK_PER_HALF_BIT = 434, parameter INST_SIZE = 10, parameter BRAM_SIZE = 18)
	(input wire clk,
	input wire rstn,
	input wire is_out,
	input wire memtoreg,
	input wire [31:0] douta,
	input wire [31:0] d,
	input wire [4:0] rd,
	output wire txd,
	output wire [31:0] dtowrite);

	parameter TX_SIZE = 12;
	logic [8:0] txbuffer[TX_SIZE**2-1:0];

	logic [TX_SIZE-1:0] txbot;
	logic [TX_SIZE-1:0] txtop;
	logic txwait;

	reg 				 tx_start;
	wire 			 tx_busy;


   // uart_tx #(CLK_PER_HALF_BIT) tx(txbuffer[txbot], tx_start, tx_busy, txd, clk, rstn);

	assign dtowrite = d;

	always @(posedge clk) begin
		if(~rstn) begin
			txbot <= 0;
			txtop <= 0;
			txwait <= 0;
		end
		else begin
			// if (is_out) begin
			// 	txbuffer[txtop] <= dtowrite[7:0];
			// 	txtop <= txtop + 1;
			// end

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
		end
	end
				
endmodule
`default_nettype wire
