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

if SERVER then AddCSLuaFile("sh_teams.lua") end

if CLIENT and not team._nwdata then
    team._count = 0
end

team._nwdata = NetworkTable("teams")

function team.GetDeadColor(t)
    local clr = team.GetColor(t)
    return Color(clr.r * 0.5, clr.g * 0.5, clr.b * 0.5, 255)
end

function team.GetShip(t)
    return ships.GetByName(team._nwdata[t].shipname)
end

if SERVER then
    function team.Add(ship)
        local t = {}
        t.shipname = ship:GetName()
        t.name = ship:GetFullName()
        t.color = ship:GetUIColor()

        table.insert(team._nwdata, t)
        team._nwdata:Update()

        local i = #team._nwdata

        team.SetUp(i, t.name, t.color, true)
    end

    function team.GetLeastPopulated()
        local min = {}

        for t, _ in ipairs(team._nwdata) do
            local players = team.NumPlayers(t)
            if #min == 0 or players < min[1].players then
                min = { { team = t, players = players } }
            elseif min[1].players == players then
                table.insert(min, { team = t, players = players })
            end
        end

        return table.Random(min).team
    end

    function team.AutoAssign(ply)
        ply:SetTeam(team.GetLeastPopulated())
    end
elseif CLIENT then
    function team.Think()
        if team._count >= #team._nwdata then return end

        for t = team._count + 1, #team._nwdata do
            local data = team._nwdata[t]
            team.SetUp(t, data.name, data.color, true)
        end
    end
end
