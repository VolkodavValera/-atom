module	VGA_CIRCLE	(	//	Read Out Side
						oRed,
						oGreen,
						oBlue,
						iVGA_X,
						iVGA_Y,
						iVGA_CLK,

						RAM_Date,
						//	Control Signals
						iRST_n,
						iColor_SW,
						Centre_X,
						Centre_Y,
						Red_color,
						Green_color,
						Blue_color);
//	Read Out Side
output	reg	[9:0]	oRed;
output	reg	[9:0]	oGreen;
output	reg	[9:0]	oBlue;
input	[9:0]		iVGA_X;
input	[8:0]		iVGA_Y;
input	[3:0]		Red_color;
input	[3:0]		Green_color;
input	[3:0]		Blue_color;
input				iVGA_CLK;
input	[11:0]		RAM_Date;
//	Control Signals
input				iRST_n;
input [1:0]			iColor_SW;
input [9:0]	 		Centre_X;
input [8:0] 		Centre_Y;

parameter Radius = 150;
parameter Wight = 640;
parameter Height = 480;
parameter Line_Width = 3;
localparam HEX_Width = 30;
localparam HEX_Height = 30;

// cicle
reg [9:0] ADDR_ROM_reg;
wire [9:0] ADDR_ROM;
wire [11:0] ROM_Q;
wire Read_Circle;
wire Read_ROM;
wire Read_Grid;

assign Read_Circle = (((iVGA_X - Centre_X)  ** 2 + (iVGA_Y - Centre_Y)  ** 2 >= (Radius - Line_Width) ** 2) && ((iVGA_X - Centre_X)  ** 2 + (iVGA_Y - Centre_Y)  ** 2 <= (Radius + Line_Width)** 2)) ? 1 : 0;
assign Read_ROM = (ROM_Q == 12'h000) ? 0 : 1;
assign ADDR_ROM = ADDR_ROM_reg;

always @(*) begin
	if (iVGA_X <= (Centre_X + HEX_Width/2) && iVGA_X >= (Centre_X - HEX_Width/2)  && iVGA_Y <= (Centre_Y + HEX_Height/2) && iVGA_Y >= (Centre_Y - HEX_Height/2)) begin
		ADDR_ROM_reg = (iVGA_Y + HEX_Height/2 - Centre_Y) * HEX_Width + (iVGA_X + HEX_Width/2 - Centre_X);
	end
	else ADDR_ROM_reg = 10'hFFF;
end


ROM_T u6 (.address(ADDR_ROM), .clock(iVGA_CLK), .q(ROM_Q));

VGA_GRID u7(.iVGA_X(iVGA_X), .iVGA_Y(iVGA_Y), .Read_Grid(Read_Grid));
	defparam
		u7.Radius1 = 512,
		u7.Radius2 = 410,
		u7.Radius3 = 320,
		u7.Radius4 = 230,
		u7.Line_Width = 1;


always@(posedge iVGA_CLK or negedge iRST_n)
begin
	if(!iRST_n)
	begin
		oRed	<=	0;
		oGreen	<=	0;
		oBlue	<=	0;
	end
	else
	begin
		if(iColor_SW[0] == 1)
		begin
			if (Read_Grid) begin
				oRed <= 0;
				oGreen <= 0;
				oBlue <= 0;
			end
			else if (Read_ROM) begin
				oRed <= ROM_Q[11:8] + 2*Blue_color;
				oGreen <= ROM_Q[7:4] + 2*Red_color;
				oBlue <= ROM_Q[3:0] + 2*Green_color;
			end
			else if (Read_Circle) begin
				oRed <= Red_color;
				oGreen <= Green_color;
				oBlue <= Blue_color;
			end
			else begin
				oRed	<=	15;
				oGreen	<=	15;
				oBlue	<=	15;
			end
		end
		else if (iColor_SW[1] == 1) begin
			oRed <= RAM_Date[11:8];
			oGreen <= RAM_Date[7:4];
			oBlue <= RAM_Date[3:0];
		end
		else
		begin
			oRed	<=	(iVGA_Y<120)					?			3	:
						(iVGA_Y>=120 && iVGA_Y<240)		?			7	:
						(iVGA_Y>=240 && iVGA_Y<360)		?			11	:
																	15	;
			oGreen	<=	(iVGA_X<80)						?			1	:
						(iVGA_X>=80 && iVGA_X<160)		?			3	:
						(iVGA_X>=160 && iVGA_X<240)		?			5	:
						(iVGA_X>=240 && iVGA_X<320)		?			7	:
						(iVGA_X>=320 && iVGA_X<400)		?			9	:
						(iVGA_X>=400 && iVGA_X<480)		?			11	:
						(iVGA_X>=480 && iVGA_X<560)		?			13	:
																	15	;
			oBlue	<=	(iVGA_Y<60)						?			15	:
						(iVGA_Y>=60 && iVGA_Y<120)		?			13	:
						(iVGA_Y>=120 && iVGA_Y<180)		?			11	:
						(iVGA_Y>=180 && iVGA_Y<240)		?			9	:
						(iVGA_Y>=240 && iVGA_Y<300)		?			7	:
						(iVGA_Y>=300 && iVGA_Y<360)		?			5	:
						(iVGA_Y>=360 && iVGA_Y<420)		?			3	:
																	1	;
		end
	end
end

endmodule

module VGA_GRID (iVGA_X, iVGA_Y, Read_Grid);

parameter Radius1 = 400;
parameter Radius2 = 200;
parameter Radius3 = 100;
parameter Radius4 = 80;
parameter Wight = 640;
parameter Height = 480;
parameter Line_Width = 1;
localparam Centre_X = Wight/2;
localparam Centre_Y = Height;
localparam y_2 = 200;
localparam x_2 = 200;

//	Read Out Side
input	[9:0]		iVGA_X;
input	[8:0]		iVGA_Y;

output Read_Grid;

wire Read_Semicircle1;
wire Read_Semicircle2;
wire Read_Semicircle3;
wire Read_Semicircle4;
wire Read_Cell1;
wire Read_Cell2;
wire Read_Cell3;
wire Read_Cell4;
wire Read_Cell5;
wire Read_Cell6;

integer i, y_i;

assign Read_Semicircle1 = (((iVGA_X - Centre_X)  ** 2 + (iVGA_Y - Centre_Y)  ** 2 >= (Radius1 - Line_Width) ** 2) && ((iVGA_X - Centre_X)  ** 2 + (iVGA_Y - Centre_Y)  ** 2 <= (Radius1 + Line_Width)** 2)) ? 1 : 0;
assign Read_Semicircle2 = (((iVGA_X - Centre_X)  ** 2 + (iVGA_Y - Centre_Y)  ** 2 >= (Radius2 - Line_Width) ** 2) && ((iVGA_X - Centre_X)  ** 2 + (iVGA_Y - Centre_Y)  ** 2 <= (Radius2 + Line_Width)** 2)) ? 1 : 0;
assign Read_Semicircle3 = (((iVGA_X - Centre_X)  ** 2 + (iVGA_Y - Centre_Y)  ** 2 >= (Radius3 - Line_Width) ** 2) && ((iVGA_X - Centre_X)  ** 2 + (iVGA_Y - Centre_Y)  ** 2 <= (Radius3 + Line_Width)** 2)) ? 1 : 0;
assign Read_Semicircle4 = (((iVGA_X - Centre_X)  ** 2 + (iVGA_Y - Centre_Y)  ** 2 >= (Radius4 - Line_Width) ** 2) && ((iVGA_X - Centre_X)  ** 2 + (iVGA_Y - Centre_Y)  ** 2 <= (Radius4 + Line_Width)** 2)) ? 1 : 0;
assign Read_Cell1 = ((iVGA_X - Centre_X) + Centre_Y <= iVGA_Y + Line_Width && (iVGA_X - Centre_X) + Centre_Y >= iVGA_Y - Line_Width) ? 1 : 0;
assign Read_Cell2 = (2*(iVGA_X - Centre_X) + Centre_Y <= iVGA_Y + Line_Width && 2*(iVGA_X - Centre_X) + Centre_Y >= iVGA_Y - Line_Width) ? 1 : 0;
assign Read_Cell3 = (6*(iVGA_X - Centre_X) + Centre_Y <= iVGA_Y + 3*Line_Width && 6*(iVGA_X - Centre_X) + Centre_Y >= iVGA_Y - 3*Line_Width) ? 1 : 0;
assign Read_Cell4 = (-(iVGA_X - Centre_X) + Centre_Y <= iVGA_Y + Line_Width && -(iVGA_X - Centre_X) + Centre_Y >= iVGA_Y - Line_Width) ? 1 : 0;
assign Read_Cell5 = (-2*(iVGA_X - Centre_X) + Centre_Y <= iVGA_Y + Line_Width && -2*(iVGA_X - Centre_X) + Centre_Y >= iVGA_Y - Line_Width) ? 1 : 0;
assign Read_Cell6 = (-6*(iVGA_X - Centre_X) + Centre_Y <= iVGA_Y + 3*Line_Width && -6*(iVGA_X - Centre_X) + Centre_Y >= iVGA_Y - 3*Line_Width) ? 1 : 0;

assign Read_Grid = Read_Semicircle1 || Read_Semicircle2 || Read_Semicircle3 || Read_Semicircle4 || Read_Cell1 || Read_Cell2 || Read_Cell3 || Read_Cell4 || Read_Cell5 || Read_Cell6;


endmodule