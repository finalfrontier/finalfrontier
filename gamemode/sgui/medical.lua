-- Copyright (c) 2014 Danni Lock [codednil@yahoo.co.uk]
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

GUI._dial = nil
GUI._powerbar = nil

function GUI:Enter()
	self.Super[BASE].Enter(self)
	
	self._dial = sgui.Create(self, "dualdial")

	if SERVER then
		self._dial:SetTargetValue(self:GetSystem():GetMaximumCharge())
		self._dial:SetCurrentValue(self:GetSystem():GetCurrentCharge()/self:GetSystem():GetMaximumCharge())
	elseif CLIENT then
		self._dial:SetSize(self:GetWidth() * 0.3, self:GetWidth() * 0.3)
		self._dial:SetInnerRatio(0.625)
		self._dial:SetCentre(self:GetWidth() * 0.5, self:GetHeight() * 0.4)
		self._dial.TargetColour = Color(255, 70, 70, 32)
		self._dial.CurrentColour = Color(255, 70, 70, 127)
	end
	
	local margin = 16
	local barheight = 48

	self._powerbar = sgui.Create(self, "powerbar")
	self._powerbar:SetSize(self:GetWidth() - margin * 2, barheight)
	self._powerbar:SetOrigin(margin, self:GetHeight() - margin - barheight)
end


if SERVER then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)
		
		self._dial:SetTargetValue(self:GetSystem():GetMaximumCharge())
	end
elseif CLIENT then
	function GUI:UpdateLayout(layout)
		self.Super[BASE].UpdateLayout(self, layout)
		
		self._dial:SetCurrentValue(self:GetSystem():GetCurrentCharge()/self:GetSystem():GetMaximumCharge())
	end
end