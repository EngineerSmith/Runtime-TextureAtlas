# Love2D-TA
Love2D runtime texture atlas

At this point in time this texture atlas only supports fixed sized images (Images that are all the same in width and height. Width and height can be different values e.g. 16x32)

## Example

```lua
local textureAtlas = require("libs.TA")
local ta = textureAtlas.newFixedSize(16)
ta:setFilter("nearest")

ta:add(love.graphics.newImage("duck.png"), "duck")
ta:add(love.graphics.newImage("cat.png"), "cat")
ta:add(love.graphics.newImage("dog.png"), "dog")
ta:add(love.graphics.newImage("rabbit.png"), "rabbit")
ta:bake()

ta:remove("dog")
ta:remove("rabbit", true) -- Remove rabbit and bake changes

local catDraw = ta:getDrawFuncForID("cat")

love.draw = function()
    ta:draw("duck", 50,50)
    catDraw(100,50, 0, 5,5)
end
```

## Docs

Clone into your lib/include file for your love2d project,
E.g. `git clone https://github.com/EngineerSmith/Love2D-TA libs/TA`

```lua
-- Require library from cloned location
local textureAtlas = require("libs.TA")

-- Create atlas to add images to
local ta = textureAtlas.newFixedSize(16,32,1)
-- textureAtlas.newFixedSize(width, height = width, padding = 1) -- default values

-- Set filter mode for texture atlas
ta:setFilter("nearest")
-- fixedSize:setFilter(min = "linear", mag = min) -- default values

-- Add or replace an image to the atlas
local rabbit = love.graphics.newImage("rabbit.png")
ta:add(rabbit, "rabbit", true)
-- fixedSize:add(image, id, bake = false) -- default values
-- You can use the last argument to bake without having to call bake afterward - it is recommended only to bake once all changes have been made. Useful for updating one image
-- Note, id can be any normal table index - not limited to strings

-- Remove an image from the atlas
ta:remove("rabbit", true)
-- fixedSize:remove(id, bake = false) -- default values
-- You can use the last argument to bake without having to call bake afterward - it is recommended only to bake once all changes have been made. Useful for updating one image

-- Bake texture atlas
ta:bake()
-- Ensure bake has been called via add, remove, or this function; otherwise, you can't draw from the texture atlas.
-- Bake checks if there have been changes when called to avoid needlessly 'rebaking'

-- Draw the image from the texture atlas
ta:draw("rabbit", 50,50)
-- fixedSize:draw(id, ...) -- values after the id are sent as arguments to love.graphics.draw

-- Get a draw function to avoid passing texture atlas around
local draw = ta:getDrawFunc()
draw("rabbit", 50,50)
-- draw(id, ...) -- values after the id are sent as arguments to love.graphics.draw

-- Get a draw function to avoid passing texture atlas and id around
local draw = ta:getDrawFuncForID("rabbit")
draw(50,50)
-- draw(...) -- values are sent as arguments to love.graphics.draw
```