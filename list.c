#include "list.h"

list * create_list() {
  	// Создадим указатель на переменную структуры списка и выделим немного памяти для нее
    list *lst = (list*)malloc(sizeof(list));

    // задаем первоначальные значения
    lst->count = 0; // наш список пуст
    lst->head = NULL; // первого элемента у нас нет
    lst->tail = NULL; // и последнего тоже

    return lst;
}

void insert_list(list *lst, int index, char *data) {
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

list * init_list (){
    list *database = create_list();

    insert_list(database, 0, "000");
    insert_list(database, 1, "001");
    insert_list(database, 2, "010");
    insert_list(database, 3, "011");
    insert_list(database, 4, "100");
    insert_list(database, 5, "101");
    insert_list(database, 6, "110");
    insert_list(database, 7, "111");
}
