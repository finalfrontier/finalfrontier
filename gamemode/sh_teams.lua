-- Copyright (c) 2014 Spartan322 [Spartan322@live.com]
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

TEAM_ORANGE = 1
TEAM_BLUE = 2

team.SetUp(TEAM_ORANGE, "Orange", Color(222,127,18,255), true)
team.SetUp(TEAM_BLUE, "Blue", Color(0,0,255,255), true)

if SERVER then
	function team.GetShip(team)
		local teamShips = {
			"ship01_ship",
			"ship02_ship",
		}

		return ships.GetByName(teamShips[team])
	end

	function team.GetLeastPopulated()
		if team.NumPlayers(TEAM_ORANGE) > team.NumPlayers(TEAM_BLUE) then
			return TEAM_BLUE
		elseif team.NumPlayers(TEAM_BLUE) > team.NumPlayers(TEAM_ORANGE) then
			return TEAM_ORANGE
		else
			return table.Random({ TEAM_ORANGE, TEAM_BLUE })
		end
	end

	function team.AutoAssign(ply)
		ply:SetTeam(team.GetLeastPopulated())
	end
end
