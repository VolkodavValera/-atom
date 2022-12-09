module VGA_SYNC(
						input CLK,
						input SYNC_RST_N,
						output reg H_SYNC_CLK,
						output reg V_SYNC_CLK,
						output wire [9:0]oCurrent_X,
						output wire [8:0]oCurrent_Y,
						output reg oSYNC_COLOR);
parameter A_TIME_H = 24;
parameter B_TIME_H = 95;
parameter C_TIME_H = 48;
parameter D_TIME_H = 640;
parameter TOTAL_TIME_H = A_TIME_H + B_TIME_H + C_TIME_H + D_TIME_H;
parameter BLANK_H = A_TIME_H + B_TIME_H + C_TIME_H;

parameter A_TIME_V = 10;
parameter B_TIME_V = 2;
parameter C_TIME_V = 33;
parameter D_TIME_V = 480;
parameter TOTAL_TIME_V = A_TIME_V + B_TIME_V + C_TIME_V + D_TIME_V;
parameter BLANK_V = A_TIME_V + B_TIME_V + C_TIME_V;

reg 			[9:0]H_Counter;
reg 			[8:0]V_Counter;

assign	oCurrent_X	=	(H_Counter >= BLANK_H)	?	H_Counter-BLANK_H	:	10'h0	;
assign	oCurrent_Y	=	(V_Counter >= BLANK_V)	?	V_Counter-BLANK_V	:	9'h0	;

always@(posedge(CLK) or negedge(SYNC_RST_N))
begin
	if(!SYNC_RST_N)
	begin
		H_Counter	<=	1'b0;
		H_SYNC_CLK	<=	1'b1;
	end
	else
	begin
		if(H_Counter < (TOTAL_TIME_H-1))
		H_Counter	<=	H_Counter + 1'b1;
		else
			begin
			H_Counter	<=	1'b0;
			oSYNC_COLOR <= 1'b0;
			end
		if(H_Counter == A_TIME_H-1)
		H_SYNC_CLK	<=	1'b0;
		if(H_Counter == A_TIME_H + B_TIME_H-1)
		H_SYNC_CLK	<=	1'b1;
		if(H_Counter == BLANK_H)
		oSYNC_COLOR <= 1'b1;
	end
end

always@(posedge(H_SYNC_CLK) or negedge(SYNC_RST_N))
begin
	if(!SYNC_RST_N)
	begin
		V_Counter	<=	1'b0;
		V_SYNC_CLK	<=	1'b1;
	end
	else
	begin
		if(V_Counter < (TOTAL_TIME_V-1))
		V_Counter	<=	V_Counter + 1'b1;
		else
		V_Counter	<=	1'b0;
		if(V_Counter == A_TIME_V-1)
		V_SYNC_CLK	<=	1'b0;
		if(V_Counter == A_TIME_V + B_TIME_V-1)
		V_SYNC_CLK	<=	1'b1;
	end
end
endmodule
