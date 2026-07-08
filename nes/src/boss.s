; ============================================================
; boss.s — end-of-loop guardian (32x32 core)
; ============================================================

boss_spawn:
    lda #40
    clc
    adc difficulty
    adc difficulty
    adc difficulty
    adc difficulty              ; hp = 40 + 4*diff... beef it up
    sta boss_hp
    lda #$F8
    sta boss_x
    lda #110
    sta boss_yh
    lda #0
    sta boss_yl
    sta boss_t
    sta boss_flash
    sta boss_dying
    lda #120
    sta boss_fire
    rts

boss_update:
    lda wv_mode
    cmp #1
    beq :+
    rts
:
    lda boss_flash
    beq :+
    dec boss_flash
:
    lda boss_dying
    beq @alive
    ; ---- death sequence: chained explosions ----
    dec boss_dying
    lda boss_dying
    and #$07
    bne :+
    jsr rng
    and #$0F
    clc
    adc boss_x
    sta tmp3
    jsr rng
    and #$0F
    clc
    adc boss_yh
    adc #4
    sta tmp4
    jsr spawn_explosion
    jsr sfx_boom
:   lda boss_dying
    bne @out
    ; done: award bonus, enter stage clear
    ldx #3                      ; thousands
    lda #5
    jsr add_score
    lda #2
    sta wv_mode
    lda #ST_CLEAR
    sta gstate
    lda #0
    sta gtimer
    lda #2                      ; ~8.5 s of interlude
    sta gtimer2
    jsr music_stop
@out:
    rts

@alive:
    inc boss_t
    ; slide in from the right to x=200
    lda boss_x
    cmp #200
    beq @hover
    dec boss_x
    jmp @fire
@hover:
    ; y = 110 + sin(t)*1.5 (sintab centered 32)
    lda boss_t
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    sta tmp1
    cmp #$80
    ror                         ; /2 signed
    clc
    adc tmp1                    ; * 1.5
    clc
    adc #94
    sta boss_yh
@fire:
    dec boss_fire
    bne @out2
    ; spread of 3 aimed shots (staggered origins fan the spread)
    lda difficulty
    asl
    asl
    asl
    sta tmp1
    lda #110
    sec
    sbc tmp1
    cmp #50
    bcs :+
    lda #50
:   sta boss_fire

    lda boss_x
    clc
    adc #2
    sta tmp3
    lda boss_yh
    clc
    adc #8
    sta tmp4
    jsr spawn_eb_aimed
    lda boss_x
    clc
    adc #2
    sta tmp3
    lda boss_yh
    clc
    adc #24
    sta tmp4
    jsr spawn_eb_aimed
    lda boss_x
    clc
    adc #6
    sta tmp3
    lda boss_yh
    clc
    adc #16
    sta tmp4
    jsr spawn_eb_aimed
    jsr sfx_hit
@out2:
    rts

; ------------------------------------------------------------
; boss_damage — A = damage
; ------------------------------------------------------------
boss_damage:
    sta tmp1
    lda boss_dying
    bne @out
    lda boss_x
    cmp #201
    bcs @out                    ; still entering: brief mercy
    lda boss_hp
    sec
    sbc tmp1
    beq @die
    bcs @ok
@die:
    lda #0
    sta boss_hp
    lda #96                     ; death fireworks duration
    sta boss_dying
    jsr sfx_bigboom
    rts
@ok:
    sta boss_hp
    lda #4
    sta boss_flash
    jsr sfx_hit
@out:
    rts
