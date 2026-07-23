;===================================================
; Klaus Bootloader
; Sistema: Klaus 1
; Versão: 26k1
; Build: 1.7.2026
;===================================================

org 0x7C00
bits 16

start:
    cli
    mov [boot_drive], dl    ; a BIOS deixa o numero do drive de boot em DL
    mov si, mensagem

proximo:
    lodsb
    cmp al, 0
    je fim

    mov ah, 0x0E
    int 0x10
    jmp proximo

fim:
    ; Le o kernel do disco (setor 2 em diante) para 0x1000:0000 = endereco 0x10000
    mov ax, 0x1000
    mov es, ax
    xor bx, bx           ; ES:BX = 0x1000:0x0000

    mov ah, 0x02         ; funcao: ler setores
    mov al, 4            ; quantidade de setores a ler (2KB, sobra espaco)
    mov ch, 0
    mov cl, 2            ; comeca no setor 2 (logo apos o boot sector)
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    ; Le o shell do disco (setor 6 em diante) para 0x2000:0000 = endereco 0x20000
    mov ax, 0x2000
    mov es, ax
    xor bx, bx

  mov ah, 0x02
    mov al, 8
    mov ch, 0
    mov cl, 6          ; comeca logo apos os 4 setores do kernel (2,3,4,5)     
    mov dh, 0
    mov dl, [boot_drive]
    int 0x13
    jc disk_error

    call enable_a20
    cli
    lgdt [gdt_descriptor]
    mov eax, cr0
    or eax, 1
    mov cr0, eax
    jmp CODE_SEG:protected_mode_start



mensagem db 'Klaus 1 Versao 26k1 Build 1.7.2026', 0

boot_drive db 0

disk_error:
    cli
.hang_disk:
    hlt
    jmp .hang_disk

enable_a20:
    in al, 0x92
    or al, 2
    out 0x92, al
    ret

; --- GDT: 3 descritores (nulo, codigo, dados) ---
gdt_start:

gdt_null:
    dq 0

gdt_code:
    dw 0xFFFF
    dw 0
    db 0
    db 10011010b
    db 11001111b
    db 0

gdt_data:
    dw 0xFFFF
    dw 0
    db 0
    db 10010010b
    db 11001111b
    db 0

gdt_end:

gdt_descriptor:
    dw gdt_end - gdt_start - 1
    dd gdt_start

CODE_SEG equ gdt_code - gdt_start
DATA_SEG equ gdt_data - gdt_start

bits 32
protected_mode_start:
    mov ax, DATA_SEG
    mov ds, ax
    mov es, ax
    mov fs, ax
    mov gs, ax
    mov ss, ax
    mov esp, 0x90000

    jmp 0x10000

    mov esi, msg_protected
    mov edi, 0xB8000
    mov ah, 0x0F

.print_loop:
    lodsb
    cmp al, 0
    je .hang
    mov [edi], ax
    add edi, 2
    jmp .print_loop

.hang:
    cli
    hlt
    jmp $

msg_protected db 'Klaus 1: modo protegido ativo!', 0

times 510-($-$$) db 0
dw 0xAA55