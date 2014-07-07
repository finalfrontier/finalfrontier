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

if SERVER then AddCSLuaFile("sh_teams_relationships.lua") end

relationships = relationships = {}

relationships.enums = {ALLY=0x5000, Neutral=0x2500, Enemy=0x0000}

if SERVER then

	function relationships.SetRelation(team1, team2, relate)
		relationships.group[team1][team2] = relate
	end
	
	function relationships.GetRelation(team1, team2)
		local relate = relationships.group[team1][team2]
		if relate == nil then
			relate = relationships.enums.Neutral
		end
		return relate
	end
	
	function relationships.Attack(team1, team2)
		if relationships.GetRelation(team1, team2) < relationships.enums.Neutral then
			return true
		else
			return false
	end
	
end
