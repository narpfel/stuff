/*
 * main.c
 *
 * Copyright 2015 narpfel <narpfel@gmx.de>
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation; either version 2 of the License, or
 * (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program; if not, write to the Free Software
 * Foundation, Inc., 51 Franklin Street, Fifth Floor, Boston,
 * MA 02110-1301, USA.
 */


#include <avr/io.h>
#include <util/delay.h>
#include <avr/interrupt.h>

#include <stdint.h>
#include <stdio.h>



int main(void)
{
    DDRB |= (1 << PB1) | (1 << PB2);
    while (1) {
        PORTB = 0b000;
        _delay_ms(1000);
        PORTB = 0b010;
        _delay_ms(1000);
        PORTB = 0b110;
        _delay_ms(1000);
        PORTB = 0b100;
        _delay_ms(1000);
    }
    return 0;
}
