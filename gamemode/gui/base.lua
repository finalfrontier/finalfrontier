GUI._parent = nil

GUI._offsetx = 0
GUI._offsety = 0

GUI._posx = 0
GUI._posy = 0

function GUI:GetOffset()
	return self._offsetx, self._offsety
end

function GUI:SetOffset(x, y)
	if x then self._offsetx = x end
	if y then self._offsety = y end

	if x or y then
		self:UpdatePosition()
	end
end

function GUI:UpdatePosition()
	self._posx = self._offsetx
	self._posy = self._offsety

	if self:HasParent() then
		local addx, addy = self:GetParent():GetPos()
		self._posx = self._posx + addx
		self._posy = self._posy + addy
	end
end

function GUI:GetPos()
	return self._posx, self._posy
end

function GUI:Remove()
	if self:HasParent() then
		self:GetParent():RemoveChild(self)
	end
end

function GUI:HasParent()
	return self._parent ~= nil
end

function GUI:GetParent()
	return self._parent
end
