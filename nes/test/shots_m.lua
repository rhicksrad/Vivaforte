-- Capture 2-way missile screenshots on both stages (dev aid).
-- Usage: Mesen.exe --testrunner build\vivaforte.nes nes\test\shots_m.lua
-- Pokes pl_missile so missiles are armed without capsule farming.

local GSTATE     = 0x04
local PL_MISSILE = 0x2E
local PL_INVULN  = 0x31

local OUT = "C:\\Users\\rhicks.RADINDIANA\\Documents\\GitHub\\Vivaforte\\nes\\build\\"

local frames = 0
local held = {}

local function rd(a) return emu.read(a, emu.memType.nesMemory) end
local function wr(a, v) emu.write(a, v, emu.memType.nesMemory) end
local function snap(name)
  local png = emu.takeScreenshot()
  local f = io.open(OUT .. name, "wb")
  f:write(png)
  f:close()
end
local function onPoll() emu.setInput(held, 0) end

local function onFrame()
  frames = frames + 1
  -- run 1: START (horizontal). Swap to SELECT for the vertical shot.
  held.start = (frames >= 100 and frames <= 104)
  if frames > 140 and rd(GSTATE) == 1 then
    wr(PL_MISSILE, 1)
    wr(PL_INVULN, 120)
    held.b = true
  end
  if frames == 450 then snap("missiles_h1.png") end
  if frames == 520 then
    snap("missiles_h2.png")
    emu.stop(0)
  end
end

emu.addEventCallback(onFrame, emu.eventType.endFrame)
emu.addEventCallback(onPoll, emu.eventType.inputPolled)
