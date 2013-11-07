;BANNER0.ASM  rotinas do PAULMON2, rotinas de entrada e saida: CIN, COUT, PSTR, 
;             entrada de string para memória, validação de caracter,
;             multiplos mapas de bits, enderecamento indireto, CJNE,
;             DJNZ, soma 16 <- 16+16, soma 16 <- 16+8
;
;Este programa recebe uma palavra 9 caracteres e a imprime em letras grandes,
;como definido pelo Bitmap abaixo.
#include <SFR51.inc>    ;contem as definições de todos os SFRs
ORG 2000h               ;Local onde este programa vai ser montado
; cabeçalho: todo programa deve ter um, para o PAULMON2 poder gerenciar
DB   0xA5,0xE5,0xE0,0xA5 ;Bytes de assinatura
DB   35,255,0,0          ;Id (35=prog)
DB   0,0,0,0             ;Prompt code vector
DB   0,0,0,0             ;Reservado
DB   0,0,0,0             ;Reservado
DB   0,0,0,0             ;Reservado
DB   0,0,0,0             ;Definido pelo usuario
DB   255,255,255,255     ;Tamanho e checksum (255=não utilizado)
DB   "Banner", 0         ;Max 31 caracteres, mais o zero
;ROTINAS DO PAULMON2
cout     EQU 0x0030          ;Imprime o acumulador na porta serial
Cin      EQU 0x0032          ;AGUARDA (prende a CPU) um byte da porta serial e coloca no acumulador
pHex     EQU 0x0034          ;Imprime o acumulador - Hex
pHex16   EQU 0x0036          ;Imprime o DPTR - Hex
pStr     EQU 0x0038          ;Imprime a string apontada pelo DPTR
                             ;tem que terminar com 0 (binario) ou um bit set High (ligado)
                             ;Apertar ESQ interrompe a impressão
gHex     EQU 0x003A          ;Pega um valor Hex e coloca no Acc
                             ;Carry setado se o ESC foi pressionado
gHex16   EQU 0x003C          ;Pega um valor Hex e coloca no DPTR
                             ;Carry setatado se o ESC foi pressionado
ESC      EQU 0x003E          ;Checagem da tecla ESC
                             ;Carry setatado se o ESC foi pressionado
Upper    EQU 0x0040          ;Converter Acc para caixa alta
                             ;Valores não-ASCII não mudam
Init     EQU 0x0042          ;Inicializar interface serial
newline  EQU 0x0048          ;Imprimir CR/LF (13 e 10) (carriage return/line feed) 
lenstr   EQU 0x004A          ;Retorna (no R0) o tamanho da string @DPTR         
pint8u   EQU 0x004D          ;Imprime Acc em um inteiro de 0 ate 255
pint8    EQU 0x0050          ;Imprime Acc em um inteiro de -128 ate 127
pint16u  EQU 0x0053          ;Imprime DPTR em um inteiro, 0 to 65535
;Memória RAM que vamos usar
dphc     EQU 7Fh        ;armazena temporariamente o dptr para a PSTRI
dplc     EQU 7Eh
string   EQU 0x20       ;armazena a palavra do usuario
num      EQU 0x2A       ;conta o numero de caracteres 

ORG  2040h            ;Começo do código executável
  sjmp   begin        ;salta nossas subrotinas
;NOSSAS SUBROTINAS  -----------------------------------------------------------------------------
pstri:                ;esta subrotina supoe que o dptr esta apontando para uma string0
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
;  mov   c,acc.7     ;senão copia para o carry o bit 7 do acc
;  anl   a,#7fh      ;apaga o bit 7
   lcall cout        ;imprime o caracter
;  jc    pstr2       ;se o carry estiver ligado saia
   sjmp  pstr1       ;senão vai tratar o proximo caracter
pstr2:
   pop   acc         ;recupera o acumulador
   push  dpl         ;repoe endereço de retorno
   push  dph
   mov   dph,dphc    ;recupera o dptr original
   mov   dpl,dplc
   ret
;-------------------------------------------------------------------------------------------------
;PROGRAMA PRINCIPAL
begin:
  lcall  newline       ;pula uma linha
; mov    dptr,#mesg1   ;dptr aponta para msg1
; lcall  pstr          ;imprime na tela a mensagem 1
  acall  pstri DB "Por favor digite uma palavra (max 9 caracteres): ",0  ;boas vindas
  mov    num,#0        ;inicializa num com 0
get_string:
  ;Pega um caracter
  lcall  cin            ;Aguarda a resposta do usuario
  lcall  upper          ;converte-o para maiusculo, poe no acumulador 
  cjne   a,#13,not_cr   ;se nao for enter, vai para not_cr
  sjmp   got_string     ;para de procurar se for CR

not_cr:
  mov    b,a               ;guarda o caracter no B
  ;é um caracter que conhecemos?(está na string chars - dicionario)?
  mov    dptr, #chars-1   ;dptr aponta para o dicionario-1

search_next:
  inc    dptr               ;avanca dptr
  clr    a                  ;limpa o acumulador
  movc   a,@a+dptr          ;pega o caracter no dicionario
  jz     get_string         ;se for o fim do dicionario (0), espera outra resposta do usuario
  cjne   a,b,search_next    ;compara com o caracter do usuario, busca outro se diferente
  ;se o programa chegou aqui, a entrada do usuario está ok
  lcall  cout               ;imprime o caracter: valida a entrada do usuario
  mov    a,#string          ;a aponta para o buffer de entrada
  add    a,num              ;(a <- a+num): onde inserir o caracter do buffer
  mov    r0,a               ;r0 aponta para o local onde armazenar o caracter
  mov    @r0,b              ;(endereçamento indireto): grava o caracter no buffer de entrada
  inc    num                ;conta este caracter
  mov    a,num              ;pega o numero de caracteres
  cjne   a,#9,get_string    ;se nao é o 9º, volta para pegar o proximo
  sjmp   got_string         ;vai tratar a entrada do usuario
  ;quando chegamos aqui temos uma string do usuario completa
  ;na memoria interna, no endereço "string", tamanho esta em "num"

got_string:
  mov    a,num             ;pega o numero de caracteres            
  jz     begin             ;não permite string vazia
  lcall  newline           ;pula uma linha           
  ;mov a,num ;imprime num em hexa ?!
  ;lcall phex
  lcall  newline           ;pula uma linha           
  lcall  newline           ;pula uma linha           
  mov    r5,#0             ;r5 conta linhas ?????

line_loop:
  mov    r3,#0             ;r3 conta caracteres do buffer

char_loop:
  mov    a,#string         ;a aponta para o primeiro caracter do buffer
  add    a,r3              ;calcula a posição do caracter a ser impresso
  mov    r0,a              ;r0 aponta pro caracter
  mov    b,@r0             ;coloca em b um caracter do buffer
  ;mov a,b
  ;lcall cout
  ;find which character within the string we have
  mov    dptr,#chars-1     ;dptr aponta para o dicionario-1    
  mov    r4,#255           ;?????
csearch:
  inc    r4                ;conta o caracter                
  inc    dptr              ;proximo caracter
  clr    a                 ;limpa o acumulador 
  movc   a,@a+dptr         ;pega o character no dicionario
  cjne   a,b,csearch       ;se a e b não forem iguais vai testar o proximo
  ;mov a, r4 ; imprime a em hexa: o que é a?
  ;lcall phex
  ;agora o r4 tem o indice desse caracter que é tambem o indice do desenho (bitmap)
  mov    a,r4              ;pega o indice do caracter no dicionario
  mov    b,#9              ;?????
  mul    ab                ;encontra a posiçao inicial do desenho no bitmap (r4*9)
  mov    dptr,#table       ;dptr aponta para a posiçao inicial das tabelas
;------------------- soma de 16+16bits: dptr <- (ba)+dptr 
  add    a,dpl             ;soma LSB(r4*9) com DPL
  mov    dpl,a             ;guarda o resultado no dpl
  mov    a,b               ;pega o MSB(r4*9)
  addc   a,dph             ;soma MSB(r4*9) com o DPH, mais o carry
  mov    dph,a             ;guarda o resultado no dph
;-------------------
  ;neste ponto o dptr aponta pro bitmap deste caracter
  mov    a,r5              ;pega o indice da linha em tratamento
;------------------- soma de 16+8bits: dptr <- dptr+a
  add    a,dpl             ;soma com o LSB do endereço do bitmap
  mov    dpl,a             ;guarda em dpl
  mov    a,dph             ;pega o MSB do endereço do bitmap
  addc   a,#0              ;soma com 0, mais o carry da ultima adiçao
  mov    dph,a             ;guarda em dph
;-------------------
  ;agora o dptr aponta para o byte que precisamos imprimir
  clr    a                 ;limpa o acumulador
  movc   a,@a+dptr         ;a pega o byte da tabela
  mov    r0,#8             ;r0 <- 8, numero de bits
bit_loop:
  rlc    a                 ;'gira' os bits do acumulador (rotate) com o carry
  push   acc               ;salva os bits rotados
  mov    a,#' '            ;a <- branco: hipótese
  jnc    btlp2             ;salta se hipótese correta
  mov    a,#'@'            ;senão corrige hipótese: imprime '@'
btlp2:
  lcall  cout              ;imprime caracter
  pop    acc               ;recupera bits rotados
  djnz   r0,bit_loop       ;conta o bit impresso
  mov    a,#' '            ;a <- branco  
  lcall  cout              ;imprime o branco entre 2 caracteres grandes
  inc    r3                ;proximo caracter do buffer
  mov    a,r3              ;pega o numero de caracteres ja tratados
  cjne   a,num,char_loop   ;se não tratou todos volta para o proximo
  lcall  newline           ;pula uma linha   
  inc    r5                ;proxima linha dos bitmaps
  mov    a,r5              ;pega o numero da linha
  cjne   a,#9,line_loop    ;se não foi a ultima, vai para a proxima linha do bitmap
  lcall  newline           ;pula uma linha
  lcall  newline           ;pula uma linha
; mov    dptr,#mesg2       ;pega a mensagem de fim de execuçao
; lcall  pstr              ;imprime a #mesg2
  acall  pstri DB "Aperte qualquer tecla",0       ;mensagem de fim de execução
  lcall  cin               ;aguarda o input do usuario
  lcall  newline           ;pula uma linha
  ret                     

;mesg1:  DB "Por favor digite uma palavra (max 9 caracteres): ",0  ;boas vindas
;mesg2:  DB "Aperte qualquer tecla",0       ;mensagem de fim de execução

chars:  DB " ABCDEFGHIJKLMNOPQRSTUVWXYZ?",0 ;dicionario

table:      ;tabela com os bitmaps
    
    DB 00000000b
    DB 00000000b 
    DB 00000000b
    DB 00000000b
    DB 00000000b
    DB 00000000b
    DB 00000000b
    DB 00000000b
    DB 00000000b
    
    DB 00010000b
    DB 00111000b
    DB 00111000b
    DB 01101100b
    DB 01101100b
    DB 01111100b
    DB 11111110b
    DB 11000110b
    DB 11000110b

    DB 11111100b
    DB 11111110b
    DB 11000110b
    DB 11000110b
    DB 11111100b
    DB 11000110b
    DB 11000110b
    DB 11111110b
    DB 11111100b

    DB 01111100b
    DB 11111110b
    DB 11000110b
    DB 11000000b
    DB 11000000b
    DB 11000000b
    DB 11000110b
    DB 11111110b
    DB 11111100b

    DB 11111100b
    DB 11111110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11111110b
    DB 11111100b

    DB 11111110b
    DB 11111110b
    DB 11000000b
    DB 11000000b
    DB 11111100b
    DB 11000000b
    DB 11000000b
    DB 11111110b
    DB 11111110b

    DB 11111110b
    DB 11111110b
    DB 11000000b
    DB 11000000b
    DB 11111100b
    DB 11111100b
    DB 11000000b
    DB 11000000b
    DB 11000000b

    DB 01111100b
    DB 11111110b
    DB 11000110b
    DB 11000000b
    DB 11001110b
    DB 11001110b
    DB 11000110b
    DB 11111110b
    DB 01111110b

    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11111110b
    DB 11111110b
    DB 11000110b
    DB 11000110b
    DB 11000110b

    DB 11111110b
    DB 11111110b
    DB 00011000b
    DB 00011000b
    DB 00011000b
    DB 00011000b
    DB 00011000b
    DB 11111110b
    DB 11111110b

    DB 11111110b
    DB 11111110b
    DB 00001100b
    DB 00001100b
    DB 00001100b
    DB 00001100b
    DB 11001100b
    DB 11111100b
    DB 01111100b

    DB 11000110b
    DB 11000110b
    DB 11001100b
    DB 11001100b
    DB 11111000b
    DB 11001100b
    DB 11001100b
    DB 11000110b
    DB 11000110b

    DB 11000000b
    DB 11000000b
    DB 11000000b
    DB 11000000b
    DB 11000000b
    DB 11000000b
    DB 11000000b
    DB 11111110b
    DB 11111110b

    DB 11000110b
    DB 11101110b
    DB 11111110b
    DB 11010110b
    DB 11010110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b

    DB 11000110b
    DB 11100110b
    DB 11100110b
    DB 11110110b
    DB 11010110b
    DB 11011110b
    DB 11001110b
    DB 11000110b
    DB 11000110b

    DB 01111100b
    DB 11111110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11111110b
    DB 01111100b

    DB 11111100b
    DB 11111110b
    DB 11000110b
    DB 11000110b
    DB 11111110b
    DB 11111100b
    DB 11000000b
    DB 11000000b
    DB 11000000b

    DB 01111100b
    DB 11111110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11111100b
    DB 01111010b

    DB 11111100b
    DB 11111110b
    DB 11000110b
    DB 11000110b
    DB 11111110b
    DB 11111100b
    DB 11001100b
    DB 11000110b
    DB 11000110b

    DB 01111110b
    DB 11111110b
    DB 11000000b
    DB 11000000b
    DB 01111100b
    DB 00000110b
    DB 00000110b
    DB 11111110b
    DB 01111110b

    DB 11111110b
    DB 11111110b
    DB 00011000b
    DB 00011000b
    DB 00011000b
    DB 00011000b
    DB 00011000b
    DB 00011000b
    DB 00011000b

    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 01111100b

    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 00111100b
    DB 00111000b
    DB 00010000b

    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 11010110b
    DB 11010110b
    DB 11111110b
    DB 11101110b
    DB 11000110b

    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 01101100b
    DB 00111000b
    DB 01101100b
    DB 11000110b
    DB 11000110b
    DB 11000110b

    DB 11000110b
    DB 11000110b
    DB 11000110b
    DB 01101100b
    DB 01101100b
    DB 00111000b
    DB 00010000b
    DB 00010000b
    DB 00010000b

    DB 11111110b
    DB 11111110b
    DB 00001100b
    DB 00001100b
    DB 00111000b
    DB 01100000b
    DB 01100000b
    DB 11111110b
    DB 11111110b

    DB 01111100b
    DB 11111110b
    DB 11000110b
    DB 00000110b
    DB 00001100b
    DB 00011000b
    DB 00000000b
    DB 00011000b
    DB 00011000b
 END
