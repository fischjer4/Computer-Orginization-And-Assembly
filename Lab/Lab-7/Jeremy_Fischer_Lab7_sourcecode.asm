;***********************************************************
;*
;*	Enter Name of file here
;*
;*	Enter the description of the program here
;*
;*	This is the skeleton file for Lab 7 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Jeremy Fischer
;*	   Date: Feb. 21 2018
;*
;***********************************************************

.include "m128def.inc"			;Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = R16				;Multipurpose register
.def	speedLevel = R17		;register that holds the current speed
.def	changePerLevel = R18	;holds the speed change per level
.def	newSpeed = R0			;holds the newSpeed to put into OCRx

.def  	waitcnt = R19			;wait loop counter
.equ  	WTime = 10				;(wait time in MS) / 10ms.

.equ	EngEnR = 4				;right Engine Enable Bit
.equ	EngEnL = 7				;left Engine Enable Bit
.equ	EngDirR = 5				;right Engine Direction Bit
.equ	EngDirL = 6				;left Engine Direction Bit
.equ  	MovFwd = (1<<EngDirR)|(1<<EngDirL)  ;move forward
.equ    ddrdLayout = 0b11110000	;upper nibble = output, lower = input
.equ  	IncSpeed = 0			;increment speed input bit
.equ  	DecSpeed = 1			;decrement speed input bit
.equ  	FullSpeed = 2			;full speed input bit
.equ  	SlowSpeed = 3			;slowest speed input bit
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							;beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000							;Beginning of IVs
	rjmp 	INIT						;Reset interrupt
.org	$0002							;INT0 => pin0, PORTD
	rcall INCRSPEED						;run INCSPEED ISR
	reti								;return from interrupt
.org	$0004							;INT1 => pin1, PORTD
	rcall DECRSPEED						;run DECSPEED ISR
	reti								;return from interrupt
.org	$0006							;INT2 => pin2, PORTD
	rcall JMPFASTEST					;run JMPFASTEST ISR
	reti								;return from interrupt
.org	$0008							;INT3 => pin3, PORTD
	rcall JMPSLOWEST					;run JMPSLOWEST ISR
	reti								;return from interrupt
.org	$0046							;End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
;Initialize Stack Pointer
	ldi R16, low(RAMEND) 				;Low Byte of End SRAM Address
	out SPL, R16 						;Write byte to SPL
	ldi R16, high(RAMEND) 				;High Byte of End SRAM Address
	out SPH, R16 						;Write byte to SPH	

;Port Set-up
	;Initialize Port B for output
	ldi   mpr, $FF						;set all bits, cuz all bits will be used
	out   DDRB, mpr         			;Set PortB to be output

	;Initialize Port D for input
	ldi   mpr, ddrdLayout
	out   DDRD, mpr         			;Set PortD to be input
	ldi   mpr, (1<<IncSpeed)|(1<<DecSpeed)|(1<<FullSpeed)|(1<<SlowSpeed)
	out   PORTD, mpr        			;Set PortD to be pull-up 

;Interrupt Masking
	;Initialize external interrupts (to trigger on falling edge)
	ldi   mpr, (1<<ISC31)|(0<<ISC30)|(1<<ISC21)|(0<<ISC20)|(1<<ISC11)|(0<<ISC10)|(1<<ISC01)|(0<<ISC00) ;'10' is falling edge
	sts   EICRA, mpr        			;Use sts, EICRA is in extended I/O space

	;Set the External Interrupt Mask
	ldi   mpr, (1<<INT3)|(1<<INT2)|(1<<INT1)|(1<<INT0) ;setting EIMSKx to 1 enables it to be deteced
	out   EIMSK, mpr

;Counters/Timers
	;Configure 8-bit Timer/Counter0
	ldi   mpr, 0b01101111				;Activate Fast PWM mode with toggle. Done by bit 3 and 6 being 1
	out   TCCR0, mpr 					;(non-inverting), and set prescaler to 1024. Normal Mode
	;Configure 8-bit Timer/Counter2
	ldi   mpr, 0b01101101				;Activate Fast PWM mode with toggle. Done by bit 3 and 6 being 1
	out   TCCR2, mpr 					;(non-inverting), and set prescaler to 1024


;Init before Main
	;Set tekbot to move forward at slowest speed to start
	ldi speedLevel, 0
	mov mpr, speedLevel
	ori   mpr, MovFwd					;load speed and direction of motor to portB
	out   PORTB, mpr					;tell TekBot change speed
	
	;Turn on interrupts
	sei

		

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;Move Robot Forward
	mov mpr, speedLevel
	ori   mpr, MovFwd					;load speed and direction of motor to portB
	out   PORTB, mpr					;tell TekBot change speed

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
WAIT:									;Begin a function with a label
	push R18
	push R19 

	OLoop:
		ldi R19, 224					;Load middle-loop count
	MLoop:
		ldi R18, 237  					;Load inner-loop count
	ILoop:
		dec R18  						;Decrement inner-loop count
		brne Iloop 						;Continue inner-loop
		dec R19 	 					;Decrement middle-loop
		brne Mloop 						;Continue middle-loop
		dec waitcnt 	 				;Decrement outer-loop count
		brne OLoop 						;Continue outer-loop

		pop R19
		pop R18
		ret 							;Return from subroutine

;-----------------------------------------------------------
; INCSPEED: 
; Desc:	Increments the speedlevel if it is below 15
;-----------------------------------------------------------
INCRSPEED:	
	;Save used variables
	push mpr
	
	ldi   waitcnt, WTime
	rcall Wait

	;Perform Function
	cpi speedLevel, 15					;check if the speedlevel is already at its highest
	breq EXITINCR						;if it is then disregard
	;I can go up a speed level
	inc speedLevel						;increment speedLevel	
	mul speedLevel, changePerLevel		;get new intensity by (seedLevel * changePerLevel)
	out OCR0, newSpeed					;set new speed level (newSpeed = R0 = MUL result)
	out OCR2, newSpeed

	EXITINCR:
		clr mpr
		sbr mpr, (1<<IncSpeed)|(1<<DecSpeed)|(1<<FullSpeed)|(1<<SlowSpeed) ;clear out any staged INTs be setting clear flag
		out EIFR, mpr					;cancel out any staged interrupts

		;Restore used variables
		pop mpr
		ret								;End a function with RET

;-----------------------------------------------------------
; DECSPEED: 
; Desc:	Decrements the speedlevel if it is above 0
;-----------------------------------------------------------
DECRSPEED:	
	;Save used variables
	push mpr

	ldi   waitcnt, WTime
	rcall Wait

	;Perform Function
	cpi speedLevel, 0					;check if the speedlevel is already at its lowest
	breq EXITDECR						;if it is then disregard
	;I can go down a speed level
	dec speedLevel						;decrement speedLevel	
	mul speedLevel, changePerLevel		;get new intensity by (seedLevel * changePerLevel)
	out OCR0, newSpeed					;set new speed level (newSpeed = R0 = MUL result)
	out OCR2, newSpeed

	EXITDECR:
		clr mpr
		sbr mpr, (1<<IncSpeed)|(1<<DecSpeed)|(1<<FullSpeed)|(1<<SlowSpeed) ;clear out any staged INTs be setting clear flag
		out EIFR, mpr					;cancel out any staged interrupts

		;Restore used variables
		pop mpr
		ret								;End a function with RET
;-----------------------------------------------------------
; JMPFASTEST: 
; Desc:	Jumps the the highest speed level, 15
;-----------------------------------------------------------
JMPFASTEST:
	;Save used variables
	push mpr

	ldi   waitcnt, WTime
	rcall Wait

	;Perform Function
	ldi speedLevel, 15					;load fastest speed to speedlevel
	mul speedLevel, changePerLevel		;get new intensity by (seedLevel * changePerLevel)
	out OCR0, newSpeed					;set new speed level (newSpeed = R0 = MUL result)
	out OCR2, newSpeed

	clr mpr
	sbr mpr, (1<<IncSpeed)|(1<<DecSpeed)|(1<<FullSpeed)|(1<<SlowSpeed) ;clear out any staged INTs be setting clear flag
	out EIFR, mpr						;cancel out any staged interrupts

	;Restore used variables
	pop mpr
	ret									;End a function with RET

;-----------------------------------------------------------
; JMPSLOWEST: 
; Desc:	Jumps the the slowest speed level, 0
;-----------------------------------------------------------
JMPSLOWEST:	
	;Save used variables
	push mpr

	ldi   waitcnt, WTime
	rcall Wait

	;Perform Function
	ldi speedLevel, 0					;load slowest speed to speedlevel
	mul speedLevel, changePerLevel		;get new intensity by (seedLevel * changePerLevel)
	out OCR0, newSpeed					;set new speed level (newSpeed = R0 = MUL result)
	out OCR2, newSpeed

	clr mpr
	sbr mpr, (1<<IncSpeed)|(1<<DecSpeed)|(1<<FullSpeed)|(1<<SlowSpeed) ;clear out any staged INTs be setting clear flag
	out EIFR, mpr						;cancel out any staged interrupts

	;Restore used variables
	pop mpr
	ret									;End a function with RET