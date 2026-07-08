; ============================================================
; player.s — movement, firing, power meter, death/respawn
; ============================================================

player_update:
    lda pl_invuln
    beq :+
    dec pl_invuln
:
    lda pl_dead
    beq @alive
    ; ---- dead: wait out respawn timer ----
    dec pl_dead
    bne @deadout
    ; timer expired: respawn or game over
    lda pl_lives
    bne @respawn
    jsr enter_gameover
    rts
@respawn:
    dec pl_lives
    lda #0
    sta pl_speed
    sta pl_weapon
    sta pl_missile
    sta pl_opts
    sta pl_shield
    sta meter
    sta plxl
    sta plyl
    lda #$10
    sta plxh
    lda #112
    sta plyh
    lda #120
    sta pl_invuln
    ; refill history so options (none now) don't streak later
    ldx #63
    lda #112
:   sta hist_y,x
    dex
    bpl :-
@deadout:
    rts

@alive:
    ; ---- movement ----
    ldx pl_speed
    lda speed_lo,x
    sta tmp1                    ; velocity 8.8 lo
    lda speed_hi,x
    sta tmp2                    ; velocity 8.8 hi

    lda pad
    and #BTN_LEFT
    beq @noleft
    lda plxl
    sec
    sbc tmp1
    sta plxl
    lda plxh
    sbc tmp2
    sta plxh
    cmp #$08
    bcs @noleft
    lda #$08
    sta plxh
    lda #0
    sta plxl
@noleft:
    lda pad
    and #BTN_RIGHT
    beq @noright
    lda plxl
    clc
    adc tmp1
    sta plxl
    lda plxh
    adc tmp2
    sta plxh
    cmp #$E0
    bcc @noright
    lda #$E0
    sta plxh
    lda #0
    sta plxl
@noright:
    lda pad
    and #BTN_UP
    beq @noup
    lda plyl
    sec
    sbc tmp1
    sta plyl
    lda plyh
    sbc tmp2
    sta plyh
    cmp #$12
    bcs @noup
    lda #$12
    sta plyh
    lda #0
    sta plyl
@noup:
    lda pad
    and #BTN_DOWN
    beq @nodown
    lda plyl
    clc
    adc tmp1
    sta plyl
    lda plyh
    adc tmp2
    sta plyh
    cmp #$D0
    bcc @nodown
    lda #$D0
    sta plyh
    lda #0
    sta plyl
@nodown:

    ; ---- record trail history for options ----
    ldx hist_idx
    inx
    txa
    and #$3F
    sta hist_idx
    tax
    lda plxh
    sta hist_x,x
    lda plyh
    sta hist_y,x

    ; ---- terrain collision (4 corner points of core box) ----
    lda pl_invuln
    bne @noterr                 ; brief mercy after (re)spawn
    lda plyh
    clc
    adc #3
    tay
    lda plxh
    clc
    adc #3
    jsr terrain_solid           ; A=x, Y=y -> carry set if solid
    bcs @crash
    lda plyh
    clc
    adc #3
    tay
    lda plxh
    clc
    adc #12
    jsr terrain_solid
    bcs @crash
    lda plyh
    clc
    adc #12
    tay
    lda plxh
    clc
    adc #3
    jsr terrain_solid
    bcs @crash
    lda plyh
    clc
    adc #12
    tay
    lda plxh
    clc
    adc #12
    jsr terrain_solid
    bcc @noterr
@crash:
    jsr player_kill
    rts
@noterr:

    ; ---- power meter activate (A button) ----
    lda pad_new
    and #BTN_A
    beq @noact
    jsr meter_activate
@noact:

    ; ---- fire (B button) ----
    lda fire_cd
    beq :+
    dec fire_cd
:   lda miss_cd
    beq :+
    dec miss_cd
:
    lda pad
    and #BTN_B
    beq @nofire
    lda fire_cd
    bne @nomain
    jsr fire_weapon
@nomain:
    lda pl_missile
    beq @nofire
    lda miss_cd
    bne @nofire
    jsr fire_missile
@nofire:
    rts

; ------------------------------------------------------------
; fire_weapon — spawn shots from ship + options
; ------------------------------------------------------------
fire_weapon:
    lda pl_weapon
    cmp #WPN_LASER
    bne :+
    lda #5
    sta fire_cd
    bne @go
:   lda #9
    sta fire_cd
@go:
    jsr sfx_shoot

    ; from ship
    lda plxh
    sta tmp3
    lda plyh
    sta tmp4
    jsr fire_from_point

    ; from options
    lda pl_opts
    beq @done
    lda hist_idx
    sec
    sbc #20
    and #$3F
    tax
    lda hist_x,x
    sta tmp3
    lda hist_y,x
    sta tmp4
    jsr fire_from_point
    lda pl_opts
    cmp #2
    bcc @done
    lda hist_idx
    sec
    sbc #40
    and #$3F
    tax
    lda hist_x,x
    sta tmp3
    lda hist_y,x
    sta tmp4
    jsr fire_from_point
@done:
    rts

; ------------------------------------------------------------
; fire_from_point — tmp3/tmp4 = origin x/y
; ------------------------------------------------------------
fire_from_point:
    lda pl_weapon
    cmp #WPN_LASER
    beq @laser
    ; forward shot
    jsr pb_find_free
    bmi @try_diag
    lda #PBT_BULLET
    sta pb_type,x
    lda tmp3
    clc
    adc #12
    sta pb_xh,x
    lda tmp4
    clc
    adc #2
    sta pb_yh,x
    lda #0
    sta pb_xl,x
    sta pb_yl,x
    sta pb_vxl,x
    sta pb_vyl,x
    sta pb_vyh,x
    lda #3                      ; 3 px/frame forward
    sta pb_vxh,x
@try_diag:
    lda pl_weapon
    cmp #WPN_DOUBLE
    bne @out
    jsr pb_find_free
    bmi @out
    lda #PBT_BULLET
    sta pb_type,x
    lda tmp3
    clc
    adc #8
    sta pb_xh,x
    lda tmp4
    sta pb_yh,x
    lda #0
    sta pb_xl,x
    sta pb_yl,x
    lda #$40
    sta pb_vxl,x
    lda #2                      ; 2.25 px/f right
    sta pb_vxh,x
    lda #$C0
    sta pb_vyl,x
    lda #$FD                    ; -2.25 px/f (up)
    sta pb_vyh,x
@out:
    rts
@laser:
    jsr pb_find_free
    bmi @out
    lda #PBT_LASER
    sta pb_type,x
    lda tmp3
    clc
    adc #14
    sta pb_xh,x
    lda tmp4
    clc
    adc #2
    sta pb_yh,x
    lda #0
    sta pb_xl,x
    sta pb_yl,x
    sta pb_vxl,x
    sta pb_vyl,x
    sta pb_vyh,x
    lda #6
    sta pb_vxh,x
    rts

; ------------------------------------------------------------
fire_missile:
    jsr pb_find_free
    bmi @out
    lda #20
    sta miss_cd
    lda #PBT_MISFALL
    sta pb_type,x
    lda plxh
    clc
    adc #4
    sta pb_xh,x
    lda plyh
    clc
    adc #10
    sta pb_yh,x
    lda #0
    sta pb_xl,x
    sta pb_yl,x
    lda #$C0                    ; 0.75 px/f forward
    sta pb_vxl,x
    lda #0
    sta pb_vxh,x
    lda #$80                    ; 1.5 px/f down
    sta pb_vyl,x
    lda #1
    sta pb_vyh,x
@out:
    rts

; ------------------------------------------------------------
; pb_find_free — X = free bullet slot, or N flag set if none
; ------------------------------------------------------------
pb_find_free:
    ldx #NUM_PB-1
:   lda pb_type,x
    beq @got
    dex
    bpl :-
    ldx #$FF
@got:
    txa                         ; N flag reflects "no slot" ($FF)
    rts

; ------------------------------------------------------------
; meter_activate — apply current meter slot
; ------------------------------------------------------------
meter_activate:
    lda meter
    bne :+
    rts
:   jsr sfx_activate
    lda meter
    cmp #MTR_SPEED
    bne :+
    lda pl_speed
    cmp #4
    bcs @clear
    inc pl_speed
    jmp @clear
:   cmp #MTR_MISSILE
    bne :+
    lda #1
    sta pl_missile
    jmp @clear
:   cmp #MTR_DOUBLE
    bne :+
    lda #WPN_DOUBLE
    sta pl_weapon
    jmp @clear
:   cmp #MTR_LASER
    bne :+
    lda #WPN_LASER
    sta pl_weapon
    jmp @clear
:   cmp #MTR_OPTION
    bne :+
    lda pl_opts
    cmp #2
    bcs @clear
    inc pl_opts
    jmp @clear
:   ; MTR_FORCE
    lda #3
    sta pl_shield
@clear:
    lda #0
    sta meter
    rts

; ------------------------------------------------------------
; player_hit — called on any damaging contact
; ------------------------------------------------------------
player_hit:
    lda pl_invuln
    ora pl_dead
    beq :+
    rts
:   lda pl_shield
    beq player_kill
    dec pl_shield
    lda #45
    sta pl_invuln
    jsr sfx_hit
    rts

; ------------------------------------------------------------
; player_kill — explode, schedule respawn
; ------------------------------------------------------------
player_kill:
    lda pl_dead
    beq :+
    rts
:   txa
    pha
    lda #90
    sta pl_dead
    lda plxh
    sta tmp3
    lda plyh
    sta tmp4
    jsr spawn_explosion
    jsr sfx_bigboom
    pla
    tax
    rts

; ------------------------------------------------------------
; capsule pickup effect
; ------------------------------------------------------------
meter_advance:
    lda meter
    clc
    adc #1
    cmp #7
    bcc :+
    lda #1
:   sta meter
    jsr sfx_pickup
    ; +500 points
    ldx #2
    lda #5
    jsr add_score
    rts
