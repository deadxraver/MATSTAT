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
%define   PROT_READ       1
%define   MAP_PRIVATE     2
%define   MMAP_CALL       9
%define   MAX_FILESIZE    130000

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
  buffer        times BUFFER_SIZE db 0
  sim_colon     db  0
  target_column_sim:
    .name   db  'dual_sim', 0
    .index  db  0
    .result dq  0
  target_column_3g:
    .name   db  'three_g', 0
    .index  db  0
    .result dq  0
  target_column_cpu:
    .name   db  'n_cores', 0
    .index  db  0
    .result dq  0

section .rodata
  sglypa            db  'Сглыпа друг артема королева', NEWLINE, NULL
  err_args          db  'wrong number of args!', NEWLINE, NULL
  help_msg          db  'usage: ./main filename.csv', NEWLINE, NULL
  help_arg          db  '--help', NULL
  err_file          db  'file not exists', NEWLINE, NULL


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

  cmp_strings: ; rdi - 1st pointer, rsi - second
    xor     rax, rax
    xor     r10, r10
    .loop:
      mov     r10b, byte [rdi + rax]
      cmp     r10b, byte [rsi + rax]
      jne     .end_not_equal        ; any byte not equal -> not equal
      cmp     r10b, NULL            ; NULL-term -> equal
      je      .end_equal
    .end_not_equal:
      cmp     r10b, SEMICOLON
      je      .end_equal
      xor     rax, rax
      ret
    .end_equal:
      mov     rax, 1
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
    mov     rdi, sglypa
    mov     rsi, STDOUT
    call    print_text
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
      mov     rdi, -1
      call    exit
    .success_open:
      mov     r8, rax
      mov     rax, MMAP_CALL        ; syscall code
      mov     rdi, 0                ; operating system will choose mapping destination
      mov     rsi, MAX_FILESIZE     ; page size
      mov     rdx, PROT_READ        ; new memory region will be marked read only
      mov     r10, MAP_PRIVATE      ; pages will not be shared
      mov     r9, 0                 ; offset inside input file
      syscall                       ; rax - pointer to mapped file
      mov     rdi, rax
      xor     rax, rax
      xor     r9, r9                ; index
    .skip_first_string:
      inc     r9
      cmp     byte [rax + rdi], NEWLINE   ; move until newline 
      je      .end_skip
      push    rax
      test    rax, rax                    ; if rax == 0 compare *rax with str
      jz      .cmp_sim
      cmp     byte [rax + rdi], SEMICOLON ; or *rax = ';', compare *(rax + 1) with str
      je      .cmp_strs
      .cmp_strs:
        lea     rax, [rax + 8]
      .cmp_sim:
        mov     rsi, target_column_sim.name
        lea     rdi, [rdi + rax]
        call    cmp_strings
        test    rax, rax
        jz      .cmp_3g
        mov     byte [target_column_sim.index], r9b
      .cmp_3g:
        mov     rsi, target_column_3g.name
        call    cmp_strings
        test    rax, rax
        jz      .cmp_cpu
        mov     byte [target_column_3g.index], r9b
      .cmp_cpu:
        mov     rsi, target_column_cpu.name
        call    cmp_strings
        test    rax, rax
        mov     byte [target_column_cpu.index], r9b
      .end_cmp:
        pop     rax
        jmp     .skip_first_string
    .end_skip:
      lea     rax, [rax + 8]
    ; TODO: 
    .end:
      call    exit

