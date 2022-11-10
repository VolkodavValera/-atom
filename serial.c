#include "serial.h"

HANDLE serial_open(char* pname)
{
	HANDLE serialHandle;
    serialHandle = CreateFile(pname, GENERIC_READ | GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

    if (serialHandle == INVALID_HANDLE_VALUE)
        printf("Error in opening serial port\n");
    else
        printf("opening serial port successful\n");

	return serialHandle;
}

uint32_t serial_set(HANDLE serialHandle)
{
    DCB serialParams = { 0 };
    COMMTIMEOUTS timeout = { 0 };
    BOOL Status;

    // Do some basic settings
    serialParams.DCBlength = sizeof(serialParams);

    Status = SetupComm(serialHandle, 1024, 1024);
    if (Status == FALSE){
        printf("Error in setupcomm\n");
        return FAULT;
    }
    else
        printf("Greate setupcomm\n");

    Status = GetCommState(serialHandle, &serialParams);
    if (Status == FALSE){
        printf("Error in getcomm\n");
        return FAULT;
    }
    else
        printf("Greate getcomm\n");

    serialParams.BaudRate = baudrate;
    serialParams.ByteSize = bytesize;
    serialParams.StopBits = stopBits;
    serialParams.Parity = parity;
    Status = SetCommState(serialHandle, &serialParams);
    if (Status == FALSE){
        printf("Error in setcomm\n");
        return FAULT;
    }
    else
        printf("Greate setcomm\n");

    // Set timeouts
    timeout.ReadIntervalTimeout = 50;
    timeout.ReadTotalTimeoutConstant = 50;
    timeout.ReadTotalTimeoutMultiplier = 50;
    timeout.WriteTotalTimeoutConstant = 50;
    timeout.WriteTotalTimeoutMultiplier = 10;

    Status = SetCommTimeouts(serialHandle, &timeout);
    if (Status == FALSE){
        printf("Error in settime\n");
        return FAULT;
    }
    else
        printf("Greate settime\n");

	return OK;
}

HANDLE serial_init(char* pname){
    HANDLE serialHandle;
    serialHandle = serial_open(pname);
    if (serial_set(serialHandle) == FAULT)
        printf("Init COM_port false\n");

    return serialHandle;
}

uint32_t serial_nb_read(HANDLE h, uint8_t* buffer, uint32_t size, uint32_t* n)
{

	if(!ReadFile(h, buffer, size, (DWORD*)n, NULL))
	{
		return FAULT;
	}

	return OK;
}



uint32_t serial_read(HANDLE h, uint8_t* buffer, uint32_t size)
{
	DWORD n = 0;
	uint32_t m = 0;

	while(m < size)
	{
		if(!ReadFile(h, buffer, size, &n, NULL))
		{
			return FAULT;
		}
		m+= n;
		buffer +=n;
	}

	return OK;
}

uint32_t serial_write(HANDLE h, uint8_t* buffer, uint32_t size)
{
	DWORD n = 0;
	uint32_t m = 0;

	while(m < size)
	{

		if(!WriteFile(h, buffer, size, &n, NULL))
		{
			return FAULT;
		}

		m += n;
		buffer += n;
	}

	return OK;
}


uint32_t serial_free(HANDLE h)
{
	uint8_t buff;
	DWORD n;

	do
	{
		if(!ReadFile(h, &buff, 1, &n, NULL))
		{
			return FAULT;
		}
	} while (n != 0);

	return OK;
}










void serial_close(HANDLE h)
{
	CloseHandle(h);
}
