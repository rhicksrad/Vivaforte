; ============================================================
; data.s — tables and level data
; ============================================================

.rodata

; ---- palettes ----
palette_data:
    ; background
    .byte $0F,$02,$12,$30       ; cave blues + white stars/text
    .byte $0F,$02,$12,$30
    .byte $0F,$06,$16,$30
    .byte $0F,$09,$19,$30
    ; sprites
    .byte $0F,$30,$21,$16       ; ship: white / blue / red
    .byte $0F,$27,$37,$30       ; power-ups: orange / yellow / white
    .byte $0F,$25,$16,$30       ; enemies: pink / red / white
    .byte $0F,$10,$20,$30       ; dim grays (meter)

; ---- player speed levels (8.8 px/frame) ----
speed_lo: .byte $00,$80,$00,$80,$00
speed_hi: .byte $01,$01,$02,$02,$03

; ---- 64-entry sine, values 0..64 centered on 32 ----
sintab:
    .byte 32,35,38,41,44,47,50,52,55,57,59,60,62,63,63,64
    .byte 64,64,63,63,62,60,59,57,55,52,50,47,44,41,38,35
    .byte 32,29,26,23,20,17,14,12, 9, 7, 5, 4, 2, 1, 1, 0
    .byte  0, 0, 1, 1, 2, 4, 5, 7, 9,12,14,17,20,23,26,29

; ---- enemy lookups, indexed by type (0 unused) ----
enemy_score: .byte 0,1,1,2,2,3          ; hundreds
enemy_tile:  .byte 0,SPT_FAN_L,SPT_DART_L,SPT_TUR_L,SPT_TUR_L,SPT_ORB_L
enemy_attr:  .byte 0,2,2,3,$83,2        ; ceiling turret is v-flipped

; ---- meter x positions ----
mul24: .byte 0,24,48,72,96,120

; ---- note periods (NTSC) ----
;            rest A2  C3  D3  E3  G2  E2  G3  A3  C4  D4  E4  G4  A4
note_lo: .byte $00,$F8,$56,$F8,$A6,$74,$4C,$3A,$FB,$AB,$7C,$52,$1C,$FD
note_hi: .byte $00,$03,$03,$02,$02,$04,$05,$02,$01,$01,$01,$01,$01,$00

; ---- music: 32-step loop ----
bass_pat:
    .byte 1,0,0,1,0,0,2,0, 1,0,5,0,6,0,5,0
    .byte 1,0,0,1,0,0,2,0, 3,0,2,0,5,0,6,0
drum_pat:
    .byte 1,0,2,0,2,0,1,0, 1,0,2,0,2,2,1,0
    .byte 1,0,2,0,2,0,1,0, 1,0,2,0,1,0,2,2
mel_pat:
    .byte  8,0,0,0,11,0,0,0,  9,0,0,0,11,0,13,0
    .byte  8,0,0,0,11,0,0,0, 12,0,11,0, 9,0, 8,0

; ---- jingle arpeggios (pulse2 period lo, hi byte is 0) ----
arp_lo_tbl: .byte $8E,$A9,$D5           ; C5 -> E5 -> G5
arp_hi_tbl: .byte $6A,$8E,$A9           ; E5 -> G5 -> C6

; ---- text (length-prefixed ASCII) ----
str_title:    .byte 9,  "VIVAFORTE"
str_subtitle: .byte 26, "A LIFE FORCE STYLE SHOOTER"
str_press:    .byte 11, "PRESS START"
str_copy:     .byte 14, "2026 VIVAFORTE"
str_score:    .byte 5,  "SCORE"
str_hi:       .byte 2,  "HI"

; ---- sprite text (OAM tile bytes, 0 = space) ----
sstr_gameover:
    .byte 9
    .byte SPT_LET_G,SPT_LET_A,SPT_LET_M,SPT_LET_E,0
    .byte SPT_LET_O,SPT_LET_V,SPT_LET_E,SPT_LET_R
sstr_pause:
    .byte 5
    .byte SPT_LET_P,SPT_LET_A,SPT_LET_U,SPT_LET_S,SPT_LET_E
sstr_stage:
    .byte 5
    .byte SPT_LET_S,SPT_LET_T,SPT_LET_A,SPT_LET_G,SPT_LET_E
sstr_clear:
    .byte 5
    .byte SPT_LET_C,SPT_LET_L,SPT_LET_E,SPT_LET_A,SPT_LET_R

; ---- wave table: delay, type, y, count, gap, flags ----
wave_table:
    .byte 120, ET_FAN,     70, 5, 14, ENF_CAP
    .byte 120, ET_FAN,    150, 5, 14, ENF_CAP
    .byte  90, ET_TURRETB,  0, 2, 60, 0
    .byte 100, ET_DART,    60, 3, 30, 0
    .byte 100, ET_FAN,    100, 6, 12, ENF_CAP
    .byte  60, ET_TURRETT,  0, 2, 50, 0
    .byte  90, ET_ORB,     80, 2, 40, 0
    .byte  90, ET_DART,   150, 4, 25, ENF_CAP
    .byte  60, ET_TURRETB,  0, 3, 50, 0
    .byte  90, ET_FAN,     60, 6, 12, ENF_CAP
    .byte  30, ET_FAN,    170, 6, 12, 0
    .byte  90, ET_ORB,    120, 3, 45, ENF_CAP
    .byte  80, ET_DART,   100, 5, 20, 0
    .byte  60, ET_TURRETT,  0, 2, 45, 0
    .byte  30, ET_TURRETB,  0, 2, 45, 0
    .byte  90, ET_FAN,     90, 7, 11, ENF_CAP
    .byte  80, ET_ORB,     60, 2, 40, 0
    .byte  60, ET_DART,   130, 5, 18, ENF_CAP
    .byte  60, ET_TURRETB,  0, 3, 40, 0
    .byte  90, ET_FAN,    130, 6, 12, ENF_CAP
    .byte  60, ET_ORB,    100, 3, 40, 0
    .byte 120, ET_DART,    80, 6, 15, 0
    .byte 200, $FF, 0, 0, 0, 0          ; boss

; ---- terrain segments: columns, top height, bottom height ----
terrain_segs:
    .byte 24,  2, 2
    .byte 16,  4, 3
    .byte 16,  3, 6
    .byte 20,  6, 4
    .byte 16,  2, 8
    .byte 20,  8, 2
    .byte 16,  5, 5
    .byte 24,  2, 3
    .byte 16,  7, 6
    .byte 12,  3, 3
    .byte 20,  4, 9
    .byte 16,  9, 3
    .byte 24,  2, 2
    .byte 16,  6, 7
    .byte 12, 10, 2
    .byte 16,  2,10
    .byte 20,  5, 5
    .byte 24,  3, 2
    .byte 0                             ; end -> loop
