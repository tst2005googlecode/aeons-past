require("socket")
require("tserial")
require("map")

local host = "localhost" -- temporary, will replace with actual input later; TODO
local port = 1802 -- same, TODO; reason I chose 1802 is because it's forwarded on my router. not important for localhost but still
local players = 4 -- for the listen() function
local timeout = 0.1

GameServer = {}
GameServer.__index = GameServer

function GameServer.new(host, port, players, timeout)
    local gameServer = {
        clients = {},
        maxClients = players,
        map = Map.new("map.txt")
    }
    print("loaded map.txt")
    setmetatable(gameServer, GameServer)
    local tcpServer, error = socket.tcp()
    if not tcpServer then
        return error
    else
        gameServer.server = tcpServer
    end
    local result, error = tcpServer:bind(host, port) -- I'd use assert but that kind of culls the error message being returned
    if not result then
        return error
    end
    result, error = tcpServer:listen(players) -- I'd use assert but that kind of culls the error message being returned
    if not result then
        return error
    end
    tcpServer:settimeout(timeout)
    return gameServer
end

function GameServer:Run()
    local newClient = self.server:accept()
    if newClient then	
        if #self.clients < self.maxClients then
            table.insert(self.clients, newClient)
            newClient:settimeout(0.01)
            print(newClient:getpeername().." connected.")
            -- send synch data
            print("sent map data to "..newClient:getpeername())
            newClient:send(TSerial.pack({"map", self.map}).."\n")
        else
            newClient:send(TSerial.pack({"full"}).."\n")
        end
    end
    for key, client in pairs(self.clients) do
        message, code = client:receive("*l")
        if not message and code == 'closed' then
            print("disconnected client")
            self.clients[key] = nil
        end
    end
    for key, client in pairs(self.clients) do
        --client:send(TSerial.pack({"beat", 0, 1}).."\n")
    end
end

function GameServer:Close()
    self.server:close()
end
--

local gameServer = GameServer.new(host, port, players, timeout)
print("server listening")
while true do
    gameServer:Run()
end
print("server done")

gameServer:Close()
