`timescale      1ns / 1ns
`define         SYS_CLK     50_000_000
//`define         UART_TEST 	1

module uart2vga_tb ();

/*----------------------------------------------------------------------------------*/
/*									Parameters										*/
/*----------------------------------------------------------------------------------*/    
parameter EIGHT_BIT_DATA   		= 8;
parameter PARITY_BIT       		= 0;
parameter STOP_BIT         		= 2;
parameter DEFAULT_BDR      		= 115200;
parameter END_WORD 				= 8'hDD;
parameter SUCCESSFULLY_RECEIVED	= 8'hFF;
parameter NOT_ALL_RECEIVED 		= 8'h11;
parameter ANSWER_CODE 			= 8'hAA;
parameter VALUE_PAUSE			= 8'hFF;
parameter ANSWER_CODE_TAKE_ROW	= 8'hCC;

parameter BYTE_SIZE_ROW         = 240;
parameter BYTE_SIZE_Y           = 2;
parameter BYTE_SIZE_STOP        = 1;
parameter STOP_BYTE             = 8'hDD;

parameter Wight                 = 640;
parameter Height                = 480;
parameter SYS_CLK_DIV2		    = `SYS_CLK / 2;
localparam REPEAT_TX_NUMBER     = BYTE_SIZE_ROW + BYTE_SIZE_Y + BYTE_SIZE_STOP;
localparam time SYS_CLK_PERIOD  = 1_000_000_000.0 / `SYS_CLK;  // (1S-ns / F mhz = P)
/*----------------------------------------------------------------------------------*/
/*								    Variables										*/
/*----------------------------------------------------------------------------------*/
logic       sys_clk;
logic	    rst_n = 1;

// VGA Interface
logic	    VGA_HS;
logic 	    VGA_VS;
logic [3:0] VGA_R;
logic [3:0] VGA_G;
logic [3:0] VGA_B;

// UART
logic       uart_tx = 1;
logic       uart_rx;

// FPGA
logic       fpga_tx = 1;
logic       fpga_rx;

// Other
logic [1:0] SW;
logic [9:0] LED;

// TX
logic       start_tx;
logic [7:0] data_tx = '0;
logic       busy;

// RX
logic [7:0] data_rx;
logic       done_byte;

bit [REPEAT_TX_NUMBER - 1 : 0] [7:0] random_date;

int         d_out;
int         i;
int         n = 0;

logic       strobe;
/*----------------------------------------------------------------------------------*/
/*								clock frequency										*/
/*----------------------------------------------------------------------------------*/
initial begin
	sys_clk = 0;

	forever #(SYS_CLK_PERIOD / 2.0) sys_clk = ~sys_clk;
end

assign fpga_rx = uart_tx;
assign uart_rx = fpga_tx;
/*----------------------------------------------------------------------------------*/
/*								    task blocks										*/
/*----------------------------------------------------------------------------------*/
task Reset();
    rst_n = 1'b1;
    @(posedge sys_clk);
    @(posedge sys_clk);
    rst_n = 1'b0;
    @(posedge sys_clk);
    @(posedge sys_clk);
    @(posedge sys_clk);
    rst_n = 1'b1;
    @(posedge sys_clk);
    @(posedge sys_clk);
endtask // Reset

task tx_date (input int n);
    data_tx = random_date[n];
    @(posedge sys_clk);
    start_tx = 1'b1;
    @(posedge sys_clk);
    start_tx = 1'b0;
endtask //tx_date 

task trx_date(input int n);
    $display("\n+------------------------------------+");
    tx_date (n);
    @(negedge busy);
    $display("| %d byte transmit \t\t\t|", n);
    @(done_byte);
    $display("+------------------------------------+");
    $display("\tAnswer: %h", data_rx);
    #2000
    if (n == (REPEAT_TX_NUMBER - 1)) begin
        if (data_rx == SUCCESSFULLY_RECEIVED) $display("\tThe package was received in full!");
        else if (data_rx == NOT_ALL_RECEIVED) begin
            @(done_byte);
            $display("Did not receive %h data", data_rx);
        end
        else begin
            $display("Problems!");
            $stop;
        end 
    end
    else if (n >= BYTE_SIZE_Y && n < (BYTE_SIZE_ROW + BYTE_SIZE_Y) && data_rx == ANSWER_CODE) begin
        $display("\tGreate T-R Date!");
    end
    else if (n < BYTE_SIZE_Y && data_rx == ANSWER_CODE_TAKE_ROW) begin
        $display("\tGreate T-R Row!");
    end
    else begin
        $display("Error! The information was lost:\n\t%b", data_rx);
        $stop;
    end
    //$display("\n\t%d", n);
    $display("+------------------------------------+");
endtask // trx_date

/*----------------------------------------------------------------------------------*/
/*								Initial blocks										*/
/*----------------------------------------------------------------------------------*/
initial begin

    SW = 2'b10;
    start_tx = 1'b0;

    `ifdef UART_TEST
    i = 0;
    repeat (REPEAT_TX_NUMBER) begin
        d_out = $random;
        random_date[i] = d_out;
        i++;
    end    
    `else

        i = 2;
    random_date[1:0] = 16'h2201;

    repeat (BYTE_SIZE_ROW) begin
        d_out = $random;
        random_date[i] = d_out;
        i++;
    end

    random_date[i] = END_WORD;
    
    `endif

    random_date[i] = STOP_BYTE;

    $display("+------------------------------------+");
	$display("|         Testing UART2VGA           |");
	$display("+------------------------------------+");

    repeat (20) @(posedge sys_clk);
    Reset();
end

initial begin
    #1000
    strobe = 1;
    #1000
    strobe = 0;
    repeat (REPEAT_TX_NUMBER) begin
        #2000
        trx_date(n);
        n++;
    end
    $display("+------------------------------------+");
	$display("|             End UART2VGA           |");
	$display("+------------------------------------+");

/*
    fork
        begin
            @(done_byte);
            $display("Greate answer!");
        end

        begin
            repeat (50000) @(posedge sys_clk);
            $display("Timeout");
        end
    join_any*/
    $stop;
end



/*----------------------------------------------------------------------------------*/
/*									Modules											*/
/*----------------------------------------------------------------------------------*/
uart2vga_with_answer DUT(
	// Clock
	.clk(sys_clk),

	// Asynchronous reset active low
	.rst_n(rst_n),

	// VGA Interface
	.VGA_HS(VGA_HS),
	.VGA_VS(VGA_VS),
	.VGA_R(VGA_R),
	.VGA_G(VGA_G),
	.VGA_B(VGA_B),

    // UART
    .tx(fpga_tx),
    .rx(fpga_rx),

	// Other
	.SW(SW),
	.LED(LED)
);

uart_transmiter dut_tx(
                    .clk(sys_clk),
                    .start_strobe(start_tx),
                    .data(data_tx),
                    .txd(uart_tx),
                    .busy(busy));
    defparam
        dut_tx.EIGHT_BIT_DATA   = EIGHT_BIT_DATA,
        dut_tx.PARITY_BIT       = PARITY_BIT,
        dut_tx.STOP_BIT         = STOP_BIT,
        dut_tx.DEFAULT_BDR      = DEFAULT_BDR,
		dut_tx.SYS_CLK_DIV2	    = SYS_CLK_DIV2;

uart_receiver dut_rx(
                    .clk(sys_clk),
                    .rst_n(rst_n),
                    .rxd(uart_rx),
                    .data(data_rx),
                    .done(done_byte));
    defparam
        dut_rx.EIGHT_BIT_DATA   = EIGHT_BIT_DATA,
        dut_rx.PARITY_BIT       = PARITY_BIT,
        dut_rx.STOP_BIT         = STOP_BIT,
        dut_rx.DEFAULT_BDR      = DEFAULT_BDR,
		dut_rx.SYS_CLK_DIV2	    = SYS_CLK_DIV2;

endmodule