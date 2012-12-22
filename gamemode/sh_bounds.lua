local _boundsIndex = {}
_boundsIndex.l = 0
_boundsIndex.t = 0
_boundsIndex.r = 0
_boundsIndex.b = 0
_boundsIndex._set = false

function _boundsIndex:GetSize()
	return { width = self.r - self.l, height = self.b - self.t }
end

function _boundsIndex:GetCentre()
	return { x = (self.r + self.l) / 2, y = (self.b + self.t) / 2 }
end

function _boundsIndex:AddPoint(x, y)
	if not self._set then
		self.l, self.t, self.r, self.b = x, y, x, y
		self._set = true
	else
		if x < self.l then self.l = x end
		if y < self.t then self.t = y end
		if x > self.r then self.r = x end
		if y > self.b then self.b = y end
	end
end

function _boundsIndex:AddBounds(bounds)
	if not self._set then
		self.l, self.t, self.r, self.b = bounds.l, bounds.t, bounds.r, bounds.b
		self._set = true
	else
		if bounds.l < self.l then self.l = bounds.l end
		if bounds.t < self.t then self.t = bounds.t end
		if bounds.r > self.r then self.r = bounds.r end
		if bounds.b > self.b then self.b = bounds.b end
	end
end

function _boundsIndex:Equals(bounds)
	return self.l == bounds.l and self.t == bounds.t and self.r == bounds.r and self.b == bounds.b
end

function Bounds(x, y, width, height)
	local bounds = {}
	if x then
		bounds.l, bounds.t, bounds.r, bounds.b = x, y, x + width, y + height
		bounds._set = true
	end
	setmetatable(bounds, { __index = _boundsIndex })
	return bounds
end
