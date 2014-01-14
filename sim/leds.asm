;LEDS.ASM: Liga os leds em sequencia.

#include <SFR51.inc> ;contem as definições de todos os SFRs
ORG 2000h            ;localização deste programa

;cabeçalho: todo programa deve ter um para o paulmon2 poder gerenciar
DB  0xA5, 0xE5, 0xE0, 0xA5 ;bytes de assinatura
DB  35,255,0,0             ;id (35=prog)
DB  0,0,0,0                ;prompt code vector
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;definido pelo usuário
DB  255,255,255,255        ;tamanho e checksum (255=não usado)
DB  "LEDs", 0              ;máximo de 31 caracteres mais o zero
ORG 2040h                  ;executável do código começa aqui

;B2C55 localizações de memória p0-> PA,PB,PC expansão de portas
port_b       EQU 0x4001 ;82c55B : porta B
port_c       EQU 0x4002 ;82C55C : porta C
port_abc_pgm EQU 0x4003 ;82c55pgm : registro de programação

esc EQU 0x003E ;Checagem da tecla ESC do paulmon2
sjmp  startup  ;salta as subrotinas locais

;
;Subrotinas locais -------------------------------
;

update:              ;Atualiza a configuração dos LEDs
  push  dph          ;salva o dptr
  push  dpl          ;"
  mov   dptr,#port_c ;dptr -> #port_c != LEDs na placa
  movx  @dptr,a      ;atualiza os LEDs
  pop   dpl          ;recupera o dptr
  pop   dph          ;o último que sai da pilha é o primeiro que entrou
ret

delay:       ;Gasta tempo, prende a CPU
  mov   r0,a

  dly2:
    mov   r1,#250

  dly3:
    nop             ;gasta 1 ciclo de máquina
    nop             ;gasta 1 ciclo de máquina
    djnz  r1,dly3
    djnz  r0,dly2
ret

;
;Programa principal-------------------------------
;
startup:
  mov  dptr,#port_abc_pgm   ;registro de programação do 8255
  mov  a,#128               ;PA=out,PB=out,PC=out (128)    =128
  movx @dptr,a              ;programa 8255   :   movx - memória externa

  begin:
    mov   dptr,#table ;dptr -> início da tabela

  loop:
    clr   a           ;a <- 0
    movc  a,@a+dptr   ;pega um byte (configuração dos LEDs) da tabela
    acall update      ;atualiza leds
    inc   dptr        ;dptr -> parâmetro de temporização
    lcall esc         ;testa se a tecla ESC foi pressionado
    jc    exit        ;carry ativado -> saia
    clr   a           ;a <- 0
    movc  a,@a+dptr   ;pega o parâmetro de temporização da tabela
    jz    begin       ;se o acumulador for 0, pula para label
    acall delay       ;gasta tempo
    inc   dptr        ;avança dptr para a próxima linha
    sjmp  loop        ;começa de novo

  exit:
    ret              ;retorna ao PAULMON2

table:
  DB 01111111b, 90
  DB 00111111b, 70
  DB 00011111b, 50
  DB 10001111b, 40
  DB 11000111b, 40
  DB 11100011b, 40
  DB 11110001b, 40
  DB 11111000b, 50
  DB 11111100b, 70
  DB 11111110b, 90
  DB 11111100b, 70
  DB 11111000b, 50
  DB 11110001b, 40
  DB 11100011b, 40
  DB 11000111b, 40
  DB 10001111b, 40
  DB 00011111b, 50
  DB 00111111b, 70
  DB 01111111b, 90
  DB 255,0

END

