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

-- Gamemode Overrides

function GM:Initialize()
	MsgN( "Final Frontier client-side is initializing..." )
	
	self.BaseClass:Initialize()
end
