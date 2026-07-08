; ============================================================
; VIVAFORTE — vars.s : zeropage and BSS variables
; ============================================================

.zeropage

; -- frame/NMI sync --
nmi_count:  .res 1
frame:      .res 1
gstate:     .res 1
gtimer:     .res 1              ; generic state timer (lo)
gtimer2:    .res 1              ; generic state timer (hi)
paused:     .res 1

; -- input --
pad:        .res 1
pad_prev:   .res 1
pad_new:    .res 1              ; newly pressed this frame

; -- scroll / terrain generation --
scroll_sub: .res 1              ; subpixel accumulator
scroll16:   .res 2              ; total scrolled pixels (16-bit)
gencol:     .res 2              ; next world column (h) / row (v) to generate
cur_top:    .res 1              ; terrain generator current heights (v: left/right widths)
cur_bot:    .res 1
seg_ptr:    .res 2              ; pointer into terrain segment table
seg_base:   .res 2              ; segment table start (for end-of-table wrap)
seg_left:   .res 1              ; columns left in current segment
seg_top:    .res 1              ; segment target heights
seg_bot:    .res 1

; -- stage / vertical mode --
stage:      .res 1              ; 0-based stage counter
stage6:     .res 1              ; stage mod NUM_STAGES (data table index)
stage_req:  .res 1              ; stage selected on the title screen
vmode:      .res 1              ; 1 = vertical-scrolling stage
vscr:       .res 1              ; PPU Y scroll for the split (16 - scroll16 mod 240)
ntrow:      .res 1              ; next nametable row for the vertical row streamer
hud_hi:     .res 1              ; HUD nametable high byte ($20 hz / $24 vt)
ctrl_top:   .res 1              ; PPUCTRL value for the HUD strip at frame top

; -- credits sequence --
cred_ptr:   .res 2              ; next credits line
cred_timer: .res 1              ; frames until the next line is queued
cred_row:   .res 1              ; alternating nametable row for lines

; -- NMI mailbox flags (main sets last, NMI clears) --
colpend:    .res 1              ; column buffer ready
strpend:    .res 1              ; string buffer ready
hudpend:    .res 1              ; HUD digits ready

; -- player --
plxl:       .res 1              ; x 8.8
plxh:       .res 1
plyl:       .res 1              ; y 8.8
plyh:       .res 1
pl_speed:   .res 1              ; 0..4
pl_weapon:  .res 1              ; WPN_*
pl_missile: .res 1
pl_opts:    .res 1              ; 0..2
pl_shield:  .res 1              ; force field hits left
pl_invuln:  .res 1
pl_lives:   .res 1
pl_dead:    .res 1              ; respawn countdown (0 = alive)
fire_cd:    .res 1
miss_cd:    .res 1
meter:      .res 1              ; 0..6
hist_idx:   .res 1

; -- score --
score:      .res 6              ; digits, index 0 = ones
hiscore:    .res 6
scdirty:    .res 1

; -- wave spawner --
wv_ptr:     .res 2
wv_wait:    .res 1
wv_left:    .res 1
wv_type:    .res 1
wv_y:       .res 1
wv_gap:     .res 1
wv_flags:   .res 1
wv_mode:    .res 1              ; 0 = table, 1 = boss active, 2 = post-boss delay
difficulty: .res 1

; -- boss --
boss_hp:    .res 1
boss_x:     .res 1              ; pixel
boss_yl:    .res 1
boss_yh:    .res 1
boss_t:     .res 1              ; sine phase / timers
boss_fire:  .res 1
boss_flash: .res 1
boss_dying: .res 1

; -- sound --
mus_on:     .res 1
mus_tick:   .res 1
mus_step:   .res 1
mus_spd:    .res 1              ; frames per step for the current track
mus_bass:   .res 2              ; current track's pattern pointers
mus_drum:   .res 2
mus_mel:    .res 2
sq1_sfx:    .res 1
sq2_sfx:    .res 1
sq2_kind:   .res 1              ; 0 pickup, 1 activate
noi_sfx:    .res 1

; -- misc --
rngseed:    .res 1
oam_ptr:    .res 1
blink_t:    .res 1

; -- scratch (never survive across subroutine calls) --
col_x:      .res 1              ; collision scratch
col_y:      .res 1
col_dmg:    .res 1
tmp1:       .res 1
tmp2:       .res 1
tmp3:       .res 1
tmp4:       .res 1
tmp5:       .res 1
tmp6:       .res 1
ptr1:       .res 2
sp_y:       .res 1              ; sprite draw args
sp_tile:    .res 1
sp_attr:    .res 1
sp_x:       .res 1

.bss

; -- player bullets (SoA) --
pb_type:    .res NUM_PB
pb_xl:      .res NUM_PB
pb_xh:      .res NUM_PB
pb_yl:      .res NUM_PB
pb_yh:      .res NUM_PB
pb_vxl:     .res NUM_PB
pb_vxh:     .res NUM_PB
pb_vyl:     .res NUM_PB
pb_vyh:     .res NUM_PB

; -- enemies --
en_type:    .res NUM_EN
en_hp:      .res NUM_EN
en_xl:      .res NUM_EN
en_xh:      .res NUM_EN
en_yl:      .res NUM_EN
en_yh:      .res NUM_EN
en_t:       .res NUM_EN
en_base:    .res NUM_EN         ; base y for sine movers
en_flags:   .res NUM_EN

; -- enemy bullets --
eb_on:      .res NUM_EB
eb_xl:      .res NUM_EB
eb_xh:      .res NUM_EB
eb_yl:      .res NUM_EB
eb_yh:      .res NUM_EB
eb_vxl:     .res NUM_EB
eb_vxh:     .res NUM_EB
eb_vyl:     .res NUM_EB
eb_vyh:     .res NUM_EB

; -- capsules --
cap_on:     .res NUM_CAP
cap_x:      .res NUM_CAP        ; pixel
cap_y:      .res NUM_CAP
cap_sub:    .res NUM_CAP        ; subpixel x

; -- explosions --
ex_t:       .res NUM_EX
ex_x:       .res NUM_EX
ex_y:       .res NUM_EX

; -- option trail history (pixel positions) --
hist_x:     .res 64
hist_y:     .res 64

; -- terrain height ring buffer, indexed by world column & 63 --
ter_top:    .res 64
ter_bot:    .res 64

; -- NMI transfer buffers --
colbuf:     .res 32             ; one nametable column (28, h) or row (32, v)
colbuf_ah:  .res 1              ; PPU address of column top
colbuf_al:  .res 1
strbuf_ah:  .res 1              ; general string transfer
strbuf_al:  .res 1
strbuf_len: .res 1
strbuf:     .res 28
hudbuf:     .res 13             ; 6 score tiles, 6 hi tiles, 1 lives tile
