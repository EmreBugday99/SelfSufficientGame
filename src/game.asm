ORG 0
[BITS 16]

start:
    jmp short bootloader_start
    nop
times 33 db 0 ; to prevent data corruption due to BIOS parameter block
code_segment_fix:
    jmp 0x7c0:bootloader_start
bootloader_start:
    cli ; Clearing interrupts
    mov ax, 0x7c0
    mov ds, ax
    mov es, ax

    mov ax, 0x00
    mov ss, ax
    mov sp, 0x7c00
    sti ; Re-enabling interrupts

    mov ah, 0 ; clearing screen
    int 10h

    jmp prepare_game_area
prepare_game_area:
    mov sp, 0x7c00
    
    mov dl, 0
    mov dh, 11
    call set_cursor

    mov si, starting_message
    call print_text
    call print_new_line

    mov si, credits_message
    call print_text
    call print_new_line

    ; waiting the game loop
    mov ah, 86h
    mov cx, 50
    mov dx, 0
    int 15h

    mov ah, 0 ; clearing screen
    int 10h

    mov sp, 0x7c00

    mov dl, 0 ; column
    mov dh, 0 ; row
    mov bh, 0 ; display page

    .fill_top:
        inc dl
        cmp dl, 20
            je .finished_filling_top
        call set_cursor

        mov al, 'x'
        call print_char
        jmp .fill_top

    .finished_filling_top:
        mov dl, 0 ; reseting column
        mov dh, 10
        jmp .fill_bottom

    .fill_bottom:
        inc dl
        cmp dl, 20
            je start_game
        call set_cursor

        mov al, 'x'
        call print_char
        jmp .fill_bottom
start_game:
    mov ah, 04h ; clearing keyboard buffer
    int 16h

    mov dl, 5
    mov dh, 5

    push 0 ; player pos increment bool
    push dx ; player pos

    call set_cursor

    mov al, 'o'
    call print_char

    jmp game_loop.game_loop_start
game_loop:
    .increment_player_y:
        inc dh
        jmp .set_player_pos
    .decrement_player_y:
        dec dh
        jmp .set_player_pos
    .change_increment_bool:
        mov ah, 04h ; clearing keyboard buffer
        int 16h
        cmp cl, 0
            je .set_increment_bool_true
        jmp .set_increment_bool_false
    .set_increment_bool_true:
        mov cl, 1
        mov ah, 0 ; clearing screen
        int 10h
        jmp .check_increment_bool
    .set_increment_bool_false:
        mov cl, 0
        mov ah, 0 ; clearing screen
        int 10h
        jmp .check_increment_bool

    .game_loop_start:

    ; waiting the game loop
    mov ah, 86h
    mov cx, 1
    mov dx, 0
    int 15h

    pop dx ; player pos
    pop cx ; player pos increment bool

    call set_cursor ; setting the cursor to player pos
    ; clearing player pos
    mov al, ' '
    call print_char
    call set_cursor

    ; checking for keystroke
    mov ah, 01h
    int 16h
    jz .check_increment_bool ; continue if no keystroke in buffer
    mov ah, 0h
    int 16h
    cmp al, 102 ; f key
        je .change_increment_bool

    .check_increment_bool:
    ; setting player pos to new pos
    cmp cl, 0
        je .increment_player_y
    cmp cl, 1
        je .decrement_player_y

    .set_player_pos:
        call set_cursor
        mov al, 'o'
        call print_char

    push cx ; player pos increment bool
    push dx ; player pos

    ;game over logic
    cmp dh, 10
        je prepare_game_area
    cmp dh, 0
        je prepare_game_area

    jmp .game_loop_start
set_cursor:
    mov ah, 02h
    int 10h
    ret
starting_message: db 'Starting Game...', 0
credits_message: db 'Developed by Emre Bugday', 0
new_line_message: db 0xa, 0
carriage_return_message: db 0xd, 0
print_new_line:
    mov si, new_line_message
    call print_text

    mov si, carriage_return_message
    call print_text

    ret
print_text:
    .loop:
        mov bx, 0 ; same as (bh, 0 & bl, 0) || 10ah=0eh pager set.
        lodsb ; load a byte from 'si' where register is pointing into 'al' register and increment 'si' register.
        cmp al, 0 ; 0 is the null terminator.
            je .done ; jump to done if equal to
        call print_char
        jmp .loop
        .done:
            mov si, 0
            ret
print_char:
    mov ah, 0eh
    int 10h
    ret
end:
    jmp $

times (510 - ($ - $$)) db 0
db 0x55
db 0xaa