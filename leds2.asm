;LEDS.ASM   : Liga os leds em sequencia. Original de PJRC
;Este programa compilou e rodou corretamente.
;Utiliza��o de tabelas ;  programa��o de portas
;MOVs diversos
;djnz

#include <SFR51.inc> ;include em minusculas!! contem as defini��es de todos os SFRs
;locat EQU 0x2000 ;localiza��o deste programa
ORG 2000h         ;localiza��o deste programa
;cabe�alho: todo programa deve ter um para o paulmon2 poder gerenciar
DB  0xA5, 0xE5, 0xE0, 0xA5 ;bytes de assinatura
DB  35,255,0,0             ;id (35=prog)
DB  0,0,0,0                ;prompt code vector
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;definido pelo usu�rio
DB  255,255,255,255        ;tamanho e checksum (255=n�o usado)
DB  "LEDs", 0              ;m�ximo de 31 caracteres mais o zero
ORG 2040h                  ;execut�vel do c�digo come�a aqui

;B2C55 localiza��es de mem�ria p0-> PA,PB,PC expans�o de portas
port_b       EQU 0x4001 ;82c55B : porta B
port_c       EQU 0x4002 ;82C55C : porta C
port_abc_pgm EQU 0x4003 ;82c55pgm : registro de programa��o

;para um exemplo mais sofisticado de como manipular as portas do 82c55 veja
;http://www.ece.orst.edu/~paul/8051-goodies/82c55.txt

esc EQU 0x003E ;Checagem da tecla ESC do paulmon2
  sjmp  startup   ;salta as subrotinas locais
;Subrotinas locais-----------------------------------------------------------------------
update:     ;Atualiza a configura��o dos LEDs
  push  dph          ;salva o dptr
  push  dpl          ;" 
  mov   dptr,#port_c ;dptr -> #port_c != LEDs na placa
  movx  @dptr,a      ;atualiza os LEDs
  pop   dpl          ;recupera o dptr
  pop   dph          ;o �ltimo que sai da pilha � o primeiro que entrou
 ret

delay:       ;Gasta tempo, prende a CPU
  mov   r0,a
dly2: 
  mov   r1,#83
dly3: 
  nop             ;gasta 1 ciclo de m�quina
  nop             ;gasta 1 ciclo de m�quina
  djnz  r1,dly3
  djnz  r0,dly2
 ret

;Programa principal ---------------------------------------------------------------------
startup:
 mov  dptr,#port_abc_pgm   ;registro de programa��o do 8255
 mov  a,#128               ;PA=out,PB=out,PC=out (128)    =128
 movx @dptr,a              ;programa 8255   :   movx - mem�ria externa

 ;coment�rios pulados

begin:
 mov   dptr,#table ;dptr -> in�cio da tabela
loop:
 clr   a           ;a <- 0
 movc  a,@a+dptr   ;pega um byte (configura��o dos LEDs) da tabela
 acall update      ;atualiza leds
 inc   dptr        ;dptr -> par�metro de temporiza��o
 lcall esc         ;testa se a tecla ESC foi pressionado
 jc    exit        ;carry ativado -> saia
 clr   a           ;a <- 0
 movc  a,@a+dptr   ;pega o par�metro de temporiza��o da tabela
 jz    exit       ;se o parametro de tempo for 0, vai reposicionar o ponteiro no in�cio da tabela
 acall delay       ;gasta tempo
 inc   dptr        ;avan�a dptr para a pr�xima linha
 sjmp  loop        ;come�a de novo
exit:
  mov   dptr,#port_c ;dptr -> #port_c != LEDs na placa
  mov   a,#11111111b ;todos os leds desligados
  movx  @dptr,a      ;atualiza os LEDs
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



