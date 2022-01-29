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
  if width > self.limitWidth then
    error("Given image's width("..width..") is bigger than the limit("..self.limitWidth.."). Image ID: "..data.id)
    return false
  elseif height > self.limitHeight then
    error("Given image's height("..height..") is bigger than the limit("..self.limitHeight.."). Image ID: "..data.id)
    return false
  end
  
  -- check if there are any unoccupied cells available for placement
  for index, unoccupiedCell in ipairs(self.unoccupiedCells) do
    -- perfect fit
    if unoccupiedCell.w == width and unoccupiedCell.h == height then
      unoccupiedCell.data = data
      insert(self.cells, unoccupiedCell)
      remove(self.unoccupiedCells, index)
      return true
    -- width is perfect, so cut height
    elseif unoccupiedCell.w == width and unoccupiedCell.h > height then
      insert(self.unoccupiedCells, cell.new(unoccupiedCell.x, unoccupiedCell.y+height, unoccupiedCell.w, unoccupiedCell.h-height))
      unoccupiedCell.h, unoccupiedCell.data = height, data
      insert(self.cells, unoccupiedCell)
      remove(self.unoccupiedCells, index)
      return true
    -- height is perfect, so cut width
    elseif unoccupiedCell.h == height and unoccupiedCell.w > width then
      insert(self.unoccupiedCells, cell.new(unoccupiedCell.x+width, unoccupiedCell.y, unoccupiedCell.w-width, unoccupiedCell.h))
      unoccupiedCell.w, unoccupiedCell.data = width, data
      insert(self.cells, unoccupiedCell)
      remove(self.unoccupiedCells, index)
      return true
    -- cell is big enough to fit but needs cutting down to size
    elseif unoccupiedCell.w > width and unoccupiedCell.h > height then
      -- pick best direction to cut
      if width > height then
        insert(self.unoccupiedCells, cell.new(unoccupiedCell.x+width, unoccupiedCell.y, unoccupiedCell.w-width, height)) -- right
        insert(self.unoccupiedCells, cell.new(unoccupiedCell.x, unoccupiedCell.y+height, unoccupiedCell.w, unoccupiedCell.h-height)) -- bottom
      else
        insert(self.unoccupiedCells, cell.new(unoccupiedCell.x+width, unoccupiedCell.y, unoccupiedCell.w-width, unoccupiedCell.h)) -- right
        insert(self.unoccupiedCells, cell.new(unoccupiedCell.x, unoccupiedCell.y+height, width, unoccupiedCell.h-height)) -- bottom
      end
      unoccupiedCell.w, unoccupiedCell.h, unoccupiedCell.data = width, height, data
      insert(self.cells, unoccupiedCell)
      remove(self.unoccupiedCells, index)
      return true
    end
  end
  -- no unoccupied cells suitable, create new cell
  
  -- score edge placement to find cheapest grow cost
  local overBottom = width - self.currentWidth -- over hang cost
  if overBottom > 0 then
    overBottom = self.currentHeight * overBottom
  else
    overBottom = 0
  end
  local bottomScore = height * (width > self.currentWidth and width or self.currentWidth) + overBottom
  
  local overRight = height - self.currentHeight -- over hang cost
  if overRight > 0 then
    overRight = self.currentHeight * overRight
  else
    overRight = 0
  end
  local rightScore = (height > self.currentHeight and height or self.currentHeight) * width + overRight
  
  -- Pick a direction to lean if scores are equal
  if bottomScore == rightScore then
    if width > height then
      rightScore = bottomScore + 1 -- place bottom
    else
      bottomScore = rightScore + 1 -- place right
    end
  end
  
  -- limits
  local limitWidth = self.currentWidth + width > self.limitWidth
  local limitHeight = self.currentHeight + height > self.limitHeight
  if limitHeight and limitWidth then
    error("Could not fit all images within texture atlas. Failed inserting image ID: "..data.id)
    return false
  elseif limitWidth then
    rightScore = bottomScore + 1 -- place bottom
  elseif limitHeight then
    bottomScore = rightScore + 1 -- place right
  end
  
  -- add best new cells
  if bottomScore < rightScore then -- place bottom
    insert(self.cells, cell.new(0, self.currentHeight, width, height, data))
    if self.currentWidth > width then
      -- create cell to fit gap between new cell height and current height
      insert(self.unoccupiedCells, cell.new(width, self.currentHeight, self.currentWidth-width, height))
    elseif self.currentWidth < width then
      insert(self.unoccupiedCells, cell.new(self.currentWidth, 0, width-self.currentWidth, self.currentWidth))
      self.currentWidth = width
    end
    self.currentHeight = self.currentHeight + height
  else -- place right
    insert(self.cells, cell.new(self.currentWidth, 0, width, height, data))
    if self.currentHeight > height then
      -- create cell to fit gap between new cell width and current width
      insert(self.unoccupiedCells, cell.new(self.currentWidth, height, width, self.currentHeight-height))
    elseif self.currentHeight < height then
      insert(self.unoccupiedCells, cell.new(0, self.currentHeight, self.currentWidth, height-self.currentHeight))
      self.currentHeight = height
    end
    self.currentWidth = self.currentWidth + width
  end
  
  -- TODO improvement: merge unoccupied cells (seperate function to reach all cases in first unoccupied loop to avoid goto)
    -- By merging cells it gives more options for images to be inserted into and decreases
    -- number of cells that will have to be looped through before placing new
    
    -- to solve: AABB - check if axis lines up so that they can be merged
    -- save time: Only call merge if unoccupied cells are created
    
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