-- contains unit creation and movement

require("map")

Unit = {}
Unit.__index = Unit

unitNames = { -- silly little thing
	partOne = {"Slab","Fridge","Punt","Butch","Bold","Splint","Flint","Bolt","Thick","Blast","Buff","Trunk","Fist","Stump","Smash","Punch","Buck","Dirk","Rip","Slate","Crud","Brick","Gristle","Slake","Bob","Crunch","Lump","Touch","Reef","Big","Smoke","Beat","Pack","Roll"},
	partTwo = {"Bulk","Large","Speed","Dead","Big","Chest","Iron","Vander","McRun","Hard","Drink","Slam","Rock","Beef","Lamp","Plank","Chunk","Steak","Slab","Bone","Side","McThorn","Fist","John","Thick","Butt","Squat","Rust","Blast","McLarge","Man","Punch","Blow","Fizzle"},
	partThree = {"head","meat","chunk","lift","flank","hair","stag","huge","fast","cheese","lots","chest","bone","gnaw","jaw","groin","man","peck","face","rock","meal","meat","cheek","iron","body","crunch","back","son","neck","steak","thrust","rod","muscle","beef","fist"}
}

unitGraphics = {
	selection = love.graphics.newImage("unit/selection.png"),
	
	nographic = love.graphics.newImage("unit/nographic.png"),
	
	basic = love.graphics.newImage("unit/basic.png"),
	amphibian = love.graphics.newImage("unit/amphibian.png")
}

MOVE_MODES = {
	WALKING = {ground = 1, overgrowth = 2},
	AMPHIBIAN = {ground = 1, overgrowth = 2, water = 2},
	SWIMMING = {water = 1},
	PHASING = {ground = 1, overgrowth = 1, obstacle = 1},
	FLYING = {ground = 1, overgrowth = 1, obstacle = 1, water = 1}
}

function Unit.new (map, unitType, coordinates, owner)
	local unit = { -- default values
			unitName = "derp",
			
			owner = owner,
			
			coordinates = coordinates,
			pixelCoordinates,
			
			unitGraphic = "nographic",
			
			speed = 5, -- how many hexes per turn can this unit move
			remainingMoves = 5,
			
			movementType = MOVE_MODES.WALKING,
			moving = false, -- for iterate moving instead of teleporting around
			
			acted = false -- if it attacked someone or whatever
	}
	
	setmetatable(unit, Unit)
	
	unit:GenerateName()
	unit.pixelCoordinates = map:Hex2PixelCoordinates(coordinates.x, coordinates.y)
	
	if unitType == "basic" then -- will make different units depending on type later on
		unit.unitGraphic = "basic"
	elseif unitType == "amphibian" then
		unit.unitGraphic = "amphibian"
		unit.movementType = MOVE_MODES.AMPHIBIAN
	end
	
	map.tiles[unit.coordinates.y][unit.coordinates.x].containsUnit = unit
	
	table.insert(owner.units, unit)
	
	return unit
end

function Unit:Draw (map)	
	love.graphics.draw(unitGraphics[self.unitGraphic], self.pixelCoordinates.x, self.pixelCoordinates.y)
	
	if self == currentPlayer.selectedUnit and not self.moving then
		love.graphics.draw(unitGraphics.selection, self.pixelCoordinates.x, self.pixelCoordinates.y)
	end
	
	if namesOn then
		love.graphics.printf(self.unitName, self.pixelCoordinates.x, self.pixelCoordinates.y + map.hexDimensionY * 0.60, map.hexDimensionX, "center") -- magic numbers!
	end
end

function Unit:CheckValidDestination (map, coordinates)
	if not map:CheckValidCoordinates (coordinates) then 
		return false 
	end
	
	if not self.movementType[map.tiles[coordinates.y][coordinates.x].terrainType] then
		return false
	end
	
	if map.tiles[coordinates.y][coordinates.x].containsUnit then
		return false
	end
	
	return true
end

function Unit:TryMove (map, coordinates)
	if self:CheckValidDestination(map, coordinates) then
		local pixelCoordinates = map:Hex2PixelCoordinates(coordinates.x, coordinates.y)
		
		if speed == 5 then
			self.pixelCoordinates = pixelCoordinates
			self:MoveInto(map, coordinates)
			return true
		else
			if self.pixelCoordinates.x > pixelCoordinates.x then
				self.pixelCoordinates.x = math.max(self.pixelCoordinates.x - map.hexDimensionX * 0.1 * speed, pixelCoordinates.x)
			else
				self.pixelCoordinates.x = math.min(self.pixelCoordinates.x + map.hexDimensionX * 0.1 * speed, pixelCoordinates.x)
			end
			
			if self.pixelCoordinates.y > pixelCoordinates.y then
				self.pixelCoordinates.y = math.max(self.pixelCoordinates.y - map.hexDimensionY * 0.1 * speed, pixelCoordinates.y)
			else
				self.pixelCoordinates.y = math.min(self.pixelCoordinates.y + map.hexDimensionY * 0.1 * speed, pixelCoordinates.y)
			end
			
			if self.pixelCoordinates.x == pixelCoordinates.x and self.pixelCoordinates.y == pixelCoordinates.y then
				self:MoveInto(map, coordinates)
				return true
			end
		end
	end
end

function Unit:MoveInto(map, coordinates)
	self.remainingMoves = self.remainingMoves - self.movementType[map.tiles[coordinates.y][coordinates.x].terrainType]
	self:ChangeCoordinates(map, coordinates)
end

function Unit:ChangeCoordinates (map, coordinates)
	map.tiles[self.coordinates.y][self.coordinates.x].containsUnit = nil
	self.coordinates = coordinates
	map.tiles[self.coordinates.y][self.coordinates.x].containsUnit = self
end

function Unit:GenerateName ()
	self.unitName = unitNames.partOne[math.random(#unitNames.partOne)].." "..unitNames.partTwo[math.random(#unitNames.partTwo)]..unitNames.partThree[math.random(#unitNames.partThree)]
end

function Unit:GetAccessibleHexes (map, speed, coordinates) -- recursion yay
	local hexList = {}
	local speed = speed or self.speed
	local coordinates = coordinates or self.coordinates	
	
	if speed >= 0 then
		hexList[HexCoordinatesHash(coordinates.x, coordinates.y)] = coordinates
		
		local neighbours = GetHexNeighbours(coordinates)
		for key, value in pairs(neighbours) do
			if self:CheckValidDestination(map, value) then
				local toInsert = self:GetAccessibleHexes(map, speed - self.movementType[map.tiles[value.y][value.x].terrainType], value)
				if toInsert then
					for k, v in pairs(toInsert) do
						hexList[k] = v
					end
				end
			end
		end
	else
		return nil
	end
	
	return hexList
end

function Unit:EndMovement()
	eventLog:AddEntry(self.unitName.." moved to coordinates "..self.coordinates.x..";"..self.coordinates.y)
	self.moving = false
		
	unitAccess = self:GetAccessibleHexes(map, self.remainingMoves, self.coordinates)
end

function Unit:Select()
	unitAccess = self:GetAccessibleHexes(map, self.remainingMoves, self.coordinates)
	currentPlayer.selectedUnit = self
end