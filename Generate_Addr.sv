module Generate_Addr (clk, rst_n, angle, ADDR_RAM_WRITE, RAM_WRITE, FIFO_READ);

/*------------------------------------------------------*/
/*						Parameters						*/
/*------------------------------------------------------*/
parameter 	WIDHT 		= 640;
parameter 	HEIGH 		= 480;
parameter 	WIDHT_ANGLE	= 8;
parameter 	SIZE_ARINC	= 512;
localparam 	Centre_X 	= WIDHT/2;
localparam 	Centre_Y 	= HEIGH;

/*------------------------------------------------------*/
/*						Input							*/
/*------------------------------------------------------*/
input 				clk;
input 				rst_n;
input 	[11:0]		angle;

/*------------------------------------------------------*/
/*						Output							*/
/*------------------------------------------------------*/
output 	[18:0]		ADDR_RAM_WRITE;
output				RAM_WRITE;
output 				FIFO_READ;

/*------------------------------------------------------*/
/*						Variables						*/
/*------------------------------------------------------*/
logic 	[31:0] 		X;
logic 	[31:0] 		Y;
logic 	[31:0] 		Radius;
logic 	[31:0]		MIN_X;
logic 	[31:0]		MAX_X;
logic 	[31:0]		MIN_Y;
logic 	[31:0]		MAX_Y;

wire 	[31:0] 		intermediate_value;

logic 				angle_reg1;
logic 				angle_reg2;
logic 				start;

wire 				Read_Line;
wire 				Read_Semicircle1;

logic				Rectangle1;
logic				Rectangle2;
logic 	[31:0]		Coordinates_point1_x;
logic 	[31:0]		Coordinates_point1_y;
logic 	[31:0]		Coordinates_point2_x;
logic 	[31:0]		Coordinates_point2_y;
logic 	[31:0]		dX1;
logic 	[31:0]		dY1;
logic 	[31:0]		mul1;
logic 	[31:0]		dX2;
logic 	[31:0]		dY2;
logic 	[31:0]		mul2;

/*------------------------------------------------------*/
/*						Сonnections						*/
/*------------------------------------------------------*/
assign ADDR_RAM_WRITE = (Y - 1) * HEIGH + X;
assign Read_Line = ( (X - Centre_X)  ** 2 + (Y - Centre_Y)  ** 2 == Radius ** 2 ) ? 1 : 0;
assign intermediate_value = angle * WIDHT_ANGLE;
assign RAM_WRITE = ( Read_Line && Rectangle1 && Rectangle2 && start) ? 1 : 0;

/*------------------------------------------------------*/
/*						Always blocks					*/
/*------------------------------------------------------*/

// Delay
always_ff @(posedge clk) begin
	angle_reg1 <= angle;
	angle_reg2 <= angle_reg1;
end

// Occasum initialis values
always_ff @(posedge clk) begin
	if (!rst_n) begin
		MIN_X <= 32'h0000_0001;
		MAX_X <= 32'h0000_0001;
		MIN_Y <= 32'h0000_0001;
		MAX_Y <= 32'h0000_0001;
	end
	else if (Radius == 512 && RAM_WRITE) begin
		MIN_X <= 32'h0000_0001;
		MAX_X <= 32'h0000_0001;
		MIN_Y <= 32'h0000_0001;
		MAX_Y <= 32'h0000_0001;
	end
	else if (angle_reg1 != angle) begin

		if (intermediate_value < HEIGH) begin
			MIN_X <= 32'h0000_0001;
			MAX_X <= Centre_X;
			MIN_Y <= Centre_Y - (intermediate_value + WIDHT_ANGLE);
			MAX_Y <= Centre_Y;
		end

		else if (intermediate_value - HEIGH < Centre_X) begin
			MIN_X <= intermediate_value - HEIGH;
			MAX_X <= Centre_X;
			MIN_Y <= 32'h0000_0001;
			MAX_Y <= Centre_Y;
		end

		else if (intermediate_value - HEIGH < WIDHT) begin
			MIN_X <= Centre_X;
			MAX_X <= (intermediate_value + WIDHT_ANGLE) - HEIGH;
			MIN_Y <= 32'h0000_0001;
			MAX_Y <= Centre_Y;
		end

		else begin
			MIN_X <= Centre_X;
			MAX_X <= WIDHT;
			MIN_Y <= intermediate_value - (WIDHT + HEIGH + WIDHT_ANGLE);
			MAX_Y <= Centre_Y;
		end

	end
end

// Coordinate grid
always_ff @(posedge clk) begin

	if (!rst_n) begin
		X <= 32'h0000_0001;
		Y <= 32'h0000_0001;
		Radius <= 32'h0000_0001;
	end

	else if (angle_reg1 != angle) begin
		Radius <= 32'h0000_0001;
		start <= 1'b1;
		FIFO_READ <= 1'b1;
	end

	else if (angle_reg2 != angle_reg1) begin
		X <= MIN_X;
		Y <= MIN_Y;
		FIFO_READ <= 1'b0;
	end

	else if (start) begin

		if (Y == MAX_Y && X == MAX_X) begin

			if (Radius == 32'd512) begin
				Radius <= 32'h0000_0001;
				start <= 1'b0;
			end

			else begin
				FIFO_READ <= 1'b1;
				Radius++;
				X <= MIN_X;
				Y <= MIN_Y;
			end

		end

		else begin

			FIFO_READ <= 1'b0;

			if (X == MAX_X) begin
				X <= MIN_X;
				Y++;
			end

			else X++;

		end
	end
end

always @(*) begin

	if (intermediate_value < HEIGH) begin

		Coordinates_point1_x 	= 32'h0000_0000;
		Coordinates_point1_y 	= HEIGH - intermediate_value;

		if (intermediate_value + WIDHT_ANGLE < HEIGH) begin

			Coordinates_point2_x 	= 32'h0000_0000;
			Coordinates_point2_y	= HEIGH - (intermediate_value + WIDHT_ANGLE);

			dX1 					= Centre_X;
			dY1						= Centre_Y - Coordinates_point1_y;
			mul1 					= Centre_X * Coordinates_point1_y;

			dX2 					= Centre_X;
			dY2 					= Centre_Y - Coordinates_point2_y;
			mul2 					= Centre_X * Coordinates_point2_y;

			Rectangle1 				= ( ( dX1 * Y <= dY1 * X + mul1 ) ) ? 1 : 0; // 1'b1;
			Rectangle2 				= ( ( dX2 * Y >= dY2 * X + mul2 ) ) ? 1 : 0; // 1'b1;

		end
		else begin

			Coordinates_point2_x 	= intermediate_value + WIDHT_ANGLE - HEIGH;
			Coordinates_point2_y	= 32'h0000_0000;

			dX1 					= Centre_X;
			dY1						= Centre_Y - Coordinates_point1_y;
			mul1 					= Centre_X * Coordinates_point1_y;

			dX2 					= Centre_X - Coordinates_point2_x;
			dY2 					= Centre_Y;
			mul2 					= Centre_Y * Coordinates_point2_x;

			Rectangle1 				= ( ( dX1 * Y <= dY1 * X + mul1 ) ) ? 1 : 0; // 1'b1;
			Rectangle2 				= ( ( dX2 * Y >= dY2 * X + mul2 ) || ( X < (~mul2 + 1)/dY2 ) ) ? 1 : 0;

		end
	end

	else if (intermediate_value < HEIGH + WIDHT - Centre_X) begin

		Coordinates_point1_x 	= intermediate_value - HEIGH;
		Coordinates_point1_y 	= 32'h0000_0000;
		Coordinates_point2_x 	= intermediate_value + WIDHT_ANGLE - HEIGH;
		Coordinates_point2_y	= 32'h0000_0000;

		if (intermediate_value + WIDHT_ANGLE < HEIGH + WIDHT - Centre_X) begin
			dX1 					= Centre_X - Coordinates_point1_x;
			dY1						= Centre_Y;
			mul1 					= Centre_Y * Coordinates_point1_x;

			dX2 					= Centre_X - Coordinates_point2_x;
			dY2 					= Centre_Y;
			mul2 					= Centre_Y * Coordinates_point2_x;

			Rectangle1 				= ( ( dX1 * Y <= dY1 * X - mul1 ) && ( X > mul1/dY1 ) ) ? 1 : 0; // 1'b1;
			Rectangle2 				= ( ( dX2 * Y >= dY2 * X - mul2 ) || ( X < mul2/dY2 ) ) ? 1 : 0; //1'b1;
		end

		else begin
			dX1 					= Centre_X - Coordinates_point1_x;
			dY1						= Centre_Y;
			mul1 					= Centre_Y * Coordinates_point1_x;

			dX2 					= Coordinates_point2_x - Centre_X;
			dY2 					= Centre_Y;
			mul2 					= Centre_Y * Coordinates_point2_x;

			Rectangle1 				= ( ( dX1 * Y <= dY1 * X - mul1 ) && ( X > mul1/dY1 ) ) ? 1 : 0; // 1'b1;
			Rectangle2 				= ( ( dX2 * Y <= mul2 - dY2 * X ) && ( X < mul2/dY2 ) ) ? 1 : 0;
		end

	end

	else if (intermediate_value < HEIGH + WIDHT) begin

		Coordinates_point1_x 	= intermediate_value - HEIGH;
		Coordinates_point1_y 	= 32'h0000_0000;

		if (intermediate_value + WIDHT_ANGLE < HEIGH + WIDHT) begin

			Coordinates_point2_x 	= intermediate_value + WIDHT_ANGLE - HEIGH;
			Coordinates_point2_y	= 32'h0000_0000;

			dX1 					= Coordinates_point1_x - Centre_X;
			dY1						= Centre_Y;
			mul1 					= Centre_Y * Coordinates_point1_x;

			dX2 					= Coordinates_point2_x - Centre_X;
			dY2 					= Centre_Y;
			mul2 					= Centre_Y * Coordinates_point2_x;

			Rectangle1 				= ( ( dX1 * Y >= mul1 - dY1 * X ) || ( X > mul1/dY1 ) ) ? 1 : 0; //1'b1;
			Rectangle2 				= ( ( dX2 * Y <= mul2 - dY2 * X ) && ( X < mul2/dY2 ) ) ? 1 : 0; // 1'b1;

		end

		else begin

			Coordinates_point2_x 	= WIDHT;
			Coordinates_point2_y	= intermediate_value + WIDHT_ANGLE - (WIDHT + HEIGH);

			dX1 					= Coordinates_point1_x - Centre_X;
			dY1						= Centre_Y;
			mul1 					= Centre_Y * Coordinates_point1_x;

			dX2 					= Coordinates_point2_x - Centre_X;
			dY2 					= Centre_Y - Coordinates_point2_y;
			mul2 					= Centre_Y * Coordinates_point2_x - Centre_X * Coordinates_point2_y;

			Rectangle1 				= ( ( dX1 * Y >= mul1 - dY1 * X ) || ( X > mul1/dY1 ) ) ? 1 : 0; //1'b1;
			Rectangle2 				= ( ( dX2 * Y <= mul2 - dY2 * X ) && ( X < mul2/dY2 ) ) ? 1 : 0; // 1'b1;

		end

	end

	else begin

		Coordinates_point1_x 	= WIDHT;
		Coordinates_point1_y 	= intermediate_value - (WIDHT + HEIGH);
		Coordinates_point2_x 	= WIDHT;
		Coordinates_point2_y	= intermediate_value + WIDHT_ANGLE - (WIDHT + HEIGH);

		dX1 					= Coordinates_point1_x - Centre_X;
		dY1						= Centre_Y - Coordinates_point1_y;
		mul1 					= Centre_Y * Coordinates_point1_x - Centre_X * Coordinates_point1_y;

		dX2 					= Coordinates_point2_x - Centre_X;
		dY2 					= Centre_Y - Coordinates_point2_y;
		mul2 					= Centre_Y * Coordinates_point2_x - Centre_X * Coordinates_point2_y;

		Rectangle1 				= ( ( dX1 * Y >= mul1 - dY1 * X ) || ( X > mul1/dY1 ) ) ? 1 : 0; //1'b1;
		Rectangle2 				= ( ( dX2 * Y <= mul2 - dY2 * X ) && ( X < mul2/dY2 ) ) ? 1 : 0; // 1'b1;
	end
end

endmodule: Generate_Addr
