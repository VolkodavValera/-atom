module VGA_Controller (clk_vga,
					rst_n,
					address_vga,
					data,
					VGA_HS,
					VGA_VS,
					VGA_R,
					VGA_G,
					VGA_B,
					SW);

parameter	Radius = 75;
parameter	Wight = 640;
parameter	Height = 480;
parameter	Line_Width = 2;
parameter	Speed = 32'h3_7FFF;
parameter	Speed_color = 32'h40;

input 			clk_vga;
input 			rst_n;
input 	[1:0]	SW;
input 	[11:0]	data;
output	[18:0]	address_vga;
output			VGA_HS;					//	VGA H_SYNC
output			VGA_VS;					//	VGA V_SYNC
output	[3:0]	VGA_R;   				//	VGA Red[3:0]
output	[3:0]	VGA_G;	 				//	VGA Green[3:0]
output	[3:0]	VGA_B;   				//	VGA Blue[3:0]

wire 			H_SYNC_CLK;
wire 			V_SYNC_CLK;
wire 	[9:0]	Current_X;
wire 	[8:0] 	Current_Y;
wire 			SYNC_COLOR;
reg		[3:0]	iVGA_R;
reg		[3:0]	iVGA_G;
reg		[3:0]	iVGA_B;
wire 	[3:0]	irVGA_R;
wire	[3:0]	irVGA_G;
wire	[3:0]	irVGA_B;
wire 	[9:0] 	Centre_X;
wire 	[8:0] 	Centre_Y;
wire 	[3:0] 	Red_color;
wire 	[3:0]	Green_color;
wire 	[3:0] 	Blue_color;
wire 	[18:0]	X;
wire 	[18:0]	Y;

assign irVGA_R[3:0] = iVGA_R[3:0];
assign irVGA_G[3:0] = iVGA_G[3:0];
assign irVGA_B[3:0] = iVGA_B[3:0];
assign VGA_HS = H_SYNC_CLK;
assign VGA_VS = V_SYNC_CLK;
/*assign X = {9'h00, Current_X};
assign Y = {10'h00, Current_Y};*/
assign address_vga = (Current_Y - 1) * Wight + Current_X - 1;

VGA_SYNC u2
(	.CLK(clk_vga),
	.H_SYNC_CLK(H_SYNC_CLK),
	.V_SYNC_CLK(V_SYNC_CLK),
	.SYNC_RST_N(rst_n),
	.oCurrent_X(Current_X),
	.oCurrent_Y(Current_Y),
	.oSYNC_COLOR(SYNC_COLOR)
);

VGA_OUT u3
(
.oVGA_R(VGA_R[3:0]),
.oVGA_G(VGA_G[3:0]),
.oVGA_B(VGA_B[3:0]),
.iVGA_R(iVGA_R[3:0]),
.iVGA_G(iVGA_G[3:0]),
.iVGA_B(iVGA_B[3:0]),
.VGA_CLK(clk_vga),
.Current_X(Current_X),
.Current_Y(Current_Y),
.SYNC_COLOR(SYNC_COLOR),
.RESET(rst_n)
);

VGA_CIRCLE u4(	.iVGA_CLK(clk_vga),
				.iRST_n(rst_n),

				.oRed(irVGA_R),
				.oGreen(irVGA_G),
				.oBlue(irVGA_B),

				.iVGA_X(Current_X),
				.iVGA_Y(Current_Y),


				.iColor_SW(SW),
				.RAM_Date(data),

				.Centre_X(Centre_X),
				.Centre_Y(Centre_Y),
				.Red_color(Red_color),
				.Green_color(Green_color),
				.Blue_color(Blue_color));
	defparam
		u4.Radius = Radius,
		u4.Wight = Wight,
		u4.Height = Height,
		u4.Line_Width = Line_Width;

CENTER_MOVEMENT u5 (.clk(clk_vga),
						.rst(rst_n),
						.Centre_X(Centre_X),
						.Centre_Y(Centre_Y),
						.Red_color(Red_color),
						.Green_color(Green_color),
						.Blue_color(Blue_color));
	defparam
		u5.Radius = Radius,
		u5.Wight = Wight,
		u5.Height = Height,
		u5.Line_Width = Line_Width,
		u5.Speed = Speed,
		u5.Speed_color = Speed_color;

endmodule: VGA_Controller

module CENTER_MOVEMENT (clk, rst, Centre_X, Centre_Y, Red_color, Green_color, Blue_color);

parameter Radius = 150;
parameter Wight = 640;
parameter Height = 480;
parameter Line_Width = 3;
parameter Speed = 32'h1F_FFFF;
parameter Speed_color = 32'h32;
localparam START_CENTR = Radius + Line_Width;

input clk;
input rst;

output [9:0] Centre_X;
output [8:0] Centre_Y;
output [3:0] Red_color;
output [3:0] Green_color;
output [3:0] Blue_color;

reg [9:0] Centre_X_reg;
reg [8:0] Centre_Y_reg;
reg [3:0] Red_color_reg;
reg [3:0] Green_color_reg;
reg [3:0] Blue_color_reg;
reg [31:0] cnt;
reg [31:0] cnt_color;
reg shift = 0;
reg shift_color = 0;
reg state_x = 0;
reg state_y = 0;
reg state_red = 0;
reg state_green = 0;
reg state_blue = 0;
wire y_more, x_more, y_less, x_less;

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		cnt <= 32'b0;
		shift <= 1'b0;
	end
	else if (cnt == Speed) begin
		cnt <= 32'b0;
		shift <= 1'b1;
	end
	else begin
		shift <= 1'b0;
		cnt <= cnt + 1;
	end
end

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		cnt_color <= 32'b0;
		shift_color <= 1'b0;
	end
	else if (cnt_color == Speed_color*Speed) begin
		cnt_color <= 32'b0;
		shift_color <= 1'b1;
	end
	else begin
		shift_color <= 1'b0;
		cnt_color <= cnt_color + 1;
	end
end

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		Centre_X_reg <= START_CENTR;
		state_x <= 0;
	end
	else if (shift) begin
		case (state_x)
			0: begin
				if (x_more) Centre_X_reg <= Centre_X_reg + 3;
				else state_x <= 1;
			end
			1: begin
				if (x_less) Centre_X_reg <= Centre_X_reg - 3;
				else state_x <= 0;
			end
		endcase
	end
end

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		Centre_Y_reg <= START_CENTR;
		state_y <= 0;
	end
	else if (shift) begin
		case (state_y)
			0: begin
				if (y_more) Centre_Y_reg <= Centre_Y_reg + 1;
				else state_y <= 1;
			end
			1: begin
				if (y_less) Centre_Y_reg <= Centre_Y_reg - 3;
				else state_y <= 0;
			end
		endcase
	end
end

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		Red_color_reg <= 0;
		state_red <= 0;
	end
	else if (shift_color) begin
		case (state_red)
			0: begin
				if (Red_color_reg < 15) Red_color_reg <= Red_color_reg + 1;
				else state_red <= 1;
			end
			1: begin
				if (Red_color_reg >= 15) Red_color_reg <= Red_color_reg - 3;
				else state_red <= 0;
			end
		endcase
	end
end

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		Green_color_reg <= 0;
		state_green <= 0;
	end
	else if (shift_color) begin
		case (state_green)
			0: begin
				if (Green_color_reg < 15) Green_color_reg <= Green_color_reg + 2;
				else state_green <= 1;
			end
			1: begin
				if (Green_color_reg >= 15) Green_color_reg <= Green_color_reg - 3;
				else state_green <= 0;
			end
		endcase
	end
end

always @(posedge clk or negedge rst) begin
	if (!rst) begin
		Blue_color_reg <= 0;
		state_blue <= 0;
	end
	else if (shift_color) begin
		case (state_blue)
			0: begin
				if (Blue_color_reg < 15) Blue_color_reg <= Blue_color_reg + 3;
				else state_blue <= 1;
			end
			1: begin
				if (Blue_color_reg >= 15) Blue_color_reg <= Blue_color_reg - 2;
				else state_blue <= 0;
			end
		endcase
	end
end

assign y_more = Centre_Y < (Height - START_CENTR);
assign x_more = Centre_X < (Wight - START_CENTR);
assign y_less = Centre_Y >= START_CENTR;
assign x_less = Centre_X >= START_CENTR;

assign Centre_X = Centre_X_reg;
assign Centre_Y = Centre_Y_reg;
assign Red_color = Red_color_reg;
assign Green_color = Green_color_reg;
assign Blue_color = Blue_color_reg;

endmodule
