local lg = love.graphics

local fixedSizeTA = {}
fixedSizeTA.__index = fixedSizeTA

local dynamicSizeTA = {
    width = 2048, -- Default texture size
    height = 2048,
}
dynamicSizeTA.__index = dynamicSizeTA

dynamicSizeTA.add = function(self, image, id, doNotBake)
    assert(self ~= nil, "Invalid dynamicSizeTA table given")
    assert(image ~= nil, "Invalid image given")
    assert(id ~= nil, "Invalid id given")
    
    self:remove(id, true)
    
    self.imagesSize = self.imagesSize + 1
    local index = self.imagesSize
    self.images[index] = {
        image = image,
        id = id,
        index = index,
    }
    self.ids[id] = index
    
    self.dirty = true
    if _doNotBake ~= true or (self.isDynamicBake and doNotBake ~= false) then
        self:bake()
    end
    
    return self
end

dynamicSizeTA.remove = function(self, id, doNotBake)
    local index = self.ids[id]
    if index then
        self.images[index] = nil
        self.quads[id] = nil
        self.ids[id] = nil
        
        self.dirty = true
        if _doNotBake ~= true or (self.isDynamicBake and doNotBake ~= false) then
            self:bake()
        end
    end
end

----- [[ REFERENCE ]] ----------------------------------
-- https://blackpawn.com/texts/lightmaps/default.html --
-- This algorimth is based on this packing pseudocode --
--------------------------------------------------------
local node = {
    leftNode = nil, rightNode = nil,
    image = nil,
    [1] = 0, [2] = 0, -- left, top
    [3] = 0, [4] = 0, -- right, bottom
}
node.__index = node
node.new = function(width,height) return setmetatable({[3]=width,[4]=height}, node) end
node.insert = function (self, image, width, height)
    if self.leftNode and self.rightNode then
        return self.leftNode:insert(image, width, height) or self.rightNode:insert(image, width, height)
    else
        if self.image then
            return nil
        end
        local nodew, nodeh = (self[3] - self[1]), (self[4] - self[2])
        if nodew < width or nodeh < height then
            return nil
        elseif nodew == width and nodeh == height then
            self.image = image
            lg.draw(image.image, leftNode[1], rightNode[2])
            return self
        end
        
        self.leftNode = node.new()
        local leftNode = self.leftNode
        self.rightNode = node.new()
        local rightNode = self.rightNode
        
        if nodew - width > nodeh - height then
            leftNode[1] = self[1]
            leftNode[2] = self[2]
            leftNode[3] = self[3] + width - 1
            leftNode[4] = self[4]
            rightNode[1] = self[1] + width
            rightNode[2] = self[2]
            rightNode[3] = self[3]
            rightNode[4] = self[4]
        else
            leftNode[1] = self[1]
            leftNode[2] = self[2]
            leftNode[3] = self[3]
            leftNode[4] = self[4] + height - 1
            rightNode[1] = self[1]
            rightNode[2] = self[2] + height
            rightNode[3] = self[3]
            rightNode[4] = self[4]
        end
        lg.draw(image.image, leftNode[1], rightNode[2])
        leftNode.image = image
        return leftNode
    end
end

dynamicSizeTA.bake = function(self, width, height)
    if self.dirty then
        width = width or self.width
        height = height or self.height
        
        if self.image then
            local cw, ch = self.image:getDimensions()
            if cw ~= width or ch ~= height then
                self.image = lg.newCanvas(width. height)
            end
        else
            self.image = lg.newCanvas(width, height)
        end
        
        local root = node.new(width, height)
        lg.push("all")
        lg.setCanvas(self.image)
        lg.clear(0,0,0,0)
        lg.origin()
        lg.setColor(1,1,1)
        for i, img in ipairs(self.images) do
            local node = root:insert(img, img.image:getDimensions())
            -- make quad with node
            self.quads[img.id] = lg.new(node[1],node[2], (node[3]-node[1]), (node[4]-node[2]), width, height)
        end
        lg.pop()
        
        self.dirty = false
    end
end

dynamicSizeTA.get = function(self, id)
    return self.quads[id]
end

dynamicSizeTA.draw = function(self, id, ...)
    lg.draw(self.image, self.quads[id], ...)
end

local new = function(isDynamicBake, isMismatchImageSizes, width, height)
    
    isMismatchImageSizes = isMismatchImageSizes == nil and true or isMismatchImageSizes
    
    if isMismatchImageSizes then
        return setmetatable({
            isDynamicBake = isDynamicBake == nil and true or isDynamicBake,
            width = width and width < 0 and 0 or dynamicSizeTA.width,
            height = height and height < 0 and 0 or dynamicSizeTA.height,
            images = {},
            imagesSize = 0,
            ids = {},
            quads = {},
            image = nil,
            dirty = false,  -- true if image is outdated and hasn't been baked yet
        }, dynamicSizeTA)
    else
        assert(type(width) == number and width >= 1, "Fixed sized TextureAtlas requires image width that's greater than 0: ".. type(width))
        assert(type(height) == number and height >= 1, "Fixed sized TextureAtlas requires image height that's greater than 0")
        
        return setmetatable({
            isDynamicBake = isDynamicBake == nil and true or isDynamicBake,
            width = width,
            height = height,
            images = {},
            imagesSize = 0,
            ids = {},
            quads = {},
            image = nil,
            dirty = false,  -- true if image is outdated and hasn't been baked yet
        }, fixedSizeTA)
    end
end

return new