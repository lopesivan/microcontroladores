;MOTORCC.ASM  :  Programa que aciona um motor de corrente cont�nua
; utiliza��o de interru��o timer0 contando 400 ciclos de m�quina
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
DB  "MOTORCC", 0           ;m�ximo de 31 caracteres mais o zero
;Rotinas do PAULMON2
cout     EQU 0x0030          ;Imprime o acumulador na porta serial
Cin      EQU 0x0032          ;AGUARDA (prende a CPU) um byte da porta serial e coloca no acumulador
pint8u   EQU 0x004D          ;Imprime Acc em um inteiro de 0 ate 255
ORG 2040h                    ;execut�vel do c�digo come�a aqui
  ljmp inicio
;NOSSAS VARI�VEIS-------
dphc EQU 7Fh               ;guarda copia do dptr para a pstri
dplc EQU 7Eh               ;
pot  EQU 7Dh               ;guarda a resposta do usu�rio
cfaixas EQU 7Ch            ;conta as faixas
;-----------------------
;NOSSAS SUBROTINAS ------------------------
;RTI timer0    rotina de tratamento de interrup��o do timer0
RTItimer0:      ;mais uma faixa de acionamento transcorrida
  push acc      ;salva registradores
  push psw      
;reinicializar o contador (soma 16+8 banner)
  mov   a,TL0             ;pega o numero de ciclos decorridos desde a interrup��o
  add   a,#70h+3          ;soma com a constante mais os CM dessas instru��es
  mov   TL0,a             ;guarda o lsb do timer
  mov   a,TH0             ;pega o msb do timer
  addc  a,#FEh            ;soma considerando o carry da ultima adi��o
  mov   TH0,a             ;guarda o msb do timer
;tratar a faixa transcorrida
  djnz  cfaixas,not_I     ;conta as faixas, salta se n�o � um ponto inicial
  mov   cfaixas,#9        ;reinicializa o contador de faixas
not_I:
  mov   a,pot             ;pega a potencia
  cjne  a,cfaixas,teste   ;n�o liga o carry se pot<=cfaixas
  jnc   liga              ;vai acionar quando n�o gera carry
;aqui desliga
;
  sjmp  saiRTI            ;termina
liga:
;aqui liga
;
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
  acall pstri DB "Acionamento do Motor CC.",10,10,13,0
  acall pstri DB "Digite a potencia desejada (0-9)(ESC para encerrar):",10,13,0
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
  mov   TH0,#FEh          ;timer conta para frente, gera interrup��o no overflow (65536 CM)
  mov   TL0,#70h          ;queremos contar 400 CM
                          ;65536-400=65136 ciclos de m�quina: inicializa��o do timer
;inicializando vari�veis
  mov   cfaixas,#1       ;contador de faixas come�a do 1 Para virar 0 na primeira interrup��o
  mov   pot,#0           ;potencia come�a do 0
;ligando o timer0
  setb  TR0              ;liga timer 0
loop:
  lcall cin             ;captura resposta do usu�rio
  cjne  a,#'9'+1,teste1 ;salta se for menor que 9
teste1:
  jnc   loop            ;salta se a entrada for inv�lida (maior que 9)
  cjne  a,#'0',teste2   ;salta se for menor que 0
teste2:
  jc    testaESC        ;testa se � ESC
  lcall cout            ;valida a resposta do usu�rio
  mov   pot,a           ;guarda a potencia escolhida pelo usu�rio
  sjmp  loop            ;vai aguardar um novo comando
testaESC
  cjne  a,#27,loop      ;salta se n�o � ESC
  clr   EA              ;desabilita Todas
  ret                   ;retorna ao PAULMON2
END
  
  
  
 
