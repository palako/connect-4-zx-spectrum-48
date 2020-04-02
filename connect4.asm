org 50000
    last_k equ 23560 ; alias to keyboard input
    colour_map equ 22528 ; mem pos for the colour of character at (1,1)
    print equ 8252
    ld a, 127
    ld (23693), a ;set the screen color
    call 3503 ;clear the screen
    ld a, 1
    out (254), a ;set the screen border color

    ;change memory location for user defined graphics (udgs)
    ld hl, udgs
    ld (23675), hl
    
    ; open channel to upper screen
    ld a, 2
    call 5633

    ;set up and print the title
    ld de, title
    ld bc, eotitle-title
    call print

    ;prints an invisible row on top of the board so that only the colour
    ;changes as the players move without having to update the graphics
    ld de, transparent
    ld bc, eotransparent-transparent
    call print
    
    ld de, board+7;skip the board colors
    ld bc, 7;just one row
    call print
    
    ;draw the player position
    ld hl, colour_map + (32*9);22816 ; mem pos for the color of (9,1)
    ld bc, (player_pos)
    add hl, bc ; move the player to the center column
    ld a, (player_color)
    ld (hl), a

    ;print the board
    ld de, board
    ld bc, eoboard-board
    call print

    
    LOOP_READ_INPUT
        ;draw the player position
        ld hl, colour_map + (32*9);32*9 is the first screen column of the 9th row
        ld bc, (player_pos)
        add hl, bc ; move the player to its column
        ld a, (player_color)
        ld (hl), a
        ld hl, last_k
        ld a, (hl)
        cp 112 ; ascii for lower case 'p'
        jr z, MOVE_RIGHT
        cp 111 ; ascii for lower case 'o'
        jr z, MOVE_LEFT
        cp 32 ; ascii for space
        jr z, DROP_CHIP
    jr LOOP_READ_INPUT
ret

MOVE_RIGHT
    ;check right boundary
    ld a, (player_pos)
    cp 18
    jr z, LOOP_READ_INPUT
    ; paint current position invisible
    ld hl, colour_map + (32*9)
    ld bc, (player_pos)
    add hl, bc
    ld (hl), 7Fh ;white/white
    ; move position to the right by one
    ld a, (player_pos)
    inc a
    ld (player_pos), a
    jp CLR_KEY
ret

MOVE_LEFT
    ;check left boundary
    ld a, (player_pos)
    cp 12
    jr z, LOOP_READ_INPUT
    ; paint current position invisible
    ld hl, colour_map + (32*9)
    ld bc, (player_pos)
    add hl, bc
    ld (hl), 7Fh ;white/white
    ; move position to the left by one
    ld a, (player_pos)
    dec a
    ld (player_pos), a
    jp CLR_KEY
ret

DROP_CHIP
    ;calculate how many spaces will the chip drop
    ld hl, column_depth
    ld a, (player_pos)
    sub 12;offset of the board on the screen
    ld c, a
    ld b, 0
    add hl, bc
    ld a, 0
    cp (hl)
    jr z, CLR_KEY ; exit if there's no spaces left in this column
    dec (hl)
    push hl; save this calculation to free the hl reg 
    ; paint current position invisible
    ld hl, colour_map + (32*9)
    ld bc, (player_pos)
    add hl, bc
    ld (hl), 7Fh ;white/white
    ld bc, 32 ;there's 32 characters in a row
    add hl, bc
    ;paint the first row with the player chip
    ld a, (player_color+1) ;red or yellow over blue
    ld (hl), a
    pop bc ;restore the pointer to the remaining free spaces for this column
    ld a, (bc)
    cp 0
    jr z, SWAP_COLOR ; exit if there was only one space left
    DROP_ANIMATION
        ; add a small pause (5 halt instructions) to time the animation
        ld b, 5
        STALL 
            halt
            djnz STALL
        
        ; paint the current position white/blue, the next row red/blue, and decrement
        ld (hl), 4Fh ;white/blue
        ld bc, 32
        add hl, bc
        ld d, a ;temporary assignment to keep a
        ld a, (player_color+1) ;red or yellow over blue
        ld (hl), a
        ld a, d;restore a
        dec a
        jr nz, DROP_ANIMATION
    SWAP_COLOR
    ;neat trick to swap colours. red(010) and green(100) only differ on two bits, so xoring with 6 reverses just those
    ld a, (player_color)
    xor 6
    ld (player_color), a
    ld a, (player_color+1)
    xor 6
    ld (player_color+1), a
    jp CLR_KEY
ret

CLR_KEY
    ld hl, last_k
    ld (hl), 0
    jp LOOP_READ_INPUT
ret

title defb 16, 1, 17, 7, 22, 3, 11, "CONNECT 4"; 16 1 blue text; 17 6 yellow ink; 22 3 11 position to print(3,11)
eotitle equ $

board defb 16, 7, 17, 1 ; white ink, blue paper
      defb 22, 10, 12, 144, 144, 144, 144, 144, 144, 144
      defb 22, 11, 12, 144, 144, 144, 144, 144, 144, 144
      defb 22, 12, 12, 144, 144, 144, 144, 144, 144, 144
      defb 22, 13, 12, 144, 144, 144, 144, 144, 144, 144
      defb 22, 14, 12, 144, 144, 144, 144, 144, 144, 144
      defb 22, 15, 12, 144, 144, 144, 144, 144, 144, 144
eoboard equ $

transparent defb 22, 9, 12 ; position (9, 12)
          defb 16, 7, 17, 7 ; white ink, white paper
eotransparent equ $

; 0 0 0 0 0 0 0 0 -> 0h
; 0 0 0 1 1 0 0 0 -> 18h
; 0 0 1 1 1 1 0 0 -> 3Ch
; 0 1 1 1 1 1 1 0 -> 7Eh
; 0 1 1 1 1 1 1 0 -> 7Eh
; 0 0 1 1 1 1 0 0 -> 3Ch
; 0 0 0 1 1 0 0 0 -> 18h
; 0 0 0 0 0 0 0 0 -> 0h
udgs defb 0h, 18h, 3Ch, 7Eh, 7Eh, 3Ch, 18h, 0h

player_pos defb 15, 0; initial position
player_color defb 7Ah, 4Ah ; red/white, red/blue
column_depth defb 6,6,6,6,6,6,6 ; how many spaces are left in each column
end 50000