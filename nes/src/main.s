; ============================================================
; VIVAFORTE — a Life Force style scrolling shooter for the NES
; 6502 assembly, ca65/ld65, NROM-256 (mapper 0), NTSC
; ============================================================

.linecont +

.include "defs.inc"

; ---- iNES header ----
.segment "HEADER"
.byte 'N','E','S',$1A
.byte 2                         ; 2x 16KB PRG ROM
.byte 1                         ; 1x 8KB CHR ROM
.byte %00000001                 ; mapper 0, vertical mirroring (horiz scroll)
.byte %00000000
.byte 0,0,0,0,0,0,0,0

.include "vars.s"

.segment "CODE"

.include "reset.s"
.include "nmi.s"
.include "game.s"
.include "player.s"
.include "bullets.s"
.include "enemies.s"
.include "boss.s"
.include "collide.s"
.include "terrain.s"
.include "hud.s"
.include "sound.s"
.include "data.s"

; ---- IRQ (unused) ----
irq:
    rti

.segment "VECTORS"
.addr nmi
.addr reset
.addr irq

.include "chr.s"
