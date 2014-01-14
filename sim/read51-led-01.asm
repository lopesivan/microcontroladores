#include <SFR51.inc>
cseg at 0

org 00H

ajmp inicio; vá para a posição início

ORG 50H

inicio:

; (11111110)2 = (FE)16 = FEh
mov A, #11111110B

repete:
  mov P1, A
  rl  A
  ajmp  repete

END
