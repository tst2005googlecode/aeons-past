require("socket")

local host = "localhost" -- temporary, will replace with actual input later; TODO
local port = 1802 -- same, TODO; reason I chose 1802 is because it's forwarded on my router. not important for localhost but still
local players = 4 -- for the listen() function
local timeout = 0.01

GameServer = {}
GameServer.__index = GameServer

function GameServer.new(host, port, players, timeout)
	local gameServer = {
		clients = {},
		maxClients = players
	}
	
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
		if not self.clients[newClient:getpeername()] then
			if #self.clients < self.maxClients then
				self.clients[newClient:getpeername()] = newClient
				print(newClient:getpeername().." connected.")
			else
				newClient:send("refusedTooMany")
			end
		end
	end
	
	for key, value in pairs(self.clients) do -- want to handle client dc later on, too
		value:send("You are player number... ah, scratch that. At least I know your IP is "..key.."\n") -- TODO: inherit PlayerClient from client for more info than that; alternately, create a different table in self with same keys but different objects for holding all the non-base-client stuff
	end
end

function GameServer:Close()
	self.server:close()
end
--

local gameServer = GameServer.new(host, port, players, timeout)
	
while true do
	gameServer:Run()
end
	
gameServer:Close()