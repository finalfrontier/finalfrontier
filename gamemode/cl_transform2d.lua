local _matrixIndex = {}
_matrixIndex.xx = 1
_matrixIndex.xy = 0
_matrixIndex.yx = 0
_matrixIndex.yy = 1

function _matrixIndex:Mul( mat )
	return Matrix(
		mat.xx * self.xx + mat.xy * self.yx, mat.xx * self.xy + mat.xy * self.yy,
		mat.yx * self.xx + mat.yy * self.yx, mat.yx * self.xy + mat.yy * self.yy )
end

function _matrixIndex:Rotate( angle )
	local c = math.cos( angle )
	local s = math.sin( angle )
	
	return self:Mul( Matrix( c, -s, s, c ) )
end

function _matrixIndex:Transform( x, y )
	return x * self.xx + y * self.xy, x * self.yx + y * self.yy
end

function _matrixIndex:Scale( x, y )
	y = y or x
	return Matrix( self.xx * x, self.xy * y, self.yx * x, self.yy * y )
end

function Matrix( xx, xy, yx, yy )
	local matrix = { xx = xx or 1, xy = xy or 0, yx = yx or 0, yy = yy or 1 }
	setmetatable( matrix, { __index = _matrixIndex } )
	return matrix
end

local _transform2dIndex = {}
_transform2dIndex.Matrix = nil
_transform2dIndex.Offset = nil

function _transform2dIndex:Translate( x, y )
	self.Offset.x = self.Offset.x + x
	self.Offset.y = self.Offset.y + y
end

function _transform2dIndex:Scale( x, y )
	self.Matrix = self.Matrix:Scale( x, y )
end

function _transform2dIndex:Rotate( ang )
	self.Matrix = self.Matrix:Rotate( ang )
end

function _transform2dIndex:Transform( x, y )
	x, y = self.Matrix:Transform( x, y )
	return x + self.Offset.x, y + self.Offset.y
end

function Transform2D()
	local trans = { Matrix = Matrix( 1, 0, 0, 1 ), Offset = { x = 0, y = 0 } }
	setmetatable( trans, { __index = _transform2dIndex } )
	return trans
end

function FindBestTransform( sourceBounds, destBounds, canRotate, flip )
	local src = sourceBounds:GetSize()
	src.centre = sourceBounds:GetCentre()
	local trans = Transform2D()
	
	if canRotate and src.width < src.height then
		trans:Rotate( math.pi / 2 )
		src.width, src.height = src.height, src.width
	end
	
	if flip then trans:Scale( 1, -1 ) end
	
	src.ratio = src.width / src.height
	
	local dest = destBounds:GetSize()
	dest.centre = destBounds:GetCentre()
	dest.ratio = dest.width / dest.height
	
	if dest.ratio < src.ratio then
		trans:Scale( dest.width / src.width )
	else
		trans:Scale( dest.height / src.height )
	end
	
	local sx, sy = trans:Transform( src.centre.x, src.centre.y )
	trans:Translate( dest.centre.x - sx, dest.centre.y - sy )
	return trans
end
