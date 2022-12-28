#ifndef __SERIAL__
#define __SERIAL__

#include<stdio.h>
#include<string.h>
#include<stdlib.h>
#include<sys/stat.h>
#include<sys/types.h>
#include<stddef.h>
#include<unistd.h>
#include<dirent.h>
#include<fcntl.h>
#include<windows.h>
#include<time.h>
#include <stdint.h>

#define baudrate CBR_115200
#define bytesize 8
#define stopBits TWOSTOPBITS
#define parity   NOPARITY //EVENPARITY

#define FAULT (-1)
#define OK    (0)

HANDLE serial_open(char* pname);
uint32_t serial_set(HANDLE h);
HANDLE serial_init(char* pname);

uint32_t serial_read(HANDLE h, uint8_t* buffer, uint32_t size);

uint32_t serial_free(HANDLE h);
uint32_t serial_nb_read(HANDLE h, uint8_t* buffer, uint32_t size, uint32_t* n);

uint32_t serial_write(HANDLE h, uint8_t* buffer, uint32_t size);
void serial_close(HANDLE h);

#endif
