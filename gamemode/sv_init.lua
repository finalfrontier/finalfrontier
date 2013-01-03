-- Server Initialization
-- Includes

include("gmtools/nwtable.lua")

include("sh_bounds.lua")
include("sh_gui.lua")
include("sh_systems.lua")
include("sv_ships.lua")

-- Resources

resource.AddFile("materials/circle.png")
resource.AddFile("materials/connector.png")

-- Gamemode Overrides

function GM:Initialize()
	MsgN("Final Frontier server-side is initializing...")
	
	math.randomseed(os.time())
	
	self.BaseClass:Initialize()
end

function GM:InitPostEntity()
	MsgN("Final Frontier server-side is initializing post-entity...")
	
	ships.InitPostEntity()
end

function GM:PlayerNoClip(ply)
	return ply:GetMoveType() == MOVETYPE_NOCLIP
end

function GM:PlayerInitialSpawn(ply)
	local num = math.random(1, 9)
	ply:SetModel("models/player/group03/male_0" .. num .. ".mdl")
	ply:SetCanWalk(true)
	
	GAMEMODE:SetPlayerSpeed(ply, 175, 250)

	ships.SendInitShipsData(ply)
end

function GM:PlayerSpawn(ply)
	local ship = ships.FindCurrentShip(ply)
	if ship then ply:SetShip(ship) end
	ply:Give("weapon_crowbar")
end

function GM:Think()
	for _, ply in ipairs(player.GetAll()) do
		ships.SendRoomStatesUpdate(ply)
	end
end
