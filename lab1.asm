%define   EXIT_CODE       60
%define   NEWLINE         10
%define   NULL            0
%define   SEMICOLON       59
%define   BUFFER_SIZE     256
%define   STDOUT          1
%define   STDERR          2
%define   WRITE_CALL      1
%define   FILE_OPEN_CALL  2
%define   O_RDONLY        0
%define   PROT_READ       0x1
%define   MAP_PRIVATE     0x2

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
  buffer    times BUFFER_SIZE db 0
  sim_colon db 0

section .rodata
  err_args  db  'wrong number of args!', NEWLINE, NULL
  help_msg  db  'usage: ./main filename.csv', NEWLINE, NULL
  help_arg  db  '--help', NULL
  err_file  db  'file not exists', NEWLINE, NULL

section .text

  exit: ; err_code in rdi
    mov     rax, EXIT_CODE  ; exit syscall
    syscall

  wrong_args:
    mov     rdi, err_args   ; pass string pointer
    mov     rsi, STDERR
    call    print_text
  print_help_and_stop:
    mov     rdi, help_msg
    mov     rsi, STDOUT
    call    print_text
    call    exit

  print_newline:
    sub     rsp, 8
    mov     byte [rsp], NEWLINE
	  mov     rax, WRITE_CALL
	  mov     rsi, rsp
	  mov     rdi, STDOUT
	  mov     rdx, 1  ; length of 1 char = 1
	  syscall
    add     rsp, 8
	  ret


  print_text: ; rdi - str pointer, rsi - stderr/stdout
    xor     rax, rax                  ; str_len = 0
    .loop:
      cmp     byte [rax + rdi], NULL  ; check for null-term
      je      .end                    ; null -> line ended
      inc     rax                     ; str_len++
      jmp     .loop
    .end:
    mov     rdx, rax                ; save str_len for syscall
    mov     rax, WRITE_CALL
    push    rdi
    mov     rdi, rsi                ; stderr/stdout
    pop     rsi
    syscall                         ; rsi - pointer, rax - syscall code, rdi - stderr/stdout, rdx - length
    ret

  parse_arg: ; rdi - pointer to arg str
    xor     rcx, rcx
    xor     rax, rax
    .loop:
      mov   al, byte [rdi + rcx]
      cmp   al, byte [help_arg + rcx]
      jne   .not_help
      cmp   al, NULL                  ; null term -> stop
      je    .is_help
      inc   rcx
      jmp   .loop
    .not_help:
      ret
    .is_help:
      call print_help_and_stop

  _start:
    pop     rax             ; argc
    dec     rax             ; argc--
    jz      wrong_args      ; no args -> err mesg and exit
    dec     rax             ; argc--
    jnz     wrong_args      ; not exactly one arg -> err mesg and exit
    pop     rdi             ; ./<programm name>
    pop     rdi             ; filename.csv
    call    parse_arg
    .open_file: ; rdi - pointer to filename, rsi - flags
      xor     rdx, rdx
      xor     rsi, rsi
      mov     rax, FILE_OPEN_CALL
      syscall
      cmp     rax, 0
      js      .error_open          ; error while opening file (not exists probably)
      jmp     .success_open
    .error_open:
      mov     rdi, err_file
      call    print_text
    .success_open:
      mov     r8, rax
      mov     rax, 9                ; mmap number
      mov     rdi, 0                ; operating system will choose mapping destination
      mov     rsi, 4096             ; page size
      mov     rdx, PROT_READ        ; new memory region will be marked read only
      mov     r10, MAP_PRIVATE      ; pages will not be shared
      mov     r9, 0                 ; offset inside test.txt
      syscall                       ; now rax will point to mapped location
      mov     rdi, rax      ; TODO: remove
      mov     rsi, STDOUT   ; remove
      call    print_text    ; remove
    .end:
      call    exit

