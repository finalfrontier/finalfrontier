-- Copyright (c) 2014 George Albany [spartan322@live.com]
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

local BASE = "page"

GUI.BaseName = BASE

GUI.TeamList = nil
GUI.Buttons = nil

if SERVER then
	function GUI:UpdateTeamList()
		local _teamdata = team.GetAllTeams()
		local _count = 0
		for k, v in pairs(_teamdata) do
			GUI.TeamList[count] = v.Name
			_count += 1
		end
	end
	function GUI:UpdateLayout()
		self:UpdateTeamList()
		
	end
elseif CLIENT then


end
