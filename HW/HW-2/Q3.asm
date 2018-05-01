.ORG 0x0046
	; Initialize Stack Pointer
	ldi R16, low(RAMEND) 	;Low Byte of End SRAM Address
	out SPL, R16 		 ;Write byte to SPL
	ldi R16, high(RAMEND)	;High Byte of End SRAM Address
	out SPH, R16 		 ;Write byte to SPH

	ldi R16, 8		;loop counter is 8
	ldi XL, low(DATA)	;load the address of the array
	ldi XH, high(DATA)		
	.DEF CURV = R17		;current value
	.DEF CURLOW = R18	;current lowest value
	ld CURLOW, X		;init CURLOW to first element

	RCALL MIN ;call MIN

.ORG 0x0060
MIN:
	tst R16			;check if R16 is 0
	breq EXIT		;if it is, go to exit
	ld CURV, X+		;get the next value in array and X++
	cp CURV, CURLOW
	brge CONT		;skip over changing lowest
	mov CURLOW, CURV 	;change lowest to the current value
	CONT:	
		dec R16		;else R16--
		rjmp MIN
	EXIT:
		sts $0108, CURLOW ;store lowest value in 0x0108
		ret

.DSEG
.ORG 0x0100
	DATA: .BYTE 8
	RESULT: .BYTE 1