.include "m128def.inc"
.def mpr = r16
.ORG $0000
   RJMP initUSART1;
.ORG $003C
   RCALL RECEIVE_DATA;
   RETI
.ORG $0046

initUSART1:
   ;Initialize Stack Pointer
   ldi mpr, low(RAMEND) ;(1) ;Low Byte of End SRAM Address
   out SPL, mpr         ;(2) ;Write byte to SPL
   ldi mpr, high(RAMEND);(3) ;High Byte of End SRAM Address
   out SPH, mpr         ;(4) ;Write byte to SPH	

   ;Configure Port D, pin 2
   ldi mpr, (0<<PD2)    ;(5) ;Set RXD1 to be input
   out DDRD, mpr        ;(6)

   ;Set baud rate at 9600bps, double data rate
   ldi mpr, (1<<U2X1)   ;(7) ;Set double data rate on USART1
   sts UCSR1A, mpr      ;(8) ;UCSR1A in extended I/O space
   ldi mpr, 207         ;(9) ;UBRR = 207
   sts UBRR1L, mpr      ;(10);UBRR1L in extended I/O space  

   ;Enable receiver and RX Complete interrupt
   ldi mpr, (1<<RXEN1)|(1<<RXCIE1) ;(11) ;Rec Enable and Rec Inrpt Enable
   sts UCSR1B, mpr     ;(12) ;UCSR1B in extended I/O space

   ;Set frame format: 8 data, 2 stop bits, asynchronous, even parity
   ldi mpr, (1<<USBS1)|(1<<UPM11)(1<<UCSZ11)|(1<<UCSZ10);(13)
   sts UCSR1C, mpr     ;(14)

   sei

MAIN:
   LDI XH, high(Buffer)
   LDI XL, low(Buffer)
LOOP:
   RJMP LOOP ; Wait for data
   ...
RECEIVE_DATA:
   push mpr ; Save mpr
   ;Receive data and store in buffer
   ldi mpr, UDR1  ;(15) mpr = pointer to recieved data
   st X+, mpr     ;(16) X = *mpr, X++

   pop mpr ; Restore mpr
   ret ;Return
Buffer:
   .BYTE 100 ;100 byte buffer 