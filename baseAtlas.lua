local baseAtlas = {
    _canvasSettings = {
        dpiscale = 1,
    },
}
baseAtlas.__index = baseAtlas

local lg = love.graphics

baseAtlas.new = function(padding)
    return setmetatable({
        padding = padding or 1,
        image,
        images = {},
        imagesSize = 0,
        ids = {},
        quads = {},
        filterMin = "linear", 
        filterMag = "linear",
        _dirty = false, -- Marked dirty if image is added or removed,
    }, baseAtlas)
end

-- TA:add(img, "foo")
-- TA:add(img, 68513, true)
baseAtlas.add = function(self, image, id, bake, ...)
    self.imagesSize = self.imagesSize + 1
    local index = self.imagesSize
    assert(type(id) ~= "nil", "Must give an id")
    self:remove(id)
    self.images[index] = {
        image = image,
        id = id,
        index = index,
    }
    self.ids[id] = index
    
    self._dirty = true
    if bake then
        self:bake(...)
    end
    
    return self
end

-- TA:remove("foo", true)
-- TA:remove(68513)
baseAtlas.remove = function(self, id, bake, ...)
    local index = self.ids[id]
    if index then
        self.images[index] = nil
        self.quads[id] = nil
        self.ids[id] = nil
        self._dirty = true
        if bake == true then
            self:bake(...)
        end
    end
    
    return self
end

baseAtlas.bake = function(self)
    error("Warning! Created atlas hasn't overriden bake function!")
end

baseAtlas.setFilter = function(self, min, mag)
    self.filterMin = min or "linear"
    self.filterMag = mag or self.filterMin
    
    return self
end

baseAtlas.draw = function(self, id, ...)
    lg.draw(self.image, self.quads[id], ...)
end

-- Following functions are if you don't want to pass textureAtlas or ids around

baseAtlas.getDrawFunc = function(self)
    return function(...)
        self:draw(...)
    end
end

baseAtlas.getDrawFuncForID = function(self, id)
    return function(...)
        lg.draw(self.image, self.quads[id], ...)
    end
end

return baseAtlas