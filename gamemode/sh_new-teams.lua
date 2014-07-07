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

if SERVER then AddCSLuaFile("sh_new-teams.lua") end

TEAM_LIMIT = 20
team_groups = {}

if SERVER then

	function team.CreateTeam(number, name, colors, joinable)
		team_groups[number] = {number=number, name=name, colors= Color(colors.r, colors.g, colors.b, colors.a), joinable=joinable}
		SetupTeam(number)
	end
	
	local function SetupTeam(new_number)
		if new_number > TEAM_LIMIT return end
		team.SetUp(team_groups[new_number].number, team_groups[new_number].name, team_groups[new_number].colors, team_groups[new_number].joinable)
	end
	
	function team.MoveTo(team_number, ply)
		ply:SetTeam(team_number)
		if team_groups[team_number].players == nil then team_groups[team_number].players = {} end
		team_groups[team_number].players += ply:GetName()
	end
	
	function team.GetSize(team_number)
		table.Count(team_groups[team_number].players)
	end
	
	function team.GetUnpopular()
		local team_sizes = {}
		local smallest = 0
		for i=1, table.Count(team_groups) do
			team_sizes[i] = team.GetSize(i)
		end
		
		for i=1, table.Count(team_sizes) do
			
			if team_sizes[i] < team_sizes[i+1] then
				smallest = i
			elseif team_sizes[i] > team_sizes[i-1] then
				smallest = i-1
			else
				smallest = i+1
			end
		end
	end
	
	function team.AssignAuto(ply)
		team.MoveTo(team.GetUnpopular, ply)	
	end
	
end
