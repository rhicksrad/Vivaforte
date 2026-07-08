; ============================================================
; VIVAFORTE — defs.inc
; Hardware registers and game constants
; ============================================================

; ---- PPU ----
PPUCTRL   = $2000
PPUMASK   = $2001
PPUSTATUS = $2002
OAMADDR   = $2003
OAMDATA   = $2004
PPUSCROLL = $2005
PPUADDR   = $2006
PPUDATA   = $2007
OAMDMA    = $4014

; ---- APU ----
SQ1_VOL   = $4000
SQ1_SWEEP = $4001
SQ1_LO    = $4002
SQ1_HI    = $4003
SQ2_VOL   = $4004
SQ2_SWEEP = $4005
SQ2_LO    = $4006
SQ2_HI    = $4007
TRI_LINEAR= $4008
TRI_LO    = $400A
TRI_HI    = $400B
NOI_VOL   = $400C
NOI_LO    = $400E
NOI_HI    = $400F
DMC_FREQ  = $4010
APU_STATUS= $4015
JOY1      = $4016
JOY2      = $4017

; ---- Controller bits (after unrolled read: A B Sel Start U D L R) ----
BTN_A      = %10000000
BTN_B      = %01000000
BTN_SELECT = %00100000
BTN_START  = %00010000
BTN_UP     = %00001000
BTN_DOWN   = %00000100
BTN_LEFT   = %00000010
BTN_RIGHT  = %00000001

; ---- PPUCTRL base: NMI on, 8x16 sprites, BG table $0000, inc +1 ----
CTRL_BASE  = %10101000          ; $A8
CTRL_INC32 = %10101100          ; +32 increment for column writes
MASK_ON    = %00011110          ; show bg + sprites incl. left 8 px
MASK_PAUSE = %00011111          ; grayscale bit set while paused

OAMBUF     = $0200

; ---- Game states ----
ST_TITLE    = 0
ST_PLAY     = 1
ST_GAMEOVER = 2
ST_CLEAR    = 3
ST_CREDITS  = 4

; ---- Number of distinct stages before the loop repeats ----
NUM_STAGES  = 6

; ---- Entity counts ----
NUM_PB  = 12                    ; player bullets (2-way missiles need room)
NUM_EN  = 8                     ; enemies
NUM_EB  = 8                     ; enemy bullets
NUM_CAP = 2                     ; power capsules
NUM_EX  = 4                     ; explosions

; ---- Player bullet types ----
PBT_NONE    = 0
PBT_BULLET  = 1
PBT_LASER   = 2
PBT_MISFALL = 3                 ; missile, falling (v: seeking a wall)
PBT_MISSLIDE= 4                 ; missile, sliding along floor (v: up a wall)
PBT_MISRISE = 5                 ; missile, rising (h only)
PBT_MISSLIDEC=6                 ; missile, sliding along ceiling (h only)

; ---- Enemy types ----
ET_NONE   = 0
ET_FAN    = 1
ET_DART   = 2
ET_TURRETB= 3                   ; turret on floor
ET_TURRETT= 4                   ; turret on ceiling
ET_ORB    = 5

ENF_CAP   = %00000001           ; carries capsule when destroyed

; ---- Weapons ----
WPN_NORMAL = 0
WPN_DOUBLE = 1
WPN_LASER  = 2

; ---- Power meter slots (1-based; 0 = empty) ----
MTR_SPEED   = 1
MTR_MISSILE = 2
MTR_DOUBLE  = 3
MTR_LASER   = 4
MTR_OPTION  = 5
MTR_FORCE   = 6

; ---- Scroll speed: 0.75 px/frame in 8.8 ----
SCROLL_SPD = $C0

; ---- delay iterations before the final split write (vertical
; stages), tuned so v loads during hblank of scanline 15 ----
SPLIT_DLY = 33

; ---- BG tile indices (string chars map as tile = ascii - $20) ----
T_BLANK  = $00
T_ROCK   = $01
T_EDGE_B = $02                  ; underside edge of ceiling wall
T_EDGE_T = $03                  ; top edge of floor wall
T_STAR1  = $04
T_STAR2  = $05
T_DIV    = $06                  ; HUD divider line
T_EDGE_R = $07                  ; right face of left wall (vertical stage)
T_EDGE_L = $08                  ; left face of right wall (vertical stage)

; ---- Sprite pair -> OAM tile byte: (pair<<1)|1  (pattern table $1000) ----
SPT_S0      = $01               ; sprite-zero hit strip
SPT_SHIP_L  = $03
SPT_SHIP_R  = $05
SPT_FAN_L   = $07
SPT_FAN_R   = $09
SPT_DART_L  = $0B
SPT_DART_R  = $0D
SPT_TUR_L   = $0F
SPT_TUR_R   = $11
SPT_ORB_L   = $13
SPT_ORB_R   = $15
SPT_PBUL    = $17
SPT_LASER   = $19
SPT_MISSILE = $1B
SPT_EBUL    = $1D
SPT_CAPSULE = $1F
SPT_OPTION  = $21
SPT_EXPA_L  = $23
SPT_EXPA_R  = $25
SPT_EXPB_L  = $27
SPT_EXPB_R  = $29
SPT_BOSS    = $2B               ; 8 pairs: $2B..$39
; sprite letters (top-half glyphs)
SPT_LET_S   = $3B
SPT_LET_M   = $3D
SPT_LET_D   = $3F
SPT_LET_L   = $41
SPT_LET_O   = $43
SPT_LET_F   = $45
SPT_LET_G   = $47
SPT_LET_A   = $49
SPT_LET_E   = $4B
SPT_LET_V   = $4D
SPT_LET_R   = $4F
SPT_LET_T   = $51
SPT_LET_C   = $53
SPT_LET_P   = $55
SPT_LET_U   = $57
; vertical-stage art
SPT_SHIPU_L = $59               ; up-facing ship (2 pairs)
SPT_SHIPU_R = $5B
SPT_LASER_V = $5D               ; vertical laser beam
SPT_MISS_V  = $5F               ; up-pointing missile
SPT_TURVL_L = $61               ; left-wall turret (2 pairs)
SPT_TURVL_R = $63
SPT_TURVR_L = $65               ; right-wall turret (2 pairs)
SPT_TURVR_R = $67
SPT_DARTV_L = $69               ; down-diving dart (2 pairs)
SPT_DARTV_R = $6B
SPT_BOSS2   = $6D               ; the Golem, stage-2 guardian (8 pairs: $6D..$7B)
SPT_BOSS3   = $7D               ; the Kraken, stage 3 (8 pairs)
SPT_BOSS4   = $8D               ; the Tetra, stage 4 (8 pairs)
SPT_BOSS5   = $9D               ; the Bastion, stage 5 (8 pairs)
SPT_BOSS6   = $AD               ; the Overmind, stage 6 (8 pairs)
