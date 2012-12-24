local _index = {}
_index.xx = 1
_index.xy = 0
_index.yx = 0
_index.yy = 1

function _index:Mul(mat)
	return Matrix(
		mat.xx * self.xx + mat.xy * self.yx, mat.xx * self.xy + mat.xy * self.yy,
		mat.yx * self.xx + mat.yy * self.yx, mat.yx * self.xy + mat.yy * self.yy)
end

function _index:Rotate(angle)
	local c = math.cos(angle)
	local s = math.sin(angle)
	
	return self:Mul(Matrix(c, -s, s, c))
end

function _index:Transform(x, y)
	return x * self.xx + y * self.xy, x * self.yx + y * self.yy
end

function _index:Scale(x, y)
	y = y or x
	return Matrix(self.xx * x, self.xy * y, self.yx * x, self.yy * y)
end

function Matrix(xx, xy, yx, yy)
	local matrix = { xx = xx or 1, xy = xy or 0, yx = yx or 0, yy = yy or 1 }
	setmetatable(matrix, { __index = _index })
	return matrix
end
