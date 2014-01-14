#include <SFR51.inc>
cseg at 0

location EQU 0x2000 ; ponto de montagem

ljmp  startup

;-------------------------------------------------
ORG location; endereco inicial de montagem
;-------------------------------------------------

;
;Cabeçalho do Paulmon2 ---------------------------
;
DB  0xA5,0xE5,0xe0,0xA5    ;signiture bytes
DB  35,255,0,0             ;id (35=prog, 253=startup, 254=command)
DB  0,0,0,0                ;prompt code vector
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;definido pelo usuário
DB  255,255,255,255        ;tamanho e checksum (255=não usado)
DB  "leds4",0              ;maximo 31 caracteres  mais o zero

ORG location+40            ;endereço de montagem do código executável
                           ; (64)[b10] == (40)(b16) 
;
;rotinas do paulmon2 -----------------------------
;
cout         EQU 0x0030 ;imprime o acumulador na serial
cin          EQU 0x0032 ;captura para o acumulador o que vem da serial
esc          EQU 0x003E ;Checagem da tecla ESC do paulmon2

port_1       EQU 0x90
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

update:  ;Atualiza a configuração dos LEDs
    push  dph          ;salva o dptr
    push  dpl          
    
    mov dptr, #port_1
    ;movx  @dptr, a
    mov  P1, a

    mov a, #0xFF
    acall delay       ;gasta tempo
    acall delay       ;gasta tempo
    acall delay       ;gasta tempo
    
    pop   dpl          ;recupera o dptr
    pop   dph  
    
    ret

;
;Programa principal-------------------------------
;
startup:
  
begin:  
    setb  TI;<<<<<<<<<<<<<<<<<<<< simulação LIGADA
    mov   dptr,#tabela

  loop:
    clr   a           ;a <- 0

    movc  a, @a+dptr
    jz begin
    acall update
    inc dptr
    sjmp  loop        ;começa de novo

  exit:
    ret              ;retorna ao PAULMON2

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
