-- Copyright (c) 2021 EngineerSmith
-- Under the MIT license, see license suppiled with this file

-- Based on BlackPawn's lightmap packing algorithm: https://blackpawn.com/texts/lightmaps/default.html
local treeNode = {}
treeNode.__index = treeNode

local lg = love.graphics

treeNode.new = function(w, h)
  return setmetatable({
    x = 0,
    y = 0,
    w = w or 0,
    h = h or 0,
    image = nil,
  }, treeNode)
end

treeNode.insert = function(self, image, width, height)
  if self[1] --[[ and self[2] ]] then
    return self[1]:insert(image, width, height) or self[2]:insert(image, width, height)
  else
    if self.image then
      return nil
    end
    if self.w < width or self.h < height then
      return nil
    end
    if self.w == width and self.h == height then
      self.image = image
      return self
    end
    
    self[1] = self.new()
    self[2] = self.new()
    
    if (self.w - width) > (self.h - height) then -- Vertical 
       -- Left
      self[1].x = self.x
      self[1].y = self.y
      self[1].w = width
      self[1].h = self.h
      -- Right
      self[2].x = self.x + width
      self[2].y = self.y
      self[2].w = self.w - width
      self[2].h = self.h
    else -- Horizontal
      -- Up
      self[1].x = self.x
      self[1].y = self.y
      self[1].w = self.w
      self[1].h = height
      -- Down
      self[2].x = self.x
      self[2].y = self.y + height
      self[2].w = self.w
      self[2].h = self.h - height
    end
    
    return self[1]:insert(image, width, height)
  end
end

treeNode.draw = function(self, quads, width, height, extrude, padding)
  if self.image then
    local img = self.image.image
    local iwidth, iheight = img:getDimensions()
    local extrudeQuad = lg.newQuad(-extrude, -extrude, iwidth+extrude*2, iheight+extrude*2, iwidth, iheight)
    lg.draw(img, extrudeQuad, self.x + padding, self.y + padding)
    quads[self.image.id] = lg.newQuad(self.x+extrude+padding, self.y+extrude+padding, iwidth, iheight, width, height)
  elseif self[1] --[[ and self[2] ]] then 
    self[1]:draw(quads, width, height, extrude, padding)
    self[2]:draw(quads, width, height, extrude, padding)
  end
end

return treeNode