if SERVER then AddCSLuaFile("player_ff_marine.lua") end

local PLAYER = {}

PLAYER.WalkSpeed = 150
PLAYER.RunSpeed = 255

PLAYER.DisplayName = "Space Marine"

local _models = {
	"models/player/combine_super_soldier.mdl"
}

if SERVER then
	function PLAYER:Init()
		team.AutoAssign(self.Player)
	end
	
	function PLAYER:Spawn()
		local ship = team.GetShip(self.Player:Team())
		local pad = table.Random(ship:GetSystem("transporter"):GetRoom():GetTransporterPads())
		
		self.Player:SetPos(pad)
		self.Player:SetShip(ship)
		
		self.Player:SetCanWalk(true)
		
		TeleportArriveEffect(self.Player, self.Player:GetPos())
	end
	
	function PLAYER:SetModel()
		self.Player:SetModel(table.Random(_models))
	end
	
	function PLAYER:Loadout()
		self.Player:Give("weapon_crowbar")
		self.Player:Give("weapon_ff_repair_tool")
	end
end

function PLAYER:SetupDataTables()
	local ply = self.Player or self
	
	ply:NetworkVar("String", 0, "ShipName")
	
	ply:NetworkVar("Int", 0, "RoomIndex")
	
	ply:NetworkVar("Bool", 0, "UsingScreen")
	
	ply:NetworkVar("Entity", 0, "CurrentScreen")
	ply:NetworkVar("Entity", 1, "OldWeapon")
	
	ply._permissions = ply:NetworkTable(0, "Permissions")
end

SetupPlayerDataTables = PLAYER.SetupDataTables

player_manager.RegisterClass("player_ff_marine", PLAYER, "player_marine")
