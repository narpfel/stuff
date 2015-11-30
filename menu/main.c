#include <stddef.h>
#include <stdio.h>

#include "menu.h"


int ask_number(char* prompt) {
    printf("%s", prompt);
    int input;
    scanf("%d", &input);
    return input;
}


void do_add(void) {
    int a = ask_number("Enter a: ");
    int b = ask_number("Enter b: ");
    printf("%d + %d = %d\n", a, b, a + b);
}


void do_multiply(void) {
    int a = ask_number("Enter a: ");
    int b = ask_number("Enter b: ");
    printf("%d * %d = %d\n", a, b, a * b);
}


void do_divide(void) {
    int a = ask_number("Enter a: ");
    int b = ask_number("Enter b: ");
    printf("%d / %d = %d\n", a, b, a / b);
}


void do_choice(void) {
    MenuItem multiply_item = {
        .description = "Multiply two numbers",
        .on_selected = &do_multiply
    };

    MenuItem divide_item = {
        .description = "Divide two numbers",
        .on_selected = &do_divide
    };

    MenuItem* items[] = {&multiply_item, &divide_item, NULL};
    Menu choice_menu = {
        .description = "Multiply or divide?",
        .items = (MenuItem **) &items
    };

    menu_ask(&choice_menu);
}


int main(void) {
    MenuItem add_item = {
        .description = "Add two numbers",
        .on_selected = &do_add
    };

    MenuItem choice_item = {
        .description = "Multiply or divide?",
        .on_selected = &do_choice
    };

    MenuItem* items[] = {&add_item, &choice_item, NULL};
    Menu menu = {
        .description = "Main menu",
        .items = (MenuItem **) &items
    };

    menu_ask(&menu);

    return 0;
}
