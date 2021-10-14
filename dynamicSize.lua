local path = select(1, ...):match("(.-)[^%.]+$")
local baseAtlas = require(path .. "baseAtlas")
local dynamicSizeTA = setmetatable({}, baseAtlas)
dynamicSizeTA.__index = dynamicSizeTA

-- Based on BlackPawn's lightmap packing: https://blackpawn.com/texts/lightmaps/default.html
local treeNode = require(path .. "treeNode")

local lg = love.graphics
local sort = table.sort

dynamicSizeTA.new = function(padding)
    return setmetatable(baseAtlas.new(padding), dynamicSizeTA)
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

-- _sortBy options: "area", "height" (default), "width", "none"
dynamicSizeTA.bake = function(self, _sortBy)
    if self._dirty then
        local shallowCopy = {unpack(self.images)}
        if _sortBy == nil or _sortBy == "height" then
            sort(shallowCopy, height)
        elseif _sortBy == "area" then
            sort(shallowCopy, area)
        elseif _sortBy == "width" then
            sort(shallowCopy, width)
        end
        local estWidth, estHeight = 0, 0
        for _, image in ipairs(shallowCopy) do
            estWidth = estWidth + image.image:getWidth()
            estHeight = estHeight + image.image:getHeight()
        end
        --error(math.sqrt(estWidth)*math.sqrt(estHeight))
        -- Calculate positions and size of canvas
        local maxWidth, maxHeight = 0,0
        local root = treeNode.new(math.huge, math.huge)
        
        for _, image in ipairs(shallowCopy) do
            local img = image.image
            local w, h = img:getDimensions()
            local node = root:insert(image, w+self.padding, h+self.padding)
            if not node then
                error("Somehow could not fit image inside tree")
            end
            if node.x + w > maxWidth then
                maxWidth = node.x + w
            end
            if node.y + h > maxHeight then
                maxHeight = node.y + h
            end
        end
        
        --error(maxWidth .. ":" .. maxHeight)
        local canvas = lg.newCanvas(maxWidth, maxHeight, self._canvasSettings)
        lg.push("all")
        lg.setCanvas(canvas)
        lg.clear(1,0,1,1)
        root:draw()
        lg.pop()
        self.image = lg.newImage(canvas:newImageData())
        self.image:setFilter(self.filterMin, self.filterMag)
        self._dirty = false
    end
    
    return self
end

return dynamicSizeTA