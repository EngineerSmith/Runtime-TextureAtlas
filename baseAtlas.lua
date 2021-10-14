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
        _hardBake = false, -- Marked true if hardBake has been called, cannot use add or remove
    }, baseAtlas)
end

-- TA:add(img, "foo")
-- TA:add(img, 68513, true)
baseAtlas.add = function(self, image, id, bake, ...)
    if self._hardBake then
        error("Cannot add images to a texture atlas that has been hard baked")
    end
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
    if self._hardBake then
        error("Cannot remove images from a texture atlas that has been hard baked")
    end
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

baseAtlas.hardBake = function(self, ...)
    local result = self:bake(...)
    self.images = nil
    self.ids = nil
    self._hardBake = true
    return result
end

baseAtlas.setFilter = function(self, min, mag)
    self.filterMin = min or "linear"
    self.filterMag = mag or self.filterMin
    if self.image then
        self.image:setFilter(self.filterMin, self.filterMag)
    end
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