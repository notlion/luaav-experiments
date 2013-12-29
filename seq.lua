local Seq = {}
Seq.__index = Seq

local function createGrid(dim)
  local grid = {}
  for i = 1, 8 * 8 do grid[i] = 0 end
  return grid
end

function Seq:new(dim)
  seq = {
    grid = createGrid(dim),
    dim = dim,
    position = 0
  }
  return setmetatable(seq, self)
end

function Seq:get(x, y)
  return self.grid[y * self.dim + x + 1]
end

function Seq:set(x, y, value)
  self.grid[y * self.dim + x + 1] = value
end

function Seq:play(callback)
  local dim, scale, position = self.dim, self.scale, self.position

  for x = 0, dim - 1 do
    local v = self:get(x, position)
    if v > 0 then
      callback(x, y)
    end
  end

  self.position = (position + 1) % dim
end

return Seq
