local path = select(1, ...)
local textureAtlas = {
    newFixedSize = require(... .. ".fixedSize").new,
    newDynamicSize = require(... .. ".dynamicSize").new
}

return textureAtlas