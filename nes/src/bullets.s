; ============================================================
; bullets.s — player bullets, missiles, enemy bullets,
;             capsules, explosions
; ============================================================

; ------------------------------------------------------------
pbullets_update:
    ldx #NUM_PB-1
@loop:
    lda pb_type,x
    bne @active
@next:
    dex
    bpl @loop
    rts
@active:
    ; pos += vel (vx may be negative: wall-seeking missiles)
    lda pb_xl,x
    clc
    adc pb_vxl,x
    sta pb_xl,x
    lda pb_xh,x
    adc pb_vxh,x
    sta pb_xh,x
    cmp #$02
    bcc @killt
    cmp #$F8
    bcs @killt
    lda pb_yl,x
    clc
    adc pb_vyl,x
    sta pb_yl,x
    lda pb_yh,x
    adc pb_vyh,x
    sta pb_yh,x
    cmp #$10
    bcc @killt
    cmp #$E8
    bcc @alive2
@killt:
    jmp @kill
@alive2:

    ; type-specific
    lda pb_type,x
    cmp #PBT_MISFALL
    beq @misfall
    cmp #PBT_MISSLIDE
    bne :+
    jmp @misslide
:   cmp #PBT_MISRISE
    bne :+
    jmp @misrise
:   cmp #PBT_MISSLIDEC
    bne :+
    jmp @misslidec
:

    ; bullet / laser: die on terrain
    lda pb_yh,x
    clc
    adc #4
    tay
    lda pb_xh,x
    clc
    adc #4
    jsr terrain_solid
    bcs @killt
    jmp @next

@misfall:
    lda vmode
    bne @vmisfall
    ; check ground under nose
    lda pb_yh,x
    clc
    adc #14
    tay
    lda pb_xh,x
    clc
    adc #4
    jsr terrain_solid
    bcc @nextj
    ; land: switch to slide
    lda #PBT_MISSLIDE
    sta pb_type,x
    lda #0
    sta pb_vyl,x
    sta pb_vyh,x
    lda #$00
    sta pb_vxl,x
    lda #2
    sta pb_vxh,x
@nextj:
    jmp @next

@vmisfall:
    ; probe the side wall we're drifting toward
    lda pb_yh,x
    clc
    adc #6
    tay
    lda pb_vxh,x
    bmi :+
    lda pb_xh,x
    clc
    adc #6
    bne :++
:   lda pb_xh,x
    clc
    adc #1
:   jsr terrain_solid
    bcc @nextj
    ; latched on: crawl up the wall
    lda #PBT_MISSLIDE
    sta pb_type,x
    lda #0
    sta pb_vxl,x
    sta pb_vxh,x
    sta pb_vyl,x
    lda #$FE                    ; -2 px/f (up)
    sta pb_vyh,x
    jmp @next

@misslide:
    lda vmode
    bne @vmisslide
    ; wall ahead -> explode; floor gone -> fall again
    lda pb_yh,x
    clc
    adc #10
    tay
    lda pb_xh,x
    clc
    adc #9
    jsr terrain_solid
    bcc :+
    jmp @mboom
:
    lda pb_yh,x
    clc
    adc #15
    tay
    lda pb_xh,x
    clc
    adc #4
    jsr terrain_solid
    bcs @nextj                  ; still on ground
    lda #PBT_MISFALL            ; slide off a ledge
    sta pb_type,x
    lda #$80
    sta pb_vyl,x
    lda #1
    sta pb_vyh,x
    jmp @next

@vmisslide:
    ; solid ahead (above) -> explode
    lda pb_yh,x
    tay
    lda pb_xh,x
    clc
    adc #4
    jsr terrain_solid
    bcs @mboom
    jmp @next

@misrise:
    ; ceiling above the nose? (horizontal stages only)
    lda pb_yh,x
    clc
    adc #2
    tay
    lda pb_xh,x
    clc
    adc #4
    jsr terrain_solid
    bcc @nextj2
    ; latch: slide forward along the ceiling
    lda #PBT_MISSLIDEC
    sta pb_type,x
    lda #0
    sta pb_vyl,x
    sta pb_vyh,x
    sta pb_vxl,x
    lda #2
    sta pb_vxh,x
@nextj2:
    jmp @next

@misslidec:
    ; wall ahead -> explode; ceiling receded -> climb to it
    lda pb_yh,x
    clc
    adc #6
    tay
    lda pb_xh,x
    clc
    adc #9
    jsr terrain_solid
    bcs @mboomj
    lda pb_yh,x
    clc
    adc #1
    tay
    lda pb_xh,x
    clc
    adc #4
    jsr terrain_solid
    bcs @nextj2                 ; still hugging the ceiling
    lda #PBT_MISRISE
    sta pb_type,x
    lda #$80
    sta pb_vyl,x
    lda #$FE
    sta pb_vyh,x
    jmp @next
@mboomj:
    jmp @mboom
@mboom:
    lda pb_xh,x
    sta tmp3
    lda pb_yh,x
    sta tmp4
    txa
    pha
    jsr spawn_explosion
    pla
    tax
@kill:
    lda #PBT_NONE
    sta pb_type,x
    jmp @next

; ------------------------------------------------------------
ebullets_update:
    ldx #NUM_EB-1
@loop:
    lda eb_on,x
    bne @active
@next:
    dex
    bpl @loop
    rts
@active:
    lda eb_xl,x
    clc
    adc eb_vxl,x
    sta eb_xl,x
    lda eb_xh,x
    adc eb_vxh,x
    sta eb_xh,x
    cmp #$02
    bcc @kill
    cmp #$F8
    bcs @kill
    lda eb_yl,x
    clc
    adc eb_vyl,x
    sta eb_yl,x
    lda eb_yh,x
    adc eb_vyh,x
    sta eb_yh,x
    cmp #$10
    bcc @kill
    cmp #$E8
    bcc @next
@kill:
    lda #0
    sta eb_on,x
@nextj:
    jmp @next

; ------------------------------------------------------------
; spawn_eb_aimed — fire an aimed bullet from (tmp3, tmp4)
; toward the player. Speed scales a little with difficulty.
; ------------------------------------------------------------
spawn_eb_aimed:
    lda pl_dead
    beq :+
    rts                         ; no target
:   ldx #NUM_EB-1
:   lda eb_on,x
    beq @got
    dex
    bpl :-
    rts
@got:
    lda #1
    sta eb_on,x
    lda tmp3
    sta eb_xh,x
    lda tmp4
    sta eb_yh,x
    lda #0
    sta eb_xl,x
    sta eb_yl,x

    ; dx = player - origin, clamped to -120..120 (avoid sign overflow)
    lda plxh
    sec
    sbc tmp3
    bcs @posx
    cmp #$88
    bcs @okx
    lda #$88
    bne @okx
@posx:
    cmp #$78
    bcc @okx
    lda #$78
@okx:
    sta tmp1
    lda plyh
    clc
    adc #4
    sec
    sbc tmp4
    bcs @posy
    cmp #$88
    bcs @oky
    lda #$88
    bne @oky
@posy:
    cmp #$78
    bcc @oky
    lda #$78
@oky:
    sta tmp2

    ; normalize both into -3..3 (arithmetic shift right together)
@norm:
    lda tmp1
    jsr abs_a
    cmp #4
    bcs @shift
    lda tmp2
    jsr abs_a
    cmp #4
    bcc @scaled
@shift:
    lda tmp1
    cmp #$80                    ; asr tmp1
    ror
    sta tmp1
    lda tmp2
    cmp #$80
    ror
    sta tmp2
    jmp @norm

@scaled:
    ; velocity = n * (84 + 10*difficulty), via table lookup
    lda difficulty
    asl
    asl
    asl
    clc
    adc #84
    sta tmp5                    ; speed unit (max 84+48=132 => 0.52 px/f per n)

    lda tmp1
    jsr scale_dir               ; A(signed -3..3) * tmp5 -> tmp1(lo)/tmp2(hi)... careful
    ; scale_dir returns lo in A, hi in Y
    sta eb_vxl,x
    tya
    sta eb_vxh,x
    lda tmp2
    jsr scale_dir
    sta eb_vyl,x
    tya
    sta eb_vyh,x
    rts

; ------------------------------------------------------------
; abs_a — A = |A| (signed 8-bit)
; ------------------------------------------------------------
abs_a:
    bpl :+
    eor #$FF
    clc
    adc #1
:   rts

; ------------------------------------------------------------
; scale_dir — signed A in -3..3 times tmp5 -> 16-bit signed
; returns lo in A, hi in Y. Clobbers tmp6.
; ------------------------------------------------------------
scale_dir:
    sta tmp6                    ; remember sign
    jsr abs_a
    tay                         ; Y = |n| (0..3)
    lda #0
    sta ptr1                    ; hi accumulator
    cpy #0
    beq @pos_done
:   clc
    adc tmp5
    bcc :+
    inc ptr1
:   dey
    bne :--
@pos_done:
    ldy ptr1                    ; Y = hi
    bit tmp6
    bpl @out
    ; negate 16-bit (A = lo, Y = hi)
    eor #$FF
    clc
    adc #1
    pha
    tya
    eor #$FF
    adc #0
    tay
    pla
@out:
    rts

; ------------------------------------------------------------
; spawn_eb_vel — bullet from (tmp3, tmp4) with whole-pixel
; velocity: A = vx (signed), Y = vy (signed).
; (tmp3/tmp4 preserved; clobbers X, tmp5, tmp6)
; ------------------------------------------------------------
spawn_eb_vel:
    sta tmp5
    sty tmp6
    ldx #NUM_EB-1
:   lda eb_on,x
    beq @got
    dex
    bpl :-
    rts
@got:
    lda #1
    sta eb_on,x
    lda tmp3
    sta eb_xh,x
    lda tmp4
    sta eb_yh,x
    lda #0
    sta eb_xl,x
    sta eb_yl,x
    sta eb_vxl,x
    sta eb_vyl,x
    lda tmp5
    sta eb_vxh,x
    lda tmp6
    sta eb_vyh,x
    rts

; ------------------------------------------------------------
; capsules
; ------------------------------------------------------------
spawn_capsule:
    ; at (tmp3, tmp4)
    ldx #NUM_CAP-1
:   lda cap_on,x
    beq @got
    dex
    bpl :-
    rts
@got:
    lda #1
    sta cap_on,x
    lda tmp3
    sta cap_x,x
    lda tmp4
    sta cap_y,x
    lda #0
    sta cap_sub,x
    rts

capsules_update:
    ldx #NUM_CAP-1
@loop:
    lda cap_on,x
    beq @next
    lda vmode
    bne @vert
    ; drift left at 0.5 px/f
    lda cap_sub,x
    clc
    adc #$80
    sta cap_sub,x
    bcc :+
    dec cap_x,x
:   lda cap_x,x
    cmp #$04
    bcc @kill
    ; gentle bob
    lda frame
    and #$0F
    bne @next
    lda frame
    and #$10
    beq :+
    inc cap_y,x
    bne @next
:   dec cap_y,x
    jmp @next
@vert:
    ; drift down at 0.5 px/f
    lda cap_sub,x
    clc
    adc #$80
    sta cap_sub,x
    bcc :+
    inc cap_y,x
:   lda cap_y,x
    cmp #$E0
    bcs @kill
    ; gentle bob
    lda frame
    and #$0F
    bne @next
    lda frame
    and #$10
    beq :+
    inc cap_x,x
    bne @next
:   dec cap_x,x
    jmp @next
@kill:
    lda #0
    sta cap_on,x
@next:
    dex
    bpl @loop
    rts

; ------------------------------------------------------------
; explosions
; ------------------------------------------------------------
spawn_explosion:
    ; at (tmp3, tmp4)
    ldx #NUM_EX-1
:   lda ex_t,x
    beq @got
    dex
    bpl :-
    ldx #0                      ; recycle oldest slot
@got:
    lda #16
    sta ex_t,x
    lda tmp3
    sta ex_x,x
    lda tmp4
    sta ex_y,x
    rts

explosions_update:
    ldx #NUM_EX-1
@loop:
    lda ex_t,x
    beq @next
    dec ex_t,x
@next:
    dex
    bpl @loop
    rts
