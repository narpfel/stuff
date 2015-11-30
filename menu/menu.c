#include <stdio.h>
#include <stdlib.h>
#include <stddef.h>
#include <stdbool.h>

#include "menu.h"


void menu_print(Menu* menu) {
    puts(menu->description);

    for (int i = 0; menu->items[i]; i++) {
        printf("%d) ", i + 1);
        menuitem_print(menu->items[i]);
    }
}


void menu_ask(Menu* menu) {
    while (true) {
        menu_print(menu);
        printf("Enter choice (0 to abort): ");
        int choice;
        scanf("%d", &choice);
        if (choice == 0) {
            return;
        }
        printf(
            "You chose '%s' (%d)\n",
            menu->items[choice - 1]->description,
            choice
        );
        menu->items[choice - 1]->on_selected();
    }
}


void menuitem_print(MenuItem* item) {
    puts(item->description);
}
