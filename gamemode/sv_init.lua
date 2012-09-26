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

function GM:PlayerSpawn( ply )
	ply:Give( "weapon_crowbar" )
end
