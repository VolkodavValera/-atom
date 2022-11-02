module VGA_OUT(RESET,
					SYNC_COLOR,
					VGA_CLK,
					oVGA_R,
					oVGA_G,
					oVGA_B,
					iVGA_R,
					iVGA_G,
					iVGA_B,
					Current_X,
					Current_Y);
input wire VGA_CLK;
input wire RESET;
input wire SYNC_COLOR;
input wire [9:0]Current_X;
input wire [8:0]Current_Y;
input wire [3:0]iVGA_R;
input wire [3:0]iVGA_G;
input wire [3:0]iVGA_B;
output reg [3:0]oVGA_R;
output reg [3:0]oVGA_G;
output reg [3:0]oVGA_B;
always@(posedge VGA_CLK or negedge RESET)
begin
	
	if(!RESET)
	begin
		oVGA_R	<=	0;
		oVGA_G	<=	0;
		oVGA_B	<=	0;
	end
	else
	begin
				oVGA_R	<=	((SYNC_COLOR == 1)&&(Current_X > 0)&&(Current_Y > 0)) ? iVGA_R : 0;
				oVGA_G	<=	((SYNC_COLOR == 1)&&(Current_X > 0)&&(Current_Y > 0)) ? iVGA_G : 0;
				oVGA_B	<=	((SYNC_COLOR == 1)&&(Current_X > 0)&&(Current_Y > 0)) ? iVGA_B : 0;
	end
end
endmodule