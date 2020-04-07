org 50000
    last_k equ 23560 ; alias to keyboard input
    colour_map equ 22528 ; mem pos for the colour of character at (1,1)
    print equ 8252
    
    ;change memory location for user defined graphics (udgs)
    ld hl, udgs
    ld (23675), hl

    START    
    ld a, 127
    ld (23693), a ;set the screen color
    call 3503 ;clear the screen
    ld a, 1
    out (254), a ;set the screen border color

    ; open channel to upper screen
    ld a, 2
    call 5633

    ;set up and print the title
    ld de, title
    ld bc, title_size
    call print

    ld de, controls
    ld bc, controls_size
    call print

    ;prints an invisible row on top of the board so that only the colour
    ;changes as the players move without having to update the graphics
    ld de, transparent
    ld bc, transparent_size
    call print
    
    ld de, board+7;skip the board colors
    ld bc, 7;just one row
    call print
    
    ;empty columns
    ld hl, column_depth_init
    ld de, column_depth
    ld bc, 7
    ldir

    ;draw the player position
    ld a, 15
    ld (player_pos), a
    ld hl, colour_map + (32*9);22816 ; mem pos for the color of (9,1)
    ld bc, (player_pos)
    add hl, bc ; move the player to the center column
    ld a, (player_color)
    ld (hl), a

    ;print the board
    ld de, board
    ld bc, board_size
    call print

    
    ;clear any previous key press
    call CLR_KEY

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

CLR_KEY
    ld hl, last_k
    ld (hl), 0
    jp LOOP_READ_INPUT
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
    jr z, SWAP_COLOR ; skip the animation space left
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
    call DID_WIN
    ;neat trick to swap colours. red(010) and green(100) only differ on two bits, so xoring with 6 reverses just those
    ld a, (player_color)
    xor 6
    ld (player_color), a
    ld a, (player_color+1)
    xor 6
    ld (player_color+1), a
    jp CLR_KEY
ret


;check up to 4 chips to the left from the current position. Board boundaries don't
;matter since outside the board the color won't be the same as the chips
DID_WIN
    ; hl points to the color atribute of the screen character where the last
    ; chip was dropped 
    ld a, (hl)
    ld c, 1;counter for number of chips in a row 
    push hl
    pop ix
    push ix
    push ix
    pop de
    ld hl, blinking
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    ld b, 4
    CHECK_LEFT
        dec ix
        cp (ix)
        jr nz, CHECK_RIGHT
        push ix
        pop de
        ld (hl), e
        inc hl
        ld (hl), d
        inc hl
        inc c
        ld d, a
        ld a, c
        cp 4
        jp Z, GAME_OVER
        ld a, d
    djnz CHECK_LEFT
    CHECK_RIGHT
    pop ix;restore to the position where the chip fell
    push ix
    push ix
    pop de
    ld b, 4
    CHECK_RIGHT_
        inc ix
        cp (ix)
        jr nz, CHECK_BOTTOM
        push ix
        pop de
        ld (hl), e
        inc hl
        ld (hl), d
        inc hl
        inc c
        ld d, a
        ld a, c
        cp 4
        jp Z, GAME_OVER
        ld a, d
        djnz CHECK_RIGHT_
    CHECK_BOTTOM
    pop ix;restore the position where the chip fell
    push ix
    push ix
    pop de
    ld hl, blinking
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    ld c, 1
    ld b, 4
    CHECK_BOTTOM_
        ld a, (ix)
        ld de, 32
        add ix, de
        cp (ix)
        jr nz, CHECK_DIAGONAL_NW_SE
        push ix
        pop de
        ld (hl), e
        inc hl
        ld (hl), d
        inc hl
        inc c
        ld a, c
        cp 4
        jp Z, GAME_OVER
    djnz CHECK_BOTTOM_
    CHECK_DIAGONAL_NW_SE
    pop ix;restore the position where the chip fell
    push ix
    push ix
    pop de
    ld hl, blinking
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    ld c, 1
    ld b, 4
    CHECK_DIAGONAL_NW_SE_
        CHECK_NW
            ld a, (ix)
            ld de, -33
            add ix, de
            cp (ix)
            jr nz, CHECK_SE
            push ix
            pop de
            ld (hl), e
            inc hl
            ld (hl), d
            inc hl
            inc c
            ld a, c
            cp 4
            jp Z, GAME_OVER
        djnz CHECK_NW
        CHECK_SE
            ld b, 4
            pop ix
            push ix
            CHECK_SE_
                ld a, (ix)
                ld de, 33
                add ix, de
                cp (ix)
                jr nz, CHECK_DIAGONAL_SW_NE
                push ix
                pop de
                ld (hl), e
                inc hl
                ld (hl), d
                inc hl
                inc c
                ld a, c
                cp 4
                jp Z, GAME_OVER
            djnz CHECK_SE_
    CHECK_DIAGONAL_SW_NE
    pop ix;restore the position where the chip fell
    push ix
    push ix
    pop de
    ld hl, blinking
    ld (hl), e
    inc hl
    ld (hl), d
    inc hl
    ld c, 1
    ld b, 4
    CHECK_SW
        ld a, (ix)
        ld de, 31
        add ix, de
        cp (ix)
        jr nz, CHECK_NE
        push ix
        pop de
        ld (hl), e
        inc hl
        ld (hl), d
        inc hl
        inc c
        ld a, c
        cp 4
        jp Z, GAME_OVER
    djnz CHECK_SW
    CHECK_NE
        ld b, 4
        pop ix
        CHECK_NE_
            ld a, (ix)
            ld de, -31
            add ix, de
            cp (ix)
            jr nz, EO_DID_WIN
            push ix
            pop de
            ld (hl), e
            inc hl
            ld (hl), d
            inc hl
            inc c
            ld a, c
            cp 4
            jp Z, GAME_OVER
        djnz CHECK_NE_
    EO_DID_WIN
ret

GAME_OVER
    ld hl, blinking
    ld b, 4
    blink
        ld e, (hl)
        inc hl
        ld d, (hl)
        ld a, (de)
        or 80h; set the blink bit active
        ld (de), a
        inc hl
    djnz blink
    ;play again?
    ld de, again
    ld bc, again_size
    call print
    READ_PLAY_AGAIN
    ld hl, last_k
    ld a, (hl)
    cp 121 ; ascii for lower case 'y'
    jp Z, START
    jp READ_PLAY_AGAIN

title defb 16, 1, 17, 7, 22, 3, 11, "CONNECT 4"; 16 1 blue text; 17 6 yellow ink; 22 3 11 position to print(3,11)
title_size equ $-title

controls defb 16, 2, 17, 7, 22, 20, 1, "o:left, p:right"
         defb 22, 21, 1, "space: drop chip"
controls_size equ $-controls
again defb 16, 1, 17, 7, 22, 17, 7, "Play again (y/n)?";
again_size equ $-again

board defb 16, 7, 17, 1 ; white ink, blue paper
      defb 22, 10, 12, 144, 144, 144, 144, 144, 144, 144
      defb 22, 11, 12, 144, 144, 144, 144, 144, 144, 144
      defb 22, 12, 12, 144, 144, 144, 144, 144, 144, 144
      defb 22, 13, 12, 144, 144, 144, 144, 144, 144, 144
      defb 22, 14, 12, 144, 144, 144, 144, 144, 144, 144
      defb 22, 15, 12, 144, 144, 144, 144, 144, 144, 144
board_size equ $-board

transparent defb 22, 9, 12 ; position (9, 12)
            defb 16, 7, 17, 7 ; white ink, white paper
transparent_size equ $-transparent

; 0 0 0 0 0 0 0 0 -> 0h
; 0 0 0 1 1 0 0 0 -> 18h
; 0 0 1 1 1 1 0 0 -> 3Ch
; 0 1 1 1 1 1 1 0 -> 7Eh
; 0 1 1 1 1 1 1 0 -> 7Eh
; 0 0 1 1 1 1 0 0 -> 3Ch
; 0 0 0 1 1 0 0 0 -> 18h
; 0 0 0 0 0 0 0 0 -> 0h
udgs defb 0h, 18h, 3Ch, 7Eh, 7Eh, 3Ch, 18h, 0h

player_color defb 7Ah, 4Ah ; red/white, red/blue
column_depth_init defb 6,6,6,6,6,6,6 ; used to restart column_depth if playing again
column_depth defb 6,6,6,6,6,6,6 ; how many spaces are left in each column
player_pos defb 15, 0; initial position
blinking equ $ ; memory address to keep the 4 chips that will blink when the game is over
end 50000