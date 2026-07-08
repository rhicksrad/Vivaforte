-- Stage 1 -> stage 2 transition test for the Mesen 2 test runner.
--
-- Usage:  Mesen.exe --testrunner build\vivaforte.nes nes\test\transition.lua
--
-- Plays stage 1 until the boss arrives, force-starts its death sequence
-- (writes boss_dying), then verifies STAGE CLEAR leads into the
-- vertical-scrolling stage 2 with the engine in a sane state.
-- Addresses from nes/build/labels.txt.

local GSTATE     = 0x04
local SCROLL16   = 0x0C
local GENCOL     = 0x0E
local STAGE      = 0x19
local VMODE      = 0x1C
local VSCR       = 0x1D
local PL_INVULN  = 0x31
local PL_LIVES   = 0x32
local WV_MODE    = 0x4D
local BOSS_X     = 0x50
local BOSS_DYING = 0x56

local LOG = "C:\\Users\\rhicks.RADINDIANA\\Documents\\GitHub\\Vivaforte\\nes\\build\\transition_log.txt"

local frames = 0
local held = {}
local killed = false
local sawClear = false
local vertFrame = -1

local function rd(a) return emu.read(a, emu.memType.nesMemory) end
local function wr(a, v) emu.write(a, v, emu.memType.nesMemory) end
local function rd16(a) return rd(a) + 256 * rd(a + 1) end
local function dbg(msg)
  local f = io.open(LOG, "a")
  if f then f:write(msg .. "\n") f:close() end
end
local function die(msg) dbg("FAIL: " .. msg) emu.stop(1) end
local function onPoll() emu.setInput(held, 0) end

local function onFrame()
  frames = frames + 1

  held.start = (frames >= 100 and frames <= 104)

  -- cheat: keep the ship invulnerable so it reliably reaches the boss
  if frames > 140 and rd(GSTATE) == 1 then wr(PL_INVULN, 120) end

  if frames % 600 == 0 then
    dbg(string.format("f=%d gstate=%d lives=%d wv_mode=%d boss_x=%d stage=%d vmode=%d",
      frames, rd(GSTATE), rd(PL_LIVES), rd(WV_MODE), rd(BOSS_X), rd(STAGE), rd(VMODE)))
  end

  -- once the boss owns the wave slot and has slid in, detonate it
  if not killed and frames > 200 and rd(GSTATE) == 1
     and rd(WV_MODE) == 1 and rd(BOSS_X) <= 200 then
    wr(BOSS_DYING, 8)
    killed = true
    dbg("boss detonated at frame " .. frames)
  end

  if killed and rd(GSTATE) == 3 then sawClear = true end

  if sawClear and vertFrame < 0 and rd(GSTATE) == 1 then
    vertFrame = frames
    dbg("stage 2 entered at frame " .. frames)
    if rd(STAGE) ~= 1 then die("expected stage 1 after clear, got " .. rd(STAGE)) end
    if rd(VMODE) ~= 1 then die("stage 2 is not vertical") end
    if rd16(GENCOL) < 30 then die("vertical terrain not initialized") end
  end

  -- let stage 2 run a while and re-check the scroll engine
  if vertFrame > 0 and frames == vertFrame + 300 then
    local s = rd16(SCROLL16)
    if s == 0 then die("stage 2 scroll not advancing") end
    local expect = (16 - s) % 240
    if rd(VSCR) ~= expect then
      die(string.format("stage 2 vscr %d != expected %d", rd(VSCR), expect))
    end
    dbg("PASS")
    emu.stop(0)
  end

  if frames == 12000 then
    if not killed then die("boss never arrived") end
    if not sawClear then die("STAGE CLEAR never happened") end
    die("stage 2 never started")
  end
end

emu.addEventCallback(onFrame, emu.eventType.endFrame)
emu.addEventCallback(onPoll, emu.eventType.inputPolled)
