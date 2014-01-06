local Seq = {}
Seq.__index = Seq

local function createGrid(nx, ny)
  local grid = {}
  for i = 1, nx * ny do grid[i] = 0 end
  return grid
end

function Seq:new(nx, ny)
  seq = {
    grid = createGrid(nx, ny),
    nx = nx,
    ny = ny,
    position = 0
  }
  return setmetatable(seq, self)
end

function Seq:get(x, y)
  return self.grid[y * self.nx + x + 1]
end

function Seq:set(x, y, value)
  self.grid[y * self.nx + x + 1] = value
end

function Seq:play(callback)
  local scale, position = self.scale, self.position

  for y = 0, self.ny - 1 do
    local v = self:get(position, y)
    if v > 0 then
      callback(position, y)
    end
  end

  self.position = (position + 1) % self.nx
end

return Seq
