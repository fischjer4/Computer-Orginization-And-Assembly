/*
	This code will cause a TekBot connected to the AVR board to
	move forward and when it touches an obstacle, it will reverse
	and turn away from the obstacle and resume forward motion.

	PORT MAP
	Port B, Pin 4 -> Output -> Right Motor Enable
	Port B, Pin 5 -> Output -> Right Motor Direction
	Port B, Pin 7 -> Output -> Left Motor Enable
	Port B, Pin 6 -> Output -> Left Motor Direction
	Port D, Pin 1 -> Input -> Left Whisker
	Port D, Pin 0 -> Input -> Right Whisker
*/
#include <avr/io.h> 
#include <util/delay.h> 
#include <stdio.h>

#define F_CPU 16000000
//checks if left whisker or both are signaled
#define leftW (PIND == 0b11111101 || PIND == 0b11111100) 
//checks if right whisker is signaled
#define rightW (PIND == 0b11111110)


/*
	Function to react to the right whisker being hit
	- Backs up for a second
	- Turns left for a second
	- Continues Forward
*/
void rightTriggered(){
	PORTB = 0b00000000;     // move backward
	_delay_ms(10000);        // wait for 1 second
	PORTB = 0b00100000;     // turn left
	_delay_ms(10000);        // wait for 1 second
}
/*
	Function to react to the left whisker being hit
	 Backs up for a second
	- Turns right for a second
	- Continues Forward
*/
void leftTriggered(){
	PORTB = 0b00000000;     // move backward
	_delay_ms(10000);        // wait for 1 second
	PORTB = 0b01000000;     // turn right
	_delay_ms(10000);        // wait for 1 second
}

int main(void){
	DDRB = 0b11110000;      // configure Port B pins for input/output
	DDRD = 0b00000000;      // configure Port D pins for input/output
	PORTD = 0b11111111;
	
	while(1) { // loop forever
		PORTB = 0b01100000;     // make TekBot move forward
		if(leftW){
			leftTriggered();
		}
		else if(rightW){
			rightTriggered();
		}
	}

	return 0;
}