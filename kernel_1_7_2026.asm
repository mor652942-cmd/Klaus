bits 32
org 0x10000

VIDEO equ 0xB8000
COR equ 0x0F

inicio:
    ; Limpa tela de uma vez só
    mov ecx, 80 * 25
    mov edi, VIDEO
    mov ax, (COR << 8) | ' '
    rep stosw

    ; Escreve mensagem UMA VEZ SÓ
    mov esi, msg
    mov edi, VIDEO
.escreve:
    lodsb
    test al, al
    jz .fim
    mov [edi], al
    mov byte [edi+1], COR
    add edi, 2
    jmp .escreve

.fim:
    jmp 0x20000          ; entrega o controle para o shell

msg db '>>> KERNEL KLAUS 1 ATIVO <<<', 0

times 2048-($-$$) db 0
