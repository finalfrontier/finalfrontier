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

SWEP.PrintName = "Medical Tool"
SWEP.Slot = 2
SWEP.ViewModel = "models/weapons/c_medkit.mdl"
SWEP.WorldModel = "models/weapons/w_medkit.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true
SWEP.UseHands = true

SWEP.Primary.ClipSize = -1
SWEP.Primary.DefaultClip = 1
SWEP.Primary.Automatic = true
SWEP.Primary.Delay = 0.4
SWEP.Primary.Ammo = "none"
SWEP.Primary.MaxRange = 85
SWEP.Secondary.ClipSize = -1
SWEP.Secondary.DefaultClip = 1
SWEP.Secondary.Automatic = true
SWEP.Secondary.Delay = 0.7
SWEP.Secondary.Ammo = "none"

function SWEP:PrimaryAttack()
		self.Weapon:SetNextPrimaryFire(CurTime() + self.Primary.Delay)
		
		if not SERVER then return end
		
		local found
		local lastDot = -1
		local aimVec = self.Owner:GetAimVector()
		
	for k,v in pairs(player.GetAll()) do
		local maxhealth = v:GetMaxHealth() or 100
			
		if v == self.Owner or v:GetShootPos():Distance(self.Owner:GetShootPos()) > self.Primary.MaxRange or v:Health() >= maxhealth or not v:Alive() then continue end
		
		local direction = v:GetShootPos() - self.Owner:GetShootPos()
		direction:Normalize()
		local dot = direction:Dot(aimVec)
		if dot > lastDot then
			lastDot = dot
			found = v
		end
			
		if found then
			found:SetHealth(found:Health() + 1)
			self.Owner:EmitSound("hl1/fvox/boop.wav", 150, found:Health())
		end
	end
end

function SWEP:SecondaryAttack()
	self.Weapon:SetNextSecondaryFire(CurTime() + self.Secondary.Delay)
	if not SERVER then return end
	
	local maxhealth = self.Owner:GetMaxHealth() or 100
	if self.Owner:Health() < maxhealth then
		self.Owner:SetHealth(self.Owner:Health() + 1)
		self.Owner:EmitSound("hl1/fvox/boop.wav", 150, self.Owner:Health())
	end
end
