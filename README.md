# Love2D-TA
Love2D runtime texture atlas

At this point in time this texture atlas only supports fixed sized images (Images that are all the same in width and height. Width and height can be different values e.g. 16x32)

## Docs

Clone into your lib/include file for your love2d project,
E.g. `git clone https://github.com/EngineerSmith/Love2D-TA libs/TA`

```lua
-- Require library from cloned location
local textureAtlas = require("libs.TA")

-- Create atlas to add images to
local ta = textureAtlas.newFixedSize(16,32,1)
-- textureAtlas.newFixedSize(width, height = width, padding = 1) -- default values

-- Add or replace an image to the atlas
local rabbit = love.graphics.newImage("rabbit.png")
ta:add(rabbit, "rabbit", true)
-- fixedSize:add(image, id, bake = false) -- default values
-- By marking the function to bake (last argument), you avoid having to call bake manually - but it is recommended only to call bake once all images have been added. Only mark true if you only wanted to update a single image
-- Note, id can be any normal table index - not limited to strings

-- Remove an image from the atlas
ta:remove("rabbit", true)
-- fixedSize:remove(id, bake = false) -- default values
-- It's recommended to call bake here, unless you're removing a lot of images at once from the texture atlas

-- Bake texture atlas
ta:bake()

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