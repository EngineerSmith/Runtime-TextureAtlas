local fixedSizeTA = {}
fixedSizeTA.__index = fixedSizeTA

local lg = love.graphics
local ceil, sqrt = math.ceil, math.sqrt

fixedSizeTA.new = function(width, height, padding)
    return setmetatable({
        width = width,
        height = height or width,
        padding = padding or 2,
        image = nil, -- Created in fixedSizeTA.bake
        images = {},
        imagesSize = 0,
        ids = {},
        quads = {},
        _dirty = false,
    }, fixedSizeTA)
end

fixedSizeTA.add = function(self, image, id)
    local width, height = image:getDimensions()
    if width ~= self.width or height ~= self.height then
        error("Given image cannot fit into a fixed sized texture atlas\n Gave: W:".. width .. " H:" ..height .. ", Expected: W:"..self.width.." H:"..self.height)
    end
    
    self:remove(id)
    
    self.imagesSize = self.imagesSize + 1
    local index = self.imagesSize
    self.images[index] = {
        image = image,
        id = id,
    }
    self.ids[id] = index
    
    self._dirty = true
    
    return self
end

fixedSizeTA.remove = function(self, id)
    local index = self.ids[id]
    
    if index then
        self.images[index] = nil
        self.quads[id] = nil
        self.ids[id] = nil
        
        self._dirty = true
    end
    
    return self
end

fixedSizeTA.bake = function(self)
    if self._dirty then
        lg.push("all")
        local size = ceil(sqrt(#self.images))
        local width, height, padding = self.width + self.padding, self.height + self.padding
        local canvas = lg.newCanvas(size * width, size * height)
        lg.setCanvas(canvas)
        for x=0, size-1, 1 do
            for y=0, size-1, 1 do
                local image = self.images[(x+y*size)+1]
                if image then
                    lg.draw(image.image, x*width, y*height)
                    self.quads[image.id] = lg.newQuad(x*width, y*height, self.width, self.height, size*width,size*height)
                end
            end
        end
        lg.pop()
        self.image = lg.newImage(canvas:newImageData(0,1,0,0,size*width,size*height))
        --error(self.image:getWidth()..":"..self.image:getHeight().." from "..canvas:getWidth()..":"..canvas:getHeight().."\nA factor of: W:"..self.image:getWidth()/canvas:getWidth().." H:"..self.image:getHeight()/canvas:getHeight())
    end
    
    return self
end

fixedSizeTA.draw = function(self, id, ...)
    lg.draw(self.image, self.quads[id], ...)
end

-- If you don't want to bother passing around ids
fixedSizeTA.getDrawFunc = function(self, id)
    return function(...)
        lg.draw(self.image, self.quads[id], ...)
    end
end

return fixedSizeTA