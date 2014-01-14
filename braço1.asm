; BRAÇO1.ASM    : ACIONAMENTO DE UM BRAÇO ROBÓTICO CONSTRUIDO COM 2 MOTORES DE PASSO
;                Escolha do modo de execução: comandar, gravar e reproduzir
;                Input do usuário uma de 8 teclas para o acionamento
;                Código modificado do stepper1.asm
#include <SFR51.inc>   ; definições de todos os SFRs
ORG  2000h             ;localização deste programa
;B2C55 localizações de memória p0-> PA,PB,PC expansão de portas
port_b       EQU 0x4001  ;82c55B  : porta B
port_c       EQU 0x4002  ;82c55C  : porta C
port_abc_pgm EQU 0x4003  ;82c55pgm  : registro de programação
esc          EQU 0x003E  ;Checagem da tecla ESC do paulmon2
cout     EQU 0x0030          ;Imprime o acumulador na porta serial
Cin      EQU 0x0032          ;AGUARDA (prende a CPU) um byte da porta serial e coloca no acumulador
pStr     EQU 0x0038          ;Imprime a string apontada pelo DPTR
Upper    EQU 0x0040          ;Converter Acc para caixa alta

;pint8u   EQU 0x004D          ;Imprime Acc em um inteiro de 0 ate 255
; cabeçalho: todo programa deve ter um, para o PAULMON2 poder gerenciar
DB  0xA5, 0xE5, 0xE0, 0xA5 ;bytes de assinatura
DB  35,255,0,0             ;id (35=prog)
DB  0,0,0,0                ;prompt code vector
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;definido pelo usuário
DB  255,255,255,255        ;tamanho e checksum (255=não usado)
DB  "BRACO1", 0             ;máximo de 31 caracteres mais o zero
ORG 2040h                  ;executável do código começa aqui
sjmp begin
;NOSSAS VARIAVEIS 
buf  EQU 80h               ;Buffer de comandos
dphc EQU 7Fh               ;guarda copia do dptr para a pstri
dplc EQU 7Eh               ;
n    EQU 7Dh               ;contador de caracteres do buffer
g    EQU 7Ch               ;flag de gravação
m    EQU 7Bh               ;flag de origem do comando
;NOSSAS SUBROTINAS -----------------------------------------------------------------------------

; ----------
pstri:               ;esta subrotina supoe que o dptr esta apontando para uma string0
  mov   dphc,dph    ;guarda dptr original
  mov   dplc,dpl    
  pop   dph         ;pega o endereço da string a ser impressa
  pop   dpl
  push  acc         ;salva o acumulador
pstr1:
  clr   a           ;limpa o acumulador
  movc  a,@a+dptr   ;pega um caracter a ser impresso
  inc   dptr        ;avança o dptr para o proximo caracter
  jz    pstr2       ;se ja for o '0' saia
; mov   c,acc.7     ;senão copia para o carry o bit 7 do acc
; anl   a,#7fh      ;apaga o bit 7
  lcall cout        ;imprime o caracter
; jc    pstr2       ;se o carry estiver ligado saia
  sjmp  pstr1       ;senão vai tratar o proximo caracter
pstr2:
  pop   acc         ;recupera o acumulador
  push  dpl         ;repoe endereço de retorno
  push  dph
  mov   dph,dphc    ;recupera o dptr original
  mov   dpl,dplc
  ret
;-----------------------------------------------------------------------------------------------
begin:
;prepara a porta de programação do 8255
  mov   dptr,#port_abc_pgm   ;registro de programação do 8255
  mov   a,#128               ;PA=out,PB=out,PC=out (128)    =128
  movx  @dptr,a              ;programa 8255   :   movx - memória externa
  acall pstri DB "Programa BRACO1: aciona um braco robotico com 2 motores de passo",13,10,10,0
menumodos:
  acall pstri DB 13,10,10,"Digite o modo de execucao:",13,10,0
  acall pstri DB "'C' - Comandar",13,10,0
  acall pstri DB "'G' - Gravar",13,10,0
  acall pstri DB "'R' - Reproduzir",13,10,0
  acall pstri DB "Ou ESC para encerrar",13,10,10,0
menumodos1:
  lcall cin
  lcall upper
  cjne  a,#'C',not_C
  acall pstri DB "Modo COMANDAR:",13,10,10,0
  mov   m,#0               ;comandos virão do teclado
  mov   g,#0               ;não grava
  sjmp  teclado            ;vai executar
menumodos2:
  ljmp  menumodos             ;ponte para o menumodos
not_C:
  cjne  a,#'G',not_G
  acall pstri DB "Modo GRAVAR:",13,10,10,0
  mov   m,#0                ;comandos virão do teclado
  mov   g,#1                ;grava
  mov   n,#0                ;buffer começa vazio
  sjmp  teclado             ;vai aguardar comando
not_G:
  cjne  a,#'R',not_R
  acall pstri DB "Modo REPRODUZIR:",13,10,10,0
  mov   m,#1                ;comandos virão da memória
  mov   g,#0                ;não grava
  mov   a,n                 ;pega o número de comandos no buffer
  jz    menumodos2             ;não permite reproduzir o buffer vazio
  mov   n,#0                ;zera o n para começar a percorrer
;  mov   dpl,#buf            ;dprt->buffer
;  mov   dph,#0              ;zera a parte alta do dptr
;  lcall pstr                ;imprime o buffer, acho.
  sjmp  case                ;vai executar
not_R:
  cjne  a,#27,menumodos1       ;se não for válido retorna
  mov   a,#00000000b        ;configuração que desliga as bobinas
  mov   dptr,#port_b        ;aponta para as bobinas
  movx  @dptr,a             ;desliga as bobinas
  cpl   a                   ;inverte a configuração 
  mov   dptr,#port_c        ;dptr -> porta c
  movx  @dptr,a             ;desliga as bobinas
  acall pstri DB 10,13,"Fim da Execucao",0
  ret                       ;retorna ao PAULMON2
case:  
  mov   a,m               ;pega flag de memória
  jz    cmdteclado        ;salta se vem do teclado
  mov   a,#buf            ;a aponta para o primeiro caracter do buffer
  add   a,n               ;calcula a posição do caracter a ser impresso
  mov   r0,a              ;r0 aponta pro caracter
  mov   b,@r0             ;coloca em b um caracter do buffer
  inc   n
;nesse ponto (b) contem um comando trazido do buffer
  mov   a,b               ;passa  esse comando para o (a)
  sjmp  tratacomando      ;vai tratar o comando
teclado:  
  acall pstri DB 13,10,10,"Digite o numero do acionamento usando o teclado numerico (NUMLOCK): ",13,10,0
  acall pstri DB "7 8 9",13,10,0
  acall pstri DB "4   6",13,10,0
  acall pstri DB "1 2 3",13,10,0
cmdteclado:
  lcall cin                  ;aguarda o input do usuario
;nesse ponto (a) tem um comando vindo do teclado ou da memória
tratacomando:
  cjne  a,#'1',not_1         ;salta se não é 1
  mov   dptr,#tab1           ;dptr->tabela 1
  sjmp  fora
ponte0:
  ljmp  case                 ;ponte para o case
not_1:
  cjne  a,#'2',not_2         ;salta se não é 2
  mov   dptr,#tab2           ;dptr->tabela 2
  sjmp  fora
not_2:
  cjne  a,#'3',not_3         ;salta se não é 3
  mov   dptr,#tab3           ;dptr->tabela 3
  sjmp  fora
not_3:
  cjne  a,#'4',not_4         ;salta se não é 4
  mov   dptr,#tab4           ;dptr->tabela 4
  sjmp  fora
not_4:
  cjne  a,#'6',not_6         ;salta se não é 6
  mov   dptr,#tab6           ;dptr->tabela 6
  sjmp  fora
not_6:
  cjne  a,#'7',not_7         ;salta se não é 7
  mov   dptr,#tab7           ;dptr->tabela 7
  sjmp  fora
not_7:
  cjne  a,#'8',not_8         ;salta se não é 8
  mov   dptr,#tab8           ;dptr->tabela 8
  sjmp  fora 
not_8:
  cjne  a,#'9',not_9         ;salta se não é 9
  mov   dptr,#tab9           ;dptr->tabela 9
  sjmp  fora
not_9:
  cjne  a,#27,ponte0        ;se não for válido retorna
  mov   a,#00000000b        ;configuração que desliga as bobinas
  mov   dptr,#port_b        ;aponta para as bobinas
  movx  @dptr,a             ;desliga as bobinas
  cpl   a                   ;inverte a configuração 
  mov   dptr,#port_c        ;dptr -> porta c
  movx  @dptr,a             ;desliga as bobinas
  mov   a,g                 ;pega o flag de gravação
  mov   b,#27               ;prepara o b com o ESC
  jnz   gravacomando        ;salta se gravar: gravar ESC
  acall pstri DB 10,13,"Fim da Execucao",0
  ret                       ;retorna ao PAULMON2
fora:
  lcall cout              ;valida o input do usuário
  mov   b,a               ;guarda o caracter
  mov   a,g               ;pega o flag de gravação
  jz    preploop          ;salta se não é pra gravar  
gravacomando:  
  mov   a,#buf             ;a aponta para o buffer de entrada
  add   a,n                ;(a <- a+n): onde inserir o caracter do buffer
  mov   r0,a               ;r0 aponta para o local onde armazenar o caracter
  mov   @r0,b              ;(endereçamento indireto): grava o comando no buffer de entrada
  inc   n                  ;conta esse comando
  mov   a,n                ;pega o numero de caracteres
  cjne  a,#7Fh,preploop    ;se nao é o 127o caracter volta para receber novo comando
  mov   b,#27              ;prepara para gravar ESC
  mov   r0,#255            ;r0 aponta para o ultimo caracter do buffer de entrada
  mov   @r0,b              ;(endereçamento indireto): grava o caracter no buffer de entrada
;  inc   n                  ;conta este caracter
  acall pstri DB 10,"BUFFER CHEIO!",13,10,0
  ljmp  menumodos             ;volta para a interface 

preploop:
  mov   a,b               ;pega o caracter
  cjne  a,#27,preploop1   ;salta se não é ESC
  ljmp  menumodos            ;se for ESC volta para a interface
preploop1:
  mov   b,#4              ;conta linhas tabela
loop:
  clr    a                ;a <- 0
  movc   a,@a+dptr        ;pega uma configuração da tabela
  push   dph              ;salva na pilha os "bits altos" do dptr
  push   dpl              ;salva na pilha os "bits baixos" do dptr
  mov    dptr,#port_b     ;faz o dptr apontar para a porta b
  movx   @dptr,a          ;energiza a bobina atual
  cpl    a                ;inverte a configuração
  mov    dptr,#port_c     ;dptr -> bobinas
  movx   @dptr,a          ;liga as bobinas 
  pop    dpl              ;recupera os "bits baixos" do dptr
  pop    dph              ;recupera os "bits altos" do dptr
  mov    r4,#30           ;o loop externo sera executado 9 vezes
delay2:
  mov    r5,#100          ;o loop interno ser executado 100 vezes
delay3:
  nop                     ;ciclo de máquina sem uso
  nop
  djnz   r5,delay3        ;conta o loop interno
  djnz   r4,delay2        ;conta o loop externo
  inc    dptr             ;proxima linha da tabela
  djnz   b,loop           ;percorre proxima linha da tabela
  ljmp   case             ;volta a aguardar novo comando do usuário

tab1:                  ;1 baixo esquerda    
    DB 00010001b
    DB 00100010b
    DB 01000100b
    DB 10001000b
tab2:                  ;2 baixo           
    DB 00010000b
    DB 00100000b
    DB 01000000b
    DB 10000000b 
tab3:                  ;3 baixo direita
    DB 00011000b
    DB 00100100b
    DB 01000010b
    DB 10000001b
tab4:                  ;4 esquerda
    DB 00000001b
    DB 00000010b
    DB 00000100b
    DB 00001000b
tab6:                  ;6 direita
    DB 00001000b
    DB 00000100b
    DB 00000010b
    DB 00000001b
tab7:                  ;7 cima esquerda
    DB 10000001b
    DB 01000010b
    DB 00100100b
    DB 00011000b
tab8:                  ;8 cima
    DB 10000000b
    DB 01000000b
    DB 00100000b
    DB 00010000b
tab9:                  ;9 cima direita
    DB 10001000b
    DB 01000100b
    DB 00100010b
    DB 00010001b
END                          ;Fim
