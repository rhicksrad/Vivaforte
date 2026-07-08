-- VIVAFORTE vertical-stage (stage 2) test for the Mesen 2 test runner.
--
-- Usage:  Mesen.exe --testrunner build\vivaforte.nes nes\test\vertical.lua
--
-- Presses SELECT on the title screen, which starts the game directly on
-- the vertical-scrolling stage, then checks the vertical engine's state.
--
-- Zero-page addresses below come from nes/build/labels.txt (ld65 -Ln
-- output). If you change vars.s, regenerate and update them.

local NMI_COUNT = 0x02
local GSTATE    = 0x04
local SCROLL16  = 0x0C
local GENCOL    = 0x0E
local STAGE     = 0x19
local VMODE     = 0x1C
local VSCR      = 0x1D
local PLXH      = 0x29
local PLYH      = 0x2B
local PL_LIVES  = 0x32
local PL_DEAD   = 0x33
local EN_TYPE   = 0x36C

local frames = 0
local held = {}
local sawEnemy = false
local scroll0 = -1
local gencol0 = -1

local function rd(a) return emu.read(a, emu.memType.nesMemory) end
local function rd16(a) return rd(a) + 256 * rd(a + 1) end
local function die(msg) emu.log("FAIL: " .. msg) emu.stop(1) end
local function onPoll() emu.setInput(held, 0) end

local function onFrame()
  frames = frames + 1

  held.select = (frames >= 100 and frames <= 104)

  if frames == 140 then
    if rd(GSTATE) ~= 1 then die("expected play state after SELECT, got " .. rd(GSTATE)) end
    if rd(STAGE) ~= 1 then die("expected stage 1 (0-based), got " .. rd(STAGE)) end
    if rd(VMODE) ~= 1 then die("expected vertical mode") end
    if rd(PL_LIVES) ~= 3 then die("expected 3 lives, got " .. rd(PL_LIVES)) end
    -- ship spawns bottom center in vertical stages
    if rd(PLXH) < 0x60 or rd(PLXH) > 0x90 then die("bad vertical spawn x " .. rd(PLXH)) end
    if rd(PLYH) < 0xB0 then die("bad vertical spawn y " .. rd(PLYH)) end
    scroll0 = rd16(SCROLL16)
    gencol0 = rd16(GENCOL)
    if gencol0 < 30 then die("initial rows not generated: gencol " .. gencol0) end
  end

  if frames > 140 and frames < 3600 then
    -- weave left/right while firing so waves get engaged
    local leftright = (math.floor(frames / 60) % 2) == 0
    held.b = true
    held.left = leftright
    held.right = not leftright
  end

  if frames == 400 then
    local s = rd16(SCROLL16)
    if s == scroll0 then die("scroll not advancing during vertical play") end
    -- vscr must track (16 - scroll16) mod 240
    local expect = (16 - s) % 240
    if rd(VSCR) ~= expect then
      die(string.format("vscr %d != expected %d (scroll %d)", rd(VSCR), expect, s))
    end
    if rd16(GENCOL) == gencol0 then die("row streamer not generating") end
  end

  if frames > 200 then
    for i = 0, 7 do
      if rd(EN_TYPE + i) ~= 0 then sawEnemy = true end
    end
  end

  if frames == 2000 then
    -- row streamer must stay ahead of the visible window
    local s = rd16(SCROLL16)
    local need = math.floor(s / 8) + 28
    if rd16(GENCOL) < need then
      die(string.format("row streamer fell behind: gencol %d < need %d", rd16(GENCOL), need))
    end
  end

  if frames == 3600 then
    if not sawEnemy then die("no enemies ever spawned on the vertical stage") end
    if rd(GSTATE) > 3 then die("bad game state " .. rd(GSTATE)) end
    if rd(VMODE) ~= 1 then die("vmode flag lost during play") end
    emu.log("PASS")
    emu.stop(0)
  end
end

emu.addEventCallback(onFrame, emu.eventType.endFrame)
emu.addEventCallback(onPoll, emu.eventType.inputPolled)
