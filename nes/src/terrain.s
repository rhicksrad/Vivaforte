; ============================================================
; terrain.s — cave generator, scrolling column/row updates,
;             terrain collision (horizontal + vertical stages)
; ============================================================

; ------------------------------------------------------------
; terrain_init — reset generator, draw the initial screen
; directly into VRAM (columns h / rows v). Rendering must be
; OFF and seg_base must point at the stage's segment table.
; ------------------------------------------------------------
terrain_init:
    lda seg_base
    sta seg_ptr
    lda seg_base+1
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

    lda vmode
    beq @horiz
    ; ---- vertical: 30 rows, world row 0 at nametable row 29 ----
    lda #29
    sta ntrow
@vrow:
    jsr gen_row_compute
    bit PPUSTATUS
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
    lda gencol
    cmp #30
    bne @vrow
    rts

@horiz:
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
; terrain_gen_check — main thread: queue a new column/row for
; the NMI when the scroll is getting close to undrawn space.
; ------------------------------------------------------------
terrain_gen_check:
    lda colpend
    beq :+
    rts                         ; NMI hasn't consumed the last one yet
:   lda vmode
    bne @vert
    ; need = (scroll16 >> 3) + 34
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

@vert:
    ; need = (scroll16 >> 3) + 29  (28 visible rows + 1 ahead)
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
    adc #29
    sta tmp1
    bcc :+
    inc tmp2
:   lda gencol+1
    cmp tmp2
    bcc @vgen
    bne @vout
    lda gencol
    cmp tmp1
    bcc @vgen
    beq @vgen
@vout:
    rts
@vgen:
    jsr gen_row_compute         ; advances gencol/ntrow itself
    lda #1
    sta colpend
    rts

; ------------------------------------------------------------
; seg_advance — step the segment interpolator one column/row:
; walk cur_top/cur_bot one unit toward the segment targets,
; loading the next table entry (wrapping) when one runs out.
; ------------------------------------------------------------
seg_advance:
    lda seg_left
    bne @step
    ldy #0
    lda (seg_ptr),y
    bne @load
    ; end of table: wrap
    lda seg_base
    sta seg_ptr
    lda seg_base+1
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
:   rts

; ------------------------------------------------------------
; gen_column_compute — build colbuf + address for world column
; `gencol`, update the height ring buffer.
; ------------------------------------------------------------
gen_column_compute:
    jsr seg_advance

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
; gen_row_compute — vertical stage: build colbuf (32 tiles) +
; address for world row `gencol` at nametable row `ntrow`,
; update the wall-width ring buffer, then advance both.
; cur_top = left wall width, cur_bot = right wall width.
; ------------------------------------------------------------
gen_row_compute:
    jsr seg_advance

    ; ---- store widths in ring ----
    lda gencol
    and #$3F
    tay
    lda cur_top
    sta ter_top,y
    lda cur_bot
    sta ter_bot,y

    ; ---- PPU address = $2000 + ntrow*32 ----
    lda ntrow
    lsr
    lsr
    lsr
    clc
    adc #$20
    sta colbuf_ah
    lda ntrow
    asl
    asl
    asl
    asl
    asl
    sta colbuf_al

    ; ---- fill 32 tiles: left wall | open + stars | right wall ----
    lda #32
    sec
    sbc cur_bot
    sta tmp2                    ; first right-wall column
    ldx cur_top
    dex
    stx tmp3                    ; left edge column (cur_top-1; $FF if none)
    ldx #0
@tile:
    cpx cur_top
    bcs @noleft
    cpx tmp3
    beq @edger
    lda #T_ROCK
    bne @put
@edger:
    lda #T_EDGE_R
    bne @put
@noleft:
    cpx tmp2
    bcc @open
    beq @edgel
    lda #T_ROCK
    bne @put
@edgel:
    lda #T_EDGE_L
    bne @put
@open:
    ; sparse deterministic starfield: hash = (col*9) ^ row
    txa
    asl
    asl
    asl
    sta tmp4
    txa
    clc
    adc tmp4
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
    cpx #32
    bne @tile

    ; ---- advance world row + nametable row (29 -> 0 -> 29 ...) ----
    inc gencol
    bne :+
    inc gencol+1
:   dec ntrow
    bpl :+
    lda #29
    sta ntrow
:   rts

; ------------------------------------------------------------
; terrain_solid — A = screen x, Y = screen y
; returns carry set if that pixel is inside a wall
; ------------------------------------------------------------
terrain_solid:
    sta tmp1                    ; screen x  (preserves X register)
    lda vmode
    beq :+
    jmp terrain_solid_v
:   cpy #17
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

; ------------------------------------------------------------
; terrain_solid_v — vertical stage. tmp1 = screen x, Y = screen y.
; World pixel = scroll16 + (239 - y); walls hug the sides.
; ------------------------------------------------------------
terrain_solid_v:
    cpy #17
    bcc @solid                  ; HUD strip is a wall
    sty tmp2
    lda #239
    sec
    sbc tmp2
    clc
    adc scroll16
    sta tmp2
    lda scroll16+1
    adc #0
    sta tmp3
    lsr tmp3
    ror tmp2
    lsr tmp3
    ror tmp2
    lsr tmp3
    ror tmp2
    lda tmp2
    and #$3F
    tay                         ; ring index of that terrain row
    lda tmp1
    lsr
    lsr
    lsr                         ; column 0..31
    cmp ter_top,y
    bcc @solid                  ; inside left wall
    sta tmp2
    lda #32
    sec
    sbc ter_bot,y               ; first right-wall column
    cmp tmp2
    bcc @solid                  ; first_right < col
    beq @solid                  ; first_right == col
    clc
    rts
@solid:
    sec
    rts

; ------------------------------------------------------------
; terrain_top_row — Y = ring index of the terrain row entering
; at the top of the play area (vertical stage spawns)
; ------------------------------------------------------------
terrain_top_row:
    lda scroll16
    clc
    adc #223
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
    tay
    rts

; ------------------------------------------------------------
; terrain_left_x  — A = first open x beside the left wall
; terrain_right_x — A = x for a 16px object hugging the right wall
; (both sampled at the top edge, for wall turret spawns)
; ------------------------------------------------------------
terrain_left_x:
    jsr terrain_top_row
    lda ter_top,y
    asl
    asl
    asl
    rts

terrain_right_x:
    jsr terrain_top_row
    lda ter_bot,y
    asl
    asl
    asl
    sta tmp1
    lda #240                    ; 256 - width*8 - 16
    sec
    sbc tmp1
    rts
