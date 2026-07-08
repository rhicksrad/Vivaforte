; ============================================================
; collide.s — all collision checks (AABB on pixel-hi bytes)
; ============================================================

collide_all:
    jsr col_pb_targets
    lda pl_dead
    beq :+
    rts
:   jsr col_en_player
    jsr col_eb_player
    jsr col_cap_player
    rts

; ------------------------------------------------------------
; abs_diff — A = |A - col scratch value in tmp1|
; (helper: caller puts other value in tmp1)
; ------------------------------------------------------------
abs_diff:
    sec
    sbc tmp1
    bcs :+
    eor #$FF
    clc
    adc #1
:   rts

; ------------------------------------------------------------
; player bullets vs enemies and boss
; ------------------------------------------------------------
col_pb_targets:
    ldx #NUM_PB-1
@bloop:
    lda pb_type,x
    bne @act
@bnext:
    dex
    bpl @bloop
    rts
@act:
    ; bullet center
    lda pb_xh,x
    clc
    adc #4
    sta col_x
    lda pb_yh,x
    clc
    adc #4
    sta col_y
    ; damage: bullet=1, laser/missile=2
    lda pb_type,x
    cmp #PBT_BULLET
    beq :+
    lda #2
    bne :++
:   lda #1
:   sta col_dmg

    ; ---- enemies ----
    ldy #NUM_EN-1
@eloop:
    lda en_type,y
    beq @enext
    lda col_x
    sta tmp1
    lda en_xh,y
    clc
    adc #8
    jsr abs_diff
    cmp #11
    bcs @enext
    lda col_y
    sta tmp1
    lda en_yh,y
    clc
    adc #8
    jsr abs_diff
    cmp #11
    bcs @enext
    ; hit!
    lda #PBT_NONE
    sta pb_type,x
    lda en_hp,y
    sec
    sbc col_dmg
    beq @edie
    bcc @edie
    sta en_hp,y
    jsr sfx_hit
    jmp @bnext
@edie:
    txa
    pha
    tya
    tax
    jsr enemy_die
    pla
    tax
    jmp @bnext
@enext:
    dey
    bpl @eloop

    ; ---- boss ----
    lda wv_mode
    cmp #1
    bne @bnextj
    lda boss_dying
    bne @bnextj
    lda col_x
    sta tmp1
    lda boss_x
    clc
    adc #16
    jsr abs_diff
    cmp #19
    bcs @bnextj
    lda col_y
    sta tmp1
    lda boss_yh
    clc
    adc #16
    jsr abs_diff
    cmp #19
    bcs @bnextj
    lda #PBT_NONE
    sta pb_type,x
    lda col_dmg
    jsr boss_damage
@bnextj:
    jmp @bnext

; ------------------------------------------------------------
; enemies vs player (contact)
; ------------------------------------------------------------
col_en_player:
    lda plxh
    clc
    adc #8
    sta col_x
    lda plyh
    clc
    adc #8
    sta col_y
    ldx #NUM_EN-1
@loop:
    lda en_type,x
    beq @next
    lda col_x
    sta tmp1
    lda en_xh,x
    clc
    adc #8
    jsr abs_diff
    cmp #12
    bcs @next
    lda col_y
    sta tmp1
    lda en_yh,x
    clc
    adc #8
    jsr abs_diff
    cmp #11
    bcs @next
    jsr player_hit
    jsr enemy_die
@next:
    dex
    bpl @loop

    ; boss body vs player
    lda wv_mode
    cmp #1
    bne @out
    lda boss_dying
    bne @out
    lda col_x
    sta tmp1
    lda boss_x
    clc
    adc #16
    jsr abs_diff
    cmp #22
    bcs @out
    lda col_y
    sta tmp1
    lda boss_yh
    clc
    adc #16
    jsr abs_diff
    cmp #21
    bcs @out
    jsr player_hit
@out:
    rts

; ------------------------------------------------------------
; enemy bullets vs player
; ------------------------------------------------------------
col_eb_player:
    lda plxh
    clc
    adc #8
    sta col_x
    lda plyh
    clc
    adc #8
    sta col_y
    ldx #NUM_EB-1
@loop:
    lda eb_on,x
    beq @next
    lda col_x
    sta tmp1
    lda eb_xh,x
    clc
    adc #2
    jsr abs_diff
    cmp #8
    bcs @next
    lda col_y
    sta tmp1
    lda eb_yh,x
    clc
    adc #2
    jsr abs_diff
    cmp #8
    bcs @next
    lda #0
    sta eb_on,x
    jsr player_hit
@next:
    dex
    bpl @loop
    rts

; ------------------------------------------------------------
; capsules vs player
; ------------------------------------------------------------
col_cap_player:
    lda plxh
    clc
    adc #8
    sta col_x
    lda plyh
    clc
    adc #8
    sta col_y
    ldx #NUM_CAP-1
@loop:
    lda cap_on,x
    beq @next
    lda col_x
    sta tmp1
    lda cap_x,x
    clc
    adc #4
    jsr abs_diff
    cmp #12
    bcs @next
    lda col_y
    sta tmp1
    lda cap_y,x
    clc
    adc #6
    jsr abs_diff
    cmp #12
    bcs @next
    lda #0
    sta cap_on,x
    txa
    pha
    jsr meter_advance
    pla
    tax
@next:
    dex
    bpl @loop
    rts
