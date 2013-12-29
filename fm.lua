local util = require('audio.util')
local Def = require('audio.Def')
Def.globalize()

local scale = { 0, 2, 4, 7, 9 }

local synth = Def{
  cf    = 300,
  mf    = 550,
  index = 2,
  dur   = 0.5,

  Env{ dur = P"dur" } *

  SinOsc{
    freq = P"cf" + SinOsc{ freq = P"mf" } * (P"mf" * P"index")
  } *

  0.3
}

local i = 0
repeat
  local note = 69 + scale[i % #scale + 1]
  local freq = util.mtof(note)
  synth{
    cf = freq,
    mf = freq * 2,
    index = 2
  }
  i = i + 1
  wait(1)
until false
