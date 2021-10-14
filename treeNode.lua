
-- Based on BlackPawn's lightmap packing: https://blackpawn.com/texts/lightmaps/default.html
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
        
        if (self.w - width) > (self.h - height) then -- Vertical split 
            self[1].x = self.x -- Left
            self[1].y = self.y
            self[1].w = width
            self[1].h = self.h
            self[2].x = self.x + width -- Right
            self[2].y = self.y
            self[2].w = self.w - width
            self[2].h = self.h
        else -- Horizontal split
            self[1].x = self.x -- Up
            self[1].y = self.y
            self[1].w = self.w
            self[1].h = height
            self[2].x = self.x -- Down
            self[2].y = self.y + height
            self[2].w = self.w
            self[2].h = self.h - height
        end
        
        return self[1]:insert(image, width, height)
    end
end

treeNode.draw = function(self)
    if self.image then
        lg.draw(self.image.image, self.x, self.y)
    elseif self[1] --[[ and self[2] ]] then 
        self[1]:draw()
        self[2]:draw()
    end
end

return treeNode