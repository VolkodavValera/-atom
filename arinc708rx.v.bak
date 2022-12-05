//--------------------------------------------------------------------------------
//                                                          ВНИИРА "НАВИГАТОР",СПб
//                                                          http://www.navigat.ru/
//Проект    :
//Автор     : CSA
//E-mail    :
//Дата      :
//Описание  : Модуль управления драйвером   ARINC 708
//            с подключением к Avalon и
//            выходом для регистратора системных событий функции
//-------------------------------------------------------------------------------------------------

`include "Common/source/common.vh"

//-------------------------------------------------------------------------------------------------
//модуль arinc708rx
//-------------------------------------------------------------------------------------------------
module arinc708rx (
	//AVALON интерфейс
    clk_drv,
	rst_n,
	address,
	read,
	readdata,
	write,
	writedata,
	//Внешний интерфейс
	ain,
	bin,
	irq,
    done
);

	`include "Common/source/cflib.v"

    //---------------------------------------------------------------------------------------------
    //параметры
    //---------------------------------------------------------------------------------------------

	`include "arinc708tx.vh"


    parameter  [7:0] ENTITY_ID  = 0;
    localparam FIFO_NUMWORDS    = `ARINC708_FIFO_NWORD;
    localparam FIFO_WIDTHU      = clog2_func(FIFO_NUMWORDS + 1);

	// TCLK = 50 тактов в периоде сигнала 1MHZ
	// TCLK/4 = 50/4 = 12

	localparam sync_cnt_min  = 8'd12; //  0+(1/4)
	localparam sync_cnt_mid  = 8'd37; // 25+(1/4)
	localparam sync_cnt_max	 = 8'd63; // 75-(1/4)

	localparam sync_cnt_78CLK = 8'd78; // 75-(1/4)

	//состояния автомата
     localparam IDLE            = 0;
	 localparam SYNC            = 1;
	 localparam RECV		    = 2;
	 localparam WFIFO 		    = 3;
	 localparam DONE		    = 4;

    //---------------------------------------------------------------------------------------------
    //входные порты
    //---------------------------------------------------------------------------------------------
    input                           clk_drv;
    input                           rst_n;
    input [ADDRESS_WIDTH - 1:0]     address;
    input                           read;
    input                           write;
    input [31:0]                    writedata;

	input                           ain;
    input                           bin;

    //---------------------------------------------------------------------------------------------
    //выходные порты
    //---------------------------------------------------------------------------------------------
    output [31:0]                   readdata;
	output  						irq;
    output                          done;

   //---------------------------------------------------------------------------------------------
   //переменные
   //---------------------------------------------------------------------------------------------

	wire posin;
	wire negin;
	wire pnedge;
	wire edge_ain;
	wire edge_bin;
	wire rx_done;


	integer i;

    reg [ADDRESS_DEPTH - 1:0]       dec_write;          // дешифратор адреса
    reg [31:0]                      temp_data;          // регистр временного хранения данных чтения с шины avalon
	reg                             module_rst;         // программный сброс
    reg                             ena_ff;             // програмное включение/отключение работы модуля от драйвера
	reg [31:0]                      nbuf;               // регистр текущего количества слов в FIFO передатчике
    wire [FIFO_WIDTHU - 1:0]        fifo_usedw;         // количество слов в fifo


	reg [7:0]  abcnt  = 8'd0;
	reg [7:0]  abcnt_ff  = 8'd0;
	reg [7:0]  pcnt_ff  = 8'd0;
	reg [7:0]  stat_ff  = 8'd0;
	reg [11:0] total_bitcnt;
	reg [4:0]  bitcnt;
	reg [31:0] sreg;
	reg [31:0] sreg_ff;
	reg        d_ff;
	reg        rx_mode_ff;
	reg        pnedge_ff = 1'd0;
	reg  	   rx_done_ff = 1'd0;
	reg 	   fsync_ff = 1'b1;
	reg        strobe_pcnt_ff = 1'b0;
	reg        in_ff;
    reg        done_sreg;


   //---------------------------------------------------------------------------------------------
   // основной код
   //---------------------------------------------------------------------------------------------

    //дешифратор адреса и формирование порегистровых сигналов чтения/записи------------------------
    always @(*)
        begin
            for(i = 0 ; i < ADDRESS_DEPTH ; i = i + 1)
                begin
                    dec_write[i] = write & (address == i);
                end
        end

    //формирование выходных данных на шине---------------------------------------------------------
    always @(*)
        begin

            //nbuf[FIFO_WIDTHU - 1:0] = fifo_usedw_ff;
            nbuf[31:FIFO_WIDTHU]  = 0;

            case (address)
                ID :
                    begin
                        temp_data[31:16] = 16'h0000;
                        temp_data[15:8]  = `COMPONENT_TYPE_ID_ARINC708RX;
                        temp_data[7:0]   = ENTITY_ID;
                    end

				DATA :
                    begin
                        temp_data = sreg_ff;
                    end

				NBUF :
                    begin
                        temp_data = nbuf;
                    end
                WBUF :
                    begin
                        temp_data = FIFO_NUMWORDS;
                    end
                CTRL :
                    begin
                        temp_data                  = 32'h0000_0000;
                        temp_data[ENA]             = ena_ff;
                    end

                default:
                    begin
                        temp_data = 32'hdead_beef;
                    end
            endcase
        end

    assign readdata = temp_data;

    //сигнал сброса модуля-------------------------------------------------------------------------
    always @ (negedge rst_n or posedge clk_drv)
        begin
            if (!rst_n)
                begin
                    module_rst <= 1'b0;
                end
            else
            begin
                module_rst <=  (
                                dec_write[CTRL] |
                                dec_write[CSET] |
                                dec_write[CCLR]
                               ) & writedata[RST];
            end
        end

    //блок регистров-------------------------------------------------------------------------------
    always @ (negedge rst_n or posedge clk_drv)
        begin
            if (!rst_n)
                begin
                    ena_ff      <= 1'b0;
                 end
            else if (module_rst)
                begin
                    ena_ff      <= 1'b0;
                end
            else
                begin

                    //доступ к битам CTRL----------------------------------------------------------

                    if(dec_write[CTRL])
                        begin
                            ena_ff      <= writedata[ENA];
                        end
                    else if(dec_write[CSET])
                        begin
                            ena_ff      <= ena_ff     | writedata[ENA];
                        end
                    else if(dec_write[CCLR])
                        begin
                            ena_ff      <= ena_ff     & ~writedata[ENA];
                        end

                end
        end



   //  Код обработки входного сигнала для моделсима (нужное разкоментировать)
   //---------------------------------------------------------------------------------------------

	assign pnedge = (posin | negin) & fsync_ff;

	pos pos_in_ff_module(clk_drv,ain,posin);
	neg neg_in_ff_module(clk_drv,ain,negin);


    // счетчик длительности импульса от фронта до фронта
	always @ (posedge clk_drv)
	    begin
			if(posin || negin) abcnt = 8'd0;
			else if(abcnt < 8'd200)  abcnt <= abcnt + 8'd1;
		 end

    // задержка хранения результата счета
	always @ (posedge clk_drv) abcnt_ff <= abcnt;

	// задержка
	always @ (posedge clk_drv) pnedge_ff <= pnedge;

    // интервал проверки смены фазы
	always @ (posedge clk_drv) begin

		if(~fsync_ff) strobe_pcnt_ff <= 1'b0;
		else if(pcnt_ff < sync_cnt_min) strobe_pcnt_ff <= 1'b1;
			 else if(pcnt_ff > sync_cnt_mid) strobe_pcnt_ff <= 1'b1;
				  else strobe_pcnt_ff <= 1'b0;
	end

    // подсчет принятых бит данных
	always @ (posedge clk_drv) begin

        if (!fsync_ff) total_bitcnt <= 12'd0;
		else if(strobe_pcnt_ff && pnedge) total_bitcnt <= total_bitcnt + 12'd1;
	end



	// Код обработки входного сигнала для аппаратуры (нужное разкоментировать)
    //---------------------------------------------------------------------------------------------

/*

	edgedet ain_edgedet_module (clk_drv,ain,edge_ain);
	edgedet bin_edgedet_module (clk_drv,bin,edge_bin);

	// RS-тригер востановления огибающей
	always @ (posedge clk_drv)
	    begin
			if(edge_ain) in_ff <= 1'b1;
			else if(edge_bin) in_ff <= 1'b0;
	 end

	assign pnedge = (posin | negin) & fsync_ff;

	pos pos_in_ff_module(clk_drv,in_ff,posin);
	neg neg_in_ff_module(clk_drv,in_ff,negin);


	    // счетчик длительности импульса от фронта до фронта
	always @ (posedge clk_drv)
	    begin
			if(posin || negin) abcnt <= 8'd0;
			else if(abcnt < 8'd200)  abcnt <= abcnt + 8'd1;
		 end

	// задержка
	always @ (posedge clk_drv) abcnt_ff <= abcnt;

	// задержка
	always @ (posedge clk_drv) pnedge_ff <= pnedge;

	// задержка
	always @ (posedge clk_drv) rx_done_ff <= rx_done;


    // интервал проверки смены фазы
	always @ (posedge clk_drv) begin

		if(~fsync_ff) strobe_pcnt_ff <= 1'b0;
		else if(pcnt_ff < sync_cnt_min) strobe_pcnt_ff <= 1'b1;
			 else if(pcnt_ff > sync_cnt_mid) strobe_pcnt_ff <= 1'b1;
				  else strobe_pcnt_ff <= 1'b0;
	end

    // подсчет принятых бит данных
	always @ (posedge clk_drv) begin

        if (!fsync_ff) bitcnt <= 8'd0;
		else if(strobe_pcnt_ff && pnedge) bitcnt <= bitcnt + 8'd1;
	end


*/

   //---------------------------------------------------------------------------------------------
   // Автомат
   //---------------------------------------------------------------------------------------------

     always @ (negedge rst_n or posedge clk_drv)
        begin
            if (!rst_n)
                begin
					stat_ff <= IDLE;
					fsync_ff <= 1'd0;
					rx_done_ff <= 1'd0;
					sreg <= 32'd0;
					sreg_ff <= 32'd0;
					rx_mode_ff <= 1'd0;
					bitcnt <= 5'd0;
                    done_sreg <= 1'b0;
                end
            else
                begin
                    case (stat_ff)

					IDLE:
						begin
							fsync_ff <= 1'd0;
							pcnt_ff <= 8'd0;
							rx_done_ff <= 1'd0;
							sreg <= 32'd0;
							if(negin && (abcnt_ff > sync_cnt_max)) stat_ff <= SYNC;
						end
					SYNC:
					begin

						if(posin && (abcnt_ff > sync_cnt_max)) begin

							stat_ff <= RECV;
							fsync_ff <= 1'd1;


							if(abcnt_ff > sync_cnt_78CLK) begin // проверка начальной фазы

								sreg <= 32'h00_00_00_00;
								pcnt_ff <= 8'd0;
								rx_mode_ff <= 1'd0;
							end
							else begin
								sreg <= 32'h80_00_00_00;
								pcnt_ff <= sync_cnt_mid;
								rx_mode_ff <= 1'd1;
							end

						end

					end

					RECV: begin

						if(pnedge && (pcnt_ff > sync_cnt_mid)) begin
							pcnt_ff <= 8'd0;
						end
						else pcnt_ff <= pcnt_ff + 8'd1;

						if(!rx_mode_ff && pnedge_ff && (bitcnt == 5'b11111)) begin
                            sreg_ff[31:0] <= sreg[31:0];
                            done_sreg <= `SET;
                        end
                        else done_sreg <= 1'b0;

						if(total_bitcnt == 12'd1600) stat_ff <= DONE;

						if(strobe_pcnt_ff) begin

							if(posin) begin

								sreg <= sreg >> 32'd1;
								bitcnt <= bitcnt + 5'd1;
							end
							else if(negin) begin

								sreg <= (sreg >> 32'd1) | 32'h80000000;
								bitcnt <= bitcnt + 5'd1;
							end
						  end
					end


					DONE: begin

					  stat_ff <= IDLE;
					  rx_done_ff <= `SET;
                      done_sreg <= 1'b0;

					end


					endcase
				end
		end


	assign done = rx_done_ff;
    assign irq = done_sreg;

    endinterface = (source);

	//assign dout = sreg_ff;


endmodule
