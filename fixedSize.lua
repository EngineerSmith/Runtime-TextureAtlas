local path = select(1, ...):match("(.-)[^%.]+$")
local baseAtlas = require(path .. "baseAtlas")
local fixedSizeTA = setmetatable({}, baseAtlas)
fixedSizeTA.__index = fixedSizeTA

local lg = love.graphics
local ceil, sqrt = math.ceil, math.sqrt

fixedSizeTA.new = function(width, height, padding)
    local self = setmetatable(baseAtlas.new(padding), fixedSizeTA)
    self.width = width or error("Width required")
    self.height = height or width
    return self
end

fixedSizeTA.add = function(self, image, id, bake)
    local width, height = image:getDimensions()
    if width ~= self.width or height ~= self.height then
        error("Given image cannot fit into a fixed sized texture atlas\n Gave: W:".. tostring(width) .. " H:" ..tostring(height) .. ", Expected: W:"..self.width.." H:"..self.height)
    end
    return baseAtlas.add(self, image, id, bake)
end

fixedSizeTA.bake = function(self)
    if self._dirty and not self._hardBake then
        local columns = ceil(sqrt(#self.images))
        local width, height = self.width, self.height
        local widthPadded, heightPadded = width + self.padding, height + self.padding
        local rows = ceil(#self.images / columns)
        local widthCanvas, heightCanvas = columns * widthPadded, rows * heightPadded
        local canvas = lg.newCanvas(widthCanvas, heightCanvas, self._canvasSettings)
        local maxIndex = self.imagesSize
        lg.push("all")
        lg.setCanvas(canvas)
        for x=0, rows-1, 1 do
            for y=0, columns-1, 1 do
                local index = (x+y*columns)+1
                if index > maxIndex then
                    break
                end
                local x, y = x*widthPadded, y*heightPadded
                local image = self.images[index]
                lg.draw(image.image, x, y)
                self.quads[image.id] = lg.newQuad(x, y, width, height, widthCanvas, heightCanvas)
            end
        end
        lg.pop()
        self.image = lg.newImage(canvas:newImageData())
        self.image:setFilter(self.filterMin, self.filterMag)
        self._dirty = false
    end
    
    return self
end

return fixedSizeTA