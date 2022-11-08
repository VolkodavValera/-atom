

#include "bbopers.h"


/*-------------------   NAME   --------------------  BIT POSITION -------------*/

static const char DEFUALT_PREAMBLE = 0b00101101;  /* 1 - 8   const values*/





unsigned char set_nbit_in_byte8_at_right(int nbit) {
    unsigned char byte8 = 0;

    if ( nbit == 0 )
        return 0;

    do {
        byte8 = byte8 << 1;
        byte8 |= 1;
    } while ( --nbit );

    return byte8;
}

unsigned short set_nbit_in_byte16_at_right(int nbit) {
    unsigned short byte16 = 0;

    do {
        byte16 = byte16 << 1;
        byte16 |= 1;
    } while ( --nbit );

    return byte16;
}

unsigned int set_nbit_in_byte32_at_right(int nbit) {
    unsigned int byte32 = 0;

    do {
        byte32 = byte32 << 1;
        byte32 |= 1;
    } while ( --nbit );

    return byte32;

}






int32_t convert_bits_to_bytes(  void *raw_buf, size_t raw_size,
                            unsigned char *res_buf, size_t res_size,
                            int nbit) {


    /* here is not enough space in the resulting buffer
     * for all numbers of length nbit */
    if ( res_size < raw_size * 8 / nbit )
        return -1;


    memset(res_buf, 0, res_size);

    /* start bit offset */
    int bit_offset = 8 - nbit;

    /* bitmask, to extract the required number f bits */
    unsigned char pop_save_bitmap = set_nbit_in_byte8_at_right(nbit);


    unsigned char *praw = (unsigned char *)raw_buf;

    unsigned char byte = *praw;


    /* I immediately calculate the bitmasks for all the required shifts
     * that will be possible during the cycle
     * to save time on calling set_nbit_in_byte8_at_right */
    unsigned char addition_bit_maps[nbit - 1];

//    /* if the number of bits in which the value is stored is even */
//    char even_flag = !(nbit % 2);

    /* calculating bitmasks */
    for (int i = 0; i < nbit; i++)
        addition_bit_maps[i] = set_nbit_in_byte8_at_right(i);

    while ( raw_size ) {
//        printf("bit to byte raw_size: %d, bit_offset: %d\n", raw_size, bit_offset);

        if ( bit_offset >= 0 ) {

            *res_buf++ = ( ( byte >> bit_offset ) & pop_save_bitmap );

            if ( bit_offset == 0 ) {
                bit_offset = 8 - nbit;

                goto buf_increment;
            } else
                bit_offset -= nbit;

            continue;

        } else if ( bit_offset < 0 ) {

            *res_buf++ = ( ( byte &   addition_bit_maps[ABS(nbit + bit_offset)] ) << ( -bit_offset ) )
                            | ( *(praw + 1) >> ( 8 + bit_offset ) );

            bit_offset = 8 + bit_offset - nbit;
        }


buf_increment:
            byte = *(++praw);
            --raw_size;
    }



    return 0;
}

int32_t convert_bytes_to_bits(  void *dest_buf, size_t dest_size,
                            unsigned char *src_buf, size_t src_size,
                            int nbit) {


    /* here is not enough space in the resulting buffer
     * for all numbers of length nbit */
    if ( dest_size * 8 / nbit < src_size)
        return -1;


    memset(dest_buf, 0, dest_size);

    /* start bit offset */
    int bit_offset = 8 - nbit;

    /* bitmask, to extract the required number f bits */
    unsigned char pop_save_bitmap = set_nbit_in_byte8_at_right(nbit);


    unsigned char *pdest = (unsigned char *)dest_buf;

    unsigned char byte = *pdest;


    /* I immediately calculate the bitmasks for all the required shifts
     * that will be possible during the cycle
     * to save time on calling set_nbit_in_byte8_at_right */
    #if 0
    unsigned char addition_bit_maps[nbit - 1];
    #endif // 0
    /* if the number of bits in which the value is stored is even */
//    char even_flag = !(nbit % 2);

    /* calculating bitmasks */
    #if 0
    for (int i = 0; i < nbit; i++)
        addition_bit_maps[i] = set_nbit_in_byte8_at_right(i);
    #endif

    while ( src_size-- ) {

        byte = *src_buf++;

        if ( bit_offset >= 0) {
            *pdest = ( *pdest | ( (byte & pop_save_bitmap) << bit_offset ) );

            if ( bit_offset == 0 ) {
                bit_offset = 8 - nbit;

                goto buf_increment;
            } else
                bit_offset -= nbit;

            continue;
        } else {
            *pdest = ( *pdest | ( (byte & pop_save_bitmap) >> (-bit_offset) )  );
            *(pdest + 1) = ( *(pdest + 1) | ((byte & pop_save_bitmap) << (8 + bit_offset)) );

            bit_offset = 8 + bit_offset - nbit;
        }

buf_increment:
            ++pdest;
    }


    return 0;
}
