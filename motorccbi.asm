;MOTORCC.ASM  :  Programa que aciona um motor de corrente contínua
; utilização de interrução timer0 contando 400 ciclos de máquina
;

#include <SFR51.inc> ;contem as definições de todos os SFRs
ORG 2000h         ;localização deste programa
;cabeçalho: todo programa deve ter um para o paulmon2 poder gerenciar
DB  0xA5, 0xE5, 0xE0, 0xA5 ;bytes de assinatura
DB  35,255,0,0             ;id (35=prog)
DB  0,0,0                  ;prompt code vector
  sjmp RTItimer0           ;salto para a rotina de interrupção
DB  0,0,0                  ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;definido pelo usuário
DB  255,255,255,255        ;tamanho e checksum (255=não usado)
DB  "MOTORCC", 0           ;máximo de 31 caracteres mais o zero
port_b       EQU 0x4001  ;82c55B  : porta B   motores estão aqui
port_c       EQU 0x4002  ;82c55C  : porta C
port_abc_pgm EQU 0x4003  ;82c55pgm  : registro de programação
;Rotinas do PAULMON2
cout     EQU 0x0030          ;Imprime o acumulador na porta serial
Cin      EQU 0x0032          ;AGUARDA (prende a CPU) um byte da porta serial e coloca no acumulador
pHex     EQU 0x0034          ;Imprime o acumulador - Hex
Upper    EQU 0x0040          ;Converter Acc para caixa alta
                             ;Valores não-ASCII não mudam
pint8u   EQU 0x004D          ;Imprime Acc em um inteiro de 0 ate 255
ORG 2040h                    ;executável do código começa aqui
  ljmp inicio
;NOSSAS VARIÁVEIS-------
dphc EQU 7Fh               ;guarda copia do dptr para a pstri
dplc EQU 7Eh               ;
pot  EQU 7Dh               ;guarda a resposta do usuário
cfaixas EQU 7Ch            ;conta as faixas
;-----------------------
;NOSSAS SUBROTINAS ------------------------
;RTI timer0    rotina de tratamento de interrupção do timer0
RTItimer0:      ;mais uma faixa de acionamento transcorrida; pot guarda a potencia desejada
  push acc      ;salva registradores
  push psw      
;reinicializar o contador (soma 16+8 banner)
  mov   a,TL0             ;pega o numero de ciclos decorridos desde a interrupção
  add   a,#70h+3          ;soma com a constante mais os CM dessas instruções
  mov   TL0,a             ;guarda o lsb do timer
  mov   a,TH0             ;pega o msb do timer
  addc  a,#FEh            ;soma considerando o carry da ultima adição
  mov   TH0,a             ;guarda o msb do timer
;tratar a faixa transcorrida
  djnz  cfaixas,not_I     ;conta as faixas, salta se não é um ponto inicial
  mov   cfaixas,#9        ;reinicializa o contador de faixas
not_I:
  mov   a,pot             ;pega a potencia
; lcall pHex
  jnz   compara           ;se não for zero vai comparar
  setb  c                 ;liga o carry para depois desligar
  sjmp  teste             ;vai acionar
compara:
  cjne  a,cfaixas,teste   ;liga o carry se pot<cfaixas
teste:
  clr  a
  cpl  c                  ;complementa o carry
  rlc  a                  ;leva o carry pro bit 0
;  jc   desliga               ;vai acionar quando gera carry
;liga:
;  mov   a,#00000001b      ;o bit 0 é ligado
;  sjmp  acionamotor       ;vai acionar
;desliga:
;  mov   a,#00000000b      ;o bit 0 é zerado
;acionamotor:
  mov  dptr,#port_b          ;onde os motores estão
  movx @dptr,a              ;aciona os motores
  cpl  a
  inc  dptr
  movx @dptr,a              ;ecoa para os leds
saiRTI:
  pop   psw
  pop   acc     ;recupera registradores
  reti          ;retorna ao programa principal
;PSTRI imprime uma string0 imediato
pstri:              ;esta subrotina supoe que o dptr esta apontando para uma string0
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
  lcall cout        ;imprime o caracter
  sjmp  pstr1       ;senão vai tratar o proximo caracter
pstr2:
  pop   acc         ;recupera o acumulador
  push  dpl         ;repoe endereço de retorno
  push  dph
  mov   dph,dphc    ;recupera o dptr original
  mov   dpl,dplc
  ret


;------------------------------------------
inicio:
;prepara a porta de programação do 8255
  mov   dptr,#port_abc_pgm   ;registro de programação do 8255
  mov   a,#128               ;PA=out,PB=out,PC=out (128)    =128
  movx  @dptr,a              ;programa 8255   :   movx - memória externa
  acall pstri DB "Acionamento do Motor CC bidirecional.",10,10,13,0
  acall pstri DB "Escolha direção: Direita (D) ou Esquerda (E).",,10,13,0
  acall pstri DB "Digite a potencia desejada (0-4)(ESC para encerrar):",10,13,0
;habilitando a interrupção timer0  
  setb  EA               ;Hab. Todas
  setb  ET0              ;Hab. Timer 0
;programando o timer0
  mov   a,TMOD            ;pega TMOD
  anl   a,#11110000b      ;mantém o timer 1 e zera o timer 0
  orl   a,#00000001b      ;seta o tmod
                          ;bit 3: gate: 0 liga por software
                          ;             1 liga por evento externo (EXT0)
                          ;bit 2: C/t: 0 contará ciclos de máquina: timer
                          ;            1 conta eventos externos
                          ;bits 1 e 0: modo: 00 compatibilidade, 13 bits 
                          ;                  01 contador de 16 bits
                          ;                  10 contador de 8+8 bits com reload
                          ;                  11 "modo misto"
  mov   TMOD,a            ;devolve o tmod
;inicializando o timer0
  mov   TH0,#FEh          ;timer conta para frente, gera interrupção no overflow (65536 CM)
  mov   TL0,#70h          ;queremos contar 400 CM
                          ;65536-400=65136 ciclos de máquina: inicialização do timer
;inicializando variáveis
  mov   cfaixas,#1       ;contador de faixas começa do 1 Para virar 0 na primeira interrupção
  mov   pot,#0           ;potencia começa do 0
;ligando o timer0
  setb  TR0              ;liga timer 0
loop:
  lcall cin             ;captura resposta do usuário
  lcall upper           ;converte para maiúsculo
  cjne  a,#'E',not_E    ;salta se não é E
  mov   dir,#1          ;armazena a direção esquerda
  sjmp  loop2
not_E:
  cjne  a,#'D',testaESC ;vai testar o ESC
  mov   dir,#-1         ;armazena a direção direita
  sjmp  loop2 
testaESC:
  cjne  a,#27,loop      ;salta se não é ESC
  mov   pot,#4          ;motor parado
  ret                   ;retorna ao PAULMON2
loop2:
  lcall cout            ;valida a entrada do usuário
loop3:
  lcall cin             ;aguarda a faixa de potência
  cjne  a,#'4'+1,teste1 ;salta se for menor que 4
teste1:
  jnc   loop2           ;salta se a entrada for inválida (maior que 4)
  cjne  a,#'0',teste2   ;salta se for menor que 0
teste2:
  jc    testaESC2       ;testa se é ESC
  lcall cout            ;valida a resposta do usuário
  anl   a,#00001111b    ;converte para binário
;é a hora de usar o #1 e #-1  
  mov   pot,a           ;guarda a potencia escolhida pelo usuário
  sjmp  loop            ;vai aguardar um novo comando
testaESC2:
  cjne  a,#27,loop3     ;salta se não é ESC
  mov   pot,#4          ;motor parado
  ret                   ;retorna ao PAULMON2
END
  
  
  
 
