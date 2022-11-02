//-------------------------------------------------------------------------------------------------
//                                                                           АО "HANDMADE",СПб
//                                                                           http://www.LeningradSpb.ru/
//Проект    : HANDMADE
//Модуль    : UART
//Автор     : csa
//E-mail    : tsurkovsergey@mail.ru
//Дата      : 22.06.2021
//Описание  : Модуль управления драйвером передатчика UART
//-------------------------------------------------------------------------------------------------

`include "common.vh"

module uart_transmiter(clk,start_strobe,data,txd,busy);

		parameter EIGHT_BIT_DATA   = 8;
		parameter PARITY_BIT       = 0;
		parameter STOP_BIT         = 2;
		parameter DEFAULT_BDR      = 115200;

		input	clk;
		input	start_strobe;
		input	[7:0] data;
		output	wire txd;
		output	wire busy;

		reg enable = `CLR;
		reg [11:0] shift = 12'h0;                  
		reg [7:0]  bit_counter = 8'h0;
		reg [16:0] nco = 17'h10000;

		wire nco_tick_ff;
		wire load; 

		
// NCO ( ГУК генератор управляемый кодом )------------------------------------------------------------------------------------------

		localparam [63:0] DEFAULT_NCO =   DEFAULT_BDR * ({{62{1'b0}},2'b10}**16)  / `SYS_CLK_DIV2;  // (2^16 * baund_rate / sys_clk)
		
		 
	
	//	always @ (*) nco_module[16:0] <= DEFAULT_NCO[16:0];
			 
		pos uart_transmiter_pos_0(clk,nco[16],nco_tick_ff);

		
		
				 always @ (negedge enable or posedge clk)
				  begin
						if(!enable) nco <= 17'h10000;
						else
							begin
								nco <= nco + DEFAULT_NCO;	
								//nco <= nco + 1;	
							end
				  end
		
// Логика передатчика ------------------------------------------------------------------------------------------
		
		
		assign txd = shift[0];
		assign busy = enable;

		
		pos uart_transmiter_pos_1(clk,enable,load);


		always@(posedge clk) begin
		 if(start_strobe) enable <= `SET;
		 else if(bit_counter == 8'd11) enable <= `CLR;
		end


		always@(posedge clk) begin
		 if(!enable) bit_counter <= 8'h0;
		 else if(nco_tick_ff) bit_counter <= bit_counter + 8'h1;
		end

			
		wire [11:0] dataToload = { {2'b11}, {1'b1}, {data[7:0]}, {1'b0} };  // { {TWO_STOP_BITS}, {PARIY_BIT}, {DATA_BITS}, {START_BIT} }

		always@(posedge clk) begin
		 if(!enable) shift <= 11'h1;
		 else if(load) shift <= dataToload;
					  else if(nco_tick_ff) shift <= shift >> 1;
		end

		
endmodule
