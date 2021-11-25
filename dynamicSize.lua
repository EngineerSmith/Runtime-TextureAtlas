-- Copyright (c) 2021 EngineerSmith
-- Under the MIT license, see license suppiled with this file
local path = select(1, ...):match("(.-)[^%.]+$")
local baseAtlas = require(path .. "baseAtlas")
local dynamicSizeTA = setmetatable({}, baseAtlas)
dynamicSizeTA.__index = dynamicSizeTA

-- Based on BlackPawn's lightmap packing: https://blackpawn.com/texts/lightmaps/default.html
local treeNode = require(path .. "treeNode")

local lg = love.graphics
local sort = table.sort

dynamicSizeTA.new = function(padding, extrude)
  return setmetatable(baseAtlas.new(padding, extrude), dynamicSizeTA)
end

local area = function(a, b)
  local aW, aH = a.image:getDimensions()
  local bW, bH = b.image:getDimensions()
  return aW * aH > bW * bH
end

local height = function(a, b)
  local aH = a.image:getHeight()
  local bH = b.image:getHeight()
  return aH > bH
end

local width = function(a, b)
  local aW = a.image:getWidth()
  local bW = b.image:getWidth()
  return aW > bW
end

-- sortBy options: "height"(default), "area", "width", "none"
dynamicSizeTA.bake = function(self, sortBy)
  if self._dirty and not self._hardBake then
    local shallowCopy = {unpack(self.images)}
    if sortBy == nil or sortBy == "height" then
      sort(shallowCopy, height)
    elseif sortBy == "area" then
      sort(shallowCopy, area)
    elseif sortBy == "width" then
      sort(shallowCopy, width)
    end
    
    -- Calculate positions and size of canvas
    local maxWidth, maxHeight = 0,0
    local root = treeNode.new(self._maxCanvasSize, self._maxCanvasSize)
    
    for _, image in ipairs(shallowCopy) do
      local img = image.image
      local width, height = img:getDimensions()
      width = width + self.padding + self.extrude * 2
      height = height + self.padding + self.extrude * 2
      local node = root:insert(image, width, height)
      if not node then
        error("Could not fit image inside tree")
      end
      if node.x + width > maxWidth then
        maxWidth = node.x + width
      end
      if node.y + height > maxHeight then
        maxHeight = node.y + height
      end
    end
    
    local canvas = lg.newCanvas(maxWidth-self.padding, maxHeight-self.padding, self._canvasSettings)
    lg.push("all")
    lg.setCanvas(canvas)
    root:draw(self.quads, maxWidth, maxHeight, self.extrude)
    lg.pop()
    local data = canvas:newImageData()
    self.image = lg.newImage(data)
    self.image:setFilter(self.filterMin, self.filterMag)
    self._dirty = false
    return self, data
  end
  
  return self
end

return dynamicSizeTA