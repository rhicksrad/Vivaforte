; ============================================================
; sound.s — APU driver: looping music + sound effects
;   pulse1: player shot (hardware sweep does the work)
;   pulse2: melody, borrowed for pickup/activate jingles
;   triangle: bassline
;   noise: drums, borrowed for explosions
; ============================================================

music_start:
    lda #1
    sta mus_on
    lda #0
    sta mus_tick
    sta mus_step
    rts

music_stop:
    lda #0
    sta mus_on
    lda #$80
    sta TRI_LINEAR
    lda #$30
    sta SQ2_VOL
    rts

sfx_pause:
    lda #$30                    ; choke channels; music resumes on unpause
    sta SQ1_VOL
    sta SQ2_VOL
    sta NOI_VOL
    lda #$80
    sta TRI_LINEAR
    rts

; ------------------------------------------------------------
; sound_update — called every NMI
; ------------------------------------------------------------
sound_update:
    lda paused
    beq :+
    rts
:
    ; ---- sfx timers ----
    lda sq1_sfx
    beq :+
    dec sq1_sfx
:
    lda noi_sfx
    beq :+
    dec noi_sfx
:
    lda sq2_sfx
    beq @no_sq2
    dec sq2_sfx
    ; jingle: rising arpeggio, period from table every 4 frames
    lda sq2_sfx
    lsr
    lsr
    tay                         ; 0..2
    lda sq2_kind
    beq :+
    lda arp_hi_tbl,y
    jmp :++
:   lda arp_lo_tbl,y
:   sta SQ2_LO
    lda #$00
    sta SQ2_HI
    lda #$7A                    ; duty 25%, constant vol 10
    sta SQ2_VOL
@no_sq2:

    ; ---- music ----
    lda mus_on
    bne :+
    rts
:   dec mus_tick
    bmi :+
    rts
:   lda #6                      ; 7 frames per step
    sta mus_tick
    ldx mus_step
    inx
    cpx #32
    bcc :+
    ldx #0
:   stx mus_step

    ; triangle bass
    lda bass_pat,x
    beq @bassoff
    tay
    lda note_lo,y
    sta TRI_LO
    lda note_hi,y
    sta TRI_HI
    lda #$FF                    ; linear counter max, halt length
    sta TRI_LINEAR
    jmp @drums
@bassoff:
    lda #$80
    sta TRI_LINEAR

@drums:
    ; noise drums (skip while an explosion owns the channel)
    lda noi_sfx
    bne @melody
    lda drum_pat,x
    beq @melody
    cmp #1
    bne @hat
    lda #$06                    ; kick: fast decay envelope
    sta NOI_VOL
    lda #$0B
    sta NOI_LO
    lda #$08
    sta NOI_HI
    jmp @melody
@hat:
    lda #$03
    sta NOI_VOL
    lda #$02
    sta NOI_LO
    lda #$08
    sta NOI_HI

@melody:
    ; pulse2 melody (skip while a jingle owns the channel)
    lda sq2_sfx
    bne @done
    ldx mus_step
    lda mel_pat,x
    beq @meloff
    tay
    lda note_lo,y
    sta SQ2_LO
    lda note_hi,y
    ora #$08                    ; short length load
    sta SQ2_HI
    lda #$B4                    ; duty 50%, envelope decay 4
    sta SQ2_VOL
    jmp @done
@meloff:
    lda #$30
    sta SQ2_VOL
@done:
    rts
@sustain:
    rts

; ------------------------------------------------------------
; SFX triggers (X-register safe)
; ------------------------------------------------------------
sfx_shoot:
    lda #$46                    ; duty 25%, envelope decay 6
    sta SQ1_VOL
    lda #$83                    ; sweep: enabled, fastest, pitch falls
    sta SQ1_SWEEP
    lda #$60
    sta SQ1_LO
    lda #$00
    sta SQ1_HI
    lda #6
    sta sq1_sfx
    rts

sfx_boom:
    lda #$07
    sta NOI_VOL
    lda #$0D
    sta NOI_LO
    lda #$08                    ; long length; envelope does the fade
    sta NOI_HI
    lda #24
    sta noi_sfx
    rts

sfx_bigboom:
    lda #$05
    sta NOI_VOL
    lda #$0F
    sta NOI_LO
    lda #$08
    sta NOI_HI
    lda #60
    sta noi_sfx
    rts

sfx_hit:
    lda #$04
    sta NOI_VOL
    lda #$06
    sta NOI_LO
    lda #$08
    sta NOI_HI
    lda #8
    sta noi_sfx
    rts

sfx_pickup:
    lda #0
    sta sq2_kind
    lda #12
    sta sq2_sfx
    rts

sfx_activate:
    lda #1
    sta sq2_kind
    lda #12
    sta sq2_sfx
    rts
