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
    sta vmode
    lda #CTRL_BASE
    sta ctrl_top
    lda #$20
    sta hud_hi
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
    beq @nostart
    lda #0
    sta stage_req
    jmp game_setup
@nostart:
    lda pad_new
    and #BTN_SELECT             ; dev/practice shortcut: begin at stage 2
    beq @done
    lda #1
    sta stage_req
    jmp game_setup
@done:
    rts

; ------------------------------------------------------------
; GAME SETUP — start a new game at stage `stage_req`
; ------------------------------------------------------------
game_setup:
    ldx #5
    lda #0
:   sta score,x
    dex
    bpl :-
    sta pl_speed
    sta pl_weapon
    sta pl_missile
    sta pl_opts
    sta pl_shield
    sta meter
    sta fire_cd
    sta miss_cd
    sta hist_idx
    lda stage_req
    sta stage
    sta difficulty
    lda #3
    sta pl_lives
    ; fall through into stage_start

; ------------------------------------------------------------
; STAGE START — (re)build the world for `stage`. Keeps score,
; lives and power-ups; resets scroll, terrain and entities.
; Even stages scroll horizontally, odd stages vertically; all
; per-stage data comes from the stage6-indexed tables.
; ------------------------------------------------------------
stage_start:
    jsr render_off
    jsr clear_nametables

    jsr stage_mod6
    sta stage6
    lda stage
    and #$01
    sta vmode

    jsr clear_entities
    lda #16
    sta vscr                    ; (16 - scroll16) mod 240
    lda #120
    sta pl_invuln

    ; per-mode setup: HUD nametable + spawn point
    lda vmode
    bne @vert
    lda #$20
    sta hud_hi
    lda #CTRL_BASE
    sta ctrl_top
    lda #$10
    sta plxh
    lda #112
    sta plyh
    jmp @common
@vert:
    lda #$24
    sta hud_hi
    lda #CTRL_BASE|$01          ; HUD strip reads nametable 1
    sta ctrl_top
    lda #$78
    sta plxh
    lda #$C8
    sta plyh
@common:
    ; per-stage data: waves + terrain
    ldy stage6
    lda stage_wave_lo,y
    sta wv_ptr
    lda stage_wave_hi,y
    sta wv_ptr+1
    lda stage_segs_lo,y
    sta seg_base
    lda stage_segs_hi,y
    sta seg_base+1
    jsr refill_hist
    lda #90
    sta wv_wait
    lda #0
    sta wv_left

    jsr load_palettes           ; stage palette (stage6-indexed)
    jsr terrain_init            ; generator state + initial screen into VRAM
    jsr hud_init                ; static HUD text + divider row

    lda #1
    sta scdirty
    jsr hud_copy

    lda #ST_PLAY
    sta gstate
    lda vmode                   ; track 0 horizontal, 1 vertical
    jsr music_start
    jsr render_on
    rts

; ------------------------------------------------------------
; stage_mod6 — A = stage mod NUM_STAGES
; ------------------------------------------------------------
stage_mod6:
    lda stage
:   cmp #NUM_STAGES
    bcc :+
    sbc #NUM_STAGES             ; carry known set
    jmp :-
:   rts

; ------------------------------------------------------------
; clear_entities — wipe bullets/enemies/capsules/explosions and
; the transient scroll + mailbox state (A left 0)
; ------------------------------------------------------------
clear_entities:
    lda #0
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
    sta pl_dead
    sta scroll_sub
    sta scroll16
    sta scroll16+1
    sta paused
    sta colpend
    sta strpend
    sta hudpend
    sta boss_dying
    sta wv_mode
    rts

; ------------------------------------------------------------
; refill_hist — fill the option trail with the spawn position
; ------------------------------------------------------------
refill_hist:
    lda #0
    sta plxl
    sta plyl
    ldx #63
    lda plxh
:   sta hist_x,x
    dex
    bpl :-
    ldx #63
    lda plyh
:   sta hist_y,x
    dex
    bpl :-
    rts

; ------------------------------------------------------------
; scroll_advance — push the world 0.75 px; vertical stages also
; track the PPU Y scroll for the split (steps down, wraps at 240)
; ------------------------------------------------------------
scroll_advance:
    lda scroll_sub
    clc
    adc #SCROLL_SPD
    sta scroll_sub
    bcc @out
    inc scroll16
    bne :+
    inc scroll16+1
:   lda vmode
    beq @out
    lda vscr
    bne :+
    lda #240
:   sec
    sbc #1
    sta vscr
@out:
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
    jsr scroll_advance
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
    jsr scroll_advance
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
    ; next stage: alternate horizontal / vertical, ramp difficulty
    inc stage
    lda difficulty
    cmp #6
    bcs :+
    inc difficulty
:   jsr stage_mod6              ; finished the last stage? roll credits
    tax                         ; set Z from the result, not the last cmp
    bne :+
    jsr credits_setup
    rts
:   jsr stage_start
@done:
    rts

; ------------------------------------------------------------
; CREDITS — victory lap: open space, drifting staff-roll text,
; and a fan shooting gallery for bonus score
; ------------------------------------------------------------
credits_setup:
    jsr render_off
    jsr clear_nametables

    lda #0
    sta vmode
    sta stage6                  ; finale flies through stage-1 blues
    jsr clear_entities
    lda #16
    sta vscr
    lda #120
    sta pl_invuln
    lda #$20
    sta hud_hi
    lda #CTRL_BASE
    sta ctrl_top
    lda #$10
    sta plxh
    lda #112
    sta plyh
    jsr refill_hist

    lda #<wave_table_c
    sta wv_ptr
    lda #>wave_table_c
    sta wv_ptr+1
    lda #<terrain_segs_c
    sta seg_base
    lda #>terrain_segs_c
    sta seg_base+1
    lda #90
    sta wv_wait
    lda #0
    sta wv_left

    ; staff roll state + duration (~75 s)
    lda #<cred_lines
    sta cred_ptr
    lda #>cred_lines
    sta cred_ptr+1
    lda #120
    sta cred_timer
    lda #0
    sta cred_row
    sta gtimer
    lda #18
    sta gtimer2

    jsr load_palettes
    jsr terrain_init
    jsr hud_init
    lda #1
    sta scdirty
    jsr hud_copy

    lda #ST_CREDITS
    sta gstate
    lda #2                      ; credits theme
    jsr music_start
    jsr render_on
    rts

; ------------------------------------------------------------
credits_frame:
    inc frame
    jsr read_pads
    jsr scroll_advance
    jsr terrain_gen_check
    jsr credits_text
    jsr spawner_update
    jsr player_update
    jsr pbullets_update
    jsr enemies_update
    jsr capsules_update
    jsr explosions_update
    jsr col_pb_targets          ; targets are shootable but harmless
    jsr col_cap_player
    jsr hud_copy
    jsr build_oam

    dec gtimer
    bne @done
    dec gtimer2
    bne @done
    jsr title_setup
@done:
    rts

; ------------------------------------------------------------
; credits_text — queue the next staff-roll line just off the
; right screen edge so it scrolls in with the starfield
; ------------------------------------------------------------
credits_text:
    lda strpend
    beq :+
    rts
:   lda cred_timer
    beq @try
    dec cred_timer
    rts
@try:
    ldy #0
    lda (cred_ptr),y
    bne :+
    rts                         ; list finished; timer runs the exit
:   sta tmp5                    ; line length
    ; column just past the right edge = scroll/8 + 33
    lda scroll16
    sta tmp1
    lda scroll16+1
    sta tmp2
    lsr tmp2
    ror tmp1
    lsr tmp2
    ror tmp1
    lsr tmp2
    ror tmp1
    lda tmp1
    clc
    adc #33
    sta tmp1                    ; column (64-wide world, wraps)
    ; the line must fit inside one nametable: (col & 31) + len <= 32
    and #$1F
    clc
    adc tmp5
    cmp #33
    bcc @fits
    rts                         ; wait for alignment
@fits:
    ; PPU address: nametable from column bit 5, alternating rows 10/16
    lda tmp1
    and #$20
    lsr
    lsr
    lsr
    clc
    adc #$20
    sta strbuf_ah
    lda cred_row
    eor #1
    sta cred_row
    bne @row10
    lda strbuf_ah               ; row 16: base + $200 + col
    clc
    adc #2
    sta strbuf_ah
    lda tmp1
    and #$1F
    sta strbuf_al
    jmp @copy
@row10:
    lda strbuf_ah               ; row 10: base + $140 + col
    clc
    adc #1
    sta strbuf_ah
    lda tmp1
    and #$1F
    clc
    adc #$40
    sta strbuf_al
@copy:
    lda tmp5
    sta strbuf_len
    ldy #0
:   iny
    lda (cred_ptr),y
    sec
    sbc #$20                    ; ascii -> tile
    sta strbuf-1,y
    cpy tmp5
    bne :-
    ; advance to the next line (len + 1 bytes)
    lda cred_ptr
    sec                         ; +1 for the length byte
    adc tmp5
    sta cred_ptr
    bcc :+
    inc cred_ptr+1
:   lda #1
    sta strpend
    lda #255                    ; ~4.3 s between lines
    sta cred_timer
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
    lda vmode
    beq :+
    jmp spawn_enemy_v
:   lda #$F8
    sta en_xh,x

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

; ------------------------------------------------------------
; spawn_enemy_v — vertical stage: spawn at the top edge.
; X = slot (type/flags already set); wv_y holds the base x.
; Floor turrets become left-wall, ceiling turrets right-wall.
; ------------------------------------------------------------
spawn_enemy_v:
    lda #$10
    sta en_yh,x
    lda wv_type
    cmp #ET_FAN
    bne :+
    lda #1
    sta en_hp,x
    lda wv_y
    sta en_base,x
    sta en_xh,x
    rts
:   cmp #ET_DART
    bne :+
    lda #1
    sta en_hp,x
    jsr rng
    and #$1F
    clc
    adc wv_y
    sta en_xh,x
    rts
:   cmp #ET_TURRETB
    bne :+
    lda #3
    sta en_hp,x
    jsr terrain_left_x          ; sit on the left wall
    sta en_xh,x
    rts
:   cmp #ET_TURRETT
    bne :+
    lda #3
    sta en_hp,x
    jsr terrain_right_x         ; sit on the right wall
    sta en_xh,x
    rts
:   ; ET_ORB
    lda #2
    clc
    adc difficulty
    sta en_hp,x
    lda wv_y
    sta en_base,x
    sta en_xh,x
    rts
