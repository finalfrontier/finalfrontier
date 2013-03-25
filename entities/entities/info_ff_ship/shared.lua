if SERVER then AddCSLuaFile("shared.lua") end

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Rooms = nil
ENT._roomlist = nil
ENT.Doors = nil

ENT.Bounds = nil

if SERVER then
	ENT._players = nil

	function ENT:KeyValue(key, value)
		if key == "hullhealth" then
			self:SetNWInt("basehullhealth", tonumber(value))
		end
	end

	function ENT:AddRoom(room)
		local name = room:GetName()
		if not name then return end

		self.Rooms[name] = room
		table.insert(self._roomlist, room)
		self.Bounds:AddBounds(room.Bounds)
		
		room.Index = #self._roomlist
	end

	function ENT:AddDoor(door)
		if not table.HasValue(self.Doors, door) then
			table.insert(self.Doors, door)
			door.Index = #self.Doors
		end
	end

	local ply_mt = FindMetaTable("Player")
	function ply_mt:SetShip(ship)
		if self._ship == ship then return end
		if self._ship then
			self._ship:_removePlayer(self)
		end
		ship:_addPlayer(self)
		self._ship = ship
		self:SetNWString("ship", ship:GetName())
	end

	function ply_mt:GetShip()
		return self._ship
	end

	function ENT:_addPlayer(ply)
		if not table.HasValue(self._players, ply) then
			table.insert(self._players, ply)
		end
	end

	function ENT:_removePlayer(ply)
		if table.HasValue(self._players, ply) then
			table.remove(self._players, table.KeyFromValue(self._players, ply))
		end
	end
elseif CLIENT then
	function ENT:AddRoom(room)
		self.Rooms[room.Name] = room
		self._roomlist[room.Index] = room

		self.Bounds:AddBounds(room.Bounds)
	end

	function ENT:AddDoor(door)
		table.insert(self.Doors, door)
	end

	function ENT:FindTransform(screen, x, y, width, height)
		local bounds = Bounds(x, y, width, height)
		return FindBestTransform(self.Bounds, bounds, true, true)
	end

	function ENT:ApplyTransform(transform)
		for _, room in pairs(self.Rooms) do
			room:ApplyTransform(transform)
		end

		for _, door in ipairs(self.Doors) do
			door:ApplyTransform(transform)
		end
	end

	function ENT:Draw(screen, roomColorFunc, doorColorFunc)
		if screen == nil then return end

		for _, room in pairs(self.Rooms) do
			room:Draw(screen, roomColorFunc)
		end

		for _, door in ipairs(self.Doors) do
			door:Draw(screen, doorColorFunc)
		end
	end

	local ply_mt = FindMetaTable("Player")
	function ply_mt:GetShip()
		if not self:GetNWString("ship") then return nil end
		return ships.FindByName(self:GetNWString("ship"))
	end
end

function ENT:Initialize()
	self.Rooms = {}
	self._roomlist = {}
	self.Doors = {}
	self.Bounds = Bounds()

	if SERVER then
		self:DrawShadow(false)
		self._players = {}
	end
end

function ENT:InitPostEntity()
	ships.Add(self)
end

function ENT:GetRooms()
	return self._roomlist
end

function ENT:GetRoomByIndex(index)
	return self._roomlist[index]
end

function ENT:IsPointInside(x, y)
	return self.Bounds:IsPointInside(x, y)
end

function ENT:GetBaseHullHealth()
	return self:GetNWInt("basehullhealth", 1)
end
