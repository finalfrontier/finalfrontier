-- Client Initialization
-- Includes

include( "sh_bounds.lua" )
include( "cl_transform2d.lua" )
include( "cl_slider.lua" )
include( "sh_systems.lua" )
include( "cl_ships.lua" )

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
	rotation = math.min( rotation or ( math.pi * 2 ), math.pi * 2 )
	startAngle = startAngle or 0
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

function WrapAngle( ang )
	return ang - math.floor( ang / ( math.pi * 2 ) ) * math.pi * 2
end

function surface.DrawCentredText( x, y, text )
	local wid, hei = surface.GetTextSize( text )
	surface.SetTextPos( x - wid / 2, y - hei / 2 )
	surface.DrawText( text )
end

-- TODO: Add check to avoid complex polys in output
function FindConvexPolygons( poly, output )
	output = output or {}
	local cur = {}
	local l = poly[ #poly ]
	local n = poly[ 1 ]
	local i = 1
	while i <= #poly do
		local v = n
		table.insert( cur, v )
		n = poly[ ( i % #poly ) + 1 ]
		i = i + 1
		
		local la = math.atan2( l.y - v.y, l.x - v.x )
		local subPoly = { v }
		
		while n ~= v do
			table.insert( subPoly, n )
			if i > #poly + 1 then
				table.remove( cur, 1 )
			end
			local na = math.atan2( n.y - v.y, n.x - v.x )
			local ang = WrapAngle( na - la )
			
			if ang > math.pi then
				n = poly[ ( i % #poly ) + 1 ]
				i = i + 1
			else
				if #subPoly > 2 then
					FindConvexPolygons( subPoly, output )
				end
				break
			end
		end
		
		if n == v then
			break
		end
		l = v
	end
	table.insert( output, cur )
	return output
end

function IsPointInsidePoly( poly, p )
	for i, v in ipairs( poly ) do
		local n = poly[ ( i % #poly ) + 1 ]
		local ax, ay = n.x - v.x, n.y - v.y
		local bx, by = p.x - v.x, p.y - v.y
		local cross = ax * by - ay * bx
		if cross < 0 then return false end
	end
	
	return true
end

function IsPointInsidePolyGroup( polys, p )
	for _, poly in ipairs( polys ) do
		if IsPointInsidePoly( poly, p ) then return true end
	end
	
	return false
end

-- Gamemode Overrides

function GM:Initialize()
	MsgN( "Final Frontier client-side is initializing..." )
	
	self.BaseClass:Initialize()
end

function GM:HUDWeaponPickedUp( weapon )
	if weapon:GetClass() == "weapon_ff_unarmed" then return end
	
	self.BaseClass:HUDWeaponPickedUp( weapon )
end

function GM:PlayerBindPress( ply, bind, pressed )
	if bind == "+attack" and ply:GetNWBool( "usingScreen" ) then
		local screen = ply:GetNWEntity( "screen" )
		if screen then screen:Click( ply ) end
	end
end
