-- Copyright (c) 2014 James King [metapyziks@gmail.com]
-- 
-- This file is part of Final Frontier.
-- 
-- Final Frontier is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
-- 
-- Final Frontier is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with Final Frontier. If not, see <http://www.gnu.org/licenses/>.

-- Server Initialization
-- Includes

-- jit.on()

include("gmtools/nwtable.lua")

include("sh_init.lua")
include("sh_teams.lua") 
include("sh_bounds.lua")
include("sh_matrix.lua")
include("sh_transform2d.lua")
include("sh_weapons.lua")
include("sh_sgui.lua")
include("sh_systems.lua")
include("sv_ships.lua")

-- Resources

resource.AddFile("materials/circle.png")
resource.AddFile("materials/connector.png")
resource.AddFile("materials/playerdot.png")
resource.AddFile("materials/objects/ship.png")
resource.AddFile("materials/objects/missile.png")

MsgN("Loading materials...")
local files = file.Find("materials/ff_*.vmt", "GAME")
for i, file in ipairs(files) do
    resource.AddFile("materials/" .. file)
end

game.ConsoleCommand("sv_loadingurl \"http://metapyziks.github.io/finalfrontier/\"\n")

-- Gamemode Overrides

function GM:Initialize()
    MsgN("Final Frontier server-side is initializing...")
    
    math.randomseed(os.time())
    
    self.BaseClass:Initialize()
end

function GM:InitPostEntity()
    MsgN("Final Frontier server-side is initializing post-entity...")
    
    ships.InitPostEntity()

    for _, ship in pairs(ships.GetAll()) do
        for _, room in pairs(ship:GetRooms()) do
            if room:GetSystemName() == "engineering" then
                for _, t in pairs({moduletype.lifesupport, moduletype.shields, moduletype.systempower}) do
                    local pos = room:GetTransporterTarget()
                    if pos then
                        local count = 1 + math.floor(math.random() * math.random() * 2)
                        for i = 1, count do
                            local mdl = ents.Create("prop_ff_module")
                            mdl:SetModuleType(t)
                            mdl:SetPos(pos + Vector(0, 0, i * 16))
                            mdl:SetAngles(Angle(0, math.random() * 360, 0))
                            mdl:Spawn()
                            mdl:SetToOptimal()
                        end
                    end
                end
            end
        end
    end
end

function GM:PlayerNoClip(ply)
    return ply:GetMoveType() == MOVETYPE_NOCLIP
end

function GM:PlayerInitialSpawn(ply)
    local num = math.random(1, 9)
    ply:SetModel("models/player/group03/male_0" .. num .. ".mdl")
    ply:SetCanWalk(true)
    ply:SetTeam(CheckTeams())
    GAMEMODE:SetPlayerSpeed(ply, 175, 250)
    ShipSet(ply)
end


function GM:PlayerSpawn(ply)
    local ship = ships.FindCurrentShip(ply)
    if ship then ply:SetShip(ship) end
    ply:Give("weapon_crowbar")
    ShipSet(ply)
end

function GM:Think()
    for _, ply in pairs(player.GetAll()) do
        local ship = ships.FindCurrentShip(ply)
        if ship and ship ~= ply:GetShip() then ply:SetShip(ship) end
    end
    return
end

function GM:SetupPlayerVisibility(ply)
    local ship = ply:GetShip()
    if not ship then return end

    local sx, sy = ship:GetCoordinates()
    local range = ship:GetRange()
    for x = math.floor(sx - range), math.floor(sx + range) do
        for y = math.floor(sy - range), math.floor(sy + range) do
            AddOriginToPVS(universe:GetSector(x, y):GetPVSPos())
        end
    end

    for _, ship in pairs(ships.GetAll()) do
        for _, room in pairs(ship:GetRooms()) do
            if #room:GetPlayers() > 0 then
                AddOriginToPVS(room:GetPos())
            end
        end
    end
end
