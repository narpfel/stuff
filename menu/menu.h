#ifndef MENU_H
#define MENU_H


typedef struct Menu Menu;
typedef struct MenuItem MenuItem;


struct Menu {
    char* description;
    MenuItem** items;
};


struct MenuItem {
    char* description;
    void (*on_selected)(void);
};


void menu_print(Menu* menu);
void menu_ask(Menu* menu);

void menuitem_print(MenuItem* item);


#endif
