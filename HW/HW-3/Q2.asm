.include "m128def.inc"
.def mpr = mpr

.ORG $0000
   RJMP INIT
.ORG $0046                 ;End of interrupt vectors
INIT: 
   ;Initialize Stack Pointer
   ldi mpr, low(RAMEND)    ;Low Byte of End SRAM Address
   out SPL, mpr            ;Write byte to SPL
   ldi mpr, high(RAMEND)   ;High Byte of End SRAM Address
   out SPH, mpr            ;Write byte to SPH	

   ;clearOC1A on compare match. pre=256, mode=CTC
   ldi mpr, (1<<COM1A1)|(1<<WGM12)|(1<<CS12)
   out TCCR1B, mpr         ;timer clock = system clock/256
   
   ldi mpr, (0<<WGM11)|(0<<WGM10)
   out TCCR1A, mpr         ;CTC mode lower 2-bits
   
WAIT:
   ldi mpr, 0b00100011     ;OCR1A holds TOP = 62499
   out OCR1AL, mpr
   ldi mpr, 0b11110100
   out OCR1AH, mpr
   ldi mpr, $00            ;set counter to 0
   out TCNT1L, mpr
   out TCNT1H, mpr

   WAITLOOP:
      in mpr, TIFR         ;Read in OCF1A in TIFR
      cpi mpr, (1<<OCF1A)
      brne WAITLOOP        ;OCF1A not set? Loop again
      ldi mpr, (1<<OCF1A)  ;Clear OCF1A by writing one to it
      out TIFR, mpr    

   RET