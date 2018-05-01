.include "m128def.inc"
.def mpr = r16
.def counter = r17

.ORG $0000
   RJMP Initialize
.ORG $0020             ;Timer/Counter0 overflow interrupt vector
   JMP Reload_counter
.ORG $0046             ;End of interrupt vectors
Initialize:
   ldi mpr, (1<<TOIE0) ;(1) ;Enable interrupt on Timer/Counter0 overflow
   out TIMSK, mpr      ;(2)
   sei                 ;Enable global interrupt
   ldi mpr, 178        ;(3) ;Load the value for delay
   out TCNT0, mpr      ;(4) 
   ldi mpr, 0b00000111 ;(5) ;prescalar = 1024, mode = normal
   out TCCR0, mpr      ;(6) 
   ldi counter, 200    ;(7) ;Set counter 200*.005=1sec.
LOOP:
   cpi counter, 0      ;Repeat until interrupted
   brne LOOP

Reload_counter:
   push mpr           ;Save mpr
   ldi mpr, 178       ;(8) ;Load the value for delay
   out TCNT0, mpr     ;(9) 
   dec counter        ;(10);Decrement counter 

   pop mpr            ;Restore mpr
   reti