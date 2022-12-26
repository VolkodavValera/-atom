`timescale      1ns / 1ns
`define         SYS_CLK 100_000_000

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

parameter BYTE_SIZE_ROW         = 240;
parameter BYTE_SIZE_Y           = 2;
parameter BYTE_SIZE_STOP        = 1;
parameter STOP_BYTE             = 8'hDD;

parameter Wight             = 640;
parameter Height            = 480;
parameter SYS_CLK_DIV2		= `SYS_CLK;
localparam REPEAT_TX_NUMBER = BYTE_SIZE_ROW + BYTE_SIZE_Y + BYTE_SIZE_STOP;
localparam time SYS_CLK_PERIOD = 1_000_000_000.0 / SYS_CLK_DIV2;  // (1S-ns / F mhz = P)
/*----------------------------------------------------------------------------------*/
/*								    Variables										*/
/*----------------------------------------------------------------------------------*/
logic       sys_clk;
logic	    rst_n;

// VGA Interface
logic	    VGA_HS;
logic	    VGA_VS;
logic	    VGA_R;
logic	    VGA_G;
logic	    VGA_B;

// UART
logic       uart_tx;
logic       uart_rx;

// FPGA
logic       fpga_tx;
logic       fpga_rx;

// Other
logic [1:0] SW;
logic [9:0] LED;

// TX
logic       start_tx;
logic [7:0] data_tx;
logic       busy;

// RX
logic [7:0] data_rx;
logic       done_byte;

bit [REPEAT_TX_NUMBER - 1 : 0] [7:0] random_date;

int d_out;
int i = 2;

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
endtask

task tx_date (input int n);
    data_tx = random_date[n];
    @(posedge sys_clk);
    start_tx = 1'b1;
    @(posedge sys_clk);
    start_tx = 1'b0;
endtask //tx_date 

/*----------------------------------------------------------------------------------*/
/*								Initial blocks										*/
/*----------------------------------------------------------------------------------*/
initial begin

    SW = 2'b10;
    start_tx = 1'b0;

    random_date[1:0] = 16'h0000;

    repeat (BYTE_SIZE_ROW) begin
        d_out = $random;
        random_date[i] = d_out;
        i++;
    end

    random_date[i] = STOP_BYTE;

    $display("+------------------------------------+");
	$display("|         Testing UART2VGA           |");
	$display("+------------------------------------+");

    Reset();
end

initial begin
    #2000
    tx_date (0);
    @(negedge busy);
    $display("0 byte transmit");
    @(done_byte);
    $display("Greate answer!");
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
        dut_tx.EIGHT_BIT_DATA  = EIGHT_BIT_DATA,
        dut_tx.PARITY_BIT      = PARITY_BIT,
        dut_tx.STOP_BIT        = STOP_BIT,
        dut_tx.DEFAULT_BDR     = DEFAULT_BDR,
		dut_tx.SYS_CLK_DIV2	   = SYS_CLK_DIV2;

uart_receiver dut_rx(
                    .clk(sys_clk),
                    .rst_n(rst_n),
                    .rxd(uart_rx),
                    .data(data_rx),
                    .done(done_byte));
    defparam
        dut_rx.EIGHT_BIT_DATA  = EIGHT_BIT_DATA,
        dut_rx.PARITY_BIT      = PARITY_BIT,
        dut_rx.STOP_BIT        = STOP_BIT,
        dut_rx.DEFAULT_BDR     = DEFAULT_BDR,
		dut_rx.SYS_CLK_DIV2	= SYS_CLK_DIV2;

endmodule