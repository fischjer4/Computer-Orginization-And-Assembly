;***********************************************************
;*
;*	Jeremy_Fischer_Lab5_sourcecode.asm
;*
;*
;***********************************************************
;*
;*	 Author: Jeremy Fischer
;*	   Date: 02/07/2018
;*
;***********************************************************

.include "m128def.inc"			; Include definition file

;***********************************************************
;*	Internal Register Definitions and Constants
;***********************************************************
.def	mpr = r16				; Multipurpose register 
.def	rlo = r0				; Low byte of MUL result
.def	rhi = r1				; High byte of MUL result
.def	zero = r2				; Zero register, set to zero in INIT, useful for calculations
.def	A = r3					; A variable
.def	B = r4					; Another variable

.def	oloop = r17				; Outer Loop Counter
.def	iloop = r18				; Inner Loop Counter


;***********************************************************
;*	Start of Code Segment
;***********************************************************
.cseg							; Beginning of code segment

;-----------------------------------------------------------
; Interrupt Vectors
;-----------------------------------------------------------
.org	$0000					; Beginning of IVs
		rjmp 	INIT			; Reset interrupt

.org	$0046					; End of Interrupt Vectors

;-----------------------------------------------------------
; Program Initialization
;-----------------------------------------------------------
INIT:							; The initialization routine
		; Initialize Stack Pointer
		ldi R16, low(RAMEND) 			; Low Byte of End SRAM Address
		out SPL, R16 					; Write byte to SPL
		ldi R16, high(RAMEND) 			; High Byte of End SRAM Address
		out SPH, R16 					; Write byte to SPH	

		clr		zero			; Set the zero register to zero, maintain
								; these semantics, meaning, don't
								; load anything else into it.

;-----------------------------------------------------------
; Main Program
;-----------------------------------------------------------
MAIN:							; The Main program
	;Setup the ADD16 function direct test
		;Setting up ADD16_OP1
		ldi ZL, low(ADD16_OP1)
		ldi ZH, high(ADD16_OP1)
		ldi mpr, $FF
		st Z+, mpr
		ldi mpr, $A2
		st Z, mpr		
		;Setting up ADD16_OP2
		ldi ZL, low(ADD16_OP2)
		ldi ZH, high(ADD16_OP2)
		ldi mpr, $77
		st Z+, mpr
		ldi mpr, $F4
		st Z, mpr	

		nop ; Check load ADD16 operands (Set Break point here #1)  
		; Call ADD16 function to test its correctness
		; (calculate A2FF + F477)
		rcall ADD16
		nop ; Check ADD16 result (Set Break point here #2)



	;Setup the SUB16 function direct test
		;Setting up SUB16_OP1
		ldi ZL, low(SUB16_OP1)
		ldi ZH, high(SUB16_OP1)
		ldi mpr, $CD
		st Z+, mpr
		ldi mpr, $4B
		st Z, mpr		
		;Setting up SUB16_OP2
		ldi ZL, low(SUB16_OP2)
		ldi ZH, high(SUB16_OP2)
		ldi mpr, $8A
		st Z+, mpr
		ldi mpr, $F0
		st Z, mpr	

		nop ; Check load SUB16 operands (Set Break point here)
		; Call SUB16 function to test its correctness
		; (calculate F08A - 4BCD)
		rcall SUB16
		nop ; Check SUB16 result (Set Break point here)



	;Setup the MUL24 function direct test
		;Get MUL24_OP1 set up
		ldi ZL, low(MUL24_OP1)
		ldi ZH, high(MUL24_OP1)
		ldi mpr, $FF
		st Z+, mpr
		st Z+, mpr	
		st Z,  mpr	
		;Get MUL24_OP2 set up
		ldi ZL, low(MUL24_OP2)
		ldi ZH, high(MUL24_OP2)
		ldi mpr, $FF
		st Z+, mpr
		st Z+, mpr	
		st Z,  mpr

		nop ; Check load MUL24 operands (Set Break point here) 
		; Call MUL24 function to test its correctness
		; (calculate FFFFFF * FFFFFF)
		rcall MUL24
		nop ; Check MUL24 result (Set Break point here)

		
		
		
	;Call COMPOUND function direct test
		nop ; Check load COMPOUND operands (Set Break point here) 
		; Call the COMPOUND function
		rcall COMPOUND
		nop ; Check COMPUND result (Set Break point here)
		; Observe final result in Memory window

DONE:	rjmp	DONE			; Create an infinite while loop to signify the 
								; end of the program.

;***********************************************************
;*	Functions and Subroutines
;***********************************************************

;-----------------------------------------------------------
; Func: ADD16
; Desc: Adds two 16-bit numbers and generates a 24-bit number
;		where the high byte of the result contains the carry
;		out bit.
;-----------------------------------------------------------
ADD16:
		;store vairables
		push ZL
		push ZH
		push YL
		push YH
		push XL
		push XH
		push B
		push A
		push MPR
		
		;Load beginning address of first operand into X
		ldi		XL, low(ADD16_OP1)		; Load low byte of address
		ldi		XH, high(ADD16_OP1)		; Load high byte of address

		;Load beginning address of second operand into Y
		ldi		YL, low(ADD16_OP2)		; Load low byte of address
		ldi		YH, high(ADD16_OP2)		; Load high byte of address

		;Load beginning address of result in Z
		ldi		ZL, low(ADD16_Result)		; Load low byte of address
		ldi		ZH, high(ADD16_Result)		; Load high byte of address

		;Execute the function
		;Add R1:R0 to R3:R2
		ld A, X+						;load A and B
		ld B, Y+
		add B, A						;Add low byte
		st Z+, B						;Store in result low byte

		ld A, X							;load A and B
		ld B, Y
		adc B, A 						;Add with carry high byte
		st Z+, B						;Store in result high byte
		
		;Store result
		brcc WASCARRY					;If no carry, do nothing.  
		ldi	mpr, $01					;else, add a carry
		st Z, mpr
		
		;No Carry
		WASCARRY: 
			nop 						;do nothing


		;pop vairables
		pop MPR
		pop A
		pop B
		pop XH
		pop XL
		pop YH
		pop YL
		pop ZH 
		pop ZL 

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: SUB16
; Desc: Subtracts two 16-bit numbers and generates a 16-bit
;		result.
;-----------------------------------------------------------
SUB16:
		;store vairables
		push ZL
		push ZH
		push YL
		push YH
		push XL
		push XH
		push B
		push A
		push MPR
		
		; Load beginning address of first operand into X
		ldi		XL, low(SUB16_OP1)		; Load low byte of address
		ldi		XH, high(SUB16_OP1)		; Load high byte of address

		; Load beginning address of second operand into Y
		ldi		YL, low(SUB16_OP2)		; Load low byte of address
		ldi		YH, high(SUB16_OP2)		; Load high byte of address

		;Load beginning address of result in Z
		ldi		ZL, low(SUB16_Result)		; Load low byte of address
		ldi		ZH, high(SUB16_Result)		; Load high byte of address

		;Execute the function
		;Add R1:R0 to R3:R2
		ld A, X+						;load A and B
		ld B, Y+
		sub B, A						;sub low byte
		st Z+, B						;Store in result low byte

		ld A, X							;load A and B
		ld B, Y
		sbc B, A 						;sub with borrow high byte
		st Z+, B						;Store in result high byte
		
		;pop vairables
		pop MPR
		pop A
		pop B
		pop XH
		pop XL
		pop YH
		pop YL
		pop ZH 
		pop ZL 

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL24
; Desc: Multiplies two 24-bit numbers and generates a 48-bit 
;		result.
;-----------------------------------------------------------
MUL24:
		; Execute the function here
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of MUL24_OP2
		ldi		YL, low(MUL24_OP2)	; Load low byte
		ldi		YH, high(MUL24_OP2)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(MUL24_Result)	; Load low byte
		ldi		ZH, high(MUL24_Result); Load high byte

		; Begin outer for loop
		ldi		oloop, 3		; Load counter
MUL24_OLOOP:
		; Set X to beginning address of MUL24_OP1
		ldi		XL, low(MUL24_OP1)	; Load low byte
		ldi		XH, high(MUL24_OP1)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 3		; Load counter
MUL24_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B

		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A

		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1	

		dec		iloop			; Decrement counter
		brne	MUL24_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 2		; Z <= Z - 2. Go to next place
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL24_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: COMPOUND
; Desc: Computes the compound expression ((D - E) + F)^2
;		by making use of SUB16, ADD16, and MUL24.
;
;		D, E, and F are declared in program memory, and must
;		be moved into data memory for use as input operands.
;
;		All result bytes should be cleared before beginning.
;-----------------------------------------------------------
COMPOUND:

		;Clear the result bytes so no corruption

		clr mpr
		ldi XL, low(SUB16_RESULT)
		ldi XH, high(SUB16_RESULT)
		st X+, mpr
		st X+, mpr

		ldi XL, low(ADD16_RESULT)
		ldi XH, high(ADD16_RESULT)
		st X+, mpr
		st X+, mpr	
		st X+, mpr

		ldi XL, low(MUL24_RESULT)
		ldi XH, high(MUL24_RESULT)
		st X+, mpr
		st X+, mpr	
		st X+, mpr
		st X+, mpr
		st X+, mpr	
		st X+, mpr

		; Setup SUB16 with operands D and E
		;Get operand D
		ldi ZL, low(OperandD<<1)		;get opD from prog memory
		ldi ZH, high(OperandD<<1)	;get opD from prog memory
		ldi YL, low(SUB16_OP2)
		ldi YH, high(SUB16_OP2)
		lpm mpr, Z+					;store opD's two bytes in SUB16_OP1
		st Y+, mpr
		lpm mpr, Z+
		st Y+, mpr
		;Get operand E
		ldi ZL, low(OperandE<<1)		;get opE from prog memory
		ldi ZH, high(OperandE<<1)	;get opE from prog memory
		ldi YL, low(SUB16_OP1)
		ldi YH, high(SUB16_OP1)
		lpm mpr, Z+					;store opE's two bytes in SUB16_OP1
		st Y+, mpr
		lpm mpr, Z+
		st Y+, mpr
		; Perform subtraction to calculate D - E
		rcall SUB16		

		; Setup the ADD16 function with SUB16 result and operand F
		;Get operand SUB16_Result
		ldi XL, low(SUB16_Result)	;get SUB16_Result
		ldi XH, high(SUB16_Result)	;get SUB16_Result
		ldi YL, low(ADD16_OP1)		;store SUB16_Result in add16 operand
		ldi YH, high(ADD16_OP1)
		ld mpr, X+					;store SUB16_Result's two bytes in ADD16_OP1
		st Y+, mpr
		ld mpr, X+
		st Y+, mpr
		;Get operand F
		ldi ZL, low(OperandF<<1)		;get opF from prog memory
		ldi ZH, high(OperandF<<1)	;get opF from prog memory
		ldi YL, low(ADD16_OP2)
		ldi YH, high(ADD16_OP2)
		lpm mpr, Z+					;store opF's two bytes in ADD16_OP2
		st Y+, mpr
		lpm mpr, Z+
		st Y+, mpr
		; Perform addition next to calculate (D - E) + F
		rcall ADD16

		; Setup the MUL24 function with ADD16 result as both operands
		;Get operand ADD16_Result
		ldi XL, low(ADD16_Result)	;get ADD16_Result
		ldi XH, high(ADD16_Result)	;get ADD16_Result
		ldi YL, low(MUL24_OP1)
		ldi YH, high(MUL24_OP1)
		ld mpr, X+					;store ADD16_Result's three bytes in MUL24_OP1
		st Y+, mpr
		ld mpr, X+
		st Y+, mpr	
		ld mpr, X+
		st Y+, mpr	

		;Get operand ADD16_Result
		ldi XL, low(ADD16_Result)	;get ADD16_Result
		ldi XH, high(ADD16_Result)	;get ADD16_Result
		ldi YL, low(MUL24_OP2)
		ldi YH, high(MUL24_OP2)
		ld mpr, X+					;store ADD16_Result's three bytes in MUL24_OP2
		st Y+, mpr
		ld mpr, X+
		st Y+, mpr	
		ld mpr, X+
		st Y+, mpr		
		; Perform multiplication to calculate ((D - E) + F)^2
		rcall MUL24

		ret						; End a function with RET

;-----------------------------------------------------------
; Func: MUL16
; Desc: An example function that multiplies two 16-bit numbers
;			A - Operand A is gathered from address $0101:$0100
;			B - Operand B is gathered from address $0103:$0102
;			Res - Result is stored in address 
;					$0107:$0106:$0105:$0104
;		You will need to make sure that Res is cleared before
;		calling this function.
;-----------------------------------------------------------
MUL16:
		push 	A				; Save A register
		push	B				; Save B register
		push	rhi				; Save rhi register
		push	rlo				; Save rlo register
		push	zero			; Save zero register
		push	XH				; Save X-ptr
		push	XL
		push	YH				; Save Y-ptr
		push	YL				
		push	ZH				; Save Z-ptr
		push	ZL
		push	oloop			; Save counters
		push	iloop				

		clr		zero			; Maintain zero semantics

		; Set Y to beginning address of B
		ldi		YL, low(addrB)	; Load low byte
		ldi		YH, high(addrB)	; Load high byte

		; Set Z to begginning address of resulting Product
		ldi		ZL, low(LAddrP)	; Load low byte
		ldi		ZH, high(LAddrP); Load high byte

		; Begin outer for loop
		ldi		oloop, 2		; Load counter
MUL16_OLOOP:
		; Set X to beginning address of A
		ldi		XL, low(addrA)	; Load low byte
		ldi		XH, high(addrA)	; Load high byte

		; Begin inner for loop
		ldi		iloop, 2		; Load counter
MUL16_ILOOP:
		ld		A, X+			; Get byte of A operand
		ld		B, Y			; Get byte of B operand
		mul		A,B				; Multiply A and B

		ld		A, Z+			; Get a result byte from memory
		ld		B, Z+			; Get the next result byte from memory
		add		rlo, A			; rlo <= rlo + A
		adc		rhi, B			; rhi <= rhi + B + carry
		ld		A, Z			; Get a third byte from the result
		adc		A, zero			; Add carry to A

		st		Z, A			; Store third byte to memory
		st		-Z, rhi			; Store second byte to memory
		st		-Z, rlo			; Store first byte to memory
		adiw	ZH:ZL, 1		; Z <= Z + 1	

		dec		iloop			; Decrement counter
		brne	MUL16_ILOOP		; Loop if iLoop != 0
		; End inner for loop

		sbiw	ZH:ZL, 1		; Z <= Z - 1
		adiw	YH:YL, 1		; Y <= Y + 1
		dec		oloop			; Decrement counter
		brne	MUL16_OLOOP		; Loop if oLoop != 0
		; End outer for loop
		 		
		pop		iloop			; Restore all registers in reverves order
		pop		oloop
		pop		ZL				
		pop		ZH
		pop		YL
		pop		YH
		pop		XL
		pop		XH
		pop		zero
		pop		rlo
		pop		rhi
		pop		B
		pop		A
		ret						; End a function with RET







;***********************************************************
;*	Stored Program Data
;***********************************************************

; Compoud operands
OperandD:
	.DW	0xFD51				; test value for operand D
OperandE:
	.DW	0x1EFF				; test value for operand E
OperandF:
	.DW	0xFFFF				; test value for operand F

;***********************************************************
;*	Data Memory Allocation
;***********************************************************

.dseg
.org	$0100				; data memory allocation for MUL16 example
addrA:	.byte 2
addrB:	.byte 2
LAddrP:	.byte 4

.org	$0110				; data memory allocation for operands
ADD16_OP1:
		.byte 2				; allocate two bytes for first operand of ADD16
ADD16_OP2:
		.byte 2				; allocate two bytes for second operand of ADD16
ADD16_Result:
		.byte 3				; allocate three bytes for ADD16 result

.org	$0120				; data memory allocation for results
SUB16_OP1:
		.byte 2				; allocate two bytes for first operand of SUB16
SUB16_OP2:
		.byte 2				; allocate two bytes for second operand of SUB16
SUB16_Result:
		.byte 2				; allocate three bytes for SUB16 result

.org	$0130				; data memory allocation for results
MUL24_OP1:
		.byte 3				; allocate two bytes for first operand of MUL24
MUL24_OP2:
		.byte 3				; allocate two bytes for second operand of MUL24
MUL24_Result:
		.byte 6				; allocate three bytes for MUL24 result

;***********************************************************
;*	Additional Program Includes
;***********************************************************
; There are no additional file includes for this program