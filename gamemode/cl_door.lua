local _mt = {}
_mt.__index = _mt

function _mt:ReadFromNet()
	self.x = net.ReadFloat()
	self.y = net.ReadFloat()
	self.angle = net.ReadFloat()
	
	self.Bounds = Bounds()
	local coords = {
		{ x = -32, y = -64 },
		{ x = -32, y =  64 },
		{ x =  32, y =  64 },
		{ x =  32, y = -64 }
	}
	local trans = Transform2D()
	trans:Rotate(self.angle * math.pi / 180)
	trans:Translate(self.x, self.y)
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

function _mt:ApplyTransform(transform)
	if not self.Poly then self.Poly = {} end

	if not self.Poly[transform] then
		local poly = {}
		local coords = {
			{ x = -32, y = -64 },
			{ x = -32, y =  64 },
			{ x =  32, y =  64 },
			{ x =  32, y = -64 }
		}
		local trans = Transform2D()
		trans:Rotate(self.angle * math.pi / 180)
		trans:Translate(self.x, self.y)
		for i, v in ipairs(coords) do
			local x, y = transform:Transform(trans:Transform(v.x, v.y))
			poly[i] = { x = x, y = y }
		end
		self.Poly[transform] = poly
	end

	self.Poly.Current = self.Poly[transform]
end

function _mt:Draw(screen, colorFunc)
	if not self.Poly then return end

	if colorFunc then
		surface.SetDrawColor(colorFunc(screen, self))
	else
		surface.SetDrawColor(Color(0, 0, 0, 255))
	end
	
	surface.DrawPoly(self.Poly.Current)
	
	surface.SetDrawColor(Color(255, 255, 255, 255))
	last = self.Poly.Current[#self.Poly.Current]
	lx, ly = last.x, last.y
	for _, v in ipairs(self.Poly.Current) do
		surface.DrawLine(lx, ly, v.x, v.y)
		lx, ly = v.x, v.y
	end
end

function Door(ship)
	return setmetatable({ Ship = ship, _lastUpdate = 0 }, _mt)
end
