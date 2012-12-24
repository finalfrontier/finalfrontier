local _index = {}
_index.Matrix = nil
_index.Offset = nil

function _index:Translate(x, y)
	self.Offset.x = self.Offset.x + x
	self.Offset.y = self.Offset.y + y
end

function _index:Scale(x, y)
	self.Matrix = self.Matrix:Scale(x, y)
end

function _index:Rotate(ang)
	self.Matrix = self.Matrix:Rotate(ang)
end

function _index:Transform(x, y)
	x, y = self.Matrix:Transform(x, y)
	return x + self.Offset.x, y + self.Offset.y
end

function Transform2D()
	local trans = { Matrix = Matrix(1, 0, 0, 1), Offset = { x = 0, y = 0 } }
	setmetatable(trans, { __index = _index })
	return trans
end

function FindBestTransform(sourceBounds, destBounds, canRotate, flip)
	local src = sourceBounds:GetSize()
	src.centre = sourceBounds:GetCentre()
	local trans = Transform2D()
	
	if canRotate and src.width < src.height then
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
