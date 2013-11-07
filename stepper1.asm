; STEPPER1.ASM  : ACIONAMENTO DE UM MOTOR DE PASSO
;                Input do usuário para direção e intensidade
;                Código modificado do stepper.asm
#include <SFR51.inc>   ; definições de todos os SFRs
ORG  2000h             ;localização deste programa
;B2C55 localizações de memória p0-> PA,PB,PC expansão de portas
port_b       EQU 0x4001  ;82c55B  : porta B
port_c       EQU 0x4002  ;82c55C  : porta C
port_abc_pgm EQU 0x4003  ;82c55pgm  : registro de programação
esc          EQU 0x003E  ;Checagem da tecla ESC do paulmon2
cout     EQU 0x0030          ;Imprime o acumulador na porta serial
pint8u   EQU 0x004D          ;Imprime Acc em um inteiro de 0 ate 255
; cabeçalho: todo programa deve ter um, para o PAULMON2 poder gerenciar
DB  0xA5, 0xE5, 0xE0, 0xA5 ;bytes de assinatura
DB  35,255,0,0             ;id (35=prog)
DB  0,0,0,0                ;prompt code vector
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;reservado
DB  0,0,0,0                ;definido pelo usuário
DB  255,255,255,255        ;tamanho e checksum (255=não usado)
DB  "STEPPER", 0           ;máximo de 31 caracteres mais o zero
ORG 2040h                  ;executável do código começa aqui
sjmp begin
;NOSSAS VARIAVEIS 
dphc EQU 7Fh               ;guarda copia do dptr para a pstri
dplc EQU 7Eh               ;
pot  EQU 7Dh               ;guarda a entrada do usuario
;NOSSAS SUBROTINAS -----------------------------------------------------------------------------
cinn:                      ;olha para a serial, se houver caracter trata, senão retorna
  jnb   ri,saicinn         ;se não há caracter na serial sai
  clr   ri                 ;libera a serial para receber um novo caracter
  mov   a,sbuf             ;pega o caracter da serial
saicinn:
  ret
; ----------
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
;-----------------------------------------------------------------------------------------------
begin:
;prepara a porta de programação do 8255
  mov   dptr,#port_abc_pgm   ;registro de programação do 8255
  mov   a,#128               ;PA=out,PB=out,PC=out (128)    =128
  movx  @dptr,a              ;programa 8255   :   movx - memória externa
  acall pstri DB "Programa Stepper1 aciona um motor de passo com direcao e velocidade selecionadas",13,10,10,0
  acall pstri DB "Digite o valor da velocidade (0-99): ",0 
;------------------ SUBROTINA PARA ENTRADA DE DOIS DIGITOS SEM EDIÇÃO ------------------------------------------
inicio0:
  mov   pot,#0               ;inicializa o buffer da potencia
inicio:
  mov   a,pot                ;pega o valor da potencia
  cjne  a,#0,digito2         ;vai para o digito 2 se existir o primeiro digito
digito1:  
  clr   a                    ;zera o acumulador
  acall cinn                 ;captura a resposta do usuario, se houver
  jz    aciona               ;se o usuario nao digitou nada vai para o acionamento do motor
  cjne  a,#'0',teste1        ;liga o carry se a<'0'
teste1:
  jc    testaESC             ;vai testar a tecla ESC
  cjne  a,#'9'+1,teste2      ;liga o carry se a<='9'
teste2:  
  jnc   aciona               ;salta se a entrada do usuario é invalida
  lcall cout                 ;valida o primeiro digito do usuario
  anl   a,#00001111b         ;converte para valor
  mov   pot,a                ;guarda o digito da velocidade
  sjmp  digito2              ;vai tratar o segundo digito
testaESC:
  cjne  a,#27,aciona        ;se for inválido vai para o acionamento
  mov   a,#00000000b        ;configuração que desliga as bobinas
  mov   dptr,#port_b        ;aponta para as bobinas
  movx  @dptr,a             ;desliga as bobinas
  cpl   a                   ;inverte a configuração 
  mov   dptr,#port_c        ;dptr -> porta c
  movx  @dptr,a             ;desliga as bobinas
  ret                       ;retorna ao PAULMON2
digito2:
  clr   a                    ;zera o acumulador
  acall cinn                 ;aguarda o segundo digito
  jz    aciona               ;salta se o usuario nao digitou o segundo algarismo
  cjne  a,#'0',teste3        ;liga o carry se o a<'0'
teste3:
  jc    testaENTER           ;vai testar a tecla ENTER
  cjne  a,#'9'+1,teste4      ;liga o carry se a<='9'
teste4:  
  jnc   aciona               ;salta se a entrada do usuario é invalida
  sjmp  valido
testaENTER:
  cjne  a,#13,testaESC2     ;se não for ENTER, vai testar ESC
  sjmp  direcao             ;vai pedir a direção
testaESC2:
  cjne  a,#27,valido        ;vai para a multiplicação
  mov    a,#00000000b       ;configuração que desliga as bobinas
  mov    dptr,#port_b       ;aponta para as bobinas
  movx   @dptr,a            ;desliga as bobinas
  cpl    a                  ;inverte a configuração 
  mov    dptr,#port_c       ;dptr -> porta c
  movx   @dptr,a            ;desliga as bobinas
  ret                       ;retorna ao PAULMON2
valido:               ;segundo dígito válido
  lcall cout                 ;valida o segundo digito do usuario
  anl   a,#00001111b         ;converte para valor
  push  acc                  ;salva o segundo algarismo
  mov   a,pot                ;traz a velocidade atual
  mov   b,#10                ;prepara o multiplicador
  mul   ab                   ;multiplica o primeiro algarismo por 10
  pop   b                    ;recupera o segundo algarismo
  add   a,b                  ;compoe a velocidade com 2 algarismos
  mov   pot,a                ;guarda a nova velocidade em pot
;------------------- FIM DA SUBROTINA DE ENTRADA DE DOIS DIGITOS ----------------------------------------------
direcao:
  mov   a,pot
  lcall pint8u         ;imprime velocidade 
  acall pstri DB 10,13,0
  sjmp  inicio0
  ret
  
  
  
aciona:
   
  sjmp  inicio
  




inicio1:
  mov   dptr,#table           ;dptr -> início da tabela 
ntable: 
  mov   b,#4            ;conta linhas tabela
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
  mov    r4,#9            ;o loop externo sera executado 100 vezes
  mov    a,r3             ;move o delay pro acumulador
delay2:
  mov    r5,a             ;o loop interno ser executado #r3 vezes
delay3:
  nop                     ;ciclo de máquina sem uso
  nop
  djnz   r5,delay3        ;conta o loop interno
  djnz   r4,delay2        ;conta o loop externo
  inc    dptr             ;proxima linha da tabela
  djnz   b,loop           ;percorre proxima linha da tabela
  acall  cinn             ;traz um caracter da serial se houver
  cjne   a,#27,inicio1     ;se não é o esc volta a percorrer a tabela
  mov    a,#00000000b     ;configuração que desliga as bobinas
  mov    dptr,#port_b     ;aponta para as bobinas
  movx   @dptr,a          ;desliga as bobinas
  cpl    a                ;inverte a configuração 
  mov    dptr,#port_c     ;dptr -> porta c
  movx   @dptr,a          ;apaga os leds
  ret                     ;retorna ao PAULMON2

table:                    ;tabela do sentiro horário
    DB 00001000b
    DB 00000100b
    DB 00000010b
    DB 00000001b

;table2:                      ;tabela do sentido anti-horário
;    DB 00000001b
;    DB 00000010b
;    DB 00000100b
;    DB 00001000b
    
END                          ;Fim
