org 50000
    ld a, 127
    ld (23693), a; set the screen color
    call 3503;clear the screen
    ld a, 1;
    out (254), a; set the screen border color
    ld hl, udgs
    ld (23675), hl ; points 23675 to user defined graphics (udgs)
    ;ld a, 2   ; if 5633 sees 2 in the accumulator, 
    ;call 5633 ; it makes the next print position the top left corner of the screen
    ;set up and print the title string and colors
    ld de, title
    ld bc, eotitle-title
    call 8252 ; prints the string at "de" with length bc 
    ;setup the board colors
    ld de, board
    ld bc, eoboard-board
    call 8252 ; prints the string at "de" with length bc 
    ld c, 8; rows
    LOOPROWS
        ld b, 8 ; columns
        LOOPCOLS
            call SETXY 
            ld a, 144; position of the first user defined graphic (kind of an ascii code)
            rst 16
            ld hl, YCOORD  
            inc (hl)
            ld a, (YCOORD)
        djnz LOOPCOLS
        ;reset to the first column
        ld hl, 12
        ld (YCOORD), hl
        ;jump to the next row
        ld hl, XCOORD
        inc (hl)
        ld a, (XCOORD)
        dec c
    jr nz, LOOPROWS
ret

SETXY
    ld a, 22
    rst 16
    ld a, (XCOORD)
    rst 16
    ld a, (YCOORD)
    rst 16
ret
title defb 16, 2, 17, 6, 22, 3, 11, "Connect 4"; 16 2 red text; 17 6 yellow ink; 22 3 11 position to print(3,11)
eotitle equ $
board defb 16, 7, 17, 1 ; white ink, blue paper
eoboard equ $
; 0 0 0 0 0 0 0 0 -> 0h
; 0 0 0 1 1 0 0 0 -> 18h
; 0 0 1 1 1 1 0 0 -> 3Ch
; 0 1 1 1 1 1 1 0 -> 7Eh
; 0 1 1 1 1 1 1 0 -> 7Eh
; 0 0 1 1 1 1 0 0 -> 3Ch
; 0 0 0 1 1 0 0 0 -> 18h
; 0 0 0 0 0 0 0 0 -> 0h
udgs defb 0h, 18h, 3Ch, 7Eh, 7Eh, 3Ch, 18h, 0h
XCOORD defb 8
YCOORD defb 12
end 50000

