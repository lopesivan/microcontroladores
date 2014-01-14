;RELOGIO.ASM  :  Programa que mostra um rel�gio digital na tela contando em tempo real
; utiliza��o de interru��o timer0 contando vig�simos de segundo
;

#include <SFR51.inc> ;contem as defini��es de todos os SFRs
ORG 2000h         ;localiza��o deste programa
;cabe�alho: todo programa deve ter um para o paulmon2 poder gerenciar
DB  0xA5, 0xE5, 0xE0, 0xA5 ;bytes de assinatura
DB  35,255,0,0             ;id (35=prog)
DB  0,0,0                  ;prompt code vector
  sjmp RTItimer0           ;salto para a rotina de interrup��o
DB  0,0,0                  ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;definido pelo usu�rio
DB  255,255,255,255        ;tamanho e checksum (255=n�o usado)
DB  "RELOGIO", 0              ;m�ximo de 31 caracteres mais o zero
;Rotinas do PAULMON2
cout     EQU 0x0030          ;Imprime o acumulador na porta serial
Cin      EQU 0x0032          ;AGUARDA (prende a CPU) um byte da porta serial e coloca no acumulador
pint8u   EQU 0x004D          ;Imprime Acc em um inteiro de 0 ate 255
ORG 2040h                  ;execut�vel do c�digo come�a aqui
  ljmp inicio
;NOSSAS VARI�VEIS-------
dphc EQU 7Fh               ;guarda copia do dptr para a pstri
dplc EQU 7Eh               ;
vigs EQU 7Dh               ;conta vig�simos
segs EQU 7Ch               ;conta segundos
mins EQU 7Bh               ;conta minutos
hors EQU 7Ah               ;conta horas
;-----------------------
;NOSSAS SUBROTINAS ------------------------
;RTI timer0    rotina de tratamento de interrup��o do timer0
RTItimer0:      ;mais um vig�simo de segundo transcorrido
  push acc      ;salva registradores
  push psw      
;reinicializar o contador (soma 16+8 banner)
  mov   a,TL0             ;pega o numero de ciclos decorridos desde a interrup��o
  add   a,#00h+3          ;soma com a constante mais os CM dessas instru��es
; add   a,#vrl0+3
  mov   TL0,a             ;guarda o lsb do timer
  mov   a,TH0             ;pega o msb do timer
  addc  a,#4Ch            ;soma considerando o carry da ultima adi��o
; addc  a,#vrh
  mov   TH0,a             ;guarda o msb do timer
;tratar o vig�simo transcorrido
  inc   vigs              ;conta o vig�simo      
  mov   a,vigs            ;pega vig�simos
  cjne  a,#20,saiRTI      ;sai se n�o � 1 segundo
  mov   vigs,#0           ;zera o contador de vig�simos
  inc   segs              ;mais um segundo transcorrido
  mov   a,segs            ;pega segundos
  cjne  a,#60,imprime     ;vai imprimir se n�o � 1 minuto
  mov   segs,#0           ;zera o contador de segundos
  inc   mins              ;mais um minuto transcorrido
  mov   a,mins            ;pega minutos
  cjne  a,#60,imprime     ;vai imprimir se n�o � 1 hora
  mov   mins,#0           ;zera o contador de minutos
  inc   hors              ;conta a hora
  mov   a,hors            ;pega horas
  cjne  a,#24,imprime     ;vai imprimir se n�o � 1dia
  mov   hors,#0           ;zera o contador de horas
imprime:
  mov   a,#13             ;coloca um CR no acumulador
  lcall cout              ;reposiciona o ponteiro de impress�o no in�cio da linha
  mov   a,hors            ;pega horas
  cjne  a,#10,testehora   ;vai testar horas
testehora:
  jnc   horas2            ;salta se horas tem 2 digitos
  mov   a,#'0'            ;coloca um '0' no acumulador
  lcall cout              ;imprime '0'
horas2:
  mov   a,hors            ;pega horas
  lcall pint8u            ;imprime 
  mov   a,#':'            ;coloca um ':' no acumulador
  lcall cout              ;imprime ':'
  mov   a,mins            ;pega minutos
  cjne  a,#10,testemins   ;vai testar minutos
testemins:
  jnc   mins2             ;salta se minutos tem 2 digitos
  mov   a,#'0'            ;coloca um '0' no acumulador
  lcall cout              ;imprime '0'
mins2:
  mov   a,mins            ;pega minutos
  lcall pint8u            ;imprime 
  mov   a,#':'            ;coloca um ':' no acumulador
  lcall cout              ;imprime ':'
  mov   a,segs            ;pega segundos
  cjne  a,#10,testesegs   ;vai testar segundos
testesegs:
  jnc   segs2             ;salta se segundos tem 2 digitos
  mov   a,#'0'            ;coloca um '0' no acumulador
  lcall cout              ;imprime '0'
segs2:
  mov   a,segs            ;pega segundos
  lcall pint8u            ;imprime 
saiRTI:
  pop   psw
  pop   acc     ;recupera registradores
  reti          ;retorna ao programa principal
;PSTRI imprime uma string0 imediato
pstri:              ;esta subrotina supoe que o dptr esta apontando para uma string0
  mov   dphc,dph    ;guarda dptr original
  mov   dplc,dpl    
  pop   dph         ;pega o endere�o da string a ser impressa
  pop   dpl
  push  acc         ;salva o acumulador
pstr1:
  clr   a           ;limpa o acumulador
  movc  a,@a+dptr   ;pega um caracter a ser impresso
  inc   dptr        ;avan�a o dptr para o proximo caracter
  jz    pstr2       ;se ja for o '0' saia
  lcall cout        ;imprime o caracter
  sjmp  pstr1       ;sen�o vai tratar o proximo caracter
pstr2:
  pop   acc         ;recupera o acumulador
  push  dpl         ;repoe endere�o de retorno
  push  dph
  mov   dph,dphc    ;recupera o dptr original
  mov   dpl,dplc
  ret


;------------------------------------------
inicio:
  acall pstri DB "Relogio. Aperte ESC para sair",10,10,13,0
;habilitando a interrup��o timer0  
  setb  EA               ;Hab. Todas
  setb  ET0              ;Hab. Timer 0
;programando o timer0
  mov   a,TMOD            ;pega TMOD
  anl   a,#11110000b      ;mant�m o timer 1 e zera o timer 0
  orl   a,#00000001b      ;seta o tmod
                          ;bit 3: gate: 0 liga por software
                          ;             1 liga por evento externo (EXT0)
                          ;bit 2: C/t: 0 contar� ciclos de m�quina: timer
                          ;            1 conta eventos externos
                          ;bits 1 e 0: modo: 00 compatibilidade, 13 bits 
                          ;                  01 contador de 16 bits
                          ;                  10 contador de 8+8 bits com reload
                          ;                  11 "modo misto"
  mov   TMOD,a            ;devolve o tmod
;inicializando o timer0
  mov   TH0,#4Ch          ;timer conta para frente, gera interrup��o no overflow (65536 CM)
  mov   TL0,#00h          ;queremos contar vig�simos de segundo: 921.600 CM /20 = 46080 CM
                          ;65536-46080=19456 ciclos de m�quina: inicializa��o do timer
;inicializando vari�veis
  mov   vigs,#0
  mov   segs,#0
  mov   mins,#0
  mov   hors,#0
;ligando o timer0
  acall pstri DB "00:00:00",0  ;inicializa o display
  setb  TR0              ;liga timer 0
loop:
  lcall cin             ;captura resposta do usu�rio
  cjne  a,#27,loop      ;salta se n�o � ESC
  clr   EA              ;desabilita Todas
  ret                   ;retorna ao PAULMON2
END
  
  
  
 
