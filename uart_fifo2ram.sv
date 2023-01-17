module uart_fifo2ram (
    // Clock
    clk,

    // Asynchronous reset active low
    rst_n,

    angle,
    fifo_q,
    read_fifo,
    address_ram,
    write_ram,
    ram_data,
    fifo_empty,
    fifo_full
    );
    /*----------------------------------------------------------------------------------*/
    /*									Parameters										*/
    /*----------------------------------------------------------------------------------*/
    parameter   Wight             = 640;
    parameter   Height            = 480;
    parameter   WIDGH_ANGLE       = 4;
    parameter   WIDGH_LINE        = 1;

    localparam  PERIMETER         = Wight + 2*Height;
    localparam  HALF_METER        = Wight/2 + Height;
    localparam  Centre_X          = Wight/2;
    localparam  Centre_Y          = Height;
    /*----------------------------------------------------------------------------------*/
    /*									Input											*/
    /*----------------------------------------------------------------------------------*/
    input							clk;
    input							rst_n;

    input [2:0]                     fifo_q;
    input [8:0]                     angle;
    input                           fifo_empty;
    input                           fifo_full;

    /*----------------------------------------------------------------------------------*/
    /*									Output											*/
    /*----------------------------------------------------------------------------------*/
    output [2:0]                    ram_data;
    output                          read_fifo;
    output                          write_ram;
    output [18:0]                   address_ram;

    /*----------------------------------------------------------------------------------*/
    /*									Variables										*/
    /*----------------------------------------------------------------------------------*/
    wire                            zero_coordinate;
    wire                            rigth_left;
    wire                            checking_radius;
    wire  [31:0]                    coordinate;
    wire  [9:0]                     range_x;
    wire  [8:0]                     range_y;

    logic [8:0]                     cnt_data;
    logic                           stop_read_fifo;

    logic [9:0]                     X;
    logic [8:0]                     Y;

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

    /*----------------------------------------------------------------------------------*/
    /*									Сonnections										*/
    /*----------------------------------------------------------------------------------*/
    assign zero_coordinate = (angle * WIDGH_ANGLE);
    assign rigth_left = (zero_coordinate >= HALF_METER) ? 1 : 0;
    assign coordinate = ((X - Centre_X)**2 + (Centre_Y - Y)**2);
    assign checking_radius = ((coordinate <= cnt_data**2 + WIDGH_LINE) && (coordinate >= cnt_data**2 - WIDGH_LINE)) ? 1 : 0;
    assign address_ram = (Y*Wight + X);
    assign ram_data = (fifo_q);
    assign range_x = (rigth_left) ? Centre_X + cnt_data : Centre_X - cnt_data;
    assign range_y = (Centre_Y - cnt_data);
    assign write_ram = (checking_radius && Rectangle1 && Rectangle2) ? 1 : 0;
    assign read_fifo = (!stop_read_fifo) ? 1 : 0;

    /*----------------------------------------------------------------------------------*/
    /*									Always blocks									*/
    /*----------------------------------------------------------------------------------*/
    always_ff @ (posedge clk) begin
        if (!rst_n) cnt_data <= 9'd1;
        else if (fifo_empty || fifo_full) cnt_data <= 9'd1;
        else if (!stop_read_fifo) cnt_data++;
    end

    always_ff @ (posedge clk) begin
        if (!rst_n) begin
            X <= Centre_X;
            Y <= Centre_Y;
            stop_read_fifo <= '0;
        end
        else if (fifo_full) stop_read_fifo <= '0;
        else if (!stop_read_fifo) stop_read_fifo <= 1'b1;
        else if (!rigth_left) begin
            if (X == range_x) begin
                X <= Centre_X;

                if (Y == range_y) begin
                    stop_read_fifo <= '0;
                    Y <= Centre_Y;
                end
                else Y--;
            end
            else X--;
        end
        else begin
            if (X == range_x) begin
                X <= Centre_X;

                if (Y == range_y) begin
                    stop_read_fifo <= '0;
                    Y <= Centre_Y;
                end
                else Y--;
            end
            else X++;
        end
    end


    always @(*) begin

    	if (zero_coordinate < Height) begin

    		Coordinates_point1_x 	= 32'h0000_0000;
    		Coordinates_point1_y 	= Height - zero_coordinate;

    		if (zero_coordinate + WIDGH_ANGLE < Height) begin

    			Coordinates_point2_x 	= 32'h0000_0000;
    			Coordinates_point2_y	= Height - (zero_coordinate + WIDGH_ANGLE);

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

    			Coordinates_point2_x 	= zero_coordinate + WIDGH_ANGLE - Height;
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

    	else if (zero_coordinate < Height + Wight - Centre_X) begin

    		Coordinates_point1_x 	= zero_coordinate - Height;
    		Coordinates_point1_y 	= 32'h0000_0000;
    		Coordinates_point2_x 	= zero_coordinate + WIDGH_ANGLE - Height;
    		Coordinates_point2_y	= 32'h0000_0000;

    		if (zero_coordinate + WIDGH_ANGLE < Height + Wight - Centre_X) begin
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

    	else if (zero_coordinate < Height + Wight) begin

    		Coordinates_point1_x 	= zero_coordinate - Height;
    		Coordinates_point1_y 	= 32'h0000_0000;

    		if (zero_coordinate + WIDGH_ANGLE < Height + Wight) begin

    			Coordinates_point2_x 	= zero_coordinate + WIDGH_ANGLE - Height;
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

    			Coordinates_point2_x 	= Wight;
    			Coordinates_point2_y	= zero_coordinate + WIDGH_ANGLE - (Wight + Height);

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

    		Coordinates_point1_x 	= Wight;
    		Coordinates_point1_y 	= zero_coordinate - (Wight + Height);
    		Coordinates_point2_x 	= Wight;
    		Coordinates_point2_y	= zero_coordinate + WIDGH_ANGLE - (Wight + Height);

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


endmodule: uart_fifo2ram
