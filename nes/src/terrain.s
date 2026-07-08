; ============================================================
; terrain.s — cave generator, scrolling column updates,
;             terrain collision
; ============================================================

; ------------------------------------------------------------
; terrain_init — reset generator, draw first 64 columns
; directly into VRAM. Rendering must be OFF.
; ------------------------------------------------------------
terrain_init:
    lda #<terrain_segs
    sta seg_ptr
    lda #>terrain_segs
    sta seg_ptr+1
    lda #0
    sta seg_left
    sta gencol
    sta gencol+1
    lda #2
    sta cur_top
    sta cur_bot
    sta seg_top
    sta seg_bot

    lda #%00101100              ; NMI off, 8x16, inc +32
    sta PPUCTRL
@col:
    jsr gen_column_compute
    bit PPUSTATUS
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
    inc gencol
    lda gencol
    cmp #64
    bne @col
    lda #%00101000              ; back to inc +1
    sta PPUCTRL
    rts

; ------------------------------------------------------------
; terrain_gen_check — main thread: queue a new column for the
; NMI when the scroll is getting close to undrawn space.
; ------------------------------------------------------------
terrain_gen_check:
    lda colpend
    beq :+
    rts                         ; NMI hasn't consumed the last one yet
:   ; need = (scroll16 >> 3) + 34
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
    adc #34
    sta tmp1
    bcc :+
    inc tmp2
:   ; if gencol <= need: generate
    lda gencol+1
    cmp tmp2
    bcc @gen
    bne @out
    lda gencol
    cmp tmp1
    bcc @gen
    beq @gen
@out:
    rts
@gen:
    jsr gen_column_compute
    inc gencol
    bne :+
    inc gencol+1
:   lda #1
    sta colpend
    rts

; ------------------------------------------------------------
; gen_column_compute — build colbuf + address for world column
; `gencol`, update the height ring buffer.
; ------------------------------------------------------------
gen_column_compute:
    ; ---- advance segment interpolator ----
    lda seg_left
    bne @step
    ldy #0
    lda (seg_ptr),y
    bne @load
    ; end of table: wrap
    lda #<terrain_segs
    sta seg_ptr
    lda #>terrain_segs
    sta seg_ptr+1
    ldy #0
    lda (seg_ptr),y
@load:
    sta seg_left
    iny
    lda (seg_ptr),y
    sta seg_top
    iny
    lda (seg_ptr),y
    sta seg_bot
    lda seg_ptr
    clc
    adc #3
    sta seg_ptr
    bcc @step
    inc seg_ptr+1
@step:
    dec seg_left
    ; cur_top -> seg_top by 1
    lda cur_top
    cmp seg_top
    beq :++
    bcs :+
    inc cur_top
    bcc :++
:   dec cur_top
:   ; cur_bot -> seg_bot by 1
    lda cur_bot
    cmp seg_bot
    beq :++
    bcs :+
    inc cur_bot
    bcc :++
:   dec cur_bot
:
    ; ---- store heights in ring ----
    lda gencol
    and #$3F
    tay
    lda cur_top
    sta ter_top,y
    lda cur_bot
    sta ter_bot,y

    ; ---- PPU address ----
    lda gencol
    and #$20
    lsr
    lsr
    lsr                         ; 0 or 4
    clc
    adc #$20
    sta colbuf_ah               ; $20 or $24
    lda gencol
    and #$1F
    clc
    adc #64                     ; row 2 (2*32)
    sta colbuf_al

    ; ---- fill 28 rows ----
    lda #28
    sec
    sbc cur_bot
    sta tmp2                    ; bottom threshold row
    ldx cur_top
    dex
    stx tmp3                    ; top edge row (cur_top-1; $FF if none)
    ldx #0
@row:
    cpx cur_top
    bcs @notop
    ; ceiling region
    cpx tmp3
    beq @edgeb
    lda #T_ROCK
    bne @put
@edgeb:
    lda #T_EDGE_B
    bne @put
@notop:
    cpx tmp2
    bcc @open
    beq @edget
    lda #T_ROCK
    bne @put
@edget:
    lda #T_EDGE_T
    bne @put
@open:
    ; sparse deterministic starfield: hash = (row*9) ^ col
    txa
    asl
    asl
    asl
    sta tmp4
    txa
    clc
    adc tmp4                    ; row*9
    eor gencol
    and #$3F
    cmp #$07
    bne @blank
    lda gencol
    and #$01
    clc
    adc #T_STAR1
    bne @put
@blank:
    lda #T_BLANK
@put:
    sta colbuf,x
    inx
    cpx #28
    bne @row
    rts

; ------------------------------------------------------------
; terrain_solid — A = screen x, Y = screen y
; returns carry set if that pixel is inside a wall
; ------------------------------------------------------------
terrain_solid:
    sta tmp1                    ; screen x  (preserves X register)
    cpy #17
    bcc @solid                  ; HUD strip is a wall
    tya
    sec
    sbc #16
    lsr
    lsr
    lsr                         ; row 0..27
    cmp #28
    bcs @solid
    sta tmp3
    lda scroll16
    clc
    adc tmp1
    sta tmp1
    lda scroll16+1
    adc #0
    sta tmp2
    lsr tmp2
    ror tmp1
    lsr tmp2
    ror tmp1
    lsr tmp2
    ror tmp1
    lda tmp1
    and #$3F
    tay                         ; Y = ring index (y arg no longer needed)
    lda tmp3
    cmp ter_top,y
    bcc @solid
    sta tmp3
    lda #28
    sec
    sbc ter_bot,y
    cmp tmp3                    ; A = threshold, M = row
    bcc @solid                  ; threshold < row
    beq @solid                  ; threshold == row
    clc
    rts
@solid:
    sec
    rts

; ------------------------------------------------------------
; terrain_floor_y — A = y of floor surface near right edge
; terrain_ceil_y  — A = y just under the ceiling near right edge
; ------------------------------------------------------------
terrain_edge_col:               ; Y = ring index at right screen edge
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
    adc #32
    and #$3F
    tay
    rts

terrain_floor_y:
    jsr terrain_edge_col
    lda ter_bot,y
    asl
    asl
    asl
    sta tmp1
    lda #240
    sec
    sbc tmp1
    rts

terrain_ceil_y:
    jsr terrain_edge_col
    lda ter_top,y
    asl
    asl
    asl
    clc
    adc #16
    rts
