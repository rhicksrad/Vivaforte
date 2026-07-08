; ============================================================
; nmi.s — vblank handler: OAM DMA, VRAM transfers, scroll split
; ============================================================

nmi:
    pha
    txa
    pha
    tya
    pha

    ; ---- OAM DMA ----
    lda #0
    sta OAMADDR
    lda #>OAMBUF
    sta OAMDMA

    ; ---- pending nametable column (h, inc+32) or row (v, inc+1) ----
    lda colpend
    beq @no_col
    bit PPUSTATUS
    lda vmode
    bne @vcol
    lda #CTRL_INC32
    sta PPUCTRL
    lda colbuf_ah
    sta PPUADDR
    lda colbuf_al
    sta PPUADDR
    ldx #0
:   lda colbuf,x
    sta PPUDATA
    inx
    cpx #28
    bne :-
    lda #CTRL_BASE
    sta PPUCTRL
    jmp @colclr
@vcol:
    lda #CTRL_BASE
    sta PPUCTRL
    lda colbuf_ah
    sta PPUADDR
    lda colbuf_al
    sta PPUADDR
    ldx #0
:   lda colbuf,x
    sta PPUDATA
    inx
    cpx #32
    bne :-
@colclr:
    lda #0
    sta colpend
@no_col:

    ; ---- pending string ----
    lda strpend
    beq @no_str
    bit PPUSTATUS
    lda strbuf_ah
    sta PPUADDR
    lda strbuf_al
    sta PPUADDR
    ldx #0
:   lda strbuf,x
    sta PPUDATA
    inx
    cpx strbuf_len
    bne :-
    lda #0
    sta strpend
@no_str:

    ; ---- pending HUD digits ----
    lda hudpend
    beq @no_hud
    bit PPUSTATUS
    lda hud_hi                  ; score digits at row 0, col 7
    sta PPUADDR
    lda #$07
    sta PPUADDR
    ldx #0
:   lda hudbuf,x
    sta PPUDATA
    inx
    cpx #6
    bne :-
    lda hud_hi                  ; hi-score digits at row 0, col 18
    sta PPUADDR
    lda #$12
    sta PPUADDR
:   lda hudbuf,x
    sta PPUDATA
    inx
    cpx #12
    bne :-
    lda hud_hi                  ; lives digit at row 0, col 27
    sta PPUADDR
    lda #$1B
    sta PPUADDR
    lda hudbuf+12
    sta PPUDATA
    lda #0
    sta hudpend
@no_hud:

    ; ---- reset scroll for the HUD strip (nametable 0 h / 1 v, 0/0) ----
    bit PPUSTATUS
    lda ctrl_top
    sta PPUCTRL
    lda #0
    sta PPUSCROLL
    sta PPUSCROLL

    ; ---- pause grayscale ----
    lda paused
    beq :+
    lda #MASK_PAUSE
    bne :++
:   lda #MASK_ON
:   sta PPUMASK

    ; ---- audio (steady 60 Hz tick) ----
    jsr sound_update

    inc nmi_count

    ; ---- sprite-0 split: switch to game scroll below the HUD ----
    lda gstate
    beq @done                   ; ST_TITLE: no split
    ; wait for sprite-0 flag to clear (pre-render line), with timeout
    ldx #0
    ldy #8
:   bit PPUSTATUS
    bvc @cleared
    inx
    bne :-
    dey
    bne :-
    jmp @done                   ; timed out; skip split this frame
@cleared:
    ldx #0
    ldy #8
:   bit PPUSTATUS
    bvs @hit
    inx
    bne :-
    dey
    bne :-
    jmp @done
@hit:
    ; we are on scanline ~14; set the game scroll before line 16
    lda vmode
    bne @vsplit
    lda scroll16+1
    and #$01
    ora #CTRL_BASE
    sta PPUCTRL
    lda scroll16
    sta PPUSCROLL
    lda #0
    sta PPUSCROLL
    jmp @done
@vsplit:
    ; vertical: mid-frame Y scroll needs the full $2006/$2005/$2005/
    ; $2006 sequence. The first three writes only touch the t latch;
    ; the final $2006 write loads v immediately, so it is delayed to
    ; land in hblank of line 15 and the play area starts clean at 16.
    lda #$00                    ; nametable 0 (Y bits rewritten below)
    sta PPUADDR
    lda vscr
    sta PPUSCROLL               ; coarse + fine Y
    lda #$00
    sta PPUSCROLL               ; X = 0
    lda vscr
    asl
    asl
    and #$E0                    ; (coarse Y & 7) << 5 | coarse X (0)
    tax
    ldy #SPLIT_DLY
:   dey
    bne :-
    stx PPUADDR
@done:
    pla
    tay
    pla
    tax
    pla
    rti
