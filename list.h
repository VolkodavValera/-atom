#ifndef _LIST_
#define _LIST_

#include <windows.h>
#include <stdio.h> // стандартная библиотека Си
#include <string.h> // для работы со строками
#include <stdlib.h> // для работы с памятью


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

list * create_list();
void insert_list(list *lst, int index, char *data);
int comparison_with_list(list *lst, char *data);
list * init_list ();

#endif
