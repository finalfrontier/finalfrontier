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

GUI.TeamList = {}
GUI.Buttons = nil


function GUI:UpdateTeamList()
	local _teamdata = team.GetAllTeams()
	local _count = 0
	for k, v in pairs(_teamdata) do
		GUI.TeamList[_count] = v.Name
		_count = _count + 1
	end
end

function GUI:UpdateButtons()
	if self.Buttons then
		for _, btn in pairs(self.Buttons) do
			btn:Remove()
		end
		self.Buttons = nil
	end
	
	self:UpdateTeamList()
	if self.TeamList then
		self.Buttons = {}
		for i, team in ipairs(self.TeamList) do
			local btn = sgui.Create(self, "teambutton")
			btn:SetTeam(i)
			btn:SetSize((self:GetWidth() - 16) / 2 - 4, 48)
			btn:SetCentre(self:GetWidth() / 4, i * 48 - 16)
			table.insert(self.Buttons, btn)
		end
	end
end

function GUI:Enter()
	self.Super[BASE].Enter(self)
	if SERVER then
		self:UpdateButtons()
	end
end

function GUI:Leave()
	self.Super[BASE].Leave(self)
	
	self.TeamList = nil
	self.Buttons = nil
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if not self.TeamList then
            layout.teams = nil
        else
            if not layout.teams or #layout.teams > #self.TeamList then
                layout.teams = {}
            end

            for i, team in ipairs(self.TeamList) do
                layout.teams[i] = team
            end
        end
    end    
end

if CLIENT then
    function GUI:UpdateLayout(layout)
        if layout.teams then
            if not self.TeamList or #self.TeamList > #layout.teams then
                self.TeamList = {}
            end

            local changed = false
            for i, team in pairs(layout.teams) do
                if not self.TeamList[i] or self.TeamList[i] ~= team then
                    changed = true
                    self.TeamList[i] = team
                end
            end

            if changed then self:UpdateButtons() end
        else
            if self.TeamList then
                self.TeamList = nil
                self:UpdateButtons()
            end
        end

        self.Super[BASE].UpdateLayout(self, layout)
    end    
end
