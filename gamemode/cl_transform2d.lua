local _mt = {}
_mt.__index = _mt

_mt.Matrix = nil
_mt.Offset = nil

function _mt:Translate(x, y)
	self.Offset.x = self.Offset.x + x
	self.Offset.y = self.Offset.y + y
end

function _mt:Scale(x, y)
	self.Matrix = self.Matrix:Scale(x, y)
end

function _mt:Rotate(ang)
	self.Matrix = self.Matrix:Rotate(ang)
end

function _mt:Transform(x, y)
	x, y = self.Matrix:Transform(x, y)
	return x + self.Offset.x, y + self.Offset.y
end

function Transform2D()
	return setmetatable({ Matrix = Matrix(1, 0, 0, 1), Offset = { x = 0, y = 0 } }, _mt)
end

function FindBestTransform(sourceBounds, destBounds, canRotate, flip, angle)
	local src = sourceBounds:GetSize()
	src.centre = sourceBounds:GetCentre()
	local trans = Transform2D()
	
	if angle then
		angle = math.Round(angle / 90)
		trans:Rotate(angle * math.pi / 2)
		if (math.abs(angle) % 2) == 1 then
			src.width, src.height = src.height, src.width
		end
	elseif canRotate and src.width < src.height then
		trans:Rotate(math.pi / 2)
		src.width, src.height = src.height, src.width
	end
	
	if flip then trans:Scale(1, -1) end
	
	src.ratio = src.width / src.height
	
	local dest = destBounds:GetSize()
	dest.centre = destBounds:GetCentre()
	dest.ratio = dest.width / dest.height
	
	if dest.ratio < src.ratio then
		trans:Scale(dest.width / src.width)
	else
		trans:Scale(dest.height / src.height)
	end
	
	local sx, sy = trans:Transform(src.centre.x, src.centre.y)
	trans:Translate(dest.centre.x - sx, dest.centre.y - sy)
	return trans
end
