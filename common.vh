//--------------------------------------------------------------------------------
//                                                          ВНИИРА "НАВИГАТОР",СПб
//                                                          http://www.navigat.ru/
//Проект    : МСНВО-2010-04
//Автор     : CSA
//E-mail    :
//Дата      :
//Описание  : Общие системные константы
//--------------------------------------------------------------------------------

`ifndef COMMON_VH       // Файл еще не включен?

`define COMMON_VH       // Для предотвращения повторного включения

//частота на шине AVALON
`define SYS_CLK                         50_000_000

//разрядность шини данных AVALON
`define AVALON_DATA_WIDTH               32

//частота домена 40 МГЦ
`define ACLK                            40000000

// идентификаторы модуля в системе

`define COMPONENT_TYPE_ID_RTC		    8'h0a
`define COMPONENT_TYPE_ID_ARINC429TX    8'h0e
`define COMPONENT_TYPE_ID_ARINC429RX    8'h0f
`define COMPONENT_TYPE_ID_ARINC708TX    8'h0b
`define COMPONENT_TYPE_ID_ARINC708RX    8'h0c

`define SET								1'b1
`define CLR								1'b0

//начальные значения выходных дискретных каналов
//	Все в 0 (хх)
`define DOUT_AFTER_RESET				32'b0000_0000_0000_0000_0000_0000_0000_0000

`endif
