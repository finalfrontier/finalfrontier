-- Server Initialization
-- Includes

include("gmtools/nwtable.lua")

include("sh_bounds.lua")
include("sh_matrix.lua")
include("sh_transform2d.lua")
include("sh_sgui.lua")
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
end

function GM:PlayerSpawn(ply)
	local ship = ships.FindCurrentShip(ply)
	if ship then ply:SetShip(ship) end
	ply:Give("weapon_crowbar")
end

function GM:Think()
	return
end

function GM:SetupPlayerVisibility(ply)
	local ship = ply:GetShip()
	if not ship then return end

	for _, room in pairs(ship:GetRooms()) do
		if #room:GetPlayers() > 0 then
			AddOriginToPVS(room:GetPos())
		end
	end
end
