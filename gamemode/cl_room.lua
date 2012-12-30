local ROOM_UPDATE_FREQ = 1

local _mt = {}
_mt.__index = _mt
_mt._lastUpdate = 0

_mt._temperature = 0
_mt._oldTemp = 0
_mt._atmosphere = 0
_mt._oldAtmo = 0
_mt._shields = 0
_mt._oldShld = 0

function _mt:ReadFromNet()
	self.Name = net.ReadString()
	self.Index = net.ReadInt(8)
	self.System = sys.Create(net.ReadString(), self)
	
	local cornerCount = net.ReadInt(8)
	for cNum = 1, cornerCount do
		local index = net.ReadInt(8)
		local pos = { x = net.ReadFloat(), y = net.ReadFloat() }
		
		self.Corners[index] = pos
		self.Bounds:AddPoint(pos.x, pos.y)
	end
	
	self.ConvexPolys = FindConvexPolygons(self.Corners)
end

function _mt:GetName()
	return self.Name
end

function _mt:GetStatusLerp()
	return math.Clamp((CurTime() - self._lastUpdate) / ROOM_UPDATE_FREQ, 0, 1)
end

function _mt:GetTemperature()
	return self._oldTemp + (self._temperature - self._oldTemp) * self:GetStatusLerp()
end

function _mt:GetAtmosphere()
	return self._oldAtmo + (self._atmosphere - self._oldAtmo) * self:GetStatusLerp()
end

function _mt:GetShields()
	return self._oldShld + (self._shields - self._oldShld) * self:GetStatusLerp()
end

function _mt:GetPermissionsName()
	return "p_" .. self.Ship.Name .. "_" .. self.Index
end

function _mt:FindTransform(screen, x, y, width, height)
	local bounds = Bounds(x, y, width, height)
	local roomBounds = Bounds()
	roomBounds:AddBounds(self.Bounds)
	for _, door in ipairs(self.Doors) do
		roomBounds:AddBounds(door.Bounds)
	end
	local angle = screen:GetAngles().Yaw + 90
	
	return FindBestTransform(roomBounds, bounds, false, true, angle)
end

function _mt:ApplyTransform(transform)
	if not self.Poly then self.Poly = {} end

	if not self.Poly[transform] then
		local x, y
		local poly = {}
		poly.Corners = {}
		for i, v in ipairs(self.Corners) do
			x, y = transform:Transform(v.x, v.y)
			poly.Corners[i] = { x = x, y = y }
		end
		poly.ConvexPolys = {}
		for j, p in ipairs(self.ConvexPolys) do
			poly.ConvexPolys[j] = {}
			for i, v in ipairs(p) do
				x, y = transform:Transform(v.x, v.y)
				poly.ConvexPolys[j][i] = { x = x, y = y }
			end
		end
		local centre = self.Bounds:GetCentre()
		x, y = transform:Transform(centre.x, centre.y)
		poly.Centre = { x = x, y = y }

		self.Poly[transform] = poly
	end

	self.Poly.Current = self.Poly[transform]
end

function _mt:Draw(screen, colorFunc)
	if not self.Poly then return end

	local last, lx, ly = nil, 0, 0

	if colorFunc then
		surface.SetDrawColor(colorFunc(screen, self))
	else
		surface.SetDrawColor(Color(32, 32, 32, 255))
	end

	for i, poly in ipairs(self.Poly.Current.ConvexPolys) do
		surface.DrawPoly(poly)
	end

	surface.SetDrawColor(Color(255, 255, 255, 255))
	last = self.Poly.Current.Corners[#self.Poly.Current.Corners]
	lx, ly = last.x, last.y
	for _, v in ipairs(self.Poly.Current.Corners) do
		surface.DrawLine(lx, ly, v.x, v.y)
		lx, ly = v.x, v.y
	end

	if self.System and self.System.Icon and self.Poly.Centre then
		surface.SetMaterial(self.System.Icon)
		surface.SetDrawColor(Color(255, 255, 255, 32))
		surface.DrawTexturedRect(self.Poly.Current.Centre.x - 32,
			self.Poly.Current.Centre.y - 32, 64, 64)
		surface.SetMaterial(WHITE)
	end
end

local ply_mt = FindMetaTable("Player")
function ply_mt:GetPermission(room)
	return self:GetNWInt(room:GetPermissionsName(), 0)
end

function ply_mt:HasPermission(room, perm)
	return self:GetPermission(room) >= perm
end

function ply_mt:SetPermission(room, perm)
	self:SetNWInt(room:GetPermissionsName(), perm)
	net.Start("SetPermission")
		net.WriteString(room.Ship.Name)
		net.WriteInt(room.Index, 8)
		net.WriteEntity(self)
		net.WriteInt(perm, 8)
	net.SendToServer()
end

function ply_mt:HasDoorPermission(door)
	return self:HasPermission(door.Rooms[1], permission.ACCESS)
		and self:HasPermission(door.Rooms[2], permission.ACCESS)
end

function Room(ship)
	local room = { Ship = ship }

	room.Bounds = Bounds()
	room.Doors = {}
	room.Corners = {}

	return setmetatable(room, _mt)
end
