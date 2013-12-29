local osc = require('osc')
local oscIn = osc.Recv(8000)
local oscOut = osc.Send('localhost', 15073)
local util = require('audio.util')
local Def = require('audio.Def')
Def.globalize()

local seq = require('seq'):new(8)

local function getOscMessages()
  for msg in oscIn:recv() do
    if msg.addr == '/monome/grid/key' then
      local x, y, v = unpack(msg)
      if v == 1 then
        local pv = seq:get(x, y)
        if pv > 0 then v = 0 else v = 1 end
        seq:set(x, y, v)
        oscOut:send('/monome/grid/led/set', x, y, v)
      end
    end
  end
end

local synth = Def{
  cf    = 300,
  mf    = 550,
  index = 5,
  dur   = 0.5,

  Env{ dur = P"dur" } *

  SinOsc{
    freq = P"cf" + SinOsc{ freq = P"mf" } * (P"mf" * P"index")
  } * 0.25
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

repeat
  getOscMessages()
  seq:play(function(x, y)
    local octave = math.floor(x / #scale) - 1
    local note = scale[x % #scale + 1]
    local freq = util.mtof(69 + octave * 12 + note)
    synth{
      cf = freq,
      mf = freq * 2.01,
      amp = (1 / seq.dim) * 0.5,
      pan = seq.position / (seq.dim - 1) * 2 - 1,
      out = bus
    }
  end)
  wait(1/8)
until false
