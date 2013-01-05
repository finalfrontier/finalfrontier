local _mt = {}
_mt.__index = _mt

_mt._lastUpdate = 0

_mt.Ship = nil
_mt.Rooms = nil

_mt.X = 0
_mt.Y = 0
_mt.Angle = 0

_mt.Open = false
_mt.Locked = false

_mt.Bounds = nil

function _mt:ReadFromNet()
	self.X = net.ReadFloat()
	self.Y = net.ReadFloat()
	self.Angle = net.ReadFloat()
	
	self.Bounds = Bounds()
	local coords = {
		{ x = -32, y = -64 },
		{ x = -32, y =  64 },
		{ x =  32, y =  64 },
		{ x =  32, y = -64 }
	}
	local trans = Transform2D()
	trans:Rotate(self.Angle * math.pi / 180)
	trans:Translate(self.X, self.Y)
	for i, v in ipairs(coords) do
		self.Bounds:AddPoint(trans:Transform(v.x, v.y))
	end

	local roomai = net.ReadInt(8)
	local roombi = net.ReadInt(8)
	self.Open = false
	self.Locked = false
	self.Rooms = { self.Ship._roomlist[roomai], self.Ship._roomlist[roombi] }
	
	table.insert(self.Rooms[1].Doors, self)
	table.insert(self.Rooms[2].Doors, self)
end

function Door(ship)
	return setmetatable({ Ship = ship }, _mt)
end
