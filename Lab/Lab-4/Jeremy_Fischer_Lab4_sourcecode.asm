;***********************************************************
;*
;*	Jeremy_Fischer_Lab4_sourcecode.asm
;*
;*	This program interacts with the LCD to display characters
;*
;*	This is the skeleton file for Lab 4 of ECE 375
;*
;***********************************************************
;*
;*	 Author: Jeremy Fischer
;*	   Date: 01/31/2018
;*
;***********************************************************

.include "m128def.inc"					; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	MPR = r16						; Multipurpose register is
										; required for LCD Driver

;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg									; Beginning of code segment

;***********************************************************
;*	Interrupt Vectors
;***********************************************************
.org	$0000							; Beginning of IVs
		rjmp INIT						; Reset interrupt

.org	$0046							; End of Interrupt Vectors

;***********************************************************
;*	Program Initialization
;***********************************************************
INIT:									; The initialization routine
		; Initialize Stack Pointer
		ldi R16, low(RAMEND) 			; Low Byte of End SRAM Address
		out SPL, R16 					; Write byte to SPL
		ldi R16, high(RAMEND) 			; High Byte of End SRAM Address
		out SPH, R16 					; Write byte to SPH

		; Initialize LCD Display
		call LCDInit					;Call LCDInit to init the driver
		rcall LCDClr					;Clear the LCD display

		;NOW LOAD STRING 1
		ldi ZL, low(JEREMY_BEG << 1) 	;Load the low byte of JEREMY_BEG
		ldi ZH, high(JEREMY_BEG << 1)	;Load the high byte of JEREMY_BEG

		;Load LCDLn1Addr into Y becuase this is where LCDDriver reads from
		;when looking for line 1. 
		ldi YL, low(LCDLn1Addr)  		;Load the low byte of LCDLn1Addr
		ldi YH, high(LCDLn1Addr) 		;Load the low byte of LCDLn1Addr

		ldi R18, low(JEREMY_END << 1)
		ldi R19, high(JEREMY_END << 1)
		rcall LOADSTRING

		;NOW LOAD STRING 2
		ldi ZL, low(HWORLD_BEG << 1) 	;Load the low byte of HWORLD_BEG
		ldi ZH, high(HWORLD_BEG << 1)	;Load the high byte of HWORLD_BEG

		;Load LCDLn2Addr into Y becuase this is where LCDDriver reads from
		;when looking for line 2. 
		ldi YL, low(LCDLn2Addr)  		;Load the low byte of LCDLn2Addr
		ldi YH, high(LCDLn2Addr) 		;Load the low byte of LCDLn2Addr

		ldi R18, low(HWORLD_END << 1)
		ldi R19, high(HWORLD_END << 1)
		rcall LOADSTRING



		; NOTE that there is no RET or RJMP from INIT, this
		; is because the next instruction executed is the
		; first instruction of the main program

;***********************************************************
;*	Main Program
;***********************************************************
MAIN:									; The Main program
		; Display the strings on the LCD Display
		rcall LCDWrLn1					;Write the first line
		rcall LCDWrLn2					;Write the second line

		rjmp	MAIN					;jump back to main and create an infinite
										;while loop.  Generally, every main program is an
										;infinite while loop, never let the main program
										;just run off

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: LOADSTRING
; Desc: Given the 'read' address in Z and the 'write' address
;		in Y, and the stopping address (low in R18 and high in R19),
;		this function will copy bytes from Z address to Y address
;		until the stop address is met by Z
;-----------------------------------------------------------
LOADSTRING:								; Begin a function with a label
		; Save variables by pushing them to the stack
		push MPR
		push ZL
		push ZH
		push YL
		push YH

		;Y and Z are already set up for read/write before function
		
		WRLINE:
			LPM MPR, Z+					;Load byte from Z (my string) and then point to next byte
			ST Y+, MPR					;Store byte in SRAM then point to next slot
			cp ZL, R18					;Compare the current ZL with the ending address
			breq COMPHIGH				;Low bytes match, check high bytes
			rjmp WRLINE					;Low bytes don't match, not at end of Line,
										;continue reading line
			COMPHIGH:
				cp ZH, R19				;Compare the current ZH with the ending address
				breq EXIT
				rjmp WRLINE				;High bytes don't match, not at end of Line,
										;continue reading line
		EXIT:
			pop YH
			pop YL
			pop ZH
			pop ZL
			pop MPR
			ret							;return from function. String is loaded in SRAM

;***********************************************************
;*	Stored Program Data
;***********************************************************

;-----------------------------------------------------------
; An example of storing a string. Note the labels before and
; after the .DB directive; these can help to access the data
;-----------------------------------------------------------
STRING_BEG:		.DB		"My Test String"		; Declaring data in ProgMem
STRING_END:

JEREMY_BEG:		.DB 	"Jeremy"				;Declaring my name in ProgMem
JEREMY_END:

HWORLD_BEG:		.DB 	"Hello World!"			;Declaring 'Hello World' in ProgMem
HWORLD_END:

;***********************************************************
;*	Additional Program Includes
;***********************************************************
.include "LCDDriver.asm"		; Include the LCD Driver
