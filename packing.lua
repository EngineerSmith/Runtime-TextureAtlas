-- Copyright (c) 2021 EngineerSmith
-- Under the MIT license, see license suppiled with this file

-- Custom algorithm to solve the rectangle packing problem
-- As every other algorithm only solved the bin packing problem

local cell = {}
cell.__index = {}

cell.new = function(x, y, z, w)
  return setmetatable({
      x = x, y = y, z = z, w = w,
      image = nil,
    }, cell)
end

local grid = {}
grid.__index = grid

grid.new = function(limitWidth, limitHeight)
  return setmetatable({
      limitWidth  = limitWidth,
      limitHeight = limitHeight,
      currentWidth = 0,
      currentHeight = 0,
      cells = {},
      unoccupiedCells = {},
    }, grid)
end

grid.insert = function(self, width, height, image)
  for index, cell in ipairs(self.unoccupiedCells) do
    if cell.w == width and cell.h >= height then
      -- split and add
      return
    elseif cell.h == height and cell.w >= width then
      -- split and add
      return
    elseif cell.w < width and cell.h < height then
      -- split and add
      return
    end
  end
  -- go to edge and score placement
end

return grid