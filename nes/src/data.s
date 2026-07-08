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

; ---- per-stage background palettes (16 bytes each) ----
pal_s1:                         ; deep cave blues
    .byte $0F,$02,$12,$30
    .byte $0F,$02,$12,$30
    .byte $0F,$06,$16,$30
    .byte $0F,$09,$19,$30
pal_s2:                         ; volcanic reds
    .byte $0F,$06,$16,$30
    .byte $0F,$06,$16,$30
    .byte $0F,$07,$17,$30
    .byte $0F,$08,$18,$30
pal_s3:                         ; bio-cavern greens
    .byte $0F,$09,$19,$30
    .byte $0F,$09,$19,$30
    .byte $0F,$0B,$1B,$30
    .byte $0F,$1A,$2A,$30
pal_s4:                         ; crystal ice
    .byte $0F,$01,$21,$30
    .byte $0F,$01,$21,$30
    .byte $0F,$0C,$1C,$30
    .byte $0F,$03,$13,$30
pal_s5:                         ; gunmetal fortress
    .byte $0F,$00,$10,$30
    .byte $0F,$00,$10,$30
    .byte $0F,$07,$17,$30
    .byte $0F,$08,$18,$30
pal_s6:                         ; dark violet finale
    .byte $0F,$03,$13,$30
    .byte $0F,$03,$13,$30
    .byte $0F,$04,$14,$30
    .byte $0F,$0C,$1C,$30

stage_pal_lo: .byte <pal_s1,<pal_s2,<pal_s3,<pal_s4,<pal_s5,<pal_s6
stage_pal_hi: .byte >pal_s1,>pal_s2,>pal_s3,>pal_s4,>pal_s5,>pal_s6

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

; ---- vertical-stage variants (turrets: B=left wall, T=right) ----
enemy_tile_v: .byte 0,SPT_FAN_L,SPT_DARTV_L,SPT_TURVL_L,SPT_TURVR_L,SPT_ORB_L
enemy_attr_v: .byte 0,2,2,3,3,2

; ---- meter x positions ----
mul24: .byte 0,24,48,72,96,120

; ---- note periods (NTSC) ----
;   0 rest  1 A2   2 C3   3 D3   4 E3   5 G2   6 E2   7 G3
;   8 A3    9 C4  10 D4  11 E4  12 G4  13 A4  14 F3  15 B3
;  16 C5   17 D5  18 E5  19 B2  20 F4  21 G5  22 F2  23 B4
note_lo: .byte $00,$F8,$56,$F8,$A6,$74,$4C,$3A,$FB,$AB,$7C,$52,$1C,$FD
         .byte $7F,$C4,$D4,$BD,$A8,$89,$3F,$8D,$00,$E1
note_hi: .byte $00,$03,$03,$02,$02,$04,$05,$02,$01,$01,$01,$01,$01,$00
         .byte $02,$01,$00,$00,$00,$03,$01,$00,$05,$00

; ---- music: three 64-step tracks (4 bars of 16) ----
; track 0 — horizontal stages: driving Am / F / C / G
mus0_bass:
    .byte  1,0,8,0,  1,0,8,0,  1,0,8,0,  5,0,7,0
    .byte 22,0,14,0, 22,0,14,0, 22,0,22,0, 2,0,3,0
    .byte  2,0,9,0,  2,0,9,0,  2,0,9,0,  7,0,4,0
    .byte  5,0,7,0,  5,0,7,0,  5,0,7,0,  3,0,4,0
mus0_drum:
    .byte 1,0,2,0, 2,0,1,0, 1,0,2,0, 2,2,1,0
    .byte 1,0,2,0, 2,0,1,0, 1,0,2,0, 2,2,1,0
    .byte 1,0,2,0, 2,0,1,0, 1,0,2,0, 2,2,1,0
    .byte 1,0,2,0, 1,0,2,0, 1,2,1,2, 1,2,2,2
mus0_mel:
    .byte  8,0,0,9,  0,0,11,0, 13,0,11,0,  9,0,11,0
    .byte 20,0,0,11, 0,0,9,0,   8,0,9,0,  11,0,9,0
    .byte 12,0,0,11, 0,0,9,0,  16,0,23,0, 12,0,9,0
    .byte 12,0,10,0, 15,0,10,0, 12,0,10,0, 11,0,10,0

; track 1 — vertical stages: tense Em pulse
mus1_bass:
    .byte  6,0,6,0,  6,0,5,0,  6,0,6,0,  6,0,1,0
    .byte  6,0,6,0,  6,0,5,0,  6,0,6,0, 19,0,1,0
    .byte  2,0,2,0,  2,0,2,0,  1,0,1,0,  1,0,1,0
    .byte 19,0,19,0, 19,0,19,0, 6,0,6,0,  6,5,6,0
mus1_drum:
    .byte 1,0,0,0, 2,0,0,0, 1,0,0,0, 2,0,2,0
    .byte 1,0,0,0, 2,0,0,0, 1,0,0,0, 2,0,2,0
    .byte 1,0,0,0, 2,0,0,0, 1,0,0,0, 2,0,2,0
    .byte 1,0,0,0, 2,0,0,0, 1,2,1,2, 2,2,2,2
mus1_mel:
    .byte  4,0,0,0,  7,0,0,0, 11,0,0,0,  7,0,4,0
    .byte  4,0,0,0,  7,0,0,0, 15,0,0,0, 11,0,7,0
    .byte  9,0,0,0, 11,0,0,0, 16,0,0,0, 11,0,9,0
    .byte 15,0,11,0, 7,0,11,0,  4,0,0,0,  0,0,0,0

; track 2 — credits: gentle C / Am / F / G stroll
mus2_bass:
    .byte  2,0,0,0,  9,0,0,0,  7,0,0,0,  9,0,0,0
    .byte  1,0,0,0,  8,0,0,0,  4,0,0,0,  8,0,0,0
    .byte 22,0,0,0, 14,0,0,0,  2,0,0,0, 14,0,0,0
    .byte  5,0,0,0,  7,0,0,0, 10,0,0,0,  7,0,0,0
mus2_drum:
    .byte 1,0,2,0, 0,0,2,0, 0,0,2,0, 0,0,2,0
    .byte 1,0,2,0, 0,0,2,0, 0,0,2,0, 0,0,2,0
    .byte 1,0,2,0, 0,0,2,0, 0,0,2,0, 0,0,2,0
    .byte 1,0,2,0, 0,0,2,0, 0,0,2,0, 0,2,0,2
mus2_mel:
    .byte  9,0,11,0, 12,0,11,0, 16,0,12,0, 11,0,12,0
    .byte  8,0,9,0,  11,0,9,0,  13,0,11,0,  9,0,11,0
    .byte 20,0,13,0, 16,0,13,0, 20,0,13,0, 16,0,17,0
    .byte 17,0,23,0, 10,0,23,0, 12,0,10,0, 11,0,10,0

track_bass_lo: .byte <mus0_bass,<mus1_bass,<mus2_bass
track_bass_hi: .byte >mus0_bass,>mus1_bass,>mus2_bass
track_drum_lo: .byte <mus0_drum,<mus1_drum,<mus2_drum
track_drum_hi: .byte >mus0_drum,>mus1_drum,>mus2_drum
track_mel_lo:  .byte <mus0_mel,<mus1_mel,<mus2_mel
track_mel_hi:  .byte >mus0_mel,>mus1_mel,>mus2_mel
track_spd:     .byte 6,6,8      ; frames per step - 1

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

; ---- vertical wave table: delay, type, base x, count, gap, flags
;      (TURRETB = left wall, TURRETT = right wall) ----
wave_table_v:
    .byte 120, ET_FAN,     60, 5, 14, ENF_CAP
    .byte 120, ET_FAN,    160, 5, 14, ENF_CAP
    .byte  90, ET_TURRETB,  0, 2, 60, 0
    .byte 100, ET_DART,    80, 3, 30, 0
    .byte 100, ET_FAN,    110, 6, 12, ENF_CAP
    .byte  60, ET_TURRETT,  0, 2, 50, 0
    .byte  90, ET_ORB,    120, 2, 40, 0
    .byte  90, ET_DART,    50, 4, 25, ENF_CAP
    .byte  60, ET_TURRETB,  0, 3, 50, 0
    .byte  90, ET_FAN,     70, 6, 12, ENF_CAP
    .byte  30, ET_FAN,    170, 6, 12, 0
    .byte  90, ET_ORB,     90, 3, 45, ENF_CAP
    .byte  80, ET_DART,   130, 5, 20, 0
    .byte  60, ET_TURRETT,  0, 2, 45, 0
    .byte  30, ET_TURRETB,  0, 2, 45, 0
    .byte  90, ET_FAN,    120, 7, 11, ENF_CAP
    .byte  80, ET_ORB,     60, 2, 40, 0
    .byte  60, ET_DART,   100, 5, 18, ENF_CAP
    .byte  60, ET_TURRETB,  0, 3, 40, 0
    .byte  90, ET_FAN,     90, 6, 12, ENF_CAP
    .byte  60, ET_ORB,    140, 3, 40, 0
    .byte 120, ET_DART,   110, 6, 15, 0
    .byte 200, $FF, 0, 0, 0, 0          ; boss

; ---- stage 3 (bio cavern, h): dart/fan swarms ----
wave_table3:
    .byte 100, ET_FAN,     80, 6, 12, ENF_CAP
    .byte  90, ET_DART,   120, 4, 22, 0
    .byte  90, ET_FAN,    150, 6, 12, ENF_CAP
    .byte  60, ET_TURRETB,  0, 3, 45, 0
    .byte  90, ET_ORB,     70, 3, 40, ENF_CAP
    .byte  60, ET_DART,    60, 5, 18, 0
    .byte  60, ET_TURRETT,  0, 3, 45, 0
    .byte  90, ET_FAN,    100, 7, 11, ENF_CAP
    .byte  30, ET_FAN,     60, 6, 12, 0
    .byte  80, ET_ORB,    130, 3, 38, ENF_CAP
    .byte  70, ET_DART,    90, 6, 16, 0
    .byte  50, ET_TURRETB,  0, 2, 40, 0
    .byte  30, ET_TURRETT,  0, 2, 40, 0
    .byte  90, ET_FAN,    130, 7, 11, ENF_CAP
    .byte  60, ET_ORB,     90, 3, 36, 0
    .byte  60, ET_DART,   140, 6, 15, ENF_CAP
    .byte  60, ET_TURRETB,  0, 3, 36, 0
    .byte  90, ET_FAN,     70, 8, 10, ENF_CAP
    .byte  60, ET_ORB,    110, 4, 34, 0
    .byte 100, ET_DART,   100, 7, 13, 0
    .byte 200, $FF, 0, 0, 0, 0          ; boss

; ---- stage 4 (crystal canyon, v): turret/orb gauntlet ----
wave_table4:
    .byte 100, ET_TURRETB,  0, 2, 55, 0
    .byte  60, ET_TURRETT,  0, 2, 55, 0
    .byte 100, ET_FAN,     90, 6, 12, ENF_CAP
    .byte  80, ET_ORB,    130, 3, 36, 0
    .byte  80, ET_DART,    60, 4, 20, ENF_CAP
    .byte  50, ET_TURRETB,  0, 3, 42, 0
    .byte  90, ET_FAN,    150, 6, 12, ENF_CAP
    .byte  40, ET_TURRETT,  0, 3, 42, 0
    .byte  90, ET_ORB,     80, 3, 34, ENF_CAP
    .byte  70, ET_DART,   110, 5, 17, 0
    .byte  50, ET_TURRETB,  0, 2, 40, 0
    .byte  30, ET_TURRETT,  0, 2, 40, 0
    .byte  90, ET_FAN,     70, 7, 11, ENF_CAP
    .byte  70, ET_ORB,    140, 4, 32, 0
    .byte  70, ET_DART,    90, 6, 15, ENF_CAP
    .byte  50, ET_TURRETB,  0, 3, 36, 0
    .byte  40, ET_TURRETT,  0, 3, 36, 0
    .byte  90, ET_FAN,    120, 8, 10, ENF_CAP
    .byte  70, ET_ORB,    100, 4, 30, 0
    .byte 200, $FF, 0, 0, 0, 0          ; boss

; ---- stage 5 (fortress, h): turret walls + heavy orbs ----
wave_table5:
    .byte 100, ET_TURRETB,  0, 3, 40, 0
    .byte  40, ET_TURRETT,  0, 3, 40, 0
    .byte  90, ET_FAN,     90, 6, 12, ENF_CAP
    .byte  70, ET_ORB,     70, 4, 32, 0
    .byte  70, ET_DART,   130, 5, 17, ENF_CAP
    .byte  50, ET_TURRETB,  0, 4, 34, 0
    .byte  90, ET_FAN,    150, 7, 11, ENF_CAP
    .byte  40, ET_TURRETT,  0, 4, 34, 0
    .byte  80, ET_ORB,    110, 4, 30, ENF_CAP
    .byte  70, ET_DART,    70, 6, 15, 0
    .byte  50, ET_TURRETB,  0, 3, 34, 0
    .byte  30, ET_TURRETT,  0, 3, 34, 0
    .byte  90, ET_FAN,     60, 8, 10, ENF_CAP
    .byte  70, ET_ORB,    130, 4, 28, 0
    .byte  60, ET_DART,   100, 7, 13, ENF_CAP
    .byte  50, ET_TURRETB,  0, 4, 30, 0
    .byte  40, ET_TURRETT,  0, 4, 30, 0
    .byte  90, ET_FAN,    110, 8, 10, ENF_CAP
    .byte 100, ET_DART,    90, 8, 12, 0
    .byte 200, $FF, 0, 0, 0, 0          ; boss

; ---- stage 6 (final descent, v): everything at once ----
wave_table6:
    .byte 100, ET_FAN,     80, 7, 11, ENF_CAP
    .byte  50, ET_FAN,    160, 7, 11, 0
    .byte  70, ET_TURRETB,  0, 3, 38, 0
    .byte  40, ET_TURRETT,  0, 3, 38, 0
    .byte  80, ET_ORB,    110, 4, 30, ENF_CAP
    .byte  70, ET_DART,    60, 6, 15, 0
    .byte  60, ET_DART,   140, 6, 15, ENF_CAP
    .byte  50, ET_TURRETB,  0, 4, 32, 0
    .byte  40, ET_TURRETT,  0, 4, 32, 0
    .byte  90, ET_FAN,    100, 8, 10, ENF_CAP
    .byte  70, ET_ORB,     70, 4, 28, 0
    .byte  60, ET_ORB,    150, 4, 28, ENF_CAP
    .byte  60, ET_DART,   110, 7, 13, 0
    .byte  50, ET_TURRETB,  0, 4, 28, 0
    .byte  40, ET_TURRETT,  0, 4, 28, 0
    .byte  90, ET_FAN,    130, 8, 10, ENF_CAP
    .byte  30, ET_FAN,     60, 8, 10, 0
    .byte  70, ET_ORB,     90, 5, 26, ENF_CAP
    .byte 100, ET_DART,   100, 8, 12, 0
    .byte 200, $FF, 0, 0, 0, 0          ; boss

; ---- credits gallery: harmless capsule-carrying fans ----
wave_table_c:
    .byte 120, ET_FAN,     80, 5, 14, ENF_CAP
    .byte 120, ET_FAN,    150, 5, 14, ENF_CAP
    .byte 120, ET_FAN,     60, 6, 12, ENF_CAP
    .byte 120, ET_FAN,    120, 6, 12, ENF_CAP
    .byte 120, ET_FAN,    100, 5, 14, ENF_CAP
    .byte 120, ET_FAN,    160, 6, 12, ENF_CAP
    .byte 120, ET_FAN,     70, 6, 12, ENF_CAP
    .byte 120, ET_FAN,    130, 6, 12, ENF_CAP
    .byte 255, ET_FAN,    100, 4, 20, ENF_CAP
    .byte 255, ET_FAN,    140, 4, 20, ENF_CAP
    .byte 255, ET_FAN,     80, 4, 20, ENF_CAP
    .byte 255, ET_FAN,    120, 4, 20, ENF_CAP
    .byte 255, ET_FAN,    100, 4, 20, ENF_CAP
    .byte 255, ET_FAN,     90, 4, 20, ENF_CAP
    .byte 255, ET_FAN,    110, 4, 20, ENF_CAP
    .byte 255, ET_FAN,    100, 4, 20, ENF_CAP
    .byte 255, ET_FAN,    120, 4, 20, ENF_CAP
    .byte 255, ET_FAN,     90, 4, 20, ENF_CAP
    .byte 200, $FF, 0, 0, 0, 0          ; unreachable

; ---- credits staff roll (length-prefixed, 0 = end) ----
cred_lines:
    .byte 9,  "VIVAFORTE"
    .byte 7,  "CREDITS"
    .byte 15, "CODE AND DESIGN"
    .byte 12, "CLAUDE FABLE"
    .byte 9,  "PIXEL ART"
    .byte 12, "CLAUDE FABLE"
    .byte 5,  "MUSIC"
    .byte 12, "CLAUDE FABLE"
    .byte 8,  "PRODUCER"
    .byte 4,  "RYAN"
    .byte 10, "THANKS FOR"
    .byte 7,  "PLAYING"
    .byte 7,  "THE END"
    .byte 0

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

; ---- vertical terrain segments: rows, left width, right width ----
terrain_segs_v:
    .byte 24, 2, 2
    .byte 16, 4, 3
    .byte 16, 3, 6
    .byte 20, 6, 4
    .byte 16, 2, 7
    .byte 20, 7, 2
    .byte 16, 5, 5
    .byte 24, 2, 3
    .byte 16, 6, 6
    .byte 12, 3, 3
    .byte 20, 4, 8
    .byte 16, 8, 3
    .byte 24, 2, 2
    .byte 16, 6, 7
    .byte 12, 8, 2
    .byte 16, 2, 8
    .byte 20, 5, 5
    .byte 24, 3, 2
    .byte 0                             ; end -> loop

; ---- stage 3 (bio, h): restless rolling flesh ----
terrain_segs3:
    .byte 16, 2, 3
    .byte 12, 5, 4
    .byte 12, 3, 7
    .byte 14, 7, 3
    .byte 12, 4, 5
    .byte 12, 8, 2
    .byte 14, 2, 8
    .byte 12, 6, 6
    .byte 12, 3, 4
    .byte 14, 5, 8
    .byte 12, 9, 3
    .byte 12, 4, 4
    .byte 14, 2, 9
    .byte 12, 8, 4
    .byte 12, 5, 6
    .byte 16, 3, 3
    .byte 0                             ; end -> loop

; ---- stage 4 (crystal, v): jagged zigzag chute ----
terrain_segs4:
    .byte 18, 3, 3
    .byte 10, 7, 2
    .byte 10, 2, 7
    .byte 12, 8, 3
    .byte 10, 3, 8
    .byte 12, 6, 6
    .byte 10, 9, 2
    .byte 12, 2, 9
    .byte 10, 5, 5
    .byte 12, 8, 4
    .byte 10, 4, 8
    .byte 14, 3, 3
    .byte 10, 7, 6
    .byte 10, 6, 7
    .byte 16, 2, 2
    .byte 0                             ; end -> loop

; ---- stage 5 (fortress, h): blocky bulkheads ----
terrain_segs5:
    .byte 20, 3, 3
    .byte  8, 9, 3
    .byte 16, 9, 3
    .byte  8, 3, 9
    .byte 16, 3, 9
    .byte  8, 6, 6
    .byte 14, 6, 6
    .byte  8, 2, 10
    .byte 14, 2, 10
    .byte  8, 10, 2
    .byte 14, 10, 2
    .byte  8, 5, 5
    .byte 18, 5, 5
    .byte  8, 8, 7
    .byte 14, 8, 7
    .byte 20, 2, 2
    .byte 0                             ; end -> loop

; ---- stage 6 (final, v): tight winding throat ----
terrain_segs6:
    .byte 16, 4, 4
    .byte 12, 8, 3
    .byte 12, 3, 8
    .byte 12, 9, 4
    .byte 12, 4, 9
    .byte 10, 6, 6
    .byte 12, 9, 2
    .byte 12, 2, 9
    .byte 10, 7, 7
    .byte 12, 8, 5
    .byte 12, 5, 8
    .byte 14, 3, 3
    .byte 12, 9, 3
    .byte 12, 3, 9
    .byte 16, 4, 4
    .byte 0                             ; end -> loop

; ---- credits: wide open space, stars only ----
terrain_segs_c:
    .byte 240, 0, 0
    .byte 0                             ; end -> loop

; ---- per-stage pointer tables (index = stage6) ----
stage_wave_lo:
    .byte <wave_table,<wave_table_v,<wave_table3
    .byte <wave_table4,<wave_table5,<wave_table6
stage_wave_hi:
    .byte >wave_table,>wave_table_v,>wave_table3
    .byte >wave_table4,>wave_table5,>wave_table6
stage_segs_lo:
    .byte <terrain_segs,<terrain_segs_v,<terrain_segs3
    .byte <terrain_segs4,<terrain_segs5,<terrain_segs6
stage_segs_hi:
    .byte >terrain_segs,>terrain_segs_v,>terrain_segs3
    .byte >terrain_segs4,>terrain_segs5,>terrain_segs6

; ---- per-stage boss: sprite base + extra hp ----
boss_tile_tbl:  .byte SPT_BOSS,SPT_BOSS2,SPT_BOSS3,SPT_BOSS4,SPT_BOSS5,SPT_BOSS6
boss_bonus_tbl: .byte 0,8,10,14,18,24
