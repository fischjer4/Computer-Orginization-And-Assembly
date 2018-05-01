;***********************************************************
;*
;*	This is the RECEIVE skeleton file for Lab 8 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Jeremy Fischer
;*	   Date: Feb. 25th 2018
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = R16				; Multi-Purpose Register
.def	bttnPress = R17			; reg used to hold what button was pressed
.def 	sendCmmd = R18			; reg used to hold the cmmd to send

.equ	EngEnR = 4				; Right Engine Enable Bit
.equ	EngEnL = 7				; Left Engine Enable Bit
.equ	EngDirR = 5				; Right Engine Direction Bit
.equ	EngDirL = 6				; Left Engine Direction Bit

.equ	mvFwdPin = 0			;Pin that will be 0 when mvFwdPin bttn is pressed
.equ	mvBckPin = 1			;Pin that will be 1 when mvBckPin bttn is pressed
.equ	trnRightPin = 4			;Pin that will be 4 when trnRightPin bttn is pressed
.equ	trnLeftPin = 5			;Pin that will be 5 when trnLeftPin bttn is pressed
.equ	haltPin = 6				;Pin that will be 6 when haltPin bttn is pressed
.equ	freezePin = 7			;Pin that will be 7 when freezePin bttn is pressed

;.equ 	roboAddr = 0b01101110	;the Robot's address that is sent so it knows Cmmd is for it
.equ 	roboAddr = 42
; Use these action codes between the remote and robot
; MSB = 1 thus:
; control signals are shifted right by one and ORed with 0b10000000 = $80
.equ	MovFwd =  ($80|1<<(EngDirR-1)|1<<(EngDirL-1))	;0b10110000 Move Forward Action Code
.equ	MovBck =  ($80|$00)								;0b10000000 Move Backward Action Code
.equ	TurnR =   ($80|1<<(EngDirL-1))					;0b10100000 Turn Right Action Code
.equ	TurnL =   ($80|1<<(EngDirR-1))					;0b10010000 Turn Left Action Code
.equ	Halt =    ($80|1<<(EngEnR-1)|1<<(EngEnL-1))		;0b11001000 Halt Action Code
.equ	Freeze =  (0b11111000)							;freeze Action Code
;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt
.org	$0046					;End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;	- Init stack
;*	- Init I/O Ports
;*	- Init USART0
;*		- Set baudrate at 2400bps
;*		- Enable transmitter
;*		- Set frame format: 8 data bits, 2 stop bits
;***********************************************************
INIT:
;Init Stack Pointer
	ldi mpr, low(RAMEND) ;Low Byte of End SRAM Address
	out SPL, mpr         ;Write byte to SPL
	ldi mpr, high(RAMEND);High Byte of End SRAM Address
	out SPH, mpr         ;Write byte to SPH	

;Init ports	
	ldi mpr, $00	 	 ;set portD to input
	out DDRD, mpr  
	ldi mpr, 0b11110011	 	 ;Set port D to pull up
	out PORTD, mpr			;RXD1 = PD2, TXD1 = PD3
	
	ldi mpr, (1<<U2X1)
	sts UCSR1A, mpr

 ;Set baud rate at 2400 bps
	ldi mpr, high(832)
	sts UBRR1H, mpr
	ldi mpr, low(832)
	sts UBRR1L, mpr
	
;USART0 frame format: 8 data, 2 stop bits, asynchronous
	ldi mpr, (0<<UMSEL1 | 1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)
	sts UCSR1C, mpr       ; UCSR0C in extended I/O space

	ldi mpr, (1<<TXEN1)	  ;enable the transmitter
	sts UCSR1B, mpr


;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	;REMEMBER buttons are passive, therefore PINx = 0 means pressed.
	in bttnPress, PIND			;read in the button presses
	cpi  bttnPress, $FF		
	breq MAIN					;if nothing is pressed, loop

	;go through all possible button presses to see if one is pressed.
	;if the bit isn't cleared, meaning that button wasn't pressed,
	;then skip the ldi command and check the next pin
	sbrs bttnPress, mvFwdPin
	ldi sendCmmd, MovFwd		;load MovFwd bit pattern

	sbrs bttnPress, mvBckPin
	ldi sendCmmd, MovBck		;load MovBck bit pattern
	
	sbrs bttnPress, trnRightPin
	ldi sendCmmd, TurnR			;load TurnR bit pattern

	sbrs bttnPress, trnLeftPin
	ldi sendCmmd, TurnL			;load TurnL bit pattern
	
	sbrs bttnPress, haltPin
	ldi sendCmmd, Halt			;load Halt bit pattern

	sbrs bttnPress, freezePin
	ldi sendCmmd, Freeze		;load Halt bit pattern

	rcall TRANSMIT 				;send the new command to robot

	rjmp	MAIN

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; TRANSMIT: 
; Desc:	Transmits the robots address to the robot so it knows
;		if the next byte coming is meant for it.
;		Then, transmit the newly read command to the robot
;-----------------------------------------------------------
TRANSMIT:
	push mpr
	
	cpi sendCmmd, $00
	breq EXITTRANSMIT 			;if there is no command, exit


	ROBOTADDR:
		lds mpr, UCSR1A
		sbrs  mpr, UDRE1 	;If byte is still in UDR, wait till it shifts to transmit reg 
		rjmp  ROBOTADDR
		ldi mpr, roboAddr
		sts   UDR1, mpr    		;Load the roboAddr to UDR0 to to sent.
	
	SENDDATA:
		lds mpr, UCSR1A
		sbrs  mpr, UDRE1 	;If byte is still in UDR, wait till it shifts to transmit reg 
		rjmp  SENDDATA
		sts   UDR1, sendCmmd 	;Load the sendCmmd to UDR0 to to sent.	

	EXITTRANSMIT:
		;cbr mpr, UDRE1
		;sts UCSR1A, mpr
		ldi sendCmmd, $00 		;reset the sendCmmd 
		pop mpr
		ret
