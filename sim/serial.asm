#include <SFR51.inc>
cseg at 0  ;<<<<<<<<<<<<<<<<<<<< simulação LIGADA

location EQU 0x2000 ; ponto de montagem

ljmp inicializa

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
DB  "labA",0               ;maximo 31 caracteres  mais o zero

ORG location+40            ;endereço de montagem do código executável
                           ; (64)[b10] == (40)(b16)
;
;rotinas do paulmon2 -----------------------------
;
cout         EQU 0x0030 ;imprime o acumulador na serial
cin          EQU 0x0032 ;captura para o acumulador o que vem da serial
esc          EQU 0x003E ;Checagem da tecla ESC do paulmon2

phex         EQU 0x0034 ;print acc in hex (2 digits)
phex16       EQU 0x0036 ;print dptr in hex (4 digits)
pstr         EQU 0x0038 ;print a string @dptr
newline      EQU 0x0048 ;print a newline (CR and LF)
pint8u       EQU 0x004D ;print acc as unsigned int (0 to 255)
pint16u      EQU 0x0053 ;print dptr as unsigned int (0 to 65535)

;82C55 memory locations P0 -> PA, PB, PC
port_b       EQU 0x4001 ;82C55B: porta B motor
port_c       EQU 0x4002 ;82C55C: porta C LEDs
port_abc_pgm EQU 0x4003 ;82C55pgm: registro de programação
                        ;configure in/out of all three ports

;nossas variáveis
dphc         EQU 0x7F
dplc         EQU 0x7E   ;variáveis para armazenar o dptr na pstri

;nossas constantes
;soma        EQU 106  ;Usado para fazer o complemento
;maxBuffer   EQU 128  ;Numero máximo de caracteres que são guardados no buffer

;-------------------------------------------------
inicializa:
  ;`<  =faça alguma coisa=  >`

  ljmp MainLoop       ; salta as subrotinas
;-------------------------------------------------

;
;subrotinas --------------------------------------
;
pstri: ;imprime mensagem imediata
  mov   dphc, dph
  mov   dplc, dpl   ;salva dptr
  pop   dph
  pop   dpl         ;recupera o endereço inicial da mensagem
  push  acc         ;salva o acumulador

pstr1:
  clr   a
  movc  a, @a+dptr  ;pega um caracter
  inc   dptr        ;avança o ponteiro
  jz    pstr2       ;testa se é o último
  lcall cout        ;imprime o caracter
  sjmp  pstr1       ;vai para o próximo

pstr2:
  pop   acc         ;recupera o acumulador
  push  dpl
  push  dph         ;empilha o endereço de retorno
  mov   dpl,dplc
  mov   dph,dphc    ;recupera o dptr original
  ret

saudacao:
  acall pstri DB 13, 10, "...............", 0
  acall pstri DB 13, 10, "Seja bem vindo usuario", 0
  lcall newline
  ret

adeus:
  acall pstri DB 13, 10 ,"...............", 0
  acall pstri DB 13, 10 ,"Fim 1 do programa!", 0
  acall pstri DB 13, 10 ,"Fim 2 do programa!", 0
  acall pstri DB 13, 10 ,"Fim 3 do programa!", 0
  acall pstri DB 13, 10 ,"Fim 4 do programa!", 0
  lcall newline
  ret

;******************* Main ****************************
MainLoop:
  setb  TI;<<<<<<<<<<<<<<<<<<<< simulação LIGADA  e integrada ao PAULMON2
  nop
  acall saudacao
  acall adeus
  ;`<  =faça alguma coisa=  >`
;-------------------------------------------------

END
