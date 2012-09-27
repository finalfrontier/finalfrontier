-- Client Initialization
-- Includes

include( "sh_systems.lua" )

-- Global Functions

function FormatNum( num, leading, trailing )	
	local str = tostring( num )
	
	local index = string.find( str, "%." )
	if not index then
		str = str .. ".0"
		index = string.len( str ) - 1
	end
	
	local num = index - 1
	
	if num > leading then
		str = string.sub( str, num - leading + 1 )
	elseif num < leading then
		str = string.rep( "0", leading - num ) .. str
	end
	
	index = string.find( str, "%." )
	num = string.len( str ) - index
	
	if trailing == 0 then
		str = string.sub( str, 1, index - 1 )
	elseif num > trailing then
		str = string.sub( str, 1, index + trailing )
	elseif num < trailing then
		str = str .. string.rep( "0", trailing - num )
	end
	
	return str
end

local sin, cos = math.sin, math.cos
function CreateCircle( x, y, radius )
	local quality = math.min( 256, 4 * math.sqrt( radius ) + 8 )
	local verts = {}
	local ang = 0
	for i = 1, quality do
		ang = i * math.pi * 2 / quality
		verts[ i ] = { x = x + cos( ang ) * radius, y = y + sin( ang ) * radius }
	end
	return verts
end

function CreateHollowCircle( x, y, innerRadius, outerRadius, startAngle, rotation )
	startAngle = startAngle or 0
	rotation = rotation or ( math.pi * 2 )
	local quality = math.min( 256, 4 * math.sqrt( outerRadius ) + 8 )
	local verts = {}
	local angA, angB
	local mul = math.pi * 2 / quality
	local count = quality * rotation / ( math.pi * 2 )
	for i = 0, count do
		angA = startAngle + i * mul
		angB = angA + mul
		if angB - startAngle > rotation then angB = startAngle + rotation end
		sinA, cosA = sin( angA ), cos( angA )
		sinB, cosB = sin( angB ), cos( angB )
		verts[ i + 1 ] = {
			{ x = x + cosA * innerRadius, y = y + sinA * innerRadius },
			{ x = x + cosA * outerRadius, y = y + sinA * outerRadius },
			{ x = x + cosB * outerRadius, y = y + sinB * outerRadius },
			{ x = x + cosB * innerRadius, y = y + sinB * innerRadius }
		}
	end
	return verts
end

-- Gamemode Overrides

function GM:Initialize()
	MsgN( "Final Frontier client-side is initializing..." )
	
	self.BaseClass:Initialize()
end
