-- holds the player's preferences, whether it's his turn, whatnot.

Player = {}
Player.__index = Player

function Player.new(playerList)
	local player = {
		id,
		
		parent = playerList,
		
		preferences = {},
		
		units = {},
		selectedUnit
	}
	
	setmetatable(player, Player)
	
	playerList:AddPlayer(player)
end

function Player:EndTurn()
	for key, value in pairs(self.units) do
		value.remainingMoves = value.speed
		value.acted = false
	end
	
	currentPlayer = self.parent:NextPlayer()
	currentPlayer.units[1]:Select()
end

PlayerList = {}
PlayerList.__index = PlayerList

function PlayerList.new()
	local playerList = {
		players = {},
		
		currentPlayerNumber = 1
	}
	
	setmetatable(playerList, PlayerList)
	
	return playerList
end

function PlayerList:AddPlayer(player)
	table.insert(self.players, player)
	player.id = "player"..#self.players
end

function PlayerList:NextPlayer()
	if self.currentPlayerNumber == #self.players then
		self.currentPlayerNumber = 1
	else
		self.currentPlayerNumber = self.currentPlayerNumber + 1
	end
	
	return self.players[self.currentPlayerNumber]
end

function PlayerList:GetCurrentPlayer()
	return self.players[self.currentPlayerNumber]
end