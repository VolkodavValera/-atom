//-------------------------------------------------------------------------------------------------
//                                                                           АО "HANDMADE",СПб
//                                                                           http://www.LeningradSpb.ru/
//Проект    : HANDMADE
//Модуль    : UART
//Автор     : csa
//E-mail    : tsurkovsergey@mail.ru
//Дата      : 22.06.2021
//Описание  : Модуль управления драйвером приемника UART
//-------------------------------------------------------------------------------------------------
module uart_receiver(clk,rst_n,rxd,data,done);

		parameter EIGHT_BIT_DATA   	= 8;
		parameter PARITY_BIT       	= 0;
		parameter STOP_BIT         	= 2;
		parameter DEFAULT_BDR      	= 115200;
		parameter SYS_CLK_DIV2		= 50_000_000;


		localparam  CLR 			= 0;
		localparam  SET 			= 1;

		input   clk;
		input   rst_n;
		input   rxd;
		output reg [EIGHT_BIT_DATA-1:0] data = '0;
		output reg done = CLR;


		localparam OVER_SAMPLING = 16;
		localparam HALF_OVER_SAMPLING = OVER_SAMPLING / 2;

		localparam [63:0] DEFAULT_NCO =  OVER_SAMPLING * DEFAULT_BDR * ({{62{1'b0}},2'b10}**16)  / SYS_CLK_DIV2;  // (OVER_SAMLING * 2^16 * baund_rate / sys_clk)

	    localparam[2:0]

		IDLE              = 3'd0,
		CHECK_START       = 3'd1,
		RECEIVE_DATA      = 3'd2,
		CHECK_PARITY 	  = 3'd3,
		CHECK_STOP_BIT    = 3'd4,
		DONE    		  = 3'd5;


		reg rx_bit = SET;
		reg parity_bit = CLR;
		reg sample = CLR;

		reg [2:0] state = 3'h0;
		reg [2:0] sync_reg = 3'hF;
		reg [3:0] clk_counter = 4'h0;
		reg [1:0] stop_bit_counter  = 2'h0;
		reg [3:0] bit_counter  = 4'h0;
		reg [16:0] nco  = 17'h0;
		reg[16:0] nco_module = DEFAULT_NCO[16:0];

		wire nco_tick_ff;



// NCO ( ГУК генератор управляемый кодом )------------------------------------------------------------------------------------------


		always @ (*) nco_module[16:0] <= DEFAULT_NCO[16:0];


		pos uart_receiver_pos_1(clk,nco[16],nco_tick_ff);


				 always @ (negedge rst_n or posedge clk)
				  begin
						if(!rst_n) nco <= 17'h10000;
						else
							begin
								nco <= nco + nco_module;
							end
				  end



// UART синхронизация  ------------------------------------------------------------------------------------------

		always@(posedge clk) if(nco_tick_ff) sync_reg <= {sync_reg[1:0],rxd};

		// противо помеховое взвшивание RXD бита (если хотябы два из трех тест-стробов равны единице, то считаем что в RXD единица)
		always@(posedge clk) rx_bit <= (sync_reg[0] & sync_reg[1]) | (sync_reg[0] & sync_reg[2]) | (sync_reg[1] & sync_reg[2]);

		// счетчик длительности бита (для смещения в центр принимаемых битов)
		always @ (posedge clk) begin

			if(state == IDLE) clk_counter <= 4'd0;
			else if(nco_tick_ff) clk_counter <= clk_counter + 4'd1;
		end

		// строб текущего бита
		always@(posedge clk) begin

			if(clk_counter == HALF_OVER_SAMPLING) sample <= nco_tick_ff;
			else sample <= CLR;
		end

// цикл переходов автомата ---------------------------------------------------------------------------------

		always @ (posedge clk) begin

			if(!rst_n) state <= IDLE;
			else begin

				case(state)

				IDLE: if(!rx_bit)   state <= CHECK_START;

				CHECK_START: begin

					if(sample) begin

						if(!rx_bit) state <= RECEIVE_DATA;
						else state <= IDLE;

					end
				end

				RECEIVE_DATA: begin

					if(sample) begin

						if(bit_counter == EIGHT_BIT_DATA-1) state <= CHECK_PARITY;
						else state <= RECEIVE_DATA;

					end
				end

				CHECK_PARITY: begin

					if(!PARITY_BIT)  state <= CHECK_STOP_BIT;
					else if(sample) begin

						if(parity_bit != rx_bit) state <= IDLE;
						else state <= CHECK_STOP_BIT;

					end
				end


				CHECK_STOP_BIT: begin

					if(sample) begin

						if(!rx_bit) state <= IDLE;
						else if(stop_bit_counter == STOP_BIT) state <= DONE;
							 else state <= CHECK_STOP_BIT;

					end
				end


				DONE: state <= IDLE;

				endcase

			end
		end



// цикл воздействия автомата ---------------------------------------------------------------------------------

		always @ (posedge clk) begin

			case(state)

			IDLE: begin

			bit_counter <= 4'd0;
			parity_bit <= CLR;
			done <= CLR;
			stop_bit_counter <= 2'd1;

			end

			RECEIVE_DATA: begin

				if(sample) begin

					bit_counter <= bit_counter + 4'd1;
					data[bit_counter] <= rx_bit;
					parity_bit <= parity_bit ^ rx_bit;

				end
			end

			CHECK_STOP_BIT: if(sample) stop_bit_counter <= stop_bit_counter + 2'd1;

			DONE: done <= SET;

			endcase
		end



endmodule
