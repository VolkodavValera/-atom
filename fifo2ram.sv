module fifo2ram (
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
    fifo_empty
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

    /*----------------------------------------------------------------------------------*/
    /*									Output											*/
    /*----------------------------------------------------------------------------------*/
    output [2:0]                    ram_data;
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


    /*----------------------------------------------------------------------------------*/
    /*									Сonnections										*/
    /*----------------------------------------------------------------------------------*/
    assign zero_coordinate = (angle * WIDGH_ANGLE);
    assign rigth_left = (zero_coordinate >= HALF_METER) ? 1 : 0;
    assign coordinate = (X**2 + Y**2);
    assign checking_radius = ((coordinate <= cnt_data**2 + WIDGH_LINE) && (coordinate >= cnt_data**2 - WIDGH_LINE)) ? 1 : 0;
    assign address_ram = (Y*Wight + X);
    assign ram_data = (fifo_q);
    assign range_x = (rigth_left) ? Centre_X + cnt_data : Centre_X - cnt_data;
    assign range_y = (Centre_Y - cnt_data);


    /*----------------------------------------------------------------------------------*/
    /*									Always blocks									*/
    /*----------------------------------------------------------------------------------*/
    always_ff @ (posedge clk) begin
        if (!rst_n) cnt_data <= 9'd1;
        else if (fifo_empty) cnt_data <= 9'd1;
        else if (!stop_read_fifo) cnt_data++;
    end

    always_ff @ (posedge clk) begin
        if (!rst_n) begin
            write_ram <= '0;
            X <= '0;
            Y <= '0;
        end
        else begin

        end
    end

endmodule: fifo2ram
