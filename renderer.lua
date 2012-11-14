-- even though there's only supposed to be one instance of it, I'd still prefer to have it as a class

require("map")
require("unit")

Renderer = {}
Renderer.__index = Renderer

function Renderer.new()
    local renderer = {}
    
    setmetatable(renderer, Renderer)
    
    return renderer
end

function Renderer:Render(entity, pixelCoordinates)
    local image = entity.imagePath
    
    if image then -- if it's even drawable
        if not self[image] then -- if not loaded yet, load now
            self[image] = love.graphics.newImage(image)
            if not self[image] then -- if loading didn't succeed, flip the fuck out
                error()
            end
        end
        
        love.graphics.draw(self[image], pixelCoordinates.x, pixelCoordinates.y)
    end
end

function Renderer:RenderUnit(unit, pixelCoordinates)
    self:Render(unit, pixelCoordinates)
    
    if unit == currentPlayer.selectedUnit and not unit.moving then
		self:Render("unit/selection.png", pixelCoordinates.x, pixelCoordinates.y)
	end
	
	if namesOn then -- namesOn really needs to be replaced, too; TODO
		love.graphics.printf(unit.unitName, unit.pixelCoordinates.x, unit.pixelCoordinates.y + map.hexDimensionY * 0.60, map.hexDimensionX, "center") -- magic numbers!
	end
end

function Renderer:RenderMap(map)
    local unitsToRender = {}

    for y = 1, map.sizeY do
        for x = 1, map.sizeX do
            if map:CheckValidCoordinates ({x = x, y = y}) then
                pixelCoordinates = map:Hex2PixelCoordinates (x, y)
                
                self:Render(map.tiles[y][x], pixelCoordinates)
                
                if map.gridOn then -- the grid
                    self:Render({imagePath = "tile/grid.png"}, pixelCoordinates)
                end
                
                if map.tiles[y][x].containsUnit then -- will later add stuff like invis, so that's why it's not just going through all units at the end; also, so units that are larger than the hex (thanks to, say, the name being displayed) don't get obscured by later hexes, they're drawn at the end
                    table.insert(unitsToRender, {unit = map.tiles[y][x].containsUnit, coordinates = pixelCoordinates})
                end
            end
        end
    end
    
    for key, value in pairs(unitsToRender) do
        self:RenderUnit(value.unit, value.coordinates)
    end
end