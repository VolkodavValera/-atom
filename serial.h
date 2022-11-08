#ifndef _LIST_
#define _LIST_

#include <windows.h>
#include <stdio.h> // стандартная библиотека Си
#include <string.h> // для работы со строками
#include <stdlib.h> // для работы с памятью
#include <unistd.h>

#define baudrate CBR_115200
#define bytesize 8
#define stopBits TWOSTOPBITS
#define parity   EVENPARITY //NOPARITY

HANDLE serial_open(char* pname);
uint32_t serial_set(HANDLE h);
HANDLE serial_init(char* pname);

uint32_t serial_read(HANDLE h, uint8_t* buffer, uint32_t size);

uint32_t serial_free(HANDLE h);
uint32_t serial_nb_read(HANDLE h, uint8_t* buffer, uint32_t size, uint32_t* n);

uint32_t serial_write(HANDLE h, uint8_t* buffer, uint32_t size);
void serial_close(HANDLE h);

#endif
