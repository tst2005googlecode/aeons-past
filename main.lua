require("map")
require("unit")
require("astar")
require("log")
require("player")
require("socket")
require("renderer")
require("tserial")

function love.load() -- this is a mess, I gotta clean it up eventually; TODO
    love.graphics.setMode(1024, 768)
    love.graphics.setCaption("Aeons Past")
    
    speed = 5
    
    renderer = Renderer.new()
    
    mouseLastHex = {x = 0, y = 0}
    
    map = nil
    
    playerList = PlayerList.new()
    Player.new(playerList)
    Player.new(playerList)
    currentPlayer = playerList:GetCurrentPlayer()
    units = {}
    --[[
    units[1] = Unit.new (map, "basic",  {x = 6, y = 6}, playerList.players[1])
    units[2] = Unit.new (map, "basic",  {x = 1, y = 6}, playerList.players[1])
    units[3] = Unit.new (map, "amphibian", {x = 10, y = 3}, playerList.players[2])
    
    currentPlayer.selectedUnit = units[1]
    ]]--
    
    unitPath = {} -- current path which the active unit has to traverse to get to the hex the mouse is pointing at
    unitAccess = {} -- for displaying the area you can move to
    
    --unitAccess = currentPlayer.selectedUnit:GetAccessibleHexes(map, currentPlayer.selectedUnit.speed, currentPlayer.selectedUnit.coordinates)
    
    namesOn = true
    displayMode = "map" -- TODO: make all those bools and whistles a table
    
    eventLog = Log.new()
    
    client = nil
    host = "localhost" -- TODO
    port = 1802 -- TODO
    timeout = 0
    
    math.randomseed(os.time())
end

function FunctionWithParam( ... ) -- closure function; courtesy of ktd; gotta go in front of everything else in case I want to use closure on something later on
    if type( arg[1] ) == 'function' then
        local f = table.remove( arg, 1 )
        return function()
            f( unpack( arg ) )
        end
    else
        return nil
    end
end

function love.update(dt)
    -- server stuff has max priority
    if client then
        local message = client:receive("*l")
        if message then
            packet = TSerial.unpack(message)
            if packet[1] == "map" then
                map = packet[2]
                setmetatable(map, Map)
            end
            love.graphics.print(message, 10, 710)
        end
    end

    -- wait for map from server to start actually updating stuff
    if not map then
        return
    end

    local mouseX = love.mouse.getX()
    local mouseY = love.mouse.getY()

    
    if mouseX > 0 and mouseX < map.currentPixelX and mouseY > 0 and mouseY < map.currentPixelY then
        local mouseCurrentHex = map:Pixel2HexCoordinates(mouseX, mouseY)
        
        if map:CheckValidCoordinates(mouseCurrentHex) then
            if mouseLastHex.x ~= mouseCurrentHex.x or mouseLastHex.y ~= mouseCurrentHex.y then -- if the mouse moved from the last hex it was in; so that A* isn't called every tick
                mouseLastHex = mouseCurrentHex
                if currentPlayer.selectedUnit and not currentPlayer.selectedUnit.moving then
                    unitPath = AStarFindPath(map, currentPlayer.selectedUnit, currentPlayer.selectedUnit.coordinates, mouseCurrentHex)
                end
            end
        else
            mouseLastHex.x, mouseLastHex.y = 0, 0
        end
    else
        mouseLastHex.x, mouseLastHex.y = 0, 0
    end
    
    if currentPlayer.selectedUnit and currentPlayer.selectedUnit.moving then
        if #unitPath > 0 then
            if currentPlayer.selectedUnit:TryMove(map, unitPath[#unitPath]) then
                table.remove(unitPath)
            end
        else
            currentPlayer.selectedUnit:EndMovement()
        end
    end
end

function love.draw()
    if not map then
        return
    end
    if displayMode == "map" then
        renderer:RenderMap(map)
        
        if mouseLastHex.x ~= 0 and not (currentPlayer.selectedUnit and currentPlayer.selectedUnit.moving) then -- if it's not outside the grid basically
            local mouseCoordinatesAdjustedToGrid = map:Hex2PixelCoordinates(mouseLastHex.x, mouseLastHex.y)
                    
            renderer:Render({imagePath = "mouseselection.png"}, mouseCoordinatesAdjustedToGrid)
            
            for key, value in pairs(unitPath) do
                if key ~= 1 then -- don't place a path graphic in the hex at which the mouse points, that's ugly
                    local pixelCoordinates = map:Hex2PixelCoordinates(value.x, value.y)
                    renderer:Render({imagePath = "unit/path.png"}, pixelCoordinates)
                end
            end
        end
        
        if currentPlayer.selectedUnit and not currentPlayer.selectedUnit.moving then
            for key, value in pairs(unitAccess) do
                local pixelCoordinates = map:Hex2PixelCoordinates(value.x, value.y)
                renderer:Render({imagePath = "unit/moveable.png"}, pixelCoordinates) -- right now covers the unit and the selection on it; TODO: fix that
            end
        end
                
        love.graphics.print("G: toggle grid; L: log; R: reroll names; N: toggle name display; Movement speed: "..speed.."; +/- to change", 10, 650)
--      love.graphics.print("Q: normal; W: 2spooky4u; E: yayifications;", 10, 670)
        love.graphics.print("Enter: end turn; Escape: quit \"game\"; S: connect to/disconnect from server", 10, 690)
        
    elseif displayMode == "log" then
        love.graphics.print(eventLog:ReadLastNEntries(10), 10, 2)
    end
end

function love.keypressed (key)
    if keyLookup[key] then
        keyLookup[key]()
    elseif key:match("%d") and not currentPlayer.selectedUnit.moving then
        local number = tonumber(key)
        if number then
            if units[number] then
                if units[number].owner == currentPlayer then
                    if currentPlayer.selectedUnit ~= units[number] then -- better compare an extra time than call astar an extra time
                        unitPath = AStarFindPath(map, currentPlayer.selectedUnit, currentPlayer.selectedUnit.coordinates, mouseLastHex)
                        units[number]:Select()
                    end
                end
            end
        end
    end
end

function love.mousepressed (x, y, button)
    local coordinates = map:Pixel2HexCoordinates(x, y)
    
    if coordinates.x < 1 or coordinates.x > map.sizeX or coordinates.y < 1 or coordinates.y > map.sizeY then
        return
    end
    
    if button == "l" and not currentPlayer.selectedUnit.moving then
        if map:CheckValidCoordinates(coordinates) then
            local unit = map.tiles[coordinates.y][coordinates.x].containsUnit
            if unit then
                if unit.owner == currentPlayer then
                    unit:Select()
                end
            end
        end
    elseif button == "r" then
        if #unitPath ~= 0 then
            if unitAccess[HexCoordinatesHash(coordinates.x, coordinates.y)] then
                currentPlayer.selectedUnit.moving = true
            end
        end
    end
end

function IncreaseSpeed()
    if speed < 5 then
        speed = speed + 1
    end
end

function DecreaseSpeed()
    if speed > 1 then
        speed = speed - 1
    end
end

function ServerConnect()
    local tcpSocket, error = socket.tcp()
    
    if not tcpSocket then
        return error
    end
    
    local result, error = tcpSocket:connect(host, port)
    
    if not result then
        return error
    end
    
    tcpSocket:settimeout(timeout)
    
    client = tcpSocket -- only if connection is well
end

function ServerDisconnect()
    client:close()
    client = nil
end

keyLookup = {
    g = function() map.gridOn = not map.gridOn end, -- toggle grid
    n = function() namesOn = not namesOn end, -- toggle names
    
    ["return"] = function() currentPlayer:EndTurn() end,
    kpenter = function() currentPlayer:EndTurn() end,
    
    r = function() for key, value in pairs(units) do value:GenerateName() end end, -- reroll names
    
--  q = function() map.world = "prime" end,
--  w = function() map.world = "deathford" end,
--  e = function() map.world = "lesca" end,

    s = function() if not client then ServerConnect() else ServerDisconnect() end end,
    
    l = function() if displayMode ~= "log" then displayMode = "log" else displayMode = "map" end end,
    
    ["kp+"] = IncreaseSpeed,
    ["+"] = IncreaseSpeed,
    
    ["kp-"] = DecreaseSpeed,
    ["-"] = DecreaseSpeed,
    
    escape = function() if displayMode ~= "map" then displayMode = "map" else love.event.push("quit") end end
}
