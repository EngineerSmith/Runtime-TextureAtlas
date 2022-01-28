-- Copyright (c) 2021 EngineerSmith
-- Under the MIT license, see license suppiled with this file

-- Custom algorithm to solve the rectangle packing problem
-- As every other algorithm only solved the bin packing problem

local path = select(1, ...):match("(.-)[^%.]+$")
local util = require(path .. "util")
local lg = love.graphics
local insert, remove = table.insert, table.remove

local cell = {}
cell.__index = {}

cell.new = function(x, y, w, h, data)
  return setmetatable({
      x = x, y = y, w= w, h = h,
      data = data,
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

grid.insert = function(self, width, height, data)
  for index, unoccupiedCell in ipairs(self.unoccupiedCells) do
    if unoccupiedCell.w == width and unoccupiedCell.h == height then
      unoccupiedCell.data = data
      remove(self.unoccupiedCells, index)
      insert(self.cells, unoccupiedCell)
      return true
    elseif unoccupiedCell.w == width and unoccupiedCell.h > height then
      insert(self.unoccupiedCells, cell.new(unoccupiedCell.x, unoccupiedCell.y+height, unoccupiedCell.w, unoccupiedCell.h-height))
      remove(self.unoccupiedCells, index)
      unoccupiedCell.h, unoccupiedCell.data = height, data
      insert(self.cells, unoccupiedCell)
      return true
    elseif unoccupiedCell.h == height and unoccupiedCell.w > width then
      insert(self.unoccupiedCells, cell.new(unoccupiedCell.x+width, unoccupiedCell.y, unoccupiedCell.w-width, unoccupiedCell.h))
      remove(self.unoccupiedCells, index)
      unoccupiedCell.w, unoccupiedCell.data = width, data
      insert(self.cells, unoccupiedCell)
      return true
    elseif unoccupiedCell.w > width and unoccupiedCell.h > height then
      -- split and add
      if width > height then
        insert(self.unoccupiedCells, cell.new(unoccupiedCell.x+width, unoccupiedCell.y, unoccupiedCell.w-width, height)) -- right
        insert(self.unoccupiedCells, cell.new(unoccupiedCell.x, unoccupiedCell.y+height, unoccupiedCell.w, unoccupiedCell.h-height)) -- bottom
      else
        insert(self.unoccupiedCells, cell.new(unoccupiedCell.x+width, unoccupiedCell.y, unoccupiedCell.w-width, unoccupiedCell.h)) -- right
        insert(self.unoccupiedCells, cell.new(unoccupiedCell.x, unoccupiedCell.y+height, width, unoccupiedCell.h-height)) -- bottom
      end
      remove(self.unoccupiedCells, index)
      unoccupiedCell.w, unoccupiedCell.h, unoccupiedCell.data = width, height, data
      insert(self.cells, unoccupiedCell)
      return true
    end
  end
  -- score edge placement
  local overBottom = width - self.currentWidth -- over hang cost
  if overBottom > 0 then
    overBottom = self.currentHeight * overBottom
  else
    overBottom = 0
  end
  local bottomScore = height * width + overBottom
  local overRight = height - self.currentHeight -- over hang cost
  if overRight > 0 then
    overRight = self.currentHeight * overRight
  else
    overRight = 0
  end
  local rightScore = height * width + overRight
  if bottomScore == rightScore then
    if width > height then
      rightScore = bottomScore + 1
    else
      bottomScore = rightScore + 1
    end
  end
  
  -- limits
  local limitWidth = self.currentWidth + width > self.limitWidth
  local limitHeight = self.currentHeight + height > self.limitHeight
  if limitHeight and limitWidth then
    error("Could not fit all images within texture atlas")
  elseif limitHeight or limitWidth then
    
  end
  
  -- add best new cells
  if bottomScore < rightScore then -- place bottom
    insert(self.cells, cell.new(0, self.currentHeight, width, height, data))
    if self.currentWidth > width then
      insert(self.unoccupiedCells, cell.new(width, self.currentHeight, self.currentWidth-width, height))
    elseif self.currentWidth < width then
      self.currentWidth = width
    end
    self.currentHeight = self.currentHeight + height
  else -- place right
    insert(self.cells, cell.new(self.currentWidth, 0, width, height, data))
    if self.currentHeight > height then
      insert(self.unoccupiedCells, cell.new(self.currentWidth, height, width, self.currentHeight-height))
    elseif self.currentHeight < height then
      self.currentHeight = height
    end
    self.currentWidth = self.currentWidth + width
  end
  -- merge unoccupied cells : pick biggest direction
  return true
end

grid.draw = function(self, quads, width, height, extrude, padding, imageData)
  for _, cell in ipairs(self.cells) do
    local image = cell.data.image
    local iwidth, iheight = util.getImageDimensions(image)
    if imageData then
      local x, y = cell.x + padding + extrude, cell.y + padding + extrude
      imageData:paste(image, x, y, 0,0, iwidth, iheight)
      if extrude > 0 then
        util.extrudeWithFill(imageData, image, extrude, x, y)
      end
      quads[cell.data.id] = {x, y, iwidth, iheight}
    else
      local extrudeQuad = lg.newQuad(-extrude, -extrude, iwidth+extrude*2, iheight+extrude*2, iwidth, iheight)
      lg.draw(image, extrudeQuad, cell.x+padding, cell.y+padding)
      quads[cell.data.id] = lg.newQuad(cell.x+extrude+padding, cell.y+extrude+padding, iwidth, iheight, width, height)
    end
  end
end

return grid