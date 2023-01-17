module UART_ARINC_Controller (clk, rst_n, rxd, txd, row, uart_data, done, fifo_empty);
/*----------------------------------------------------------------------------------*/
/*									Parameters										*/
/*----------------------------------------------------------------------------------*/
parameter   EIGHT_BIT_DATA   		= 8;
parameter   PARITY_BIT       		= 0;
parameter   STOP_BIT         		= 2;
parameter   DEFAULT_BDR      		= 115200;
parameter   END_WORD 				= 8'hDD;
parameter   SUCCESSFULLY_RECEIVED	= 8'hBC;
parameter   NOT_ALL_RECEIVED 		= 8'h11;
parameter   ANSWER_CODE 			= 8'hAA;
parameter   ANSWER_CODE_TAKE_ROW	= 8'hCC;
parameter   VALUE_PAUSE			    = 8'hFF;

parameter   Wight                   = 512;
parameter   SYS_CLK_DIV2		    = 100_000_000;

parameter	CNT_BYTE_MAX	        = 8'hC0;

localparam  START_WORD 		        = 0;
localparam  FEEDBACK_START	        = 1;
localparam  ROW_VALUE 		        = 2;
localparam  FEEDBACK_ROW	        = 3;
localparam  CONVERT_BYTE_1 	        = 4;
localparam  FEEDBACK_CONVERT        = 5;
/*localparam  CONVERT_BYTE_2 	= 3;
localparam  CONVERT_BYTE_3 	= 4;*/
localparam  CHECK_END_WORD 	        = 6;
/*localparam  SUCCESS 		= 5;
localparam  STOP_WORD 		= 6;
*/

/*----------------------------------------------------------------------------------*/
/*									Input											*/
/*----------------------------------------------------------------------------------*/
	input								clk;
	input								rst_n;

    input                           	rxd;

    input                               fifo_empty;

/*----------------------------------------------------------------------------------*/
/*									Output											*/
/*----------------------------------------------------------------------------------*/
	output                          	txd;
	output logic [3 * Wight - 1 : 0]	uart_data;
	output logic [8:0]					row;
	output logic						done;

/*----------------------------------------------------------------------------------*/
/*									Variables										*/
/*----------------------------------------------------------------------------------*/
	logic [7:0] 						data_rx;
	logic [7:0] 						data_tx;
	logic 								start_tx;
	wire 								busy;
	wire 								busy_neg;
	logic 								done_byte;
	logic [2:0] 						state;
	logic 								answer;
	logic 								answer_err;
	logic [7:0] 						cnt_data;
	logic [7:0] 						cnt_pause;
	logic 								pause;




/*----------------------------------------------------------------------------------*/
/*									Сonnections										*/
/*----------------------------------------------------------------------------------*/
	assign start_tx = answer | answer_err;

/*----------------------------------------------------------------------------------*/
/*									Always blocks									*/
/*----------------------------------------------------------------------------------*/
	always_ff @ (posedge clk) begin
		if (data_tx <= NOT_ALL_RECEIVED && busy_neg) begin
			answer_err <= 1'b1;
		end
		else answer_err <= '0;
	end

	always_ff @ (posedge clk) begin
		if (state == FEEDBACK_START || state == FEEDBACK_ROW || state == FEEDBACK_CONVERT || state == CHECK_END_WORD ) cnt_pause++;
		else cnt_pause <= '0;
	end

	always_ff @ (posedge clk) begin
		if (cnt_pause == 4'hF) pause <= 1'b1;
		else pause <= 1'b0;
	end

/*----------------------------------------------------------------------------------*/
/*										Modules										*/
/*----------------------------------------------------------------------------------*/
	neg neg_busy(clk, busy, busy_neg);

	uart_receiver UART_RX(
                    .clk(clk),
                    .rst_n(rst_n),
                    .rxd(rxd),
                    .data(data_rx),
                    .done(done_byte));
    defparam
        UART_RX.EIGHT_BIT_DATA  = EIGHT_BIT_DATA,
        UART_RX.PARITY_BIT      = PARITY_BIT,
        UART_RX.STOP_BIT        = STOP_BIT,
        UART_RX.DEFAULT_BDR     = DEFAULT_BDR,
		UART_RX.SYS_CLK_DIV2	= SYS_CLK_DIV2;

    uart_transmiter UART_TX(
                    .clk(clk),
                    .start_strobe(start_tx),
                    .data(data_tx),
                    .txd(txd),
                    .busy(busy));
    defparam
        UART_TX.EIGHT_BIT_DATA  = EIGHT_BIT_DATA,
        UART_TX.PARITY_BIT      = PARITY_BIT,
        UART_TX.STOP_BIT        = STOP_BIT,
        UART_TX.DEFAULT_BDR     = DEFAULT_BDR,
		UART_TX.SYS_CLK_DIV2	= SYS_CLK_DIV2;
/*----------------------------------------------------------------------------------*/
/*									State Mashines									*/
/*----------------------------------------------------------------------------------*/
	// State
	always_ff @ (posedge clk) begin
		if (!rst_n) state <= START_WORD;
		else begin
			case (state)

				START_WORD: begin
					if (done_byte) state <= FEEDBACK_START;
				end

				FEEDBACK_START: begin
					if (pause) state <= ROW_VALUE;
				end

				ROW_VALUE: begin
					if (done_byte) state <= FEEDBACK_ROW;
				end

				FEEDBACK_ROW: begin
					if (pause) state <= CONVERT_BYTE_1;
				end

				CONVERT_BYTE_1: begin
					/*if (data_rx == END_WORD) state <= STOP_WORD;
					else if (cnt_data == Wight) state <= CHECK_END_WORD;
					else
					state <= CONVERT_BYTE_2;*/
					if (done_byte) begin
						if (cnt_data == CNT_BYTE_MAX || data_rx == END_WORD) state <= CHECK_END_WORD;
						else state <= FEEDBACK_CONVERT;
					end
				end

				FEEDBACK_CONVERT: begin
					if (pause) state <= CONVERT_BYTE_1;
				end
/*
				CONVERT_BYTE_2: begin
					if (data_rx == END_WORD) state <= STOP_WORD;
					else if (cnt_data == Wight) state <= CHECK_END_WORD;
					else
					state <= CONVERT_BYTE_3;
				end

				CONVERT_BYTE_3: begin
					if (data_rx == END_WORD) state <= STOP_WORD;
					else
					if (cnt_data == (Wight - 3)) state <= CHECK_END_WORD;
					else state <= CONVERT_BYTE_1;
				end
*/
				CHECK_END_WORD: begin
					if (fifo_empty) state <= START_WORD;
				end
/*
				SUCCESS: begin
					state <= START_WORD;
				end

				STOP_WORD: begin
					state <= START_WORD;
				end
*/
				default: state <= START_WORD;
			endcase
		end
	end

	// Realization state
	always_ff @ (posedge clk) begin
		if (!rst_n) begin
			row 		<= '0;
			uart_data 	<= '0;
			answer 		<= '0;
			cnt_data	<= '0;
			done		<= '0;
			data_tx		<= '0;
		end
		else if (data_tx <= NOT_ALL_RECEIVED && busy_neg) begin
			data_tx <= Wight - cnt_data;
		end
		else begin
			case (state)

				START_WORD: begin
					row[8] 		<= data_rx[0];
					uart_data 	<= '0;
					cnt_data	<= '0;
					done		<= '0;
					answer		<= answer_err;
				end

				FEEDBACK_START: begin
					if (pause) begin
						data_tx <= ANSWER_CODE_TAKE_ROW;
						answer <= 1'b1;
					end
				end

				ROW_VALUE: begin
					answer <= 1'b0;

					if (done_byte) begin
						row[7:0] <= data_rx;
					end
				end

				FEEDBACK_ROW: begin
					if (pause) begin
						data_tx <= ANSWER_CODE_TAKE_ROW;
						answer <= 1'b1;
					end
				end

				CONVERT_BYTE_1: begin
					answer <= 1'b0;

					if (done_byte) begin
						if (cnt_data < CNT_BYTE_MAX) begin
							uart_data[8 * cnt_data] 	<= data_rx[7];
							uart_data[8 * cnt_data + 1] <= data_rx[6];
							uart_data[8 * cnt_data + 2] <= data_rx[5];
							uart_data[8 * cnt_data + 3] <= data_rx[4];
							uart_data[8 * cnt_data + 4] <= data_rx[3];
							uart_data[8 * cnt_data + 5] <= data_rx[2];
							uart_data[8 * cnt_data + 6] <= data_rx[1];
							uart_data[8 * cnt_data + 7] <= data_rx[0];							
						end

					end

					//data_tx <= data_rx;
				end

				FEEDBACK_CONVERT: begin
					if (pause) begin
						data_tx <= ANSWER_CODE;
						answer <= 1'b1;
						cnt_data++;
					end
				end
/*
				CONVERT_BYTE_2: begin
					uart_data[3 * cnt_data + 2] <= data_rx[0];
					uart_data[3 * cnt_data + 3] <= data_rx[1];
					uart_data[3 * cnt_data + 4] <= data_rx[2];
					uart_data[3 * cnt_data + 5] <= data_rx[3];
					uart_data[3 * cnt_data + 6] <= data_rx[4];
					uart_data[3 * cnt_data + 7] <= data_rx[5];
					uart_data[3 * cnt_data + 8] <= data_rx[6];
					uart_data[3 * cnt_data + 9] <= data_rx[7];

					cnt_data 					<= cnt_data + 3;
				end

				CONVERT_BYTE_3: begin
					uart_data[3 * cnt_data + 1] <= data_rx[0];
					uart_data[3 * cnt_data + 2] <= data_rx[1];
					uart_data[3 * cnt_data + 3] <= data_rx[2];
					uart_data[3 * cnt_data + 4] <= data_rx[3];
					uart_data[3 * cnt_data + 5] <= data_rx[4];
					uart_data[3 * cnt_data + 6] <= data_rx[5];
					uart_data[3 * cnt_data + 7] <= data_rx[6];
					uart_data[3 * cnt_data + 8] <= data_rx[7];

					cnt_data 					<= cnt_data + 3;
				end
*/
				CHECK_END_WORD: begin
					if (fifo_empty) begin
						if (data_rx == END_WORD) begin
							done 	<= 1'b1;
							data_tx <= SUCCESSFULLY_RECEIVED;
							answer 	<= 1'b1;
						end
						else begin
							data_tx <= NOT_ALL_RECEIVED;
							answer 	<= 1'b1;
						end
					end
				end
/*
				SUCCESS: begin
					done 	<= 1'b1;
					data_tx <= SUCCESSFULLY_RECEIVED;
					answer 	<= 1'b1;
				end

				STOP_WORD: begin
					data_tx <= NOT_ALL_RECEIVED;
					answer 	<= 1'b1;
				end
*/
				default: begin
					row 		<= '0;
					uart_data 	<= '0;
					answer 		<= '0;
					cnt_data	<= '0;
					done		<= '0;
					data_tx		<= '0;
				end
			endcase
		end
	end


endmodule // UART_ARINC_Controller
