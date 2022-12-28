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
#define SIZE_BUFFER             BYTE_SIZE_Y + BYTE_SIZE_ROW + BYTE_SIZE_STOP
#define NUMBER_ROWS             480
#define SIZE_BYTE               8
#define STOP_BYTE               0xDD
#define SUCCESSFULLY_RECEIVED   0xBC
#define NOT_ALL_RECEIVED        0x11
#define ANSWER_CODE             0xAA
#define ANSWER_CODE_TAKE_ROW    0xCC

char* Handle_Name   = "\\\\.\\COM5";
char* File_Name     = "init_mem_uart2.txt";

int main() {

    setlocale(LC_ALL, "russian");

    // Open serial port
    HANDLE serialHandle;
    DWORD BytesWritten = 0;          // No of bytes written to the port
    unsigned char str[4];
    unsigned char data[WIDTH_DISPLAY];
    unsigned char SerialBuffer[NUMBER_ROWS][SIZE_BUFFER];
    FILE *f;
    list *database = init_list();
    unsigned char rx_data;
    int n = 0, m = 0;

    serialHandle = serial_init(Handle_Name);

    if ((f = fopen(File_Name, "r")) == NULL)
    {
      printf("Fail open file");
      return 1;
    }

    /* ---------------------------------------------------- */
    /* |                       word                       | */
    /* ---------------------------------------------------- */
    /* |                    SIZE_BUFFER                   | */
    /* ---------------------------------------------------- */
    /* |  NUMBER_ROWS  |      date        |    END_WORD   | */
    /* ---------------------------------------------------- */
    /* | BYTE_SIZE_Y  |   BYTE_SIZE_ROW  | BYTE_SIZE_STOP | */
    /* ---------------------------------------------------- */

    /*  Row - 640 pixel, data - 3 bit,  640 * 3 = 8 * 240   */

    for (size_t i = 0; i < NUMBER_ROWS; i++) {

        // String value
        SerialBuffer[i][0] = i >> SIZE_BYTE;
        SerialBuffer[i][1] = (char) i;

        // Line-by-line reading of data from a file and comparison with a palette
        for (size_t j = 0; j < WIDTH_DISPLAY; j++) {
            fgets(str, sizeof(str), f);
            if (strlen(str) == 1) fgets(str, sizeof(str), f);
            data[j] = comparison_with_list(database, str);
            memset(str, '\0', strlen(str));
        }

        // Placing a line in the buffer
        if ( convert_bytes_to_bits(SerialBuffer[i] + BYTE_SIZE_Y, BYTE_SIZE_ROW, data, WIDTH_DISPLAY, 3) < 0 ) {
            printf ("convert error\n");
        }

        //  End of the word
        SerialBuffer[i][SIZE_BUFFER - 1] = STOP_BYTE;
        //printf("SerialBuffer[%d][%d] (before) = %x\n", i, SIZE_BUFFER, SerialBuffer[i][SIZE_BUFFER]);
        //if (i != 0) printf("SerialBuffer[%d][%d] = %x - SerialBuffer[%d][%d] = %x\n", i-1, SIZE_BUFFER, SerialBuffer[i-1][SIZE_BUFFER - 1], i, SIZE_BUFFER, SerialBuffer[i][SIZE_BUFFER - 1]);
    }

    printf("convert greate\n");
    printf("Size: %d", sizeof(SerialBuffer[0]));
/*
    for (size_t i = 0; i < NUMBER_ROWS; i++) {
        printf("SerialBuffer[%d] = %d %d\n", i, SerialBuffer[i][0], SerialBuffer[i][1]);
        printf("SerialBuffer[%d][%d] (after) = %x\n", i, SIZE_BUFFER, SerialBuffer[i][SIZE_BUFFER - 1]);
    }
*/
    printf("%x\n", STOP_BYTE);
    printf("/-----------------------------------/\n");
    printf("/---------------START---------------/\n");
    printf("/-----------------------------------/\n\n");


#if 0
    while (n != NUMBER_ROWS) {
        if (serial_write(serialHandle, SerialBuffer[n], SIZE_BUFFER) < 0) {
            printf("Error write handle\n");
            return 1;
        }
        else printf("Write success\n");
        printf("wait answer\n");

        if (serial_read (serialHandle, &rx_data, 1) < 0) {
            printf("Error read handle\n");
            return 1;
        }
        else printf("Read success! RX_DATA = %x\n", rx_data);
        if (rx_data == SUCCESSFULLY_RECEIVED) n++;
        else if (rx_data == NOT_ALL_RECEIVED) {
            //serial_read (serialHandle, &rx_data, 1);
            printf("The amount of data not received: %в\n", rx_data);
        }
        else {
            printf("error answer\n");
            return 1;
        }
    }

#else
    while (n != NUMBER_ROWS) {
        printf ("\n/--------row - %d    byte - %d------/\n", n, m);
        printf ("/-----------------------------------/\n");
        
        if (serial_write(serialHandle, SerialBuffer[n]+m, 1) < 0) {
            printf("Error write handle\n");
            return 1;
        }

        if (serial_read (serialHandle, &rx_data, 1) < 0) {
            printf("Error read handle\n");
            return 1;
        }
        else printf("Read success! RX_DATA = %x\n", rx_data);

        if (rx_data == SUCCESSFULLY_RECEIVED) {
            m = 0;
            n++;
        }
        else if (rx_data == NOT_ALL_RECEIVED) m = 0;
        else if (rx_data == ANSWER_CODE_TAKE_ROW) {
            m++;
            printf("Take row!\n");
            if (m == 2) {
                printf ("/-----------------------------------/\n");
                printf ("/------------ROW TAKE FULL----------/\n");
            }
        }
        else if (rx_data == ANSWER_CODE) {
            m++;
            printf("Greate answer\n");
        }
        else printf ("This is not the message we've been waiting for!\n");

        printf ("/-----------------------------------/\n");
    }
#endif
    printf("The file has ended\n");
    serial_close(serialHandle);

    return 0;
}
