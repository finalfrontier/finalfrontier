-- Server Initialization
-- Includes

include( "sh_systems.lua" )
include( "sv_ships.lua" )

-- Gamemode Overrides

function GM:Initialize()
	MsgN( "Final Frontier server-side is initializing..." )
	
	math.randomseed( os.time() )
	
	self.BaseClass:Initialize()
end

function GM:InitPostEntity()
	MsgN( "Final Frontier server-side is initializing post-entity..." )
	
	Ships.InitPostEntity()
end

function GM:PlayerNoClip( ply )
	return ply:GetMoveType() == MOVETYPE_NOCLIP
end

function GM:PlayerInitialSpawn( ply )
	local num = math.random( 1, 9 )
	ply:SetModel( "models/player/group03/male_0" .. num .. ".mdl" )
	
	Ships.SendShipsData( ply )
end

function GM:PlayerSpawn( ply )
	ply:Give( "weapon_ff_unarmed" )
end
