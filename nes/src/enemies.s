; ============================================================
; enemies.s — enemy behaviors
; ============================================================

enemies_update:
    lda vmode
    beq :+
    jmp enemies_update_v
:   ldx #NUM_EN-1
@loop:
    lda en_type,x
    bne @active
@next:
    dex
    bpl @loop
    rts
@active:
    inc en_t,x
    lda en_type,x
    cmp #ET_FAN
    beq @fan
    cmp #ET_DART
    beq @dart
    cmp #ET_TURRETB
    beq @turret
    cmp #ET_TURRETT
    beq @turret
    jmp @orb

; ---- FAN: sine-wave flyer ----
@fan:
    ; x -= 1.25
    lda en_xl,x
    sec
    sbc #$40
    sta en_xl,x
    lda en_xh,x
    sbc #1
    sta en_xh,x
    cmp #$04
    bcc @killj
    ; y = base + sin(t*2)/1  (sintab is 0..64, centered 32)
    lda en_t,x
    asl
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    clc
    adc en_base,x
    sta en_yh,x
    jmp @next
@killj:
    jmp @kill

; ---- DART: cruise, then lunge at the player ----
@dart:
    lda en_t,x
    cmp #50
    bcc @dcruise
    ; lunge: x -= 1.75, home y at 1 px/f
    lda en_xl,x
    sec
    sbc #$C0
    sta en_xl,x
    lda en_xh,x
    sbc #1
    sta en_xh,x
    cmp #$04
    bcc @killj
    lda en_yh,x
    cmp plyh
    beq @next2
    bcc :+
    dec en_yh,x
    jmp @next2
:   inc en_yh,x
    jmp @next2
@dcruise:
    ; x -= 0.5
    lda en_xl,x
    sec
    sbc #$80
    sta en_xl,x
    lda en_xh,x
    sbc #0
    sta en_xh,x
    cmp #$04
    bcc @killj
@next2:
    jmp @next

; ---- TURRET: glued to terrain, fires aimed shots ----
@turret:
    ; move exactly with the scroll (0.75 px/f)
    lda en_xl,x
    sec
    sbc #SCROLL_SPD
    sta en_xl,x
    lda en_xh,x
    sbc #0
    sta en_xh,x
    cmp #$04
    bcs :+
    jmp @kill
:
    ; fire on a difficulty-scaled period
    lda difficulty
    asl
    asl
    asl
    sta tmp1
    lda #120
    sec
    sbc tmp1                    ; 120 - 8*diff
    cmp en_t,x
    bcs @next2
    lda #0
    sta en_t,x
    lda en_xh,x
    clc
    adc #4
    sta tmp3
    lda en_yh,x
    clc
    adc #6
    sta tmp4
    txa
    pha
    jsr spawn_eb_aimed
    pla
    tax
    jmp @next

; ---- ORB: slow drifter, radial-ish shots ----
@orb:
    ; x -= 0.75
    lda en_xl,x
    sec
    sbc #$C0
    sta en_xl,x
    lda en_xh,x
    sbc #0
    sta en_xh,x
    cmp #$04
    bcc @kill
    ; slow sine bob
    lda en_t,x
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    cmp #$80
    ror                         ; /2 signed
    clc
    adc en_base,x
    sta en_yh,x
    ; fire every 96 frames
    lda en_t,x
    cmp #96
    bcc @next3
    lda #0
    sta en_t,x
    lda en_xh,x
    clc
    adc #4
    sta tmp3
    lda en_yh,x
    clc
    adc #6
    sta tmp4
    txa
    pha
    jsr spawn_eb_aimed
    pla
    tax
@next3:
    jmp @next

@kill:
    lda #ET_NONE
    sta en_type,x
    jmp @next

; ------------------------------------------------------------
; enemies_update_v — vertical stage: everything dives from the
; top; turrets cling to the side walls and ride the scroll.
; ------------------------------------------------------------
enemies_update_v:
    ldx #NUM_EN-1
@loop:
    lda en_type,x
    bne @active
@next:
    dex
    bpl @loop
    rts
@active:
    inc en_t,x
    lda en_type,x
    cmp #ET_FAN
    beq @fan
    cmp #ET_DART
    beq @dart
    cmp #ET_TURRETB
    beq @turret
    cmp #ET_TURRETT
    beq @turret
    jmp @orb

; ---- FAN: sine-wave diver ----
@fan:
    ; y += 1.25
    lda en_yl,x
    clc
    adc #$40
    sta en_yl,x
    lda en_yh,x
    adc #1
    sta en_yh,x
    cmp #$E0
    bcs @killj
    ; x = base + sin(t*2)
    lda en_t,x
    asl
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    clc
    adc en_base,x
    sta en_xh,x
    jmp @next
@killj:
    jmp @kill

; ---- DART: cruise, then lunge at the player ----
@dart:
    lda en_t,x
    cmp #50
    bcc @dcruise
    ; lunge: y += 1.75, home x at 1 px/f
    lda en_yl,x
    clc
    adc #$C0
    sta en_yl,x
    lda en_yh,x
    adc #1
    sta en_yh,x
    cmp #$E0
    bcs @killj
    lda en_xh,x
    cmp plxh
    beq @next2
    bcc :+
    dec en_xh,x
    jmp @next2
:   inc en_xh,x
    jmp @next2
@dcruise:
    ; y += 0.5
    lda en_yl,x
    clc
    adc #$80
    sta en_yl,x
    lda en_yh,x
    adc #0
    sta en_yh,x
    cmp #$E0
    bcs @killj
@next2:
    jmp @next

; ---- TURRET: glued to the wall, fires aimed shots ----
@turret:
    ; ride the scroll down (0.75 px/f)
    lda en_yl,x
    clc
    adc #SCROLL_SPD
    sta en_yl,x
    lda en_yh,x
    adc #0
    sta en_yh,x
    cmp #$E0
    bcc :+
    jmp @kill
:
    ; fire on a difficulty-scaled period
    lda difficulty
    asl
    asl
    asl
    sta tmp1
    lda #120
    sec
    sbc tmp1                    ; 120 - 8*diff
    cmp en_t,x
    bcs @next2
    lda #0
    sta en_t,x
    lda en_xh,x
    clc
    adc #8
    sta tmp3
    lda en_yh,x
    clc
    adc #8
    sta tmp4
    txa
    pha
    jsr spawn_eb_aimed
    pla
    tax
    jmp @next

; ---- ORB: slow sinker, aimed shots ----
@orb:
    ; y += 0.75
    lda en_yl,x
    clc
    adc #$C0
    sta en_yl,x
    lda en_yh,x
    adc #0
    sta en_yh,x
    cmp #$E0
    bcs @kill
    ; slow sine sway
    lda en_t,x
    and #$3F
    tay
    lda sintab,y
    sec
    sbc #32
    cmp #$80
    ror                         ; /2 signed
    clc
    adc en_base,x
    sta en_xh,x
    ; fire every 96 frames
    lda en_t,x
    cmp #96
    bcc @next3
    lda #0
    sta en_t,x
    lda en_xh,x
    clc
    adc #4
    sta tmp3
    lda en_yh,x
    clc
    adc #6
    sta tmp4
    txa
    pha
    jsr spawn_eb_aimed
    pla
    tax
@next3:
    jmp @next

@kill:
    lda #ET_NONE
    sta en_type,x
    jmp @next

; ------------------------------------------------------------
; enemy_die — X = slot; explosion, score, capsule drop
; ------------------------------------------------------------
enemy_die:
    ; capture slot data first — the helpers below clobber X
    lda en_flags,x
    and #ENF_CAP
    sta tmp5
    lda en_type,x
    tay
    lda enemy_score,y
    sta tmp6
    lda en_xh,x
    sta tmp3
    lda en_yh,x
    sta tmp4
    lda #ET_NONE
    sta en_type,x
    txa
    pha
    jsr spawn_explosion
    jsr sfx_boom
    lda tmp6
    ldx #2                      ; hundreds digit
    jsr add_score
    lda tmp5
    beq :+
    jsr spawn_capsule           ; tmp3/tmp4 still hold the position
:   pla
    tax
    rts
