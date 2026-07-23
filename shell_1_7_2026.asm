bits 32
org 0x20000

VIDEO equ 0xB8000
COR equ 0x0F

inicio:
    mov ecx, 80 * 25
    mov edi, VIDEO
    mov ax, (COR << 8) | ' '
    rep stosw

    mov esi, msg
    mov edi, VIDEO
.escreve_msg:
    lodsb
    test al, al
    jz .fim_msg
    mov [edi], al
    mov byte [edi+1], COR
    add edi, 2
    jmp .escreve_msg
.fim_msg:

    ; cursor comeca na 3a linha, coluna 0
    mov dword [cursor_pos], VIDEO + (80 * 2 * 2)
    mov dword [buffer_pos], 0
    call print_prompt

loop_principal:
loop_principal:
    call ler_scancode
    test al, al
    jz loop_principal

    call scancode_para_ascii
    test al, al
    jz loop_principal

    call escreve_char
    jmp loop_principal

ler_scancode:
.espera:
    in al, 0x64
    test al, 1
    jz .espera
    in al, 0x60
    ret

scancode_para_ascii:
    test al, 0x80
    jnz .nao_mapeado
    cmp al, 0x39
    ja .nao_mapeado
    movzx ebx, al
    mov al, [tabela_scancode + ebx]
    ret
.nao_mapeado:
    xor al, al
    ret

escreve_char:
    cmp al, 13
    je .enter
    cmp al, 8
    je .backspace

   mov edi, [cursor_pos]
    mov [edi], al
    mov byte [edi+1], COR
    add edi, 2
    mov [cursor_pos], edi

    cmp dword [buffer_pos], 63
    jae .fim_escreve
    mov edi, buffer
    add edi, [buffer_pos]
    mov [edi], al
    inc dword [buffer_pos]
.fim_escreve:
    ret
.enter:
    .enter:
    mov edi, buffer
    add edi, [buffer_pos]
    mov byte [edi], 0
    call processa_comando
    mov dword [buffer_pos], 0

    
    mov eax, [cursor_pos]
    sub eax, VIDEO
    xor edx, edx
    mov ebx, 160
    div ebx
    inc eax
    mov ebx, 160
    mul ebx
    add eax, VIDEO
    mov [cursor_pos], eax
    call print_prompt
    ret

.backspace:
    mov edi, [cursor_pos]
    cmp edi, VIDEO
    je .fim_backspace
    sub edi, 2
    mov byte [edi], ' '
    mov byte [edi+1], COR
    mov [cursor_pos], edi

    cmp dword [buffer_pos], 0
    je .fim_backspace
    dec dword [buffer_pos]
.fim_backspace:
    ret

cursor_pos: dd 0
buffer_pos: dd 0
buffer: times 64 db 0

processa_comando:
    mov esi, cmd_reiniciar
    mov edi, buffer
    call comparar_string
    test eax, eax
    jz .fim_processa
    call reiniciar_pc
.fim_processa:
    ret

comparar_string:
.loop_cmp:
    mov al, [esi]
    mov bl, [edi]
    cmp al, bl
    jne .diferente
    test al, al
    jz .igual
    inc esi
    inc edi
    jmp .loop_cmp
.igual:
    mov eax, 1
    ret
.diferente:
    xor eax, eax
    ret

reiniciar_pc:
.espera_teclado:
    in al, 0x64
    test al, 2
    jnz .espera_teclado
    mov al, 0xFE
    out 0x64, al
.trava_reboot:
    hlt
    jmp .trava_reboot

cmd_reiniciar db 'reiniciar', 0

print_prompt:
    mov esi, prompt
    mov edi, [cursor_pos]
.escreve_prompt:
    lodsb
    test al, al
    jz .fim_prompt
    mov [edi], al
    mov byte [edi+1], COR
    add edi, 2
    jmp .escreve_prompt
.fim_prompt:
    mov [cursor_pos], edi
    ret

prompt db 'klaus> ', 0

msg db 'Klaus 1 Versao 26k1 Build 1.7.2026', 0

tabela_scancode:
db 0, 0
db '1','2','3','4','5','6','7','8','9','0'
db '-','='
db 8
db 9
db 'q','w','e','r','t','y','u','i','o','p'
db '[',']'
db 13
db 0
db 'a','s','d','f','g','h','j','k','l'
db ';',39
db '`'
db 0
db '\'
db 'z','x','c','v','b','n','m'
db ',','.','/'
db 0
db '*'
db 0
db ' '

times 4096-($-$$) db 0
