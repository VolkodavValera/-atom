//--------------------------------------------------------------------------------
//                                                          ������ "���������",���
//                                                          http://www.navigat.ru/
//������    : �����-2010-04/���� ����������/����� �� ����.466531.002-01 [0]
//�����     : sma
//E-mail    : 
//����      : 
//��������  :  ���� �������� ����� ������� 
//-------------------------------------------------------------------------------------------------


//-------------------------------------------------------------------------------------------------
// ������� �������� � ���������� ��������� �������� � �������� 
//-------------------------------------------------------------------------------------------------
`define PACK_ARRAY(  GENVAR, PK_WIDTH, PK_LEN, PK_SRC, PK_DEST) genvar GENVAR; generate for(GENVAR = 0;GENVAR < (PK_LEN); GENVAR = GENVAR + 1) begin assign PK_DEST[((PK_WIDTH)*GENVAR + ((PK_WIDTH)-1)):((PK_WIDTH)*GENVAR)] = PK_SRC[GENVAR];end endgenerate
`define UNPACK_ARRAY(GENVAR, PK_WIDTH, PK_LEN, PK_DEST, PK_SRC) genvar GENVAR; generate for(GENVAR = 0;GENVAR < (PK_LEN); GENVAR = GENVAR + 1) begin assign PK_DEST[GENVAR] = PK_SRC[((PK_WIDTH)*GENVAR + ((PK_WIDTH)-1)):((PK_WIDTH)*GENVAR)];end endgenerate


//-------------------------------------------------------------------------------------------------
// ������� clog2_func
// ���������� ����������� � ������� ������� �������� ��������� �� ��������� 2
//-------------------------------------------------------------------------------------------------
function integer clog2_func;
    input integer depth;
    integer i,res;
    begin
        for(i = 0; 2**i < depth; i = i + 1)
            res = i + 1;
        clog2_func = res;
    end          
endfunction

function integer nbits;
    input integer value;
    begin
       value = value < 0 ? -value : value;
       for (nbits=0; value>0; nbits=nbits+1)
	   begin
          value = value>>1;
       end
    end
endfunction