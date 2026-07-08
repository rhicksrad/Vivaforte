; ============================================================
; hud.s — HUD, score, OAM building, sprite text
; ============================================================

; ------------------------------------------------------------
; hud_init — static HUD text + divider (rendering off)
; ------------------------------------------------------------
hud_init:
    lda #<str_score
    sta ptr1
    lda #>str_score
    sta ptr1+1
    lda #$20
    ldx #$01
    jsr ppu_string
    lda #<str_hi
    sta ptr1
    lda #>str_hi
    sta ptr1+1
    lda #$20
    ldx #$10
    jsr ppu_string
    ; ship-stock icon '*' at col 26
    bit PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$1A
    sta PPUADDR
    lda #('*'-$20)
    sta PPUDATA
    ; divider line across row 1
    bit PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$20
    sta PPUADDR
    lda #T_DIV
    ldx #32
:   sta PPUDATA
    dex
    bne :-
    rts

; ------------------------------------------------------------
; add_score — X = digit index (0=ones), A = amount 0..9
; ------------------------------------------------------------
add_score:
    clc
    adc score,x
@chk:
    cmp #10
    bcc @store
    sec
    sbc #10
    sta score,x
    inx
    cpx #6
    bcs @done
    lda score,x
    clc
    adc #1
    jmp @chk
@store:
    sta score,x
@done:
    lda #1
    sta scdirty
    rts

; ------------------------------------------------------------
; hud_copy — snapshot digits into hudbuf for the NMI
; ------------------------------------------------------------
hud_copy:
    ldx #0
    ldy #5
:   lda score,y
    clc
    adc #$10
    sta hudbuf,x
    inx
    dey
    bpl :-
    ldy #5
:   lda hiscore,y
    clc
    adc #$10
    sta hudbuf,x
    inx
    dey
    bpl :-
    lda pl_lives
    clc
    adc #$10
    sta hudbuf+12
    lda #1
    sta hudpend
    lda #0
    sta scdirty
    rts

; ------------------------------------------------------------
; oam_clear — hide all sprites, reset allocator past sprite 0
; ------------------------------------------------------------
oam_clear:
    lda #$F0
    ldx #0
:   sta OAMBUF,x
    inx
    inx
    inx
    inx
    bne :-
    lda #4
    sta oam_ptr
    rts

; ------------------------------------------------------------
; put_sprite — one 8x16 sprite from sp_y/sp_tile/sp_attr/sp_x
; put_sprite16 — a 16x16 object (two sprites, tiles T and T+2)
; ------------------------------------------------------------
put_sprite:
    ldx oam_ptr
    beq @full                   ; wrapped: OAM exhausted
    lda sp_y
    sec
    sbc #1
    sta OAMBUF,x
    inx
    lda sp_tile
    sta OAMBUF,x
    inx
    lda sp_attr
    sta OAMBUF,x
    inx
    lda sp_x
    sta OAMBUF,x
    inx
    stx oam_ptr
@full:
    rts

put_sprite16:
    jsr put_sprite
    lda sp_tile
    pha
    lda sp_x
    pha
    clc
    adc #8
    sta sp_x
    lda sp_tile
    clc
    adc #2
    sta sp_tile
    jsr put_sprite
    pla
    sta sp_x
    pla
    sta sp_tile
    rts

; ------------------------------------------------------------
; sprite_text — ptr1 = length-prefixed list of OAM tile bytes
; ($00 = space), tmp1 = x, tmp2 = y
; ------------------------------------------------------------
sprite_text:
    ldy #0
    lda (ptr1),y
    sta tmp3                    ; length
    lda tmp2
    sta sp_y
    lda #0
    sta sp_attr
@loop:
    iny
    lda (ptr1),y
    beq @space
    sta sp_tile
    lda tmp1
    sta sp_x
    tya
    pha
    jsr put_sprite
    pla
    tay
@space:
    lda tmp1
    clc
    adc #8
    sta tmp1
    cpy tmp3
    bne @loop
    rts

; ------------------------------------------------------------
; build_oam — rebuild the sprite list for one frame
; ------------------------------------------------------------
build_oam:
    jsr oam_clear
    ; sprite 0: hidden strip overlapping the HUD divider
    lda #$0D
    sta OAMBUF+0
    lda #SPT_S0
    sta OAMBUF+1
    lda #%00100000              ; behind background
    sta OAMBUF+2
    lda #$08
    sta OAMBUF+3

    jsr draw_overlay_text       ; lowest OAM slots: wins scanline priority

    lda frame
    and #$01
    bne @odd
    jsr draw_player
    jsr draw_options
    jsr draw_pbullets
    jsr draw_enemies
    jsr draw_boss
    jsr draw_ebullets
    jsr draw_capsules
    jsr draw_explosions
    jmp @meter
@odd:
    jsr draw_ebullets
    jsr draw_boss
    jsr draw_enemies
    jsr draw_pbullets
    jsr draw_capsules
    jsr draw_explosions
    jsr draw_player
    jsr draw_options
@meter:
    jsr draw_meter
    rts

; ------------------------------------------------------------
; draw_overlay_text — state banners ("STAGE CLEAR", "GAME OVER")
; ------------------------------------------------------------
draw_overlay_text:
    lda paused
    beq :+
    lda #108
    sta tmp1
    lda #110
    sta tmp2
    lda #<sstr_pause
    sta ptr1
    lda #>sstr_pause
    sta ptr1+1
    jmp sprite_text
:   lda gstate
    cmp #ST_CLEAR
    beq @clear
    cmp #ST_GAMEOVER
    beq @go
    rts
@clear:
    lda #108
    sta tmp1
    lda #100
    sta tmp2
    lda #<sstr_stage
    sta ptr1
    lda #>sstr_stage
    sta ptr1+1
    jsr sprite_text
    lda #108
    sta tmp1
    lda #122
    sta tmp2
    lda #<sstr_clear
    sta ptr1
    lda #>sstr_clear
    sta ptr1+1
    jmp sprite_text
@go:
    lda #96
    sta tmp1
    lda #110
    sta tmp2
    lda #<sstr_gameover
    sta ptr1
    lda #>sstr_gameover
    sta ptr1+1
    jmp sprite_text

; ------------------------------------------------------------
draw_player:
    lda pl_dead
    beq :+
    rts
:   lda pl_invuln
    beq @show
    lda frame
    and #$02
    beq @show
    rts
@show:
    lda plyh
    sta sp_y
    lda plxh
    sta sp_x
    lda #SPT_SHIP_L
    sta sp_tile
    lda #0
    ldy pl_shield
    beq :+
    lda #1                      ; shielded: orange palette
:   sta sp_attr
    jmp put_sprite16

; ------------------------------------------------------------
draw_options:
    lda pl_dead
    beq :+
    rts
:   lda pl_opts
    bne :+
    rts
:   lda hist_idx
    sec
    sbc #20
    and #$3F
    tax
    lda hist_x,x
    sta sp_x
    lda hist_y,x
    sta sp_y
    lda #SPT_OPTION
    sta sp_tile
    lda #1
    sta sp_attr
    jsr put_sprite
    lda pl_opts
    cmp #2
    bcs :+
    rts
:   lda hist_idx
    sec
    sbc #40
    and #$3F
    tax
    lda hist_x,x
    sta sp_x
    lda hist_y,x
    sta sp_y
    lda #SPT_OPTION
    sta sp_tile
    jmp put_sprite

; ------------------------------------------------------------
draw_pbullets:
    ldx #NUM_PB-1
@loop:
    lda pb_type,x
    beq @next
    cmp #PBT_LASER
    beq @laser
    cmp #PBT_BULLET
    beq @bullet
    lda #SPT_MISSILE            ; both missile states
    ldy #1
    bne @set
@laser:
    lda #SPT_LASER
    ldy #0
    beq @set
@bullet:
    lda #SPT_PBUL
    ldy #0
@set:
    sta sp_tile
    sty sp_attr
    lda pb_xh,x
    sta sp_x
    lda pb_yh,x
    sta sp_y
    txa
    pha
    jsr put_sprite
    pla
    tax
@next:
    dex
    bpl @loop
    rts

; ------------------------------------------------------------
draw_enemies:
    ldx #NUM_EN-1
@loop:
    lda en_type,x
    beq @next
    tay
    lda enemy_tile,y
    sta sp_tile
    lda enemy_attr,y
    sta sp_attr
    lda en_xh,x
    sta sp_x
    lda en_yh,x
    sta sp_y
    txa
    pha
    jsr put_sprite16
    pla
    tax
@next:
    dex
    bpl @loop
    rts

; ------------------------------------------------------------
draw_boss:
    lda wv_mode
    cmp #1
    beq :+
    rts
:   lda boss_dying
    beq @solid
    and #$02                    ; strobe while dying
    beq @solid
    rts
@solid:
    lda #2                      ; enemy palette
    ldy boss_flash
    beq :+
    lda #1                      ; hit flash palette
:   sta sp_attr
    ; 8 sprites: 4 columns x 2 rows
    ldx #0                      ; column 0..3
@col:
    txa
    asl
    asl
    asl                         ; col*8
    clc
    adc boss_x
    sta sp_x
    lda boss_yh
    sta sp_y
    txa
    asl
    asl                        ; col*4 -> tile offset (2 pairs per column)
    clc
    adc #SPT_BOSS
    sta sp_tile
    txa
    pha
    jsr put_sprite
    lda sp_tile
    clc
    adc #2
    sta sp_tile
    lda boss_yh
    clc
    adc #16
    sta sp_y
    jsr put_sprite
    pla
    tax
    inx
    cpx #4
    bne @col
    rts

; ------------------------------------------------------------
draw_ebullets:
    lda #SPT_EBUL
    sta sp_tile
    lda #2
    sta sp_attr
    ldx #NUM_EB-1
@loop:
    lda eb_on,x
    beq @next
    lda eb_xh,x
    sta sp_x
    lda eb_yh,x
    sta sp_y
    txa
    pha
    jsr put_sprite
    pla
    tax
@next:
    dex
    bpl @loop
    rts

; ------------------------------------------------------------
draw_capsules:
    lda #SPT_CAPSULE
    sta sp_tile
    lda #1
    sta sp_attr
    ldx #NUM_CAP-1
@loop:
    lda cap_on,x
    beq @next
    lda cap_x,x
    sta sp_x
    lda cap_y,x
    sta sp_y
    txa
    pha
    jsr put_sprite
    pla
    tax
@next:
    dex
    bpl @loop
    rts

; ------------------------------------------------------------
draw_explosions:
    ldx #NUM_EX-1
@loop:
    lda ex_t,x
    beq @next
    cmp #9
    bcs @framea
    lda #SPT_EXPB_L
    bne @set
@framea:
    lda #SPT_EXPA_L
@set:
    sta sp_tile
    lda #1
    sta sp_attr
    lda ex_x,x
    sta sp_x
    lda ex_y,x
    sta sp_y
    txa
    pha
    jsr put_sprite16
    pla
    tax
@next:
    dex
    bpl @loop
    rts

; ------------------------------------------------------------
draw_meter:
    lda #214
    sta sp_y
    ldx #0
@loop:
    txa
    pha
    ; x position: 56 + i*24
    lda mul24,x
    clc
    adc #56
    sta sp_x
    txa
    asl
    clc
    adc #SPT_LET_S
    sta sp_tile
    ; palette: selected slot glows
    inx                         ; compare against 1-based meter
    cpx meter
    beq @sel
    lda #3                      ; dim
    bne @attr
@sel:
    lda frame
    and #$08
    beq @selon
    lda #3
    bne @attr
@selon:
    lda #1
@attr:
    sta sp_attr
    jsr put_sprite
    pla
    tax
    inx
    cpx #6
    bne @loop
    rts
