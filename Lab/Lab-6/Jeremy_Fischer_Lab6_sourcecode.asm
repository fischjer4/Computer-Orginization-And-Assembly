;***********************************************************
;*
;*	Jeremy_Fischer_Lab6_sourcecode.adm
;*
;***********************************************************
;*
;*	 Author: Jeremy Fischer
;*	   Date: 02/12/2018
;*
;***********************************************************

.include "m128def.inc"					;Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def  mpr = R16
.def  waitcnt = R17						;wait loop counter
.def  ilcnt = R18						;inner loop counter
.def  olcnt = R19						;outer loop counter
.equ  WTime = 100						;(wait time in MS) / 10ms. So 1s
.equ  WskrR = 0							;right whisker input bit
.equ  WskrL = 1							;left whisker input bit
.equ  EngEnR = 4						;right engine direction bit
.equ  EngEnL = 7						;left engine enable bit
.equ  EngDirR = 5						;right engine direction bit
.equ  EngDirL = 6						;left engine direction bit
.equ  MovFwd = (1<<EngDirR|1<<EngDirL)  ;move forward
.equ  MovBck = $00						;move backward
.equ  TurnR = (1<<EngDirL)				;turn right
.equ  TurnL = (1<<EngDirR)				;turn left	
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg									;Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000							;Beginning of IVs
	rjmp 	INIT						;Reset interrupt
.org	$0002							;INT0 => pin0, PORTD
	rcall HITRIGHT						;run hitright ISR
	reti								;return from interrupt
.org	$0004							;INT1 => pin1, PORTD
	rcall HITLEFT						;run hitleft ISR
	reti								;return from interrupt
.org	$0046							;End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:									;The initialization routine
	;Initialize Stack Pointer
	ldi R16, low(RAMEND) 				;Low Byte of End SRAM Address
	out SPL, R16 						;Write byte to SPL
	ldi R16, high(RAMEND) 				;High Byte of End SRAM Address
	out SPH, R16 						;Write byte to SPH	

	;Initialize Port B for output
	ldi   mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)
	out   DDRB, mpr         			;Set PortB to be output

	; Initialize Port D for input
	ldi   mpr, (0<<WskrL)|(0<<WskrR)
	out   DDRD, mpr         			;Set PortD to be input
	ldi   mpr, (1<<WskrL)|(1<<WskrR)
	out   PORTD, mpr        			;Set PortD to be pull-up 

	;Initialize external interrupts (to trigger on falling edge)
	ldi   mpr, (1<<ISC01)|(0<<ISC00)|(1<<ISC11)|(0<<ISC10) ;'10' is falling edge
	sts   EICRA, mpr        			;Use sts, EICRA is in extended I/O space

	;Set the External Interrupt Mask
	ldi   mpr, (1<<INT0)|(1<<INT1) 		;setting EIMSKx to 1 enables it to be deteced
	out   EIMSK, mpr

	;Turn on interrupts
	sei



;***********************************************************
;*	Main Program
;***********************************************************
MAIN:									;The Main program
	; Move Robot Forward
	ldi   mpr, MovFwd					;load move forward bit sequence
	out   PORTB, mpr					;tell TekBot to move forward
	rjmp  MAIN							;infinite loop. End of program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; WAIT: 
; Desc: A wait loop that is 16 + 159975*waitcnt cycles or roughly
; 		waitcnt*10ms. Just initialize wait for the specific amount
; 		of time in 10ms intervals. Here is the general equation
; 		for the number of clock cycles in the wait loop:
;		((3 * ilcnt + 3) * olcnt + 3) * waitcnt + 13 + call
;-----------------------------------------------------------
WAIT:								;Begin a function with a label
	OLoop:
		ldi olcnt, 224				;Load middle-loop count
	MLoop:
		ldi ilcnt, 237  			;Load inner-loop count
	ILoop:
		dec ilcnt  					;Decrement inner-loop count
		brne Iloop 					;Continue inner-loop
		dec olcnt 	 				;Decrement middle-loop
		brne Mloop 					;Continue middle-loop
		dec waitcnt 	 			;Decrement outer-loop count
		brne OLoop 					;Continue outer-loop
		ret 						;Return from subroutine

;-----------------------------------------------------------
; HITLEFT: 
; Desc: This function is an ISR that handles the tekbot
;		hitting its left trigger. The tekbot backs up
;		for one second, then turns right for one second
;-----------------------------------------------------------
HITLEFT:							; Begin a function with a label
	;Save variable by pushing them to the stack
	push  mpr
	push  waitcnt
	in    mpr, SREG
	push  mpr

	; Move Backwards for a second
	ldi   mpr, MovBck
	out   PORTB, mpr
	ldi   waitcnt, WTime
	rcall Wait
	
	; Turn left for a second
	ldi   mpr, TurnR
	out   PORTB, mpr
	ldi   waitcnt, WTime
	rcall Wait
	
	;clear out any staged INT0 or INT1
	sbr mpr, (1<<WskrR)|(1<<WskrL)	;setting bits in flag register to 1 since pull up resistor
	out EIFR, mpr					;cancel out any staged interrupts

	;Restore variable by popping them from the stack in reverse order
	pop   mpr
	out   SREG, mpr
	pop   waitcnt
	pop   mpr
	ret								;return to caller
;----------------------------------------------------
; HITRIGHT: 
; Desc: This function is an ISR that handles the tekbot
;		hitting its right trigger. The tekbot backs up
;		for one second, then turns left for one second
;-----------------------------------------------------------
HITRIGHT:							; Begin a function with a label

	;Save variable by pushing them to the stack
	push  mpr
	push  waitcnt
	in    mpr, SREG
	push  mpr

	; Move Backwards for a second
	ldi   mpr, MovBck
	out   PORTB, mpr
	ldi   waitcnt, WTime
	rcall Wait
	
	; Turn left for a second
	ldi   mpr, TurnL
	out   PORTB, mpr
	ldi   waitcnt, WTime
	rcall Wait
	
	;clear out any staged INT0 or INT1
	sbr mpr, (1<<WskrR)|(1<<WskrL)	;setting bits in flag register to 1 since pull up resistor
	out EIFR, mpr					;cancel out any staged interrupts

	;Restore variable by popping them from the stack in reverse order
	pop   mpr
	out   SREG, mpr
	pop   waitcnt
	pop   mpr
	ret								;return to caller