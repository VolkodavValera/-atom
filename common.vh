//--------------------------------------------------------------------------------
//                                                          ������ "���������",���
//                                                          http://www.navigat.ru/
//������    : �����-2010-04
//�����     : CSA
//E-mail    :
//����      :
//��������  : ����� ��������� ���������
//--------------------------------------------------------------------------------

`ifndef COMMON_VH       // ���� ��� �� �������?

`define COMMON_VH       // ��� �������������� ���������� ���������

//������� �� ���� AVALON
`define SYS_CLK                         50_000_000

//����������� ���� ������ AVALON
`define AVALON_DATA_WIDTH               32

//������� ������ 40 ���
`define ACLK                            40000000

// �������������� ������ � �������

`define COMPONENT_TYPE_ID_RTC		    8'h0a
`define COMPONENT_TYPE_ID_ARINC429TX    8'h0e
`define COMPONENT_TYPE_ID_ARINC429RX    8'h0f
`define COMPONENT_TYPE_ID_ARINC708TX    8'h0b
`define COMPONENT_TYPE_ID_ARINC708RX    8'h0c

`define SET								1'b1
`define CLR								1'b0

//��������� �������� �������� ���������� �������
//	��� � 0 (��)
`define DOUT_AFTER_RESET				32'b0000_0000_0000_0000_0000_0000_0000_0000

`endif
