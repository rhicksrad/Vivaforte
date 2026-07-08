-- Full-campaign test: stages 1-6, six bosses, credits, title.
--
-- Usage:  Mesen.exe --testrunner build\vivaforte.nes nes\test\alllevels.lua
--
-- Rides invulnerably through each stage, screenshots every stage and
-- boss, force-kills each boss once it has fully entered, and verifies:
-- stage counter and scroll mode per stage, credits after stage 6,
-- staff roll runs, then back to the title. Addresses from labels.txt.

local GSTATE     = 0x04
local SCROLL16   = 0x0C
local STAGE      = 0x19
local STAGE6     = 0x1A
local VMODE      = 0x1C
local PL_INVULN  = 0x31
local PL_LIVES   = 0x32
local WV_MODE    = 0x4D
local BOSS_X     = 0x50
local BOSS_YH    = 0x52
local BOSS_DYING = 0x56

local OUT = "C:\\Users\\rhicks.RADINDIANA\\Documents\\GitHub\\Vivaforte\\nes\\build\\"
local LOG = OUT .. "alllevels_log.txt"

local frames = 0
local held = {}
local bossKilled = {}
local stageShot = {}
local stageStartFrame = {}
local credShots = 0
local credFrame = -1
local sawTitle = false

local function rd(a) return emu.read(a, emu.memType.nesMemory) end
local function wr(a, v) emu.write(a, v, emu.memType.nesMemory) end
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

  held.start = (frames >= 100 and frames <= 104)

  local g = rd(GSTATE)
  if g == 1 then wr(PL_INVULN, 120) end

  if g == 1 then
    local s = rd(STAGE)
    -- sanity + screenshot 400 frames into each new stage
    if stageStartFrame[s] == nil then
      stageStartFrame[s] = frames
      dbg(string.format("stage %d (1-based %d) entered at f=%d vmode=%d stage6=%d",
        s, s + 1, frames, rd(VMODE), rd(STAGE6)))
      if rd(VMODE) ~= (s % 2) then die("stage " .. s .. " wrong scroll mode") end
      if rd(STAGE6) ~= (s % 6) then die("stage " .. s .. " wrong stage6") end
    end
    if not stageShot[s] and frames == stageStartFrame[s] + 400 then
      stageShot[s] = true
      snap(string.format("run_stage%d.png", s + 1))
    end
    -- boss handling: screenshot when fully entered, then detonate
    if not bossKilled[s] and rd(WV_MODE) == 1 and rd(BOSS_DYING) == 0 then
      local entered
      if s % 2 == 0 then entered = rd(BOSS_X) <= 200
      else entered = rd(BOSS_YH) >= 48 end
      if entered then
        snap(string.format("run_boss%d.png", s + 1))
        wr(BOSS_DYING, 8)
        bossKilled[s] = true
        dbg(string.format("boss %d detonated at f=%d", s + 1, frames))
      end
    end
  end

  if g == 4 then                -- ST_CREDITS
    if credFrame < 0 then
      credFrame = frames
      dbg("credits entered at f=" .. frames)
      if not bossKilled[5] then die("credits before stage 6 boss died") end
      held.b = true             -- join the shooting gallery
    end
    if credShots == 0 and frames == credFrame + 700 then
      credShots = 1
      snap("run_credits1.png")
    end
    if credShots == 1 and frames == credFrame + 2600 then
      credShots = 2
      snap("run_credits2.png")
    end
  end

  if credFrame > 0 and g == 0 and not sawTitle then
    sawTitle = true
    dbg("returned to title at f=" .. frames)
    if rd(PL_LIVES) > 3 then die("weird lives count " .. rd(PL_LIVES)) end
    dbg("PASS")
    emu.stop(0)
  end

  if frames == 45000 then
    for s = 0, 5 do
      if not bossKilled[s] then die("never killed boss " .. (s + 1)) end
    end
    if credFrame < 0 then die("credits never started") end
    die("never returned to title")
  end
end

emu.addEventCallback(onFrame, emu.eventType.endFrame)
emu.addEventCallback(onPoll, emu.eventType.inputPolled)
