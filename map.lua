-- contains everything related to maps:
--  loading from file
--  drawing the map
--  conversion to pixel coordinates from hex coordinates and vice versa

Map = {}
Map.__index = Map

function Map.new (sourceFile) -- constructor for a Map class instance
    local map = {
        world = "prime", -- can be "prime", "lesca" or "deathford"; Lesca being this game's ripoff off Feywild, Deathford is Shadowfell
        gridImage = "tile/grid.png",
        
        sizeX = 10,
        sizeY = 10,
        
        hexDimensionX = 80,
        hexDimensionY = 80,
        
        -- vars determening the size of the map-displaying area in the game window; start at "all of the map" because it's small enough to fit the screen
        currentPixelX,
        currentPixelY,
        
        gridOn = true,
        
        tiles = {{}}
    }
    
    setmetatable(map, Map)
    
    map.currentPixelX = (map.sizeX + 0.5) * map.hexDimensionX
    map.currentPixelY = (map.sizeY * 0.75 + 0.25) * map.hexDimensionY

    local j = 1
    
    for line in io.lines(sourceFile) do
        map.tiles[j] = {}
        
        for i = 1, #line do
            local current = line:sub(i,i)
            
            if current:match("%D") then break end -- a non-digit, including "\", ends the current line
            
            if map:CheckValidCoordinates({x = i, y = j}) then
                map.tiles[j][i] = Tile.new(current)
            end
        end
        
        j = j + 1
    end
    
    return map
end

-- function Map:Draw ()
   -- for y = 1, self.sizeY do
       -- for x = 1, self.sizeX do
           -- if self:CheckValidCoordinates ({x = x, y = y}) then
               -- pixelCoordinates = self:Hex2PixelCoordinates (x, y)
               
               -- self.tiles[y][x]:Draw(pixelCoordinates)
               
                -- if self.gridOn then -- the grid
                   -- renderer:Render("tile/grid.png", pixelCoordinates)
                -- end
            -- end
        -- end
    -- end
-- end

function Map:CheckValidCoordinates (coordinates)
    if coordinates.x < 1 or coordinates.x > self.sizeX or coordinates.y < 1 or coordinates.y > self.sizeY then
        return false
    elseif (coordinates.x == self.sizeX and coordinates.y == 1) or (coordinates.x == 1 and coordinates.y == self.sizeY) then -- don't count the top right and bottom left corners as valid; we have a sort of a "sloped" map as a result
        return false
    else
        return true
    end
end

function Map:Hex2PixelCoordinates (x, y)
    coordinates = {x = 0, y = 0}
    
    coordinates.x = ((x - 1) + (y % 2) / 2) * self.hexDimensionX
    coordinates.y = (y - 1) * self.hexDimensionY * 0.75
    
    return coordinates
end

-- using the guide on http://www.gamedev.net/page/resources/_/technical/game-programming/coordinates-in-hexagon-based-tile-maps-r1800
function Map:Pixel2HexCoordinates (x, y)
    coordinates = {x = 0, y = 0}
    
    local section = {}
    
    section.x = math.floor(x / self.hexDimensionX) -- edge cases will be resolved incorrectly as there's no ceiling() function but that's to be solved later; TODO
    section.y = math.floor(y / (self.hexDimensionY * 0.75)) + 1
    
    section.cursorX = x % self.hexDimensionX
    section.cursorY = y % (self.hexDimensionY * 0.75)
    
    if section.y % 2 == 0 then -- even
        if section.cursorX > self.hexDimensionX * 0.5 then -- right side
            if section.cursorY * 2 > section.cursorX - self.hexDimensionX * 0.5 then
                coordinates.x = section.x + 1
                coordinates.y = section.y
            else
                coordinates.x = section.x + 1
                coordinates.y = section.y - 1
            end
        else -- left side
            if section.cursorY * 2 > self.hexDimensionX * 0.5 - section.cursorX then
                coordinates.x = section.x + 1
                coordinates.y = section.y
            else
                coordinates.x = section.x
                coordinates.y = section.y - 1
            end
        end
    else -- odd
        if section.cursorX > self.hexDimensionX * 0.5 then -- right side
            if section.cursorY * 2 < self.hexDimensionX - section.cursorX then
                coordinates.x = section.x + 1
                coordinates.y = section.y - 1
            else
                coordinates.x = section.x + 1
                coordinates.y = section.y
            end
        else -- left side
            if section.cursorY * 2 > section.cursorX then
                coordinates.x = section.x
                coordinates.y = section.y
            else
                coordinates.x = section.x + 1
                coordinates.y = section.y - 1
            end
        end
    end
    
    return coordinates
end

function GetHexNeighbours (coordinates)
    local results = {}
    
    results.NW = {x = coordinates.x - (coordinates.y + 1) % 2, y = coordinates.y - 1}
    results.NE = {x = coordinates.x + coordinates.y % 2, y = coordinates.y - 1}
    results.W = {x = coordinates.x - 1, y = coordinates.y}
    results.E = {x = coordinates.x + 1, y = coordinates.y}
    results.SW = {x = coordinates.x - (coordinates.y + 1) % 2, y = coordinates.y + 1}
    results.SE = {x = coordinates.x + coordinates.y % 2, y = coordinates.y + 1}
    
    return results
end

function AreNeighbours (hexOne, hexTwo)

    if hexOne.y == hexTwo.y then
        if hexOne.x == hexTwo.x - 1 or hexOne.x == hexTwo.x + 1 then
            return true
        else
            return false
        end
    end
    
    if hexOne.y < hexTwo.y - 1 or hexOne.y > hexTwo.y + 1 then
        return false
    end
    
    if hexOne.x == hexTwo.x then
        return true
    end
    
    if hexOne.x == hexTwo.x - 1 + 2 * (hexOne.y % 2) then
        return true
    else
        return false
    end
end

function HexCoordinatesHash (x,y)
    return (x - 1)..(y - 1)-- with x and y being within [1,10] it's ridiculously easy
end

-- tiles

Tile = {}
Tile.__index = Tile

function Tile.new (tileType)
    local tile = {
        tileName = "default",
        imagePath = "tile/nographic.png",
        
        terrainType = "none",
        
        containsUnit -- link to the unit if any
    }
    
    setmetatable(tile,Tile)
    
    if tileType == "0" then
        tile.tileName = "grass"
        tile.terrainType = "ground"
    elseif tileType == "1" then
        tile.tileName = "wall"
        tile.terrainType = "obstacle"
    elseif tileType == "2" then
        tile.tileName = "water"
        tile.terrainType = "water"
    elseif tileType == "3" then
        tile.tileName = "forest"
        tile.terrainType = "overgrowth"
    end
    
    tile.imagePath = table.concat({"tile/","prime/",tile.tileName,".png"},"")
    
    return tile
end