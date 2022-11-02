`include "Floating_point.svh"

module Floating_point (clk, rst_n, in_arinc, graf_angle);

input 			clk;
input 			rst_n;
input [11:0]	in_arinc;

output [7:0]	graf_angle;

logic [31:0] 	angle = '0;
logic 			ready;
logic [11:0] 	in_arinc_ff;
int 			i, j, x;

always_ff @(posedge clk) in_arinc_ff <= in_arinc;

always_ff @(posedge clk) begin
	if (!rst_n) begin 
		angle <= '0;
		ready <= '0;
		graf_angle <= '0;
	end
	else if (in_arinc_ff != in_arinc) ready <= 1'b0;
	else begin
		if (!ready) begin
			for (i = 0; i < 12; i++) begin
				x <= (in_arinc[i]) ? Bit_Avalon[i] : '0;
				angle <= sumf (angle, x);
				if (i == 11) ready <= 1;
			end
		end
		else if (angle == 32'h0000_0000) graf_angle <= '0;
		else begin
			for (j = 1; j < 200; j++) begin
				if (angle > Whole_corners[j - 1] && angle <= Whole_corners[j]) graf_angle <= j;
				else if (j == 199) angle <= 32'd200;
			end

		end
	end
end

endmodule: Floating_point