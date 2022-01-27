-- Copyright (c) 2021 EngineerSmith
-- Under the MIT license, see license suppiled with this file

local path = select(1, ...):match("(.-)[^%.]+$")
local baseAtlas = require(path .. "baseAtlas")
local util = require(path .. "util")
local fixedSizeTA = setmetatable({}, baseAtlas)
fixedSizeTA.__index = fixedSizeTA

local lg = love.graphics
local ceil, floor, sqrt = math.ceil, math.sqrt, math.floor

fixedSizeTA.new = function(width, height, padding, extrude, spacing)
  local self = setmetatable(baseAtlas.new(padding, extrude, spacing), fixedSizeTA)
  self.width = width or error("Width required")
  self.height = height or width
  return self
end

fixedSizeTA.add = function(self, image, id, bake)
  local width, height = util.getImageDimensions(image)
  if width ~= self.width or height ~= self.height then
    error("Given image cannot fit into a fixed sized texture atlas\n Gave: W:".. tostring(width) .. " H:" ..tostring(height) .. ", Expected: W:"..self.width.." H:"..self.height)
  end
  return baseAtlas.add(self, image, id, bake)
end

fixedSizeTA.bake = function(self)
  if self._dirty and not self._hardBake then
    local columns = ceil(sqrt(self.imagesSize))
    local width, height = self.width, self.height
    local widthPadded = width + self.spacing + self.extrude * 2 + self.padding * 2
    local heightPadded = height + self.spacing + self.extrude * 2 + self.padding * 2
    local maxIndex = self.imagesSize

    local widthCanvas = columns * widthPadded
    if widthCanvas > self._maxCanvasSize then
      columns = floor(self._maxCanvasSize / width)
      widthCanvas = columns * widthPadded
    end

    local rows = ceil(self.imagesSize / columns)
    local heightCanvas = rows * heightPadded
    if heightPadded > self._maxCanvasSize then
      rows = floor(self._maxCanvasSize / height)
      heightCanvas = rows * heightPadded
    end

    widthCanvas, heightCanvas = widthCanvas - self.spacing, heightCanvas - self.spacing
    if self.bakeAsPow2 then
      widthCanvas = math.pow(2, math.ceil(math.log(widthCanvas)/math.log(2)))
      heightCanvas = math.pow(2, math.ceil(math.log(heightCanvas)/math.log(2)))
    end

    if self._pureImageMode then
      local imageData = love.image.newImageData(widthCanvas, heightCanvas, "rgba8")
      for x=0, columns-1 do
        for y=0, rows-1 do
          local index = (x+y*rows)+1
          if index > maxIndex then
            break
          end
          local x, y = x * widthPadded + self.padding, y * heightPadded + self.padding
          local image = self.images[index]
          local iw, ih = image:getDimensions()
          imageData:paste(image, x, y, 0, 0, iw, ih)
          if self.extrude > 0 then
            util.extrudeImageData(imageData, image, self.extrude, x, y, 0, -1, 0, 0, iw, 1) -- top
            util.extrudeImageData(imageData, image, self.extrude, x, y, -1, 0, 0, 0, 1, ih) -- left
            util.extrudeImageData(imageData, image, self.extrude, x, y + ih - 1, 0, 1, 0, ih - 1, iw, 1) -- bottom
            util.extrudeImageData(imageData, image, self.extrude, x + iw - 1, y, 1, 0, iw - 1, 0, 1, ih) -- right
            util.fillImageData(imageData, x - self.extrude - 1, y - self.extrude - 1, self.extrude, self.extrude, image:getPixel(0, 0)) -- top-left
            util.fillImageData(imageData, x + iw, y - self.extrude - 1, self.extrude, self.extrude, image:getPixel(iw - 1, 0)) -- top-right
            util.fillImageData(imageData, x + iw, y + ih, self.extrude, self.extrude, image:getPixel(iw - 1, ih - 1)) -- bottom-right
            util.fillImageData(imageData, x - self.extrude - 1, y + ih, self.extrude, self.extrude, image:getPixel(0, ih - 1)) -- bottom-left
          end
        end
      end
    else
      if columns * rows < self.imagesSize then
        error("Cannot support "..tostring(self.imagesSize).." images, due to system limits of canvas size. Max allowed on this system: "..tostring(columns * rows))
      end

      local extrudeQuad = lg.newQuad(-self.extrude, -self.extrude, width+self.extrude*2, height+self.extrude*2, self.width, self.height)
      local canvas = lg.newCanvas(widthCanvas, heightCanvas, self._canvasSettings)
      lg.push("all")
      lg.setBlendMode("replace")
      lg.setCanvas(canvas)
      for x=0, columns-1 do
        for y=0, rows-1 do
          local index = (x+y*rows)+1
          if index > maxIndex then
            break
          end
          local x, y = x * widthPadded + self.padding, y * heightPadded + self.padding
          local image = self.images[index]
          lg.draw(image.image, extrudeQuad, x, y)
          self.quads[image.id] = lg.newQuad(x+self.extrude, y+self.extrude, width, height, widthCanvas, heightCanvas)
        end
      end
      lg.pop()
      local data = canvas:newImageData()
      self.image = lg.newImage(data)
      self.image:setFilter(self.filterMin, self.filterMag)
      self._dirty = false
    end

    return self, self.image
  end

  return self
end

return fixedSizeTA