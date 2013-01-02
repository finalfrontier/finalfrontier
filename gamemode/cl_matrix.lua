local _mt = {}
_mt.__index = _mt

_mt.xx = 1
_mt.xy = 0
_mt.yx = 0
_mt.yy = 1

function _mt:Mul(mat)
	return Matrix(
		mat.xx * self.xx + mat.xy * self.yx, mat.xx * self.xy + mat.xy * self.yy,
		mat.yx * self.xx + mat.yy * self.yx, mat.yx * self.xy + mat.yy * self.yy)
end

function _mt:Rotate(angle)
	local c = math.cos(angle)
	local s = math.sin(angle)
	
	return self:Mul(Matrix(c, -s, s, c))
end

function _mt:Transform(x, y)
	return x * self.xx + y * self.xy, x * self.yx + y * self.yy
end

function _mt:Scale(x, y)
	y = y or x
	return Matrix(self.xx * x, self.xy * y, self.yx * x, self.yy * y)
end

function Matrix(xx, xy, yx, yy)
	return setmetatable({ xx = xx or 1, xy = xy or 0, yx = yx or 0, yy = yy or 1 }, _mt)
end
