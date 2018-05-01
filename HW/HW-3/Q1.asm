.include "m128def.inc"
.def mpr = r16

START:
.org $0000
   RJMP INIT
.org $0002
   RJMP ISR_DevA
.org $0008
   RJMP ISR_DevB
.org $000C
   RJMP ISR_DevC

INIT:
   ldi mpr, 0b10000011
   sts EICRA, mpr
   ldi mpr, 0b00001100
   out EICRB, mpr
   ldi mpr, 0b00101001  ;(1)
   out EIMSK, mpr
   ldi mpr, $00
   out DDRD, mpr
   out DDRE, mpr        ;(2)
   ldi mpr,0b00001000
   out PORTD, mpr       ;(3)
   sei
   ...
MAIN:
   {...
   ...do something...
   ...}
ISR_DevA:
   ...
   ...
   sbr mpr, (1<<0)|(1<<3)|(1<<5)     ;(4)
   out EIFR, mpr                     ;(5)
   RETI
ISR_DevB:
   {...
   ...
   RETI
   }
ISR_DevC:
   {...
   ...
   RETI
   }