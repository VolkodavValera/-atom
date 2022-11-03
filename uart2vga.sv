//`include "vga_avalon.svh"

module uart2vga (
	// Clock
	clk,

	// Asynchronous reset active low
	rst_n,

	// VGA Interface
	VGA_HS,
	VGA_VS,
	VGA_R,
	VGA_G,
	VGA_B,

    // UART
    //tx,
    rx,

	// Other
	SW,
	LED,
);

/*------------------------------------------------------*/
/*						Parameters						*/
/*------------------------------------------------------*/
	parameter ADDRESS_WIDTH		= 3;
    parameter Wight             = 640;
    parameter Height            = 480;
    localparam  MAX_ADDR_RAM    = Wight * Height;
	localparam WAIT_ARINC		= 0;
	localparam FIFO_ARINC_FULL 	= 1;
	localparam READ_DATA		= 2;
	localparam FIFO_ARINC_EMPTY	= 3;


/*------------------------------------------------------*/
/*						Input							*/
/*------------------------------------------------------*/
	input							clk;
	input							rst_n;

    input                           rx;

	input [1:0]						SW;

/*------------------------------------------------------*/
/*						Output							*/
/*------------------------------------------------------*/
	output							VGA_HS;					//	VGA H_SYNC
	output							VGA_VS;					//	VGA V_SYNC
	output	[3:0]					VGA_R;   				//	VGA Red[3:0]
	output	[3:0]					VGA_G;	 				//	VGA Green[3:0]
	output	[3:0]					VGA_B;   				//	VGA Blue[3:0]

    //output                          tx;

	output 	[9:0]					LED;

/*------------------------------------------------------*/
/*						Variables						*/
/*------------------------------------------------------*/

	// PLL signals
	// ---------------------------------------------------
	wire 							clk_sys;
	wire 							clk_vga;

    // Other
    logic   [18:0]                  cnt_received_uart_data;

	// RAM
	logic 	[2:0] 					RAM_Q;
    logic   [2:0]                   RAM_DATA;
	wire 	[18:0]					RAM_ADDR;
	wire 	[18:0]					ram_read_address;
	wire 	[18:0]					ram_write_address;
	wire 							ram_write;

	// ROM
	wire 	[11:0]					ROM_Q;
	wire 	[2:0]					ROM_ADDR;

    // UART
    logic                           UART_DONE;
    logic                           UART_DONE_FF;
    logic   [2:0]                   UART_DATA;


/*------------------------------------------------------*/
/*						Сonnections						*/
/*------------------------------------------------------*/
    assign ram_write_address = (cnt_received_uart_data);
    assign ram_write = (UART_DONE_FF);
	assign RAM_ADDR = ram_write ? ram_write_address : ram_read_address;
	assign ROM_ADDR = (RAM_Q);
	assign LED = (SW[0]) ? 10'h2AA : (SW[1]) ? 10'h1DD : 10'h3F1;

/*------------------------------------------------------*/
/*						Always blocks					*/
/*------------------------------------------------------*/
    always_ff @ (posedge clk_sys) begin
        UART_DONE_FF <= UART_DONE;
    end

    always_ff @ (posedge clk_sys) begin
        if (!rst_n) cnt_received_uart_data <= '0;
        else if (UART_DONE_FF) begin
            if (cnt_received_uart_data == MAX_ADDR_RAM) cnt_received_uart_data <= '0;
            else cnt_received_uart_data++;
        end
    end

/*------------------------------------------------------*/
/*						Modules							*/
/*------------------------------------------------------*/
	VGA_Controller VGA (
			.clk_vga(clk_vga),
			.rst_n(rst_n),

			// Read date
			.address_vga(ram_read_address),
			.data(ROM_Q),

			// VGA SIDE
			.VGA_HS(VGA_HS),
			.VGA_VS(VGA_VS),
			.VGA_R(VGA_R),
			.VGA_G(VGA_G),
			.VGA_B(VGA_B),
			.SW(SW));

    uart_receiver UART_Controller(
            .clk(clk_sys),
            .rst_n(rst_n),
            .rxd(rx),
            .data(RAM_DATA),
            .done(UART_DONE));
    defparam
        UART_Controller.EIGHT_BIT_DATA  = 3,
        UART_Controller.PARITY_BIT      = 0,
        UART_Controller.STOP_BIT        = 2,
        UART_Controller.DEFAULT_BDR     = 115200;

/*------------------------------------------------------*/
/*						RAM								*/
/*------------------------------------------------------*/
	altsyncram	RAM_DISPLEY (
				.address_a (RAM_ADDR),
				.clock0 (clk_sys),
				.data_a (RAM_DATA),
				.wren_a (ram_write),
				.q_a (RAM_Q),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_b (1'b1),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_b (1'b0));
	defparam
		RAM_DISPLEY.clock_enable_input_a = "BYPASS",
		RAM_DISPLEY.clock_enable_output_a = "BYPASS",
		RAM_DISPLEY.intended_device_family = "MAX 10",
		RAM_DISPLEY.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		RAM_DISPLEY.lpm_type = "altsyncram",
		RAM_DISPLEY.numwords_a = 307200,
		RAM_DISPLEY.operation_mode = "SINGLE_PORT",
		RAM_DISPLEY.outdata_aclr_a = "NONE",
		RAM_DISPLEY.outdata_reg_a = "CLOCK0",
		RAM_DISPLEY.power_up_uninitialized = "FALSE",
		RAM_DISPLEY.read_during_write_mode_port_a = "NEW_DATA_NO_NBE_READ",
		RAM_DISPLEY.widthad_a = 19,
		RAM_DISPLEY.width_a = 3,
		RAM_DISPLEY.width_byteena_a = 1;


/*------------------------------------------------------*/
/*						PLL								*/
/*------------------------------------------------------*/
	altpll	PLL_VGA (
    				.inclk (clk),
    				.clk (clk_vga),
    				.areset (1'b0),
    				.clkena ({6{1'b1}}),
    				.clkswitch (1'b0),
    				.configupdate (1'b0),
    				.extclkena ({4{1'b1}}),
    				.fbin (1'b1),
    				.pfdena (1'b1),
    				.phasecounterselect ({4{1'b1}}),
    				.phasestep (1'b1),
    				.phaseupdown (1'b1),
    				.pllena (1'b1),
    				.scanaclr (1'b0),
    				.scanclk (1'b0),
    				.scanclkena (1'b1),
    				.scandata (1'b0),
    				.scanread (1'b0),
    				.scanwrite (1'b0));
	defparam
		PLL_VGA.bandwidth_type = "AUTO",
		PLL_VGA.clk0_divide_by = 2000,
		PLL_VGA.clk0_duty_cycle = 50,
		PLL_VGA.clk0_multiply_by = 1007,
		PLL_VGA.clk0_phase_shift = "0",
		PLL_VGA.compensate_clock = "CLK0",
		PLL_VGA.inclk0_input_frequency = 20000,
		PLL_VGA.intended_device_family = "MAX 10",
		PLL_VGA.lpm_type = "altpll",
		PLL_VGA.operation_mode = "NORMAL",
		PLL_VGA.pll_type = "AUTO",
		PLL_VGA.port_clk0 = "PORT_USED",
		PLL_VGA.width_clock = 5;


	altpll	PLL_SYSTEM (
                        .inclk (clk),
                        .clk (clk_sys),
                        .areset (1'b0),
                        .clkena ({6{1'b1}}),
                        .clkswitch (1'b0),
                        .configupdate (1'b0),
                        .extclkena ({4{1'b1}}),
                        .fbin (1'b1),
                        .pfdena (1'b1),
                        .phasecounterselect ({4{1'b1}}),
                        .phasestep (1'b1),
                        .phaseupdown (1'b1),
                        .pllena (1'b1),
                        .scanaclr (1'b0),
                        .scanclk (1'b0),
                        .scanclkena (1'b1),
                        .scandata (1'b0),
                        .scanread (1'b0),
                        .scanwrite (1'b0));
	defparam
        PLL_SYSTEM.bandwidth_type = "AUTO",
        PLL_SYSTEM.clk0_divide_by = 36,
        PLL_SYSTEM.clk0_duty_cycle = 50,
        PLL_SYSTEM.clk0_multiply_by = 103,
        PLL_SYSTEM.clk0_phase_shift = "0",
        PLL_SYSTEM.compensate_clock = "CLK0",
        PLL_SYSTEM.inclk0_input_frequency = 20000,
        PLL_SYSTEM.intended_device_family = "MAX 10",
        PLL_SYSTEM.lpm_type = "altpll",
        PLL_SYSTEM.operation_mode = "NORMAL",
        PLL_SYSTEM.pll_type = "AUTO",
        PLL_SYSTEM.port_clk0 = "PORT_USED",
        PLL_SYSTEM.width_clock = 5;

/*------------------------------------------------------*/
/*						ROM								*/
/*------------------------------------------------------*/
	altsyncram	ROM_Palitra (
				.address_a (ROM_ADDR),
				.clock0 (clk_sys),
				.q_a (ROM_Q),
				.aclr0 (1'b0),
				.aclr1 (1'b0),
				.address_b (1'b1),
				.addressstall_a (1'b0),
				.addressstall_b (1'b0),
				.byteena_a (1'b1),
				.byteena_b (1'b1),
				.clock1 (1'b1),
				.clocken0 (1'b1),
				.clocken1 (1'b1),
				.clocken2 (1'b1),
				.clocken3 (1'b1),
				.data_a ({12{1'b1}}),
				.data_b (1'b1),
				.rden_a (1'b1),
				.rden_b (1'b1),
				.wren_a (1'b0),
				.wren_b (1'b0));
	defparam
		ROM_Palitra.address_aclr_a = "NONE",
		ROM_Palitra.clock_enable_input_a = "BYPASS",
		ROM_Palitra.clock_enable_output_a = "BYPASS",
		ROM_Palitra.init_file = "./source/palitra.hex",
		ROM_Palitra.intended_device_family = "MAX 10",
		ROM_Palitra.lpm_hint = "ENABLE_RUNTIME_MOD=NO",
		ROM_Palitra.lpm_type = "altsyncram",
		ROM_Palitra.numwords_a = 8,
		ROM_Palitra.operation_mode = "ROM",
		ROM_Palitra.outdata_aclr_a = "NONE",
		ROM_Palitra.outdata_reg_a = "CLOCK0",
		ROM_Palitra.widthad_a = 3,
		ROM_Palitra.width_a = 12,
		ROM_Palitra.width_byteena_a = 1;


endmodule: uart2vga
