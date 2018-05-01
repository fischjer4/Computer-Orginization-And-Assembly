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
.def  acceptNext = R20					;used as flag for recieving command
.def  mpr = R16
.def  waitcnt = R17						;wait loop counter
.def  recvdCmmd = R18
.def  cmmd = R19
.def  timesFrozen = R21 				;keeps track of times I've been frozen

.equ  WTime = 100						;(wait time in MS) / 10ms. So 1s

.equ  WskrR = 0							;Right Whisker Input Bit
.equ  WskrL = 1							;Left Whisker Input Bit
.equ  EngEnR = 4						; Right Engine Enable Bit
.equ  EngEnL = 7						; Left Engine Enable Bit
.equ  EngDirR = 5						; Right Engine Direction Bit
.equ  EngDirL = 6						; Left Engine Direction Bit

.equ  maxTimeFrozen = 3					;3 times frozen max
.equ  FreezeSend = 0b01010101			;byte to send to freeze other robots

.equ  BotAddress = 43			;The robots address

;/////////////////////////////////////////////////////////////
;These macros are the values to make the TekBot Move.
;/////////////////////////////////////////////////////////////
.equ	MovFwd =  1<<(EngDirR-1)|1<<(EngDirL-1)	;0b01100000 Move Forward Action Code
.equ	MovBck =  $00						;0b00000000 Move Backward Action Code
.equ	TurnR  =  1<<(EngDirL-1)				;0b01000000 Turn Right Action Code
.equ	TurnL  =  (1<<(EngDirR - 1))			;0b00100000 Turn Left Action Code
.equ	Halt   =  1<<(EngEnR-1)|1<<(EngEnL-1)	
.equ	Freeze =  (0b11111000)				;0b11111000 Freeze Action Code

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000						;Beginning of IVs
		rjmp 	INIT					; Reset interrupt
.org	$0002							;INT0 => pin0, PORTD
	rcall HITRIGHT						;run hitright ISR
	reti								
.org	$0004							;INT1 => pin1, PORTD
	rcall HITLEFT						;run hitleft ISR
	reti								
.ORG $003C								;RXC was triggered
    rjmp  EXECCMMD						;Execute the command
	reti
.org	$0046					; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:
;Initialize Stack Pointer
	ldi R16, low(RAMEND) 				;Low Byte of End SRAM Address
	out SPL, R16 						;Write byte to SPL
	ldi R16, high(RAMEND) 				;High Byte of End SRAM Address
	out SPH, R16 						;Write byte to SPH	
	
;Init ports
	ldi mpr, (1<<PE1)	 				;Set Port E pin 0 (RXD0) for input (implicitly)
	out DDRE, mpr						;Port E pin 1 (TXD0) for output
	;Initialize Port B for output
	ldi   mpr, (1<<EngEnL)|(1<<EngEnR)|(1<<EngDirR)|(1<<EngDirL)
	out   DDRB, mpr         			;Set PortB to be output

	; Initialize Port D for input
	ldi   mpr, (0<<WskrL)|(0<<WskrR)
	out   DDRD, mpr         			;Set PortD to be input
	ldi   mpr, (1<<WskrL)|(1<<WskrR)
	out   PORTD, mpr        			;Set PortD to be pull-up 

	;Initialize external interrupts (to trigger on falling edge)
	ldi   mpr, (1<<ISC11)|(0<<ISC10)|(1<<ISC01)|(0<<ISC00) ;'10' is falling edge
	sts   EICRA, mpr        			;Use sts, EICRA is in extended I/O space

	;Set the External Interrupt Mask
	ldi   mpr, (1<<INT0)|(1<<INT1) 		;setting EIMSKx to 1 enables it to be deteced
	out   EIMSK, mpr



;Set baud rate at 2400 bps
	ldi mpr, (1<<U2X1)
	sts UCSR1A, mpr

	ldi mpr, high(832)
	sts UBRR1H, mpr
	ldi mpr, low(832)
	sts UBRR1L, mpr
	
;USART1 frame format: 8 data, 2 stop bits, asynchronous
	ldi mpr, (0<<UMSEL1 | 1<<USBS1 | 1<<UCSZ11 | 1<<UCSZ10)
	sts UCSR1C, mpr       ; UCSR0C in extended I/O space

	;enable the reciever and the RX Complete Interrupt Enable
	ldi mpr, (1<<TXEN1)|(1<<RXEN1)|(1<<RXCIE1) 
	sts UCSR1B, mpr
	ldi waitcnt, Wtime

	ldi acceptNext, 0
	ldi cmmd, MovFwd
;Turn on interrupts
	sei

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:
	; Move Robot Forward
	out   PORTB, cmmd				;tell TekBot to move forward
	rjmp  MAIN						;infinite loop. End of program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; WAIT: 
; Desc: A wait loop that is 16 + 159975*waitcnt cycles or roughly
; 		waitcnt*10ms. Just initialize wait for the specific amount
; 		of time in 10ms intervals. Here is the general equation
; 		for the number of clock cycles in the wait loop:
;		((3 * R19 + 3) * R18 + 3) * waitcnt + 13 + call
;-----------------------------------------------------------
WAIT:								;Begin a function with a label
	push R18
	push R19

	OLoop:
		ldi R18, 224				;Load middle-loop count
	MLoop:
		ldi R19, 237  			;Load inner-loop count
	ILoop:
		dec R19  					;Decrement inner-loop count
		brne Iloop 					;Continue inner-loop
		dec R18 	 				;Decrement middle-loop
		brne Mloop 					;Continue middle-loop
		dec waitcnt 	 			;Decrement outer-loop count
		brne OLoop 					;Continue outer-loop

	pop R19
	pop R18
	ret 						;Return from subroutine

;-----------------------------------------------------------
; EXECCMMD: 
; Desc: First checks the Address sent. If it is this bot's
;		address, then the next byte, the command, is executed
;-----------------------------------------------------------
EXECCMMD:
	;Save variable by pushing them to the stack
	push  mpr
	push  waitcnt
	
	lds recvdCmmd, UDR1

	rcall CHECKFREEZE				;check if recvdCmmd was freeze from other robot	

	cpi acceptNext, 1			
	brne NEEDADDR					;Get the bot address

	
	rcall GETCMMD					;execute command
	ldi	acceptNext, 0;				;reset acceptNext
	rjmp EXIT						;jmp to exit

	NEEDADDR:
		cpi recvdCmmd, BotAddress
		brne EXIT					;if address != bot, exit
		ldi	acceptNext, 1			;if address == bot, get command next byte recieved
	EXIT:
		;Restore variable by popping them from the stack in reverse order

		pop   waitcnt
		pop   mpr
		ret								;return to caller

;-----------------------------------------------------------
; GETCMMD: 
; Desc: executes the command. recvdCmmd holds the command
;	MovFwd = 0b01100000 Move Forward Action Code
;	MovBck = 0b00000000 Move Backward Action Code
;	TurnR  = 0b01000000 Turn Right Action Code
;	TurnL  = 0b00100000 Turn Left Action Code
;	Halt   = 0b10010000 Halt Action Code
;-----------------------------------------------------------
GETCMMD:
	push mpr

	ldi mpr, ($80|MovFwd)			;is this the move forward cmmd
	cp recvdCmmd, mpr 			;Compare Skip if Equal
	breq FWD

	
	ldi mpr, ($80|MovBck)			;is this the move backward cmmd
	cp recvdCmmd, mpr				;Compare Skip if Equal
	breq BCK

	ldi mpr, ($80|TurnR)			;is this the turn right cmmd
	cp recvdCmmd, mpr				;Compare Skip if Equal
	breq TRNR

	ldi mpr, ($80|TurnL)			;is this the turn left cmmd
	cp recvdCmmd, mpr				;Compare Skip if Equal
	breq TRNL

	ldi mpr, ($80|Halt)				;is this the halt cmmd
	cp recvdCmmd, mpr				;Compare Skip if Equal
	breq HLT

	ldi mpr, (Freeze)				;is this the Freeze cmmd
	cp recvdCmmd, mpr				;Compare Skip if Equal
	breq FRZ

	FWD:
		ldi cmmd, MovFwd				;yes, then load MovFwd into the cmmd
		rjmp EXITCMMD
	BCK:
		ldi cmmd, MovBck				;yes, then load MovBck into the cmmd
		rjmp EXITCMMD
	TRNR:
		ldi cmmd, TurnR					;yes, then load TurnR into the cmmd
		rjmp EXITCMMD
	TRNL:
		ldi cmmd, TurnL					;yes, then load TurnL into the cmmd
		rjmp EXITCMMD
	HLT:
		ldi cmmd, Halt					;yes, then load Halt into the cmmd
		rjmp EXITCMMD
	FRZ:
		rcall FREEZEOTHERS
		rjmp EXITCMMD

	EXITCMMD:
		pop mpr
		ret


;-----------------------------------------------------------
; CHECKFREEZE: 
; Desc: Checks if I just got frozen
;-----------------------------------------------------------
CHECKFREEZE:
	push mpr
	push recvdCmmd
	push cmmd 

	cpi  recvdCmmd, FreezeSend		;if I did just get the freeze signal from another
	brne EXITCHECK
	
	;It is the Freeze command
	cli  							;turn off interrrupts

	ldi cmmd, Halt					;load Halt into the cmmd
	out PORTB, cmmd					;Halt the robot

	inc timesFrozen					;increment the times ive been frozen
	cpi timesFrozen, maxTimeFrozen	
	breq STAYFROZEN

	ldi	  waitcnt, 250				;wait for 2.5 seconds. (250 * 10ms) = 2500ms
	rcall WAIT
	ldi	  waitcnt, 250				;wait for 5.5 seconds. (250 * 10ms) = 2500ms
	rcall WAIT

	;I havn't reached maxTimeFrozen yet
	rjmp EXITCHECK					;exit the check

	STAYFROZEN:
		rjmp STAYFROZEN				;stay here till reset

	EXITCHECK:
		pop cmmd
		out PORTB, cmmd				;load what robot was ding previously

		pop recvdCmmd
		pop mpr
		sei							;reset the interrupt flag
		ret

;-----------------------------------------------------------
; FREEZEOTHERS: 
; Desc: Send Freeze signal to other robots
;-----------------------------------------------------------
FREEZEOTHERS:
	push mpr

	; Disable the receiver
	ldi		mpr, (0<<RXCIE1)|(1<<TXCIE1)|(0<<RXEN1)|(1<<TXEN1)
	sts		UCSR1B, mpr

	TRANSMIT:
		lds mpr, UCSR1A
		sbrs  mpr, UDRE1 	;If byte is still in UDR, wait till it shifts to transmit reg 
		rjmp  TRANSMIT
		ldi mpr, FreezeSend
		sts   UDR1, mpr    		;Load the roboAddr to UDR0 to to sent.

		; Enable the receiver
		ldi		mpr, (1<<RXCIE1)|(1<<TXCIE1)|(1<<RXEN1)|(1<<TXEN1)
		sts		UCSR1B, mpr

	pop mpr
	ret


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
	ldi   mpr, 1<<(EngDirL)
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
	ldi   mpr, 1<<(EngDirR)
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