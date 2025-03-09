%define   EXIT_CODE 60
%define   NEWLINE   10
%define   NULL      0

global _start
; TODO:
; - сколько моделей с 2 сим-картами
; - сколько поддерживают 3G
; - наибольшее число ядер процессора
; - выборочное среднее
; - выборочная дисперсия
; - выборочная медиана
; - выборочная квантиль порядка 2/5
section .data
  buffer    db    256

section .rodata
  err_args  db  'wrong number of args!', NEWLINE, NULL
  help_msg  db  'usage: ./main filename.csv', NEWLINE, NULL
  help_arg  db  '--help', NULL

section .text

  exit: ; err_code in rdi
    mov     rax, exit_code  ; exit syscall
    syscall

  wrong_args:
    ; TODO: print err_args
    mov     rdi, -1
  print_help_and_stop:
    ; TODO: print help_msg
    call    exit

  print_text:
    ; TODO: print until null-terminator
    ret

  parse_args:
    pop     ebx             ; argc
    dec     ebx             ; argc - 1
    beqz    ebx, wrong_args ; if no args -> print err msg
    dec     ebx             ; argc - 1
    bnz     ebx, wrong_args ; if not exactly one arg -> err msg
    pop     ebx             ; ./<program-name>

  _start:
    xor   rdi, rdi
    call  exit

