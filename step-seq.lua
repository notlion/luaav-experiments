local osc = require('osc')
local oscIn = osc.Recv(8000)
local oscOut = osc.Send('localhost', 10381)--15073)
local util = require('audio.util')
local Def = require('audio.Def')
Def.globalize()

local seq = require('seq'):new(16, 8)

local function getOscMessages()
  for msg in oscIn:recv() do
    if msg.addr == '/monome/grid/key' then
      print(unpack(msg))
      local x, y, v = unpack(msg)
      local rx = seq.nx - x - 1 -- Reverse X
      if v == 1 then
        local pv = seq:get(rx, y)
        if pv > 0 then v = 0 else v = 1 end
        seq:set(rx, y, v)
        oscOut:send('/monome/grid/led/set', x, y, v)
      end
    end
  end
end

local synth = Def{
  cf    = 300,
  mf    = 550,
  index = 8.1,
  dur   = 0.25,
  pan   = 0,
  Pan2{
    Env{ dur = P"dur" } *
    SinOsc{
      freq = P"cf" + SinOsc{ freq = P"mf" } * (P"mf" * P"index")
    } * 0.25,
    P"pan"
  }
}

local Mixer = Def{
  dry = 1,
  wet = 0.2,
  P'input' + Delay{
    P'wet' * P'input',
    delay = 1/4,
    feedback = 0.25
  }
}

local bus = audio.Bus("bus")
local mixer = Mixer{ input = bus }

-- Clear Monome LEDs
oscOut:send('/monome/grid/led/all', 0)

local scale = { 0, 2, 4, 7, 9 } -- Pentatonic Major

local i = 0
repeat
  getOscMessages()
  seq:play(function(x, y)
    local octave = math.floor(y / #scale) - 1
    local note = scale[y % #scale + 1]
    local freq = util.mtof(69 + octave * 12 + note)
    synth{
      cf = freq,
      mf = freq * 2.01,
      index = 2 + math.floor(i % 30),
      amp = (1 / seq.ny) * 0.5,
      -- pan = seq.position / (seq.dim - 1) * 2 - 1,
      out = bus
    }
  end)
  i = i + 1
  wait(1/8)
until false
