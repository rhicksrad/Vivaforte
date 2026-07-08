; ============================================================
; game.s — game states: title, gameplay, stage clear, game over
; ============================================================

; ------------------------------------------------------------
; TITLE SCREEN
; ------------------------------------------------------------
title_setup:
    jsr render_off
    lda #0
    sta gstate                  ; ST_TITLE
    sta paused
    sta strpend
    sta colpend
    sta hudpend
    sta scroll16
    sta scroll16+1
    jsr music_stop
    jsr clear_nametables

    ; sprinkle a starfield into nametable 0
    ldx #48
@star:
    jsr rng
    and #$03
    clc
    adc #$20                    ; addr hi $20-$22 (avoid attribute table)
    cmp #$23
    bcs @skipst
    sta tmp1
    jsr rng
    sta tmp2
    bit PPUSTATUS
    lda tmp1
    sta PPUADDR
    lda tmp2
    sta PPUADDR
    txa
    and #$01
    clc
    adc #T_STAR1
    sta PPUDATA
@skipst:
    dex
    bne @star

    ; title text
    lda #<str_title
    sta ptr1
    lda #>str_title
    sta ptr1+1
    lda #$21                    ; row 8, col 11  = $2000 + 8*32 + 11 = $210B
    ldx #$0B
    jsr ppu_string

    lda #<str_subtitle
    sta ptr1
    lda #>str_subtitle
    sta ptr1+1
    lda #$21                    ; row 11, col 5 = $2165
    ldx #$65
    jsr ppu_string

    lda #<str_press
    sta ptr1
    lda #>str_press
    sta ptr1+1
    lda #$22                    ; row 17, col 10 = $2000+17*32+10 = $222A
    ldx #$2A
    jsr ppu_string

    lda #<str_copy
    sta ptr1
    lda #>str_copy
    sta ptr1+1
    lda #$23                    ; row 25, col 9 = $2000+25*32+9 = $2329
    ldx #$29
    jsr ppu_string

    ; hi-score line, row 20 col 11 = $2000+20*32+11 = $228B
    bit PPUSTATUS
    lda #$22
    sta PPUADDR
    lda #$8B
    sta PPUADDR
    lda #('H'-$20)
    sta PPUDATA
    lda #('I'-$20)
    sta PPUDATA
    lda #T_BLANK
    sta PPUDATA
    ldx #5
:   lda hiscore,x
    clc
    adc #$10                    ; digit tiles at $10
    sta PPUDATA
    dex
    bpl :-

    ; reset scroll
    bit PPUSTATUS
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL
    sta blink_t
    jsr oam_clear               ; no sprite 0 needed on title, all offscreen
    jsr render_on
    rts

; ------------------------------------------------------------
title_frame:
    jsr read_pads
    inc blink_t

    ; blink PRESS START via string buffer
    lda blink_t
    and #$1F
    bne @noblink
    lda strpend
    bne @noblink
    lda #$22
    sta strbuf_ah
    lda #$2A
    sta strbuf_al
    lda #11
    sta strbuf_len
    lda blink_t
    and #$20
    beq @showtext
    ldx #10                     ; blank it
    lda #T_BLANK
:   sta strbuf,x
    dex
    bpl :-
    jmp @setpend
@showtext:
    ldx #10
:   lda str_press+1,x
    sec
    sbc #$20
    sta strbuf,x
    dex
    bpl :-
@setpend:
    lda #1
    sta strpend
@noblink:

    ; demo ship bobbing on the title
    jsr oam_clear
    lda blink_t
    and #$7F
    lsr
    tax
    lda sintab,x
    lsr
    lsr
    clc
    adc #148
    sta sp_y
    lda #48
    sta sp_x
    lda #SPT_SHIP_L
    sta sp_tile
    lda #0
    sta sp_attr
    jsr put_sprite16

    lda pad_new
    and #BTN_START
    beq @done
    jsr game_setup
@done:
    rts

; ------------------------------------------------------------
; GAME SETUP — start a new game
; ------------------------------------------------------------
game_setup:
    jsr render_off
    jsr clear_nametables

    ; zero score, entities, player state
    ldx #5
    lda #0
:   sta score,x
    dex
    bpl :-
    ldx #NUM_PB-1
:   sta pb_type,x
    dex
    bpl :-
    ldx #NUM_EN-1
:   sta en_type,x
    dex
    bpl :-
    ldx #NUM_EB-1
:   sta eb_on,x
    dex
    bpl :-
    ldx #NUM_CAP-1
:   sta cap_on,x
    dex
    bpl :-
    ldx #NUM_EX-1
:   sta ex_t,x
    dex
    bpl :-
    sta pl_speed
    sta pl_weapon
    sta pl_missile
    sta pl_opts
    sta pl_shield
    sta pl_dead
    sta meter
    sta fire_cd
    sta miss_cd
    sta scroll_sub
    sta scroll16
    sta scroll16+1
    sta paused
    sta difficulty
    sta colpend
    sta strpend
    sta hudpend
    sta boss_dying
    sta wv_mode
    lda #3
    sta pl_lives
    lda #120
    sta pl_invuln
    lda #$10
    sta plxh
    lda #112
    sta plyh
    lda #0
    sta plxl
    sta plyl
    sta hist_idx
    ; fill history with spawn pos so options don't streak
    ldx #63
    lda #$10
:   sta hist_x,x
    dex
    bpl :-
    ldx #63
    lda #112
:   sta hist_y,x
    dex
    bpl :-

    ; wave table
    lda #<wave_table
    sta wv_ptr
    lda #>wave_table
    sta wv_ptr+1
    lda #90
    sta wv_wait
    lda #0
    sta wv_left

    jsr terrain_init            ; generator state + first 64 columns into VRAM
    jsr hud_init                ; static HUD text + divider row

    lda #1
    sta scdirty
    jsr hud_copy

    lda #ST_PLAY
    sta gstate
    jsr music_start
    jsr render_on
    rts

; ------------------------------------------------------------
; PLAY — one gameplay frame
; ------------------------------------------------------------
play_frame:
    inc frame
    jsr read_pads

    lda pad_new
    and #BTN_START
    beq @nopause
    lda paused
    eor #1
    sta paused
    jsr sfx_pause
    lda paused
    beq @nopause                ; just unpaused: resume normally
    jsr build_oam               ; freeze this frame with the PAUSE banner
@nopause:
    lda paused
    beq :+
    rts                         ; frozen (NMI keeps OAM/scroll as-is)
:
    ; scroll advance: scroll16 += 0.75 px
    lda scroll_sub
    clc
    adc #SCROLL_SPD
    sta scroll_sub
    bcc :+
    inc scroll16
    bne :+
    inc scroll16+1
:
    jsr terrain_gen_check
    jsr spawner_update
    jsr player_update
    jsr pbullets_update
    jsr enemies_update
    jsr boss_update
    jsr ebullets_update
    jsr capsules_update
    jsr explosions_update
    jsr collide_all
    jsr hud_copy
    jsr build_oam
    rts

; ------------------------------------------------------------
; STAGE CLEAR — brief interlude, then loop harder
; ------------------------------------------------------------
clear_frame:
    inc frame
    jsr read_pads
    ; keep world scrolling
    lda scroll_sub
    clc
    adc #SCROLL_SPD
    sta scroll_sub
    bcc :+
    inc scroll16
    bne :+
    inc scroll16+1
:
    jsr terrain_gen_check
    jsr player_update
    jsr pbullets_update
    jsr explosions_update
    jsr hud_copy
    jsr build_oam               ; overlay text drawn inside, first

    dec gtimer
    bne @done
    dec gtimer2
    bne @done
    ; resume: next loop
    inc difficulty
    lda difficulty
    cmp #7
    bcc :+
    lda #6
    sta difficulty
:   lda #<wave_table
    sta wv_ptr
    lda #>wave_table
    sta wv_ptr+1
    lda #180
    sta wv_wait
    lda #0
    sta wv_left
    sta wv_mode
    lda #ST_PLAY
    sta gstate
    jsr music_start
@done:
    rts

; ------------------------------------------------------------
; GAME OVER
; ------------------------------------------------------------
gameover_frame:
    jsr read_pads
    jsr explosions_update
    jsr hud_copy
    jsr build_oam               ; overlay text drawn inside, first

    dec gtimer
    bne @wait
    dec gtimer2
    beq @totitle
@wait:
    lda pad_new
    and #BTN_START
    beq @done
@totitle:
    jsr title_setup
@done:
    rts

; ------------------------------------------------------------
; enter game over (called when last life lost)
; ------------------------------------------------------------
enter_gameover:
    lda #ST_GAMEOVER
    sta gstate
    lda #0
    sta gtimer
    lda #2                      ; ~8.5 s or START
    sta gtimer2
    jsr music_stop
    ; update hi-score
    ldx #5
:   lda score,x
    cmp hiscore,x
    bcc @nohi
    bne @newhi
    dex
    bpl :-
    rts
@newhi:
    ldx #5
:   lda score,x
    sta hiscore,x
    dex
    bpl :-
@nohi:
    rts

; ------------------------------------------------------------
; WAVE SPAWNER
; ------------------------------------------------------------
spawner_update:
    lda wv_mode
    beq @table
    rts                         ; boss handles itself
@table:
    lda wv_wait
    beq :+
    dec wv_wait
    rts
:
    lda wv_left
    bne @spawn_next
    ; fetch next table entry: delay, type, y, count, gap, flags
    ldy #0
    lda (wv_ptr),y
    sta wv_wait
    iny
    lda (wv_ptr),y
    cmp #$FF
    bne @notboss
    ; ---- boss time ----
    lda #1
    sta wv_mode
    jsr boss_spawn
    rts
@notboss:
    sta wv_type
    iny
    lda (wv_ptr),y
    sta wv_y
    iny
    lda (wv_ptr),y
    sta wv_left
    iny
    lda (wv_ptr),y
    sta wv_gap
    iny
    lda (wv_ptr),y
    sta wv_flags
    ; advance pointer by 6
    lda wv_ptr
    clc
    adc #6
    sta wv_ptr
    bcc :+
    inc wv_ptr+1
:   rts

@spawn_next:
    jsr spawn_enemy
    dec wv_left
    lda wv_gap
    sta wv_wait
    rts

; ------------------------------------------------------------
; spawn_enemy — spawn one enemy of wv_type at right edge
; ------------------------------------------------------------
spawn_enemy:
    ; find free slot
    ldx #NUM_EN-1
:   lda en_type,x
    beq @found
    dex
    bpl :-
    rts                         ; no slot free
@found:
    lda wv_type
    sta en_type,x
    lda #0
    sta en_t,x
    sta en_xl,x
    sta en_yl,x
    sta en_flags,x
    lda #$F8
    sta en_xh,x

    ; capsule carrier: last enemy of a flagged wave
    lda wv_flags
    and #ENF_CAP
    beq :+
    lda wv_left
    cmp #1
    bne :+
    lda #ENF_CAP
    sta en_flags,x
:
    ; hp + y by type
    lda wv_type
    cmp #ET_FAN
    bne :+
    lda #1
    sta en_hp,x
    lda wv_y
    sta en_base,x
    sta en_yh,x
    rts
:   cmp #ET_DART
    bne :+
    lda #1
    sta en_hp,x
    jsr rng
    and #$1F
    clc
    adc wv_y
    sta en_yh,x
    rts
:   cmp #ET_TURRETB
    bne :+
    lda #3
    sta en_hp,x
    jsr terrain_floor_y         ; A = y of floor top at right edge
    sec
    sbc #16
    sta en_yh,x
    rts
:   cmp #ET_TURRETT
    bne :+
    lda #3
    sta en_hp,x
    jsr terrain_ceil_y          ; A = y just below ceiling at right edge
    sta en_yh,x
    rts
:   ; ET_ORB
    lda #2
    clc
    adc difficulty
    sta en_hp,x
    lda wv_y
    sta en_base,x
    sta en_yh,x
    rts
