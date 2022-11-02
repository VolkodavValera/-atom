module Avalon_Bridge (clk,
				rst_n,

				// Avalon Side
				in_read,
				in_write,
				in_readdata,
				in_writedata,
				in_address,

				// Output Side
				out_read,
				out_write,
				out_readdata,
				out_writedata,
				out_address
				);

	input 			clk;
	input 			rst_n;
	input 			in_read;
	input 			in_write;
	input	[2:0]	in_address;
	input 	[31:0]	in_writedata;
	input	[31:0]	out_readdata;

	output 			out_read;
	output 			out_write;
	output	[2:0]	out_address;
	output 	[31:0]	out_writedata;
	output	[31:0]	in_readdata;

endmodule
