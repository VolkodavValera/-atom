
#ifndef BBOPERS_H
#define BBOPERS_H

#include <string.h>
#include <stdint.h>



#define ABS(v) (v > 0 ? v : -v)


unsigned char set_nbit_in_byte8_at_right(int nbit);
unsigned short set_nbit_in_byte16_at_right(int nbit);
unsigned int set_nbit_in_byte32_at_right(int nbit);


/* @param nbit how many bits are encoded for each value */
int32_t convert_bits_to_bytes(  void *raw_buf, size_t raw_size,
                            unsigned char *res_buf, size_t res_size,
                            int nbit);

/*
 * функция берёт байты src_buf и из каждого берёт nbit первых бит справа и укладывает их поочерёдно в dest_buf
 *
 */
int32_t convert_bytes_to_bits(  void *dest_buf, size_t dest_size,
                            unsigned char *src_buf, size_t src_size,
                            int nbit);


#endif /* BBOPERS_H */
