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

local BASE = "container"

GUI.BaseName = BASE

GUI.SelectedColor = Color(200,200,200)
GUI.NonSelectedColor = Color(109,109,109)
GUI.OnTeamColor = Color(0,156,15)

GUI._team = nil
GUI._teamName = nil

GUI._joinButton = nil
GUI._nameButton = nil

function GUI:UpdateNames()
	self._teamName = team.GetName(self._team)
	self._nameButton.Text = self._teamName
end

function GUI:Initialize()
	self.Super[BASE].Initialize(self)
	
	self._joinButton = sgui.Create(self, "button")
	self._nameButton = sgui.Create(self, "button")
	
	if SERVER then
		self._joinbutton.OnClick = function(btn)
			local ply = self:GetPlayer()
			if ply:Team() == self._team then
				ply:SetTeam(0)
			else
				ply:SetTeam(self._team)
			end
		end
		self:UpdateNames()
	end
end

function GUI:SetBounds(bounds)
    self.Super[BASE].SetBounds(self, bounds)

    self._nameButton:SetWidth(self:GetWidth() - self:GetHeight())
    self._joinButton:SetWidth(self:GetHeight())
    self._nameButton:SetHeight(self:GetHeight())
    self._joinButton:SetHeight(self:GetHeight())

    self._joinButton:SetOrigin(self._nameButton:GetRight(), 0)
end

function GUI:GetTeam()
	return self._team	
end


function GUI:SetTeam(team)
	self._team = team
	self:UpdateNames()
end

if CLIENT then
	function GUI:Draw()
		if self._team then
			self._joinButton.CanClick = true
			local ply = self:GetPlayer()
			if ply:Team() == self._team then
				self._nameButton.Color = self.OnTeamColor
			elseif self.nameButton:IsCursorInside() then
				self._nameButton.Color = self.SelectedColor
			else
				self._nameButton.Color = self.UnSelectedColor
			end
			if self.joinButton:IsCursorInside() then
				self._joinButton.Color = self.SelectedColor
			else
				self._joinButton.Color = self.UnSelectedColor
			end
			if ply:Team() == self._team then
				self._joinButton.Text = "-"
			else
				self._joinButton.Text = "+"
			end
		end
		self.Super[BASE].Draw(self)
	end
end
