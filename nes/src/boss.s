; ============================================================
; boss.s — stage guardians (32x32 core, 8 sprites)
;   kind = stage6:  0 Guardian orb (h)   1 Golem (v)
;                   2 Kraken (h)         3 Tetra (v)
;                   4 Bastion (h)        5 Overmind (v)
; ============================================================

boss_spawn:
    lda #40
    clc
    adc difficulty
    adc difficulty
    adc difficulty
    adc difficulty              ; hp = 40 + 4*diff
    ldy stage6
    clc
    adc boss_bonus_tbl,y        ; later guardians are tougher
    sta boss_hp
    ldy vmode
    beq @horiz
    lda #112                    ; vertical: drop in from the top
    sta boss_x
    lda #$10
    sta boss_yh
    bne @common
@horiz:
    lda #$F8                    ; horizontal: slide in from the right
    sta boss_x
    lda #110
    sta boss_yh
@common:
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
    ; ---- entry ----
    lda vmode
    bne @vent
    lda boss_x
    cmp #200
    beq @move
    dec boss_x
    jmp @fire
@vent:
    lda boss_yh
    cmp #48
    beq @move
    inc boss_yh
    jmp @fire

    ; ---- per-kind movement ----
@move:
    lda stage6
    asl
    tay
    lda @mv_tbl,y
    sta ptr1
    lda @mv_tbl+1,y
    sta ptr1+1
    jmp (ptr1)
@mv_tbl:
    .addr @mv_orb, @mv_golem, @mv_kraken
    .addr @mv_tetra, @mv_bastion, @mv_overmind

@mv_orb:
    ; y = 94 + 1.5*sin(t): tall vertical bob
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
    jmp @fire

@mv_golem:
    ; x = 96 + 1.5*sin(t): wide canyon sweep
    lda boss_t
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    sta tmp1
    cmp #$80
    ror
    clc
    adc tmp1
    clc
    adc #96
    sta boss_x
    jmp @fire

@mv_kraken:
    ; lazy figure-8: y = 94 + 1.5*sin(t), x = 196 + sin(2t)/4
    lda boss_t
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    sta tmp1
    cmp #$80
    ror
    clc
    adc tmp1
    clc
    adc #94
    sta boss_yh
    lda boss_t
    asl
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    cmp #$80
    ror
    cmp #$80
    ror                         ; /4 signed
    clc
    adc #196
    sta boss_x
    jmp @fire

@mv_tetra:
    ; fast full sweep + shallow bob
    lda boss_t
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    sta tmp1
    cmp #$80
    ror
    clc
    adc tmp1
    clc
    adc #96
    sta boss_x
    lda boss_t
    asl
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    cmp #$80
    ror
    cmp #$80
    ror
    clc
    adc #48
    sta boss_yh
    jmp @fire

@mv_bastion:
    ; armored hunter: creep toward the player's altitude
    lda frame
    and #$01
    bne @firej
    lda plyh
    sec
    sbc #8
    cmp #24
    bcs :+
    lda #24
:   cmp #176
    bcc :+
    lda #176
:   cmp boss_yh
    beq @firej
    bcc :+
    inc boss_yh
    jmp @fire
:   dec boss_yh
@firej:
    jmp @fire

@mv_overmind:
    ; roaming drift: x = 96 + 1.5*sin(t), y = 44 + sin(2t)/2
    lda boss_t
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    sta tmp1
    cmp #$80
    ror
    clc
    adc tmp1
    clc
    adc #96
    sta boss_x
    lda boss_t
    asl
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    cmp #$80
    ror
    clc
    adc #44
    sta boss_yh

    ; ---- fire (shared period, per-kind pattern) ----
@fire:
    dec boss_fire
    beq :+
    rts
:   lda difficulty
    asl
    asl
    asl
    sta tmp1
    lda #110
    sec
    sbc tmp1                    ; 110 - 8*diff
    cmp #50
    bcs :+
    lda #50
:   sta boss_fire

    lda stage6
    asl
    tay
    lda @fi_tbl,y
    sta ptr1
    lda @fi_tbl+1,y
    sta ptr1+1
    jmp (ptr1)
@fi_tbl:
    .addr @fi_orb, @fi_golem, @fi_kraken
    .addr @fi_tetra, @fi_bastion, @fi_overmind

@fi_orb:
    ; 3 aimed shots, staggered origins fan the spread
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
    jmp @firesfx

@fi_golem:
    ; alternates: aimed spread / straight spit from the mouth
    lda boss_t
    and #$40
    bne @golem_spit
    lda boss_x
    clc
    adc #8
    sta tmp3
    lda boss_yh
    clc
    adc #30
    sta tmp4
    jsr spawn_eb_aimed
    lda boss_x
    clc
    adc #24
    sta tmp3
    lda boss_yh
    clc
    adc #30
    sta tmp4
    jsr spawn_eb_aimed
    jmp @aim_mouth
@golem_spit:
    lda boss_x
    clc
    adc #8
    sta tmp3
    lda boss_yh
    clc
    adc #28
    sta tmp4
    lda #0
    ldy #2
    jsr spawn_eb_vel            ; straight down
    lda boss_x
    clc
    adc #24
    sta tmp3
    lda #0
    ldy #2
    jsr spawn_eb_vel
@aim_mouth:
    lda boss_x
    clc
    adc #16
    sta tmp3
    lda boss_yh
    clc
    adc #26
    sta tmp4
    jsr spawn_eb_aimed
    jmp @firesfx

@fi_kraken:
    ; two aimed tentacle shots + a straight ink jet
    lda boss_x
    clc
    adc #4
    sta tmp3
    lda boss_yh
    clc
    adc #26
    sta tmp4
    jsr spawn_eb_aimed
    lda boss_x
    clc
    adc #12
    sta tmp3
    lda boss_yh
    clc
    adc #30
    sta tmp4
    jsr spawn_eb_aimed
    lda boss_x
    sta tmp3
    lda boss_yh
    clc
    adc #12
    sta tmp4
    lda #<-2
    ldy #0
    jsr spawn_eb_vel            ; straight left
    jmp @firesfx

@fi_tetra:
    ; shard ring: down, down-left, down-right + one aimed
    lda boss_x
    clc
    adc #16
    sta tmp3
    lda boss_yh
    clc
    adc #30
    sta tmp4
    lda #0
    ldy #2
    jsr spawn_eb_vel
    lda #<-1
    ldy #2
    jsr spawn_eb_vel
    lda #1
    ldy #2
    jsr spawn_eb_vel
    lda boss_x
    clc
    adc #16
    sta tmp3
    lda boss_yh
    clc
    adc #16
    sta tmp4
    jsr spawn_eb_aimed
    jmp @firesfx

@fi_bastion:
    ; only fires while the armor is open
    lda boss_t
    bpl @nofire
    lda boss_x
    sta tmp3
    lda boss_yh
    clc
    adc #4
    sta tmp4
    lda #<-2
    ldy #0
    jsr spawn_eb_vel
    lda boss_x
    sta tmp3
    lda boss_yh
    clc
    adc #24
    sta tmp4
    lda #<-2
    ldy #0
    jsr spawn_eb_vel
    lda boss_x
    clc
    adc #4
    sta tmp3
    lda boss_yh
    clc
    adc #14
    sta tmp4
    jsr spawn_eb_aimed
    jmp @firesfx
@nofire:
    rts

@fi_overmind:
    ; psychic rain + aimed pair
    lda boss_x
    clc
    adc #16
    sta tmp3
    lda boss_yh
    clc
    adc #30
    sta tmp4
    lda #0
    ldy #2
    jsr spawn_eb_vel
    lda #<-1
    ldy #2
    jsr spawn_eb_vel
    lda #1
    ldy #2
    jsr spawn_eb_vel
    lda boss_x
    clc
    adc #4
    sta tmp3
    lda boss_yh
    clc
    adc #24
    sta tmp4
    jsr spawn_eb_aimed
    lda boss_x
    clc
    adc #28
    sta tmp3
    lda boss_yh
    clc
    adc #24
    sta tmp4
    jsr spawn_eb_aimed

@firesfx:
    jsr sfx_hit
    rts

; ------------------------------------------------------------
; boss_damage — A = damage
; ------------------------------------------------------------
boss_damage:
    sta tmp1
    lda boss_dying
    bne @out
    lda vmode
    bne @vmercy
    lda boss_x
    cmp #201
    bcs @out                    ; still entering: brief mercy
    bcc @armor
@vmercy:
    lda boss_yh
    cmp #48
    bcc @out                    ; still entering
@armor:
    lda stage6                  ; the Bastion shrugs shots off while closed
    cmp #4
    bne @go
    lda boss_t
    bpl @out
@go:
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
