org 50000
    last_k equ 23560 ; alias to keyboard input
    colour_map equ 22528 ; mem pos for the colour of character at (1,1)
    
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
    call 8252

    ;prints an invisible row on top of the board so that only the colour
    ;changes as the players move
    ld de, invisible
    ld bc, eoinvisible-invisible
    call 8252
    
    ;draw the player position
    ld hl, colour_map + (32*9);22816 ; mem pos for the color of (9,1)
    ld bc, (player_pos)
    add hl, bc ; move the player to the center column
    ld a, (player_color)
    ld (hl), a

    ;setup the board colors
    ld de, board
    ld bc, eoboard-board
    call 8252

    ; ;draw the 6x7 board
    ld c, 6; rows
    LOOPROWS
        ld b, 7 ; columns
        LOOPCOLS
            call SETXY 
            ld a, 144; position of the first user defined graphic (kind of an ascii code)
            rst 16
            ld hl, YCOORD  
            inc (hl)
        djnz LOOPCOLS
        ;reset to the first column of the board
        ld a, 12
        ld hl, YCOORD
        ld (hl), a
        ;jump to the next row of the board
        ld hl, XCOORD
        inc (hl)
        dec c
    jr nz, LOOPROWS

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
    ; paint current position invisible
    ld hl, colour_map + (32*9)
    ld bc, (player_pos)
    add hl, bc
    ld (hl), 7Fh ;white/white
    ld bc, 32
    add hl, bc

    ;paint the first row with the player chip
    ld a, (player_color+1) ;red or yellow over blue
    ld (hl), a
    
    
    ;calculate how many spaces will the chip drop
    ld (chip_pos), hl ; save the current chip position
    ld hl, column_depth
    ld a, (player_pos)
    sub 12
    ld c, a
    ld b, 0
    add hl, bc
    ld a, (hl)
    dec (hl)
    ld hl, (chip_pos)
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
    jp CLR_KEY
ret

CLR_KEY
    ld hl, last_k
    ld (hl), 0
    jp LOOP_READ_INPUT
ret

SETXY
    ld a, 22
    rst 16
    ld a, (XCOORD)
    rst 16
    ld a, (YCOORD)
    rst 16
ret
title defb 16, 1, 17, 7, 22, 3, 11, "CONNECT 4"; 16 2 red text; 17 6 yellow ink; 22 3 11 position to print(3,11)
eotitle equ $

board defb 16, 7, 17, 1 ; white ink, blue paper
eoboard equ $

invisible defb 22, 9, 12 ; position (9, 12)
          defb 16, 7, 17, 7 ; white ink, white paper
          defb 144, 144, 144, 144, 144, 144, 144
eoinvisible equ $

; 0 0 0 0 0 0 0 0 -> 0h
; 0 0 0 1 1 0 0 0 -> 18h
; 0 0 1 1 1 1 0 0 -> 3Ch
; 0 1 1 1 1 1 1 0 -> 7Eh
; 0 1 1 1 1 1 1 0 -> 7Eh
; 0 0 1 1 1 1 0 0 -> 3Ch
; 0 0 0 1 1 0 0 0 -> 18h
; 0 0 0 0 0 0 0 0 -> 0h
udgs defb 0h, 18h, 3Ch, 7Eh, 7Eh, 3Ch, 18h, 0h

XCOORD defb 10
YCOORD defb 12

player_pos defb 15, 0; initial position
player_color defb 7Ah, 4Ah ; 58: red/white 10: red/blue
column_depth defb 5,3,4,5,5,5,5 ; how many spaces are left in each column
chip_pos defb 0 ; stores the position of the chip for the animation
end 50000