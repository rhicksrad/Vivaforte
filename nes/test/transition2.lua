-- Stage 2 (vertical) boss + stage 2 -> 3 transition test for Mesen 2.
--
-- Usage:  Mesen.exe --testrunner build\vivaforte.nes nes\test\transition2.lua
--
-- Starts on stage 2 via SELECT, rides invulnerably to the Golem,
-- screenshots it, force-starts its death, then verifies the handoff
-- back to a horizontal stage 3. Addresses from nes/build/labels.txt.

local GSTATE     = 0x04
local SCROLL16   = 0x0C
local STAGE      = 0x19
local VMODE      = 0x1C
local PL_INVULN  = 0x31
local WV_MODE    = 0x4D
local BOSS_YH    = 0x52
local BOSS_DYING = 0x56

local OUT = "C:\\Users\\rhicks.RADINDIANA\\Documents\\GitHub\\Vivaforte\\nes\\build\\"
local LOG = OUT .. "transition2_log.txt"

local frames = 0
local held = {}
local killed = false
local sawClear = false
local hzFrame = -1

local function rd(a) return emu.read(a, emu.memType.nesMemory) end
local function wr(a, v) emu.write(a, v, emu.memType.nesMemory) end
local function rd16(a) return rd(a) + 256 * rd(a + 1) end
local function dbg(msg)
  local f = io.open(LOG, "a")
  if f then f:write(msg .. "\n") f:close() end
end
local function die(msg) dbg("FAIL: " .. msg) emu.stop(1) end
local function snap(name)
  local png = emu.takeScreenshot()
  local f = io.open(OUT .. name, "wb")
  f:write(png)
  f:close()
end
local function onPoll() emu.setInput(held, 0) end

local function onFrame()
  frames = frames + 1

  held.select = (frames >= 100 and frames <= 104)
  if frames > 140 and rd(GSTATE) == 1 then wr(PL_INVULN, 120) end

  -- Golem on screen and fully entered: screenshot, then detonate
  if not killed and frames > 200 and rd(GSTATE) == 1
     and rd(WV_MODE) == 1 and rd(BOSS_YH) >= 48 then
    if rd(BOSS_DYING) == 0 then
      snap("golem.png")
      wr(BOSS_DYING, 8)
      killed = true
      dbg("golem detonated at frame " .. frames)
    end
  end

  if killed and rd(GSTATE) == 3 then sawClear = true end

  if sawClear and hzFrame < 0 and rd(GSTATE) == 1 then
    hzFrame = frames
    dbg("stage 3 entered at frame " .. frames)
    if rd(STAGE) ~= 2 then die("expected stage 2 (0-based) after clear, got " .. rd(STAGE)) end
    if rd(VMODE) ~= 0 then die("stage 3 should scroll horizontally") end
  end

  if hzFrame > 0 and frames == hzFrame + 300 then
    if rd16(SCROLL16) == 0 then die("stage 3 scroll not advancing") end
    snap("stage3.png")
    dbg("PASS")
    emu.stop(0)
  end

  if frames == 12000 then
    if not killed then die("golem never arrived") end
    if not sawClear then die("STAGE CLEAR never happened") end
    die("stage 3 never started")
  end
end

emu.addEventCallback(onFrame, emu.eventType.endFrame)
emu.addEventCallback(onPoll, emu.eventType.inputPolled)
