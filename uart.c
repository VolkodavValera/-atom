#include <windows.h>
#include <stdio.h> // стандартная библиотека Си
#include <string.h> // для работы со строками
#include <stdlib.h> // для работы с памятью
#include <locale.h>

#define baudrate CBR_115200
#define bytesize 8
#define stopBits TWOSTOPBITS
#define parity   NOPARITY

char* Handle_Name = "\\\\.\\COM4";

// структура элемента списка
typedef struct list_item {
    void *data; // по этому указателю мы храним какие-то данные
    struct list_item *next; // это у нас ссылка на следующий указатель
    struct list_item *prev; // это у нас ссылка на предыдущий указатель
} list_item;

// Общая структура списка
typedef struct list {
    int count; // информация о размере списка
    list_item *head; // это ссылка на головной элемент
    list_item *tail; // это у нас ссылка на последний элемент (хвост списка)
} list;

list * create() {
  	// Создадим указатель на переменную структуры списка и выделим немного памяти для нее
    list *lst = (list*)malloc(sizeof(list));

    // задаем первоначальные значения
    lst->count = 0; // наш список пуст
    lst->head = NULL; // первого элемента у нас нет
    lst->tail = NULL; // и последнего тоже

    return lst;
}

void insert(list *lst, int index, char *data) {
		// создадим указатель переменной элемента списка,
		// и присвоим ему значение указателя на первый элемент списка
  	list_item *base = lst->head;

  	// создадим указатель переменной на новый элемент и выделим под него память
		list_item *new_item = (list_item*)malloc(sizeof(list_item));

  	// выделим память внутри самого элемента структуры куда принимаем данные,
  	// и получим указатель на него,
  	// strlen() нужен, чтобы выделенная память была равна длинне полученной строки.
  	new_item->data = malloc(sizeof(char) * strlen(data));
  	strcpy(new_item->data, data); // копируем туда данные

  	// Пришла пора решить куда мы определим элемент,
  	// т.к. у нас еще нет элементов, lst->head вернет нам NULL.
  	// Следовательно нужно условие, при создании первого элемента списка.
  	if (base == NULL) {
      	// Этот элемент единственный, а значит его указатели будут NULL.
      	new_item->next = NULL;
        new_item->prev = NULL;

      	// При этом, он сам будет первым и последним в списке.
        lst->head = new_item;
        lst->tail = new_item;
        lst->count++; // Увеличем кол-во на единицу
        return;
    }

  	// Если индекс, который пришел будет меньше нуля, то будем вставлять в конец
  	if (index < 0) {
    		// голова теперь будет ссылаться на новый элм. впереди себя
      	base->prev = new_item;
        new_item->prev = NULL;
        new_item->next = base; // а ссылка на след. элм. у нового будет на голову

        lst->head = new_item; // назначаем новый элемент головой
    } else { // тут все в обратном порядке
    		base = lst->tail; // перейдем в хвост списка

      	// пусть он теперь ссылаеться на новый элемент
      	base->next = new_item;
      	new_item->next = NULL; // Новый не будет иметь ссылки на следующий
      	new_item->prev = base; // А предыдущий у него будет хвост списка

      	lst->tail = new_item; // Назначаем новый элемент хвостом списка
    }
  lst->count++; // увеличим размер на единицу
}

int comparison_with_list(list *lst, char *data) {
    int i = 0; // организуем счетчик
    list_item *base = lst->head; // перейдем к первому элементу
  	// воспользуемся функцией strcmp, чтобы сравнить перебираемые строки
    while (strcmp(base->data, data) != 0) {
        // пока строки не совпадут с тем что бы ищем, будем перебирать элементы
      	base = base->next;
        i++;
    }
    //printf("comp_int: %d\n", i);
    return i;
}

list * init (){
    list *database = create();

    insert(database, 0, "000");
    insert(database, 1, "001");
    insert(database, 2, "010");
    insert(database, 3, "011");
    insert(database, 4, "100");
    insert(database, 5, "101");
    insert(database, 6, "110");
    insert(database, 7, "111");
}

int main() {

    setlocale(LC_ALL, "russian");

    // Open serial port
    HANDLE serialHandle;
    DCB serialParams = { 0 };
    COMMTIMEOUTS timeout = { 0 };
    DWORD BytesWritten = 0;          // No of bytes written to the port
    char str[4];
    char *r_str;
    char SerialBuffer;
    char *estr;
    FILE *f;
    list *database = init();
    BOOL Status;

    serialHandle = CreateFile(Handle_Name, GENERIC_WRITE, 0, 0, OPEN_EXISTING, FILE_ATTRIBUTE_NORMAL, 0);

    if (serialHandle == INVALID_HANDLE_VALUE)
        printf("Error in opening serial port\n");
    else
        printf("opening serial port successful\n");

    // Do some basic settings
    serialParams.DCBlength = sizeof(serialParams);

    Status = GetCommState(serialHandle, &serialParams);
    if (Status == FALSE)
        printf("Error in getcomm\n");
    else
        printf("Greate getcomm\n");

    serialParams.BaudRate = baudrate;
    serialParams.ByteSize = bytesize;
    serialParams.StopBits = stopBits;
    serialParams.Parity = parity;
    Status = SetCommState(serialHandle, &serialParams);
    if (Status == FALSE)
        printf("Error in setcomm\n");
    else
        printf("Greate setcomm\n");

    // Set timeouts
    timeout.ReadIntervalTimeout = 50;
    timeout.ReadTotalTimeoutConstant = 50;
    timeout.ReadTotalTimeoutMultiplier = 50;
    timeout.WriteTotalTimeoutConstant = 50;
    timeout.WriteTotalTimeoutMultiplier = 10;

    Status = SetCommTimeouts(serialHandle, &timeout);
    if (Status == FALSE)
        printf("Error in settime\n");
    else
        printf("Greate settime\n");

    if ((f = fopen("init_mem_uart.txt", "r")) == NULL)
    {
      printf("Fail open file");
      return 1;
    }

    while (!feof (f)) {
        //printf("proc...\n");
        estr = fgets(str, sizeof(str), f);
        //printf("getted: %d\n", strlen(str));
        if (strlen(str) == 1) continue;
        /*printf("str: %c\n", str);
        printf("estr: %c\n", estr);
        printf("comp: %d\n", comparison_with_list(database, str));*/
        SerialBuffer = comparison_with_list(database, str);
        //printf ("\nRead file: %s\tSerial: %d\n", str, SerialBuffer);
        //Writing data to Serial Port
        Status = WriteFile(serialHandle,            // Handle to the Serialport
                           &SerialBuffer,           // Data to be written to the port
                           sizeof(SerialBuffer),    // No of bytes to write into the port
                           &BytesWritten,           // No of bytes written to the port
                           NULL);
        if (Status == FALSE)
        {
            printf_s("\nFail to Written Port");
            return 1;
        }
        //else printf("Greate write to COM\n");
        memset(str, '\0', strlen(str));
    }

    printf("The file has ended\n");
    CloseHandle(serialHandle);

    return 0;
}
