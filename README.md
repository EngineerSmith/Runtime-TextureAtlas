# Love2D-TA
Love2D runtime texture atlas! Tested and written on __love 11.3__ android.

**Fixed Size**: All images must have the same width and height (e.g. 16x16, 512x64, etc)
**Dynamic Size**: All images can be whatever size they want; however, from unit tests it takes about twice as long to bake the texture using BlackPawn's lightmap packing algorithm (and the default "height" sort option)
## Examples
### Fixed Size
All images must be the same size
```lua
local textureAtlas = require("libs.TA")
local ta = textureAtlas.newFixedSize(16, 32)
ta:setFilter("nearest")

ta:add(love.graphics.newImage("duck.png"), "duck")
ta:add(love.graphics.newImage("cat.png"), "cat")
ta:add(love.graphics.newImage("dog.png"), "dog")
ta:add(love.graphics.newImage("rabbit.png"), "rabbit")
ta:bake()

ta:remove("dog")
ta:remove("rabbit", true) -- Remove rabbit and bake changes

ta:hardBake() -- Cannot add or remove images, and deletes all references to given images so they can be cleaned from memory

local catDraw = ta:getDrawFuncForID("cat")

love.draw = function()
    ta:draw("duck", 50,50)
    catDraw(100,50, 0, 5,5)
end
```
### Dynamic Size
Images don't have to be the same size
```lua
local textureAtlas = require("libs.TA")
local ta = textureAtlas.newDynamicSize()
ta:setFilter("nearest")

ta:add(love.graphics.newImage("521x753.png"), "duck")
ta:add(love.graphics.newImage("25x1250.png"), "cat")
ta:add(love.graphics.newImage("duck.png"), "duck") -- Replace previous image at id without having to call ta:remove
ta:add(love.graphic.newImage("rabbit.png", "rabbit")

ta:bake("height") -- Sorting algorithm optimizes space use

ta:remove("rabbit") -- will need to bake again
ta:remove("cat", true, "area") -- remove graphic, bake with this sort

ta:hardBake() -- Cannot add or remove images, and deletes all references to given images so they can be cleaned from memory

local duckDraw = ta:getDrawFuncForID("duck")

love.draw = function()
    ta:draw("banner", 50,50)
    duckDraw(100,50, 0, 5,5)
end
```
## Docs
Clone into your lib/include file for your love2d project,
E.g. `git clone https://github.com/EngineerSmith/Love2D-TA libs/TA`
### require
Require the library using the init.lua
```lua
local textureAtlas = require("libs.TA") -- the location where it has been cloned to
```
### textureAtlas.new
Create an atlas to add images to
  Fixed Size atlas require all added images to have the same width and height
  Dynamic Size atlas allows more freedom for size of image
```lua
local fs = textureAtlas.newFixedSize(width, height = width, padding = 1)
local ds = textureAtlas.newDynamicSize(padding = 1)
```
### textureAtlas:setFilter(min, mag = min)
Similar to `image:setFilter`; however, will always override default filter even if not changed. E.g. if `love.graphics.setDefaultFilter("nearest", "nearest")` is called, textureAtlas will continue to bake in `"linear"`
```lua
ta:setFilter(min, mag = min)
ta:setFilter("nearest")
```
### textureAtlas:add(image, id, bake = false, ...)
Add or replace an image to your atlas. Use the 3rd argument to bake the addition. Recommended to only bake once all changes have been made - useful for updating one image. 4th argument is passed to `textureAtlas.bake`
**Note, id can be any normal table index variable type - not limited to strings**
```lua
ta:add(image, id, bake = false, ...)
ta:add(love.graphics.newImage("rabbit.png"), "rabbit")

fs:add(love.graphics.newImage("duck.png"), true)
ds:add(love.graphics.newImage("duck.png"), true, "height") -- option to add in sorting algorithm
```
### textureAtlas:remove(id, bake = false, ...)
Remove an image added to the atlas. Use the 2nd argument to bake the removal. Recommended to only bake once all changes have been made or if you're only making a single change. 4th argument is passed to `textureAtlas.bake`
### textureAtlas:bake
Baking takes all added images and stitches them together onto a single image. Basic check in place to ensure it only bakes when changes have been made via `add` or `remove` to avoid needless baking
```lua
fixed:bake()
dynamic:bake(sortby)
dynamic:bake("height") 
-- _sortBy options: "height" (default), "area", "width", "none"
-- "height" and "area" are best from unit testing - but do your own tests to see what works best for your images
-- use dynamic.image to grab the baked image
```
### textureAtlas:hardBake
Hard baking bakes the image and removes references to all given images. Once called, you cannot add, remove or bake again. This function is designed to free up unused memory.
**Note, any references to images that still exist outside of textureAtlas will keep the image alive (`image:release` is not called)**
```lua
fixed:hardBake()
dynamic:hardBake(sortBy) -- See textureAtlas:bake for sortBy options
```
### textureAtlas:draw(id, ...)
Draw function to draw given id, 2nd argument will be passed to `love.graphics.draw`
```lua
ta:draw(id, ...) ---translates to--> love.graphics.draw(ta.image, ta.quads[id], ...)
ta:draw("duck", 50,50, 0, 5,5) -- draws id "duck" at 50,50 at scale 5
```
### textureAtlas:getDrawFunc()
Get a draw function to avoid passing given texture atlas around
```lua
local draw = ta:getDrawFunc()
-- draw(id, ...) -- See textureAtlas:draw(id, ...)
draw("duck", 50,50, 0, 5,5) -- draws id "duck" at 50,50 at scale 5
```
### textureAtlas:getDrawFuncForID(id)
Get a draw function to avoid passing given texture atlas and id around
```lua
local draw = ta:getDrawFuncForID("duck")
-- draw(...) -- values are sent as arguments to love.graphics.draw, similar to textureAtlas:draw(id, ...)
draw(50,50, 0, 5,5) -- draws id "duck" at 50,50 at scale 5
```