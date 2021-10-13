local fixedSizeTA = {
    _canvasSettings = {
        dpiscale = 1,
    }
}
fixedSizeTA.__index = fixedSizeTA

local lg = love.graphics
local ceil, sqrt = math.ceil, math.sqrt

fixedSizeTA.new = function(width, height, padding)
    return setmetatable({
        width = width or error("Width required"),
        height = height or width,
        padding = padding or 1,
        image,
        images = {},
        imagesSize = 0,
        ids = {},
        quads = {},
        filterMin = "linear", 
        filterMag = "linear",
        _dirty = false, -- Marked dirty if image is added or removed,
    }, fixedSizeTA)
end

-- TA:add(img, "foo")
-- TA:add(img, 68513)
fixedSizeTA.add = function(self, image, id, bake)
    local width, height = image:getDimensions()
    if width ~= self.width or height ~= self.height then
        error("Given image cannot fit into a fixed sized texture atlas\n Gave: W:".. width .. " H:" ..height .. ", Expected: W:"..self.width.." H:"..self.height)
    end
    
    self.imagesSize = self.imagesSize + 1
    local index = self.imagesSize
    assert(type(id) ~= "nil", "Must give an id")
    self:remove(id)
    self.images[index] = {
        image = image,
        id = id,
    }
    self.ids[id] = index
    
    self._dirty = true
    if bake then
        self:bake()
    end
    
    return self
end

-- TA:remove("foo")
-- TA:remove(68513)
fixedSizeTA.remove = function(self, id, bake)
    local index = self.ids[id]
    if index then
        self.images[index] = nil
        self.quads[id] = nil
        self.ids[id] = nil
        self._dirty = true
        if bake == true then
            self:bake()
        end
    end
    
    return self
end

fixedSizeTA.bake = function(self)
    if self._dirty then
        local size = ceil(sqrt(#self.images))
        local width, height = self.width, self.height
        local widthPadded, heightPadded = width + self.padding, height + self.padding
        local widthCanvas, heightCanvas = size * widthPadded, size * heightPadded
        local canvas = lg.newCanvas(widthCanvas, heightCanvas, self._canvasSettings)
        local maxIndex = self.imagesSize
        lg.push("all")
        lg.setCanvas(canvas)
        for x=0, size-1, 1 do
            for y=0, size-1, 1 do
                local index = (x+y*size)+1
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

fixedSizeTA.setFilter = function(self, min, mag)
    self.filterMin = min or "linear"
    self.filterMag = mag or self.filterMin
    
    return self
end

fixedSizeTA.draw = function(self, id, ...)
    lg.draw(self.image, self.quads[id], ...)
end

fixedSizeTA.getDrawFunc = function(self)
    return function(...)
        self:draw(...)
    end
end

-- If you don't want to bother passing around ids
fixedSizeTA.getDrawFuncForID = function(self, id)
    return function(...)
        lg.draw(self.image, self.quads[id], ...)
    end
end

return fixedSizeTA