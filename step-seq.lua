local osc = require('osc')
local oscIn = osc.Recv(8000)
local oscOut = osc.Send('localhost', 15073)

local Def = require('audio.Def')
Def.globalize()

local seq = require('seq'):new(8)

local function getOscMessages()
  for msg in oscIn:recv() do
    if msg.addr == '/monome/grid/key' then
      local x, y, v = unpack(msg)
      if v == 1 then
        local pv = seq:get(x, y)
        if pv > 0 then
          v = 0
        else
          v = 1
        end
        seq:set(x, y, v)
        oscOut:send('/monome/grid/led/set', x, y, v)
      end
    end
  end
end

local Synth = Def{
  freq = 110,
  amp = 0.5,
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

-- Clear Monome LEDs
oscOut:send('/monome/grid/led/all', 0)

repeat
  getOscMessages()
  seq:play(Synth)
  wait(0.1)
until false
