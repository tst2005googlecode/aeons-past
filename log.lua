Log = {}
Log.__index = Log

function Log.new()
	local log = {
		entries = {}
	}
	
	setmetatable(log,Log)
	
	return log
end

function Log:AddEntry(entry)
	table.insert(self.entries, entry)
end

function Log:ReadEntry(index)
	return self.entries[index] or "entry not found"
end

function Log:ReadLastNEntries(n)
	if #self.entries == 0 then
		return "no entries"
	end

	local n = n or 1
	local index = math.max(1,#self.entries - n - 1) -- an extra -1 so it doesn't grab an extra line
	
	return table.concat(self.entries, "\n", index)
end