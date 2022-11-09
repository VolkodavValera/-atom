module UART_Controller (clk, rst_n, rxd, txd, row, uart_data, done);
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


parameter Wight             = 640;
parameter Height            = 480;

localparam  START_WORD 		= 0;
localparam  ROW_VALUE 		= 1;
localparam  CONVERT_BYTE_1 	= 2;
localparam  CONVERT_BYTE_2 	= 3;
localparam  CONVERT_BYTE_3 	= 4;
localparam  SUCCESS 		= 5;
localparam  STOP_WORD 		= 6;

/*----------------------------------------------------------------------------------*/
/*									Input											*/
/*----------------------------------------------------------------------------------*/
	input							clk;
	input							rst_n;

    input                           rxd;

/*----------------------------------------------------------------------------------*/
/*									Output											*/
/*----------------------------------------------------------------------------------*/
	output                          txd;
	output [3 * Wight - 1 : 0]		uart_data;
	output [8:0]					row;
	output 							done;

/*----------------------------------------------------------------------------------*/
/*									Variables										*/
/*----------------------------------------------------------------------------------*/
	logic [7:0] 					data_rx;
	logic [7:0] 					data_tx;
	logic 							start_tx;
	wire 							busy;
	wire 							busy_neg;
	logic 							done_byte;
	logic [2:0] 					state;
	logic 							answer;
	logic 							answer_err;
	logic [9:0] 					cnt_data = '0;



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
        UART_RX.DEFAULT_BDR     = DEFAULT_BDR;

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
        UART_TX.DEFAULT_BDR     = DEFAULT_BDR;
/*----------------------------------------------------------------------------------*/
/*									State Mashines									*/
/*----------------------------------------------------------------------------------*/
	// State
	always_ff @ (posedge clk) begin
		if (!rst_n) state <= START_WORD;
		else if (done_byte) begin
			case (state)

				START_WORD: begin
					state <= ROW_VALUE;
				end

				ROW_VALUE: begin
					state <= CONVERT_BYTE_1;
				end

				CONVERT_BYTE_1: begin
					if (data_rx == END_WORD) state <= STOP_WORD;
					else if (cnt_data == Wight) state <= SUCCESS;
					else state <= CONVERT_BYTE_2;
				end

				CONVERT_BYTE_2: begin
					if (data_rx == END_WORD) state <= STOP_WORD;
					else if (cnt_data == Wight) state <= SUCCESS;
					else state <= CONVERT_BYTE_3;
				end

				CONVERT_BYTE_3: begin
					if (data_rx == END_WORD) state <= STOP_WORD;
					else if (cnt_data == Wight) state <= SUCCESS;
					else state <= CONVERT_BYTE_1;
				end


				SUCCESS: begin
					state <= START_WORD;
				end

				STOP_WORD: begin
					state <= START_WORD;
				end

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
			answer		<= '0;
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
					answer 		<= '0;
					cnt_data	<= '0;
					done		<= '0;
					answer		<= '0;
				end

				ROW_VALUE: begin
					row[7:0] <= data_rx;
				end

				CONVERT_BYTE_1: begin
					uart_data[3 * cnt_data] 	<= data_rx[0];
					uart_data[3 * cnt_data + 1] <= data_rx[1];
					uart_data[3 * cnt_data + 2] <= data_rx[2];
					uart_data[3 * cnt_data + 3] <= data_rx[3];
					uart_data[3 * cnt_data + 4] <= data_rx[4];
					uart_data[3 * cnt_data + 5] <= data_rx[5];
					uart_data[3 * cnt_data + 6] <= data_rx[6];
					uart_data[3 * cnt_data + 7] <= data_rx[7];

					cnt_data 					<= cnt_data + 2;
				end

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


				SUCCESS: begin
					done 	<= 1'b1;
					data_tx <= SUCCESSFULLY_RECEIVED;
					answer 	<= 1'b1;
				end

				STOP_WORD: begin
					data_tx <= NOT_ALL_RECEIVED;
					answer 	<= 1'b1;
				end

				default: begin
					row 		<= '0;
					uart_data 	<= '0;
					answer 		<= '0;
					cnt_data	<= '0;
					done		<= '0;
					answer		<= '0;
					data_tx		<= '0;
				end
			endcase
		end
	end


endmodule // VGA_Controller
