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

SYS.FullName = "Medical Bay"
SYS.SGUIName = "medical"

SYS.Powered = true

function SYS:GetMaximumCharge()
	return self._nwdata.maxcharge or 0
end

function SYS:GetCurrentCharge()
	return math.min(self._nwdata.charge or 0, self._nwdata.maxcharge or 0)
end

if SERVER then
	resource.AddFile("materials/systems/medical.png")
	
	SYS._oldScore = 0
	
	function SYS:Initialize()
		self._nwdata.maxcharge = 1
		self._nwdata.charge = 0
		self._nwdata:Update()
	end
	
	function SYS:CalculatePowerNeeded()
		local needed = 0
		if self._nwdata.charge < self._nwdata.maxcharge then
			needed = 6
		end
		return needed
	end
	
	function SYS:Think()
		local needsUpdate = false
		
		local score = self:GetRoom():GetModuleScore(moduletype.SYSTEM_POWER)

		if score ~= self._oldScore then
			self._oldScore = score

			self._nwdata.maxcharge = score * 500
			
			needsUpdate = true
		end
		
		if self._nwdata.charge < self._nwdata.maxcharge then
			self._nwdata.charge = math.min(self._nwdata.maxcharge, self._nwdata.charge + self:GetPower() / 4)
			needsUpdate = true
		elseif self._nwdata.charge > self._nwdata.maxcharge then
			self._nwdata.charge = self._nwdata.maxcharge
			needsUpdate = true
		end
		
		if self._nwdata.charge >= 5 then
			for _, ply in ipairs(player.GetAll()) do
				if ply:GetRoom() == self:GetRoom() and (ply:Health() < ply:GetMaxHealth()) then
					ply:SetHealth(math.min(ply:Health() + 1, ply:GetMaxHealth()))
					self._nwdata.charge = self._nwdata.charge - 5
					needsUpdate = true
				end
			end
		end
		
		if needsUpdate then
			self._nwdata:Update()
		end
	end
elseif CLIENT then
	SYS.Icon = Material("systems/medical.png", "smooth")
end