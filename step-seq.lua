local osc = require('osc')
local oscIn = osc.Recv(8000)
local oscOut = osc.Send('localhost', 15073)

function getOscMessages()
  for msg in oscIn:recv() do
    if msg.addr == '/monome/grid/key' then
      local x, y, v = unpack(msg)
      if v == 1 then
        local pv = getGrid(x, y)
        if pv > 0 then
          v = 0
        else
          v = 1
        end
        setGrid(x, y, v)
        oscOut:send('/monome/grid/led/set', x, y, v)
      end
    end
  end
end

local gridDim = 8
local grid = {}
for i = 1, 8 * 8 do grid[i] = 0 end

function getGrid(x, y)
  return grid[y * gridDim + x + 1]
end

function setGrid(x, y, v)
  grid[y * gridDim + x + 1] = v
end

local util = require('audio.util')
local Def  = require('audio.Def')
Def.globalize()

local Synth = Def{
  freq = 110,
  amp = 0.2,
  pan = 0,
  Pan2{
    Env{ dur = 1 } * Square{ freq = P'freq' } * P'amp',
    P'pan'
  }
}

local Mixer = Def{
  dry = 1,
  wet = 0.2,
  -- P'input' + Delay{
  --   P'wet' * P'input',
  --   delay = 1/4,
  --   feedback = 0.25
  -- }
  P'input' + Reverb{
    P'wet' * P'input',
    decay=0.1,
    bandwidth=0.9995,
    damping=0.2
  }
}

local bus = audio.Bus("bus")
local mixer = Mixer{ input = bus }

local y = 0

-- Clear Monome LEDs
oscOut:send('/monome/grid/led/all', 0)

local pentatonicMajor = { 0, 2, 4, 7, 9 }
local scale = pentatonicMajor

repeat
  getOscMessages()

  local freqs = {}
  for x = 0, gridDim - 1 do
    local v = getGrid(x, y)
    if v > 0 then
      local octave = math.floor(x / #scale) - 1
      local note = scale[x % #scale + 1]
      local freq = util.mtof(69 + octave * 12 + note)
      table.insert(freqs, freq)
    end
  end

  for i = 1, #freqs do
    Synth{
      amp  = (1 / 8) * 0.5,
      freq = freqs[i],
      pan  = y / (gridDim - 1) * 2 - 1,
      -- out  = bus -- Pan is not working with effects for some reason.
    }
  end

  y = (y + 1) % gridDim
  wait(0.1)
until false
