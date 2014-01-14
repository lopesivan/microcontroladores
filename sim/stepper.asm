; STEPPER.ASM  : ACIONAMENTO DE UM MOTOR DE PASSO
;                Código modificado do LEDs.asm
#include <SFR51.inc>   ;include em minúsculas!! contem as definições de todos os SFRs
ORG  2000h       ;localização deste programa
;B2C55 localizações de memória p0-> PA,PB,PC expansão de portas
port_b       EQU 0x4001  ;82c55B  : porta B
port_c       EQU 0x4002  ;82c55C  : porta C
port_abc_pgm EQU 0x4003  ;82c55pgm  : registro de programação
esc          EQU 0x003E  ;Checagem da tecla ESC do paulmon2
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
;NOSSAS SUBROTINAS -----------------------------------------------------------------------------
cinn:                      ;olha para a serial, se houver caracter trata, senão retorna
  jnb   ri,saicinn         ;se não há caracter na serial sai
  clr   ri                 ;libera a serial para receber um novo caracter
  mov   a,sbuf             ;pega o caracter da serial
saicinn:
  ret
;-----------------------------------------------------------------------------------------------
begin:
  mov   r3, #100                ;velocidade default: delay de 100
;prepara a porta de programação do 8255
  mov   dptr,#port_abc_pgm   ;registro de programação do 8255
  mov   a,#128               ;PA=out,PB=out,PC=out (128)    =128
  movx  @dptr,a              ;programa 8255   :   movx - memória externa
inicio:
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
  mov    dptr,#port_c     ;dptr -> leds
  movx   @dptr,a          ;liga os leds 
  pop    dpl              ;recupera os "bits baixos" do dptr
  pop    dph              ;recupera os "bits altos" do dptr
  mov    r4,#9          ;o loop externo sera executado 100 vezes
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
  cjne   a,#27,inicio     ;se não é o esc volta a percorrer a tabela
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
