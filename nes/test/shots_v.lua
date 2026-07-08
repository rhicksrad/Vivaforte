-- Capture vertical-stage screenshots (dev aid, not a pass/fail test).
-- Usage: Mesen.exe --testrunner build\vivaforte.nes nes\test\shots_v.lua
-- Requires AllowIoOsAccess. Writes PNGs next to the ROM's build dir.

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
  held.select = (frames >= 100 and frames <= 104)
  if frames > 140 then
    held.b = true
    held.up = (frames % 240) < 100
    held.left = (frames % 120) < 50
    held.right = (frames % 120) >= 60 and (frames % 120) < 110
  end
  if frames == 300 then snap("vert300.png") end
  if frames == 900 then snap("vert900.png") end
  if frames == 1800 then
    snap("vert1800.png")
    emu.stop(0)
  end
end

emu.addEventCallback(onFrame, emu.eventType.endFrame)
emu.addEventCallback(onPoll, emu.eventType.inputPolled)
