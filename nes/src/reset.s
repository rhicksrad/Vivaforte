; ============================================================
; reset.s — power-on init, PPU helpers, palette load
; ============================================================

reset:
    sei
    cld
    ldx #$40
    stx JOY2                    ; APU frame counter: 4-step, IRQ off
    ldx #$FF
    txs
    inx                         ; X = 0
    stx PPUCTRL                 ; NMI off
    stx PPUMASK                 ; rendering off
    stx DMC_FREQ                ; DMC IRQ off
    bit PPUSTATUS

    ; first vblank wait
:   bit PPUSTATUS
    bpl :-

    ; clear RAM $0000-$07FF
    lda #0
    tax
:   sta $0000,x
    sta $0300,x
    sta $0400,x
    sta $0500,x
    sta $0600,x
    sta $0700,x
    inx
    bne :-
    ; OAM buffer: everything offscreen
    lda #$F0
:   sta OAMBUF,x
    inx
    bne :-

    ; second vblank wait — PPU is warmed up after this
:   bit PPUSTATUS
    bpl :-

    ; APU: enable pulse1, pulse2, triangle, noise
    lda #%00001111
    sta APU_STATUS
    lda #$30                    ; constant volume 0 (silent)
    sta SQ1_VOL
    sta SQ2_VOL
    sta NOI_VOL
    lda #$80
    sta TRI_LINEAR
    lda #$08                    ; sweeps off (negate set to avoid muting)
    sta SQ1_SWEEP
    sta SQ2_SWEEP

    lda #$5A
    sta rngseed
    lda #5                      ; starting hi-score: 5000
    sta hiscore+3

    jsr load_palettes
    jsr title_setup

main_forever:
    jsr wait_nmi
    lda gstate
    cmp #ST_TITLE
    bne :+
    jsr title_frame
    jmp main_forever
:   cmp #ST_PLAY
    bne :+
    jsr play_frame
    jmp main_forever
:   cmp #ST_CLEAR
    bne :+
    jsr clear_frame
    jmp main_forever
:   cmp #ST_CREDITS
    bne :+
    jsr credits_frame
    jmp main_forever
:   jsr gameover_frame
    jmp main_forever

; ------------------------------------------------------------
wait_nmi:
    lda nmi_count
:   cmp nmi_count
    beq :-
    rts

; ------------------------------------------------------------
; Turn rendering + NMI off (call from main thread, waits for vblank
; so the screen is not disabled mid-frame).
render_off:
    lda nmi_count
    sta tmp1
:   bit PPUSTATUS               ; raw vblank flag (works with NMI disabled)
    bmi :+
    lda nmi_count               ; or the NMI ticked (flag consumed by handler)
    cmp tmp1
    beq :-
:   lda #%00101000              ; NMI off, keep 8x16 mode
    sta PPUCTRL
    lda #0
    sta PPUMASK
    rts

; Turn rendering + NMI back on (waits for vblank first).
render_on:
    bit PPUSTATUS
:   bit PPUSTATUS
    bpl :-
    lda #CTRL_BASE
    sta PPUCTRL
    lda #MASK_ON
    sta PPUMASK
    rts

; ------------------------------------------------------------
; load_palettes — rendering must be off (or in vblank).
; Sprites come from the base set; the background half is
; re-tinted per stage from the stage6-indexed tables.
load_palettes:
    bit PPUSTATUS
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR
    ldx #0
:   lda palette_data,x
    sta PPUDATA
    inx
    cpx #32
    bne :-
    ldy stage6
    lda stage_pal_lo,y
    sta ptr1
    lda stage_pal_hi,y
    sta ptr1+1
    bit PPUSTATUS
    lda #$3F
    sta PPUADDR
    lda #$00
    sta PPUADDR
    ldy #0
:   lda (ptr1),y
    sta PPUDATA
    iny
    cpy #16
    bne :-
    rts

; ------------------------------------------------------------
; clear_nametables — fill $2000-$27FF with tile 0 / attr 0.
; Rendering must be off.
clear_nametables:
    bit PPUSTATUS
    lda #$20
    sta PPUADDR
    lda #$00
    sta PPUADDR
    lda #0
    ldx #8                      ; 8 pages of 256
    ldy #0
:   sta PPUDATA
    iny
    bne :-
    dex
    bne :-
    rts

; ------------------------------------------------------------
; ppu_string — write text directly to PPU (rendering off).
; ptr1 = string (length-prefixed), A/X = PPU addr hi/lo
ppu_string:
    bit PPUSTATUS
    sta PPUADDR
    stx PPUADDR
    ldy #0
    lda (ptr1),y
    sta tmp1                    ; length
:   iny
    lda (ptr1),y
    sec
    sbc #$20                    ; ascii -> tile
    sta PPUDATA
    cpy tmp1
    bne :-
    rts

; ------------------------------------------------------------
; rng — galois LFSR, returns A
rng:
    lda rngseed
    asl
    bcc :+
    eor #$5F
:   sta rngseed
    rts

; ------------------------------------------------------------
read_pads:
    lda pad
    sta pad_prev
    lda #1
    sta JOY1
    sta pad                     ; ring counter sentinel
    lsr
    sta JOY1
:   lda JOY1
    lsr                         ; bit 0 -> carry
    rol pad
    bcc :-
    ; newly pressed
    lda pad_prev
    eor #$FF
    and pad
    sta pad_new
    rts
