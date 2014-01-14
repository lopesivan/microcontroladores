#include <SFR51.inc>
cseg at 0

sjmp  startup

;
;Subrotinas locais -------------------------------
;

;delay for a number of ms (specified by acc)
delay:
        mov     r0, a
dly2:   mov     r1, #230
dly3:   nop
        nop
        nop                     ;6 NOPs + DJNZ is 4.34 us
        nop                     ;with the 22.1184 MHz crystal
        nop
        nop
        djnz    r1, dly3        ;repeat 230 times for 1 ms
        djnz    r0, dly2        ;repeat for specified # of ms
        ret

;
;Programa principal-------------------------------
;
startup:

begin:
  mov   dptr,#tabela

  loop:
    clr   a           ;a <- 0

    movc  a, @a+dptr
    jz begin

    push  dph          ;salva o dptr
    push  dpl

    mov   dptr, #0x90
    mov  p1, a

    mov a, #0xFF
    acall delay       ;gasta tempo
    acall delay       ;gasta tempo
    acall delay       ;gasta tempo

    pop   dpl         ;recupera o dptr
    pop   dph

  inc dptr
    sjmp  loop        ;começa de novo

tabela:; gera agrupamentos de 8 bits
  DB 01111111b
  DB 00111111b
  DB 00011111b
  DB 10001111b
  DB 11000111b
  DB 11100011b
  DB 11110001b
  DB 11111000b
  DB 11111100b
  DB 11111110b
  DB 11111100b
  DB 11111000b
  DB 11110001b
  DB 11100011b
  DB 11000111b
  DB 10001111b
  DB 00011111b
  DB 00111111b
  DB 01111111b
  DB 255,0

END
