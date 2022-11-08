#include <windows.h>
#include <stdio.h> // стандартная библиотека Си
#include <string.h> // для работы со строками
#include <stdlib.h> // для работы с памятью
#include <locale.h>
#include <unistd.h>
#include "list.h"
#include "serial.h"

char* Handle_Name   = "\\\\.\\COM4";
char* File_Name     = "init_mem_uart2.txt"

int main() {

    setlocale(LC_ALL, "russian");

    // Open serial port
    HANDLE serialHandle;
    DWORD BytesWritten = 0;          // No of bytes written to the port
    char str[4];
    char *r_str;
    char SerialBuffer;
    char *estr;
    FILE *f;
    list *database = init_list();
    int n = 0;

    serialHandle = serial_init(Handle_Name);

    if ((f = fopen(File_Name, "r")) == NULL)
    {
      printf("Fail open file");
      return 1;
    }


    printf("The file has ended\n");
    serial_close(serialHandle);

    return 0;
}
