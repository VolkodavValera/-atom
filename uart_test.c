#include <windows.h>
#include <stdio.h> // стандартная библиотека Си
#include <string.h> // для работы со строками
#include <stdlib.h> // для работы с памятью
#include <locale.h>
#include <unistd.h>
#include <stdint.h>
#include "list.h"
#include "serial.h"
#include "bbopers.h"

#define WIDTH_DISPLAY           640
#define BYTE_SIZE_ROW           240
#define BYTE_SIZE_Y             2
#define BYTE_SIZE_STOP          1
#define NUMBER_ROWS             480
#define SIZE_BYTE               8
#define STOP_BYTE               0xDD
#define SUCCESSFULLY_RECEIVED   0xFF
#define NOT_ALL_RECEIVED        0x11

char* Handle_Name   = "\\\\.\\COM4";
char* File_Name     = "init_mem_uart2.txt";

int main() {

    setlocale(LC_ALL, "russian");

    // Open serial port
    HANDLE serialHandle;
    DWORD BytesWritten = 0;          // No of bytes written to the port
    unsigned char str[4];
    unsigned char data[WIDTH_DISPLAY];
    unsigned char SerialBuffer[NUMBER_ROWS][BYTE_SIZE_Y + BYTE_SIZE_ROW + BYTE_SIZE_STOP];
    FILE *f;
    list *database = init_list();
    unsigned char rx_data;
    int n = 0;

    serialHandle = serial_init(Handle_Name);

    if ((f = fopen(File_Name, "r")) == NULL)
    {
      printf("Fail open file");
      return 1;
    }

    for (size_t i = 0; i < NUMBER_ROWS; i++) {
        SerialBuffer[i][0] = i >> SIZE_BYTE;
        SerialBuffer[i][1] = (char) i;
        SerialBuffer[i][BYTE_SIZE_Y + BYTE_SIZE_ROW + BYTE_SIZE_STOP] = STOP_BYTE;
        for (size_t j = 0; j < WIDTH_DISPLAY; j++) {
            fgets(str, sizeof(str), f);
            if (strlen(str) == 1) fgets(str, sizeof(str), f);
            data[j] = comparison_with_list(database, str);
            memset(str, '\0', strlen(str));
        }
        if ( convert_bytes_to_bits(SerialBuffer[i] + BYTE_SIZE_Y, BYTE_SIZE_ROW, data, WIDTH_DISPLAY, 3) < 0 ) {
            printf ("convert error\n");
        }
    }
    printf("convert greate\n");
    while (n != NUMBER_ROWS) {
        if (serial_write(serialHandle, SerialBuffer[n], BYTE_SIZE_Y + BYTE_SIZE_ROW + BYTE_SIZE_STOP) < 0) {
            printf("Error write handle\n");
            return 1;
        }
        printf("wait answer\n");
        if (serial_nb_read (serialHandle, &rx_data, 1, 0) < 0) {
            printf("Error read handle\n");
            return 1;
        }
        if (rx_data == SUCCESSFULLY_RECEIVED) n++;
        else if (rx_data == NOT_ALL_RECEIVED) {
            serial_nb_read (serialHandle, &rx_data, 1, 0);
            printf("The amount of data not received: %в\n", rx_data);
        }
        else {
            printf("error answer\n");
            return 1;
        }
    }


    printf("The file has ended\n");
    serial_close(serialHandle);

    return 0;
}
