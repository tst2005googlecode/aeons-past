-- astar for hexes
require("map") -- for the estimate
require("unit") -- getting the impassable tiles

function AStarFindPath (map, unit, start, finish) -- both the arguments are tables of the {x, y} format
	local openNodes = NodeList.new()
	local closedNodes = NodeList.new()
	local current
		
	current = Node.new(start,finish) -- no need to pass the terrainType here since it doesn't get evaluated if there's no parent; neither does the parent
	openNodes:AddNode(current) -- inserting the first one since that's the basis for everything else
	
	while #openNodes do
		if current.coordinates.x == finish.x and current.coordinates.y == finish.y then
			return current:BuildPath(start)
		end
		
		for key, value in pairs(GetHexNeighbours(current.coordinates)) do
			if unit:CheckValidDestination(map, value) then
				local node = Node.new(value, finish, unit, map.tiles[value.y][value.x].terrainType, current)
				if not closedNodes[node.nodeHash] then
					openNodes:AddNode(node)
				end
			end
		end
		
		openNodes:RemoveNode(current)
		closedNodes:AddNode(current)
		
		current = openNodes:FindNodeWithLowestF()
		
		if not current then -- if the tile is unreachable, for example
			return {}
		end
	end
	
	return {} -- if no path found it reaches this return of NOTHING
end

Node = {}

Node.__index = Node

function Node.new (coordinates, finish, unit, terrainType, parent)
	local node = {
		parent = parent,
		coordinates = coordinates,
		
		g = 0,
		h = 0,
		
		f = 0,
		
		numberInOpenNodes = currentNumber,
		
		nodeHash = "00"
	}
	
	setmetatable(node,Node)
	
	if node.parent then
		node.g = parent.g + unit.movementType[terrainType]
	else
		node.g = 0
	end
	
	node.h = FindEstimatePathLength(coordinates, finish)
	
	node.f = node.g + node.h
	
	 -- I'll be using a hash function here for faster finding; we can expect our maps to be no larger than 10x10 and that simplifies matters: x - 1 and y - 1 both lie within single digits; if they larger, I'd have to write a better hash function than just concatenation of the two digits
	node.nodeHash = HexCoordinatesHash(node.coordinates.x, node.coordinates.y)
	
	return node
end

function Node:BuildPath (start)
	local path = {}
	local current = self
	
	while current.coordinates.x ~= start.x or current.coordinates.y ~= start.y do
		table.insert(path,current.coordinates)
		current = current.parent
	end
	
	return path
end

NodeList = {}

NodeList.__index = NodeList

function NodeList.new ()
	local nodeList = {}
	
	setmetatable(nodeList,NodeList)
	
	return nodeList
end

function NodeList:AddNode (node)
	if not self[node.nodeHash] or self[node.nodeHash].g > node.g then
		self[node.nodeHash] = node
	end
end

function NodeList:RemoveNode (node)
	self[node.nodeHash] = nil
end

function NodeList:FindNodeWithLowestF ()
	local node
	
	for key, value in pairs(self) do
		if not node or node.f > value.f then
			node = value
		end
	end
	
	return node
end

function FindEstimatePathLength (start, finish) -- for the heuristics; both the arguments are tables of the {x, y} format
	
	local length = 0
	
	local current = {x = start.x, y = start.y}
		
	while current.y ~= finish.y do
		local currentNeighbours = GetHexNeighbours(current)
		
		if current.y > finish.y then
			destination = "N"
		else
			destination = "S"
		end
		
		if current.x < finish.x then
			current = currentNeighbours[destination.."E"]
		elseif current.x > finish.x then
			current = currentNeighbours[destination.."W"]
		else
			if current.y % 2 == 0 then
				current = currentNeighbours[destination.."E"]
			else
				current = currentNeighbours[destination.."W"]
			end
		end
			
		length = length + 1
	end
	
	while current.x ~= finish.x do
	
		if current.x > finish.x then
			current.x = current.x - 1
		else
			current.x = current.x + 1
		end
		
		length = length + 1	
	end
		
	return length
end