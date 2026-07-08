-- Capture horizontal-stage screenshots (dev aid, not a pass/fail test).
-- Usage: Mesen.exe --testrunner build\vivaforte.nes nes\test\shots_h.lua

local OUT = "C:\\Users\\rhicks.RADINDIANA\\Documents\\GitHub\\Vivaforte\\nes\\build\\"

local frames = 0
local held = {}
local function onPoll() emu.setInput(held, 0) end

local function snap(name)
  local png = emu.takeScreenshot()
  local f = io.open(OUT .. name, "wb")
  f:write(png)
  f:close()
end

local function onFrame()
  frames = frames + 1
  held.start = (frames >= 100 and frames <= 104)
  if frames > 140 then
    held.b = true
    held.up = (frames % 240) < 100
    held.down = (frames % 240) >= 120 and (frames % 240) < 220
  end
  if frames == 900 then
    snap("horz900.png")
    emu.stop(0)
  end
end

emu.addEventCallback(onFrame, emu.eventType.endFrame)
emu.addEventCallback(onPoll, emu.eventType.inputPolled)
