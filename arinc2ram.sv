module arinc2fifo(
    // Clock
    clk,

    // Asynchronous reset active low
    rst_n,

    angle,
    arinc_data,
    fifo_data,
    read_arinc_data,
    fifo_write);
    /*----------------------------------------------------------------------------------*/
    /*									Parameters										*/
    /*----------------------------------------------------------------------------------*/
    parameter Wight             = 640;
    parameter Height            = 480;

    /*----------------------------------------------------------------------------------*/
    /*									Input											*/
    /*----------------------------------------------------------------------------------*/
    input							clk;
    input							rst_n;

    input [31:0]                    arinc_data;
    input                           read_arinc_data;

    /*----------------------------------------------------------------------------------*/
    /*									Output											*/
    /*----------------------------------------------------------------------------------*/
    output [2:0]                    fifo_data;
    output                          fifo_write;
    output [8:0]                    angle;

    /*----------------------------------------------------------------------------------*/
    /*									Variables										*/
    /*----------------------------------------------------------------------------------*/
    // Counters of received and transmitted data
    logic [7:0] 					cnt_32bit_data;
    logic [8:0]                     cnt_3bit_data;

    //
    logic [3:0]                     cnt_3bit_in_32bit_data;
    logic                           start_cnt;
    logic                           start_32bit_cnt;


    /*----------------------------------------------------------------------------------*/
    /*									Сonnections										*/
    /*----------------------------------------------------------------------------------*/


    /*----------------------------------------------------------------------------------*/
    /*									Always blocks									*/
    /*----------------------------------------------------------------------------------*/
    // Counters data 32 bit
    always_ff @ (posedge clk) begin
        if (!rst_n) cnt_32bit_data <= '0;
        else if (start_32bit_cnt) begin
            if (cnt_32bit_data == 8'd50) cnt_32bit_data <= '0;
            else cnt_32bit_data++;
        end
    end

    // Start
    always_ff @ (posedge clk) begin
        if (!rst_n) start_cnt <= '0;
        else if (read_arinc_data) start_cnt <= 1'b1;
        else if (cnt_3bit_in_32bit_data == 4'd10) start_cnt <= '0;
    end

    // Counters of 3-bit data in a 32-bit word
    always_ff @ (posedge clk) begin
        if (!rst_n) cnt_3bit_in_32bit_data <= '0;
        else if (!start_cnt) cnt_3bit_in_32bit_data <= '0;
        else cnt_3bit_in_32bit_data++;
    end

    // Translating a 32-bit word into 3-bit data
    always_ff @ (posedge clk) begin
        if (!rst_n) begin
            fifo_data <= '0;
            fifo_write <= '0;
        end
        else if (!start_cnt) begin
            fifo_data <= '0;
            fifo_write <= '0;
        end
        else if (cnt_32bit_data > 8'd2) begin
            if (cnt_32bit_data % 3 == 0) begin
                fifo_data <= arinc_data >> (cnt_3bit_in_32bit_data * 3);

                if (cnt_3bit_in_32bit_data < 4'd10) fifo_write <= 1'b1;
                else fifo_write <= '0;
            end
            else if (cnt_32bit_data % 3 == 1) begin
                if (cnt_3bit_in_32bit_data == 0) fifo_data[2] <= arinc_data[0];
                else fifo_data <= arinc_data >> (cnt_3bit_in_32bit_data * 3 - 1);

                if (cnt_3bit_in_32bit_data < 4'd10) fifo_write <= 1'b1;
                else fifo_write <= '0;
            end
            else begin
                if (cnt_3bit_in_32bit_data == 0) fifo_data[2:1] <= arinc_data[1:0];
                else fifo_data <= arinc_data >> (cnt_3bit_in_32bit_data * 3 - 2);

                if (cnt_3bit_in_32bit_data < 4'd11) fifo_write <= 1'b1;
                else fifo_write <= '0;
            end
        end
    end

    // Angle
    always_ff @ (posedge clk) begin
        if (!rst_n) angle <= '0;
        else if (cnt_32bit_data == 8'd2) angle <= arinc_data[30:19];
    end
    /*----------------------------------------------------------------------------------*/
    /*										Modules										*/
    /*----------------------------------------------------------------------------------*/
    pos pos_start (clk, start_cnt, start_32bit_cnt);

endmodule: arinc2fifo
