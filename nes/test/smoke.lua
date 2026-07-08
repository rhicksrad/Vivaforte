-- VIVAFORTE smoke test for the Mesen 2 test runner.
--
-- Usage:  Mesen.exe --testrunner build\vivaforte.nes nes\test\smoke.lua
--
-- Requires Mesen 2 with the script sandbox relaxed:
--   Documents\Mesen2\settings.json ->  "AllowIoOsAccess": true, "ScriptTimeout": 120
-- (Only needed for the screenshot; RAM checks work without it.)
--
-- Zero-page addresses below come from nes/build/labels.txt (ld65 -Ln output).
-- If you change vars.s, regenerate and update them.

local NMI_COUNT = 0x02
local GSTATE    = 0x04
local SCROLL16  = 0x0C
local PL_LIVES  = 0x24
local SCORE     = 0x2A
local EN_TYPE   = 0x35A

local frames = 0
local held = {}
local sawEnemy = false
local titleNmi0 = -1
local scroll0 = -1

local function rd(a) return emu.read(a, emu.memType.nesMemory) end
local function die(msg) emu.log("FAIL: " .. msg) emu.stop(1) end
local function onPoll() emu.setInput(held, 0) end

local function onFrame()
  frames = frames + 1

  if frames == 30 then titleNmi0 = rd(NMI_COUNT) end
  if frames == 90 then
    if rd(NMI_COUNT) == titleNmi0 then die("NMI counter not advancing on title") end
    if rd(GSTATE) ~= 0 then die("expected title state, got " .. rd(GSTATE)) end
  end

  held.start = (frames >= 100 and frames <= 104)

  if frames == 140 then
    if rd(GSTATE) ~= 1 then die("expected play state after START, got " .. rd(GSTATE)) end
    if rd(PL_LIVES) ~= 3 then die("expected 3 lives, got " .. rd(PL_LIVES)) end
    scroll0 = rd(SCROLL16) + 256 * rd(SCROLL16 + 1)
  end

  if frames > 140 and frames < 3600 then
    local updown = (math.floor(frames / 60) % 2) == 0
    held.b = true
    held.up = updown
    held.down = not updown
  end

  if frames == 400 then
    local s = rd(SCROLL16) + 256 * rd(SCROLL16 + 1)
    if s == scroll0 then die("scroll not advancing during play") end
  end

  if frames > 200 then
    for i = 0, 7 do
      if rd(EN_TYPE + i) ~= 0 then sawEnemy = true end
    end
  end

  if frames == 3600 then
    if not sawEnemy then die("no enemies ever spawned") end
    if rd(GSTATE) > 3 then die("bad game state " .. rd(GSTATE)) end
    emu.log("PASS")
    emu.stop(0)
  end
end

emu.addEventCallback(onFrame, emu.eventType.endFrame)
emu.addEventCallback(onPoll, emu.eventType.inputPolled)
