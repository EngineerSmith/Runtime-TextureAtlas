-- Copyright (c) 2021 EngineerSmith
-- Under the MIT license, see license suppiled with this file

-- Custom algorithm to solve the rectangle packing problem
-- As every other algorithm only solved the bin packing problem

local insert, remove = table.insert, table.remove

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
      currentWidth  = 0,
      currentHeight = 0,
      cells = {},
      unoccupiedCells = {},
    }, grid)
end

grid.insert = function(self, width, height, image)
  for index, unoccupiedCell in ipairs(self.unoccupiedCells) do
    if unoccupiedCell.w == width and unoccupiedCell.h == height then
      unoccupiedCell.image = image
      remove(self.unoccupiedCells, index)
      insert(self.cells, unoccupiedCell)
      return
    elseif cell.w == width and cell.h > height then
      insert(self.unoccupiedCells, cell.new(unoccupiedCell.x, unoccupiedCell.y+height, width, height-unoccupiedCell.h))
      remove(self.unoccupiedCells, index)
      unoccupiedCell.h, unoccupiedCell.image = height, image
      insert(self.cells, unoccupiedCell) -- top
      return
    elseif cell.h == height and cell.w > width then
      insert(self.unoccupiedCells, cell.new(unoccupiedCell.x+width, unoccupiedCell.y, width-unoccupiedCell.w, height))
      remove(self.unoccupiedCells, index)
      unoccupiedCell.w, unoccupiedCell.image = width, image
      insert(self.cells, unoccupiedCell)
      return
    elseif cell.w > width and cell.h > height then
      -- split and add
      insert(self.unoccupiedCells, cell.new(unoccupiedCell.x+width, unoccupiedCell.y+height, width-unoccupiedCell.w, height-unoccupiedCell.h))
      remove(self.unoccupiedCells, index)
      unoccupiedCell.w, unoccupiedCell.h, unoccupiedCell.image = width, height, image
      insert(self.cells, unoccupiedCell)
      return
    end
  end
  -- go to edge and score placement
end

return grid