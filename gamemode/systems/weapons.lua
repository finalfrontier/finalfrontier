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

SYS.FullName = "Weapons"
SYS.SGUIName = "weapons"

SYS.Powered = true

function SYS:IsAutoShooting(slot)
    return self._nwdata.autoshoot and (self._nwdata.autoshoot[slot] or false)
end

function SYS:HasTarget()
    return IsValid(self._nwdata.target) and self:GetShip():IsObjectInRange(self._nwdata.target)
end

function SYS:GetTarget()
    if self:HasTarget() then
        return self._nwdata.target
    elseif SERVER and self._nwdata.target then
        self._nwdata.target = nil
        self._nwdata:Update()
    end

    return nil
end

if SERVER then
    resource.AddFile("materials/systems/weapons.png")

    function SYS:Initialize()
        self._nwdata.autoshoot = {}
        self._nwdata.target = nil
        self._nwdata:Update()
    end

    function SYS:CalculatePowerNeeded()
        local tot = 0
        for slot = moduletype.WEAPON_1, moduletype.WEAPON_3 do
            local mdl = self:GetRoom():GetModule(slot)
            if mdl and not mdl:IsFullyCharged() then
                local weapon = mdl:GetWeapon()
                tot = tot + weapon:GetMaxPower()
            end
        end
        return tot
    end

    function SYS:CanTarget(target)
        return IsValid(target) and target:GetClass() == "info_ff_object" and (
            target:GetObjectType() == objtype.SHIP or
            target:GetObjectType() == objtype.MODULE)
    end

    function SYS:SetTarget(target)
        if not target or self:CanTarget(target) then
            self._nwdata.target = target
            self._nwdata:Update()
        end
    end

    function SYS:FireWeapon(slot)
        local mdl = self:GetRoom():GetModule(slot)
        if mdl and mdl:CanShoot() then
            mdl:RemoveCharge(mdl:GetWeapon():GetShotCharge())
            mdl:GetWeapon():OnShoot(self:GetShip(), self:GetTarget(), self:GetShip():GetRotation())
            sound.Play(mdl:GetWeapon().LaunchSound, self:GetRoom():GetPos())
        end
    end

    function SYS:ToggleAutoShoot(slot)
        self._nwdata.autoshoot[slot] = not self:IsAutoShooting(slot)
        self._nwdata:Update()
    end

    function SYS:Think(dt)
        local power = self:GetPower()
        local needed = self:GetPowerNeeded()
        if needed > 0 then
            local ratio = power / needed
            for slot = moduletype.WEAPON_1, moduletype.WEAPON_3 do
                local mdl = self:GetRoom():GetModule(slot)
                if mdl then mdl:AddCharge(ratio * dt) end
            end
        end

        if self:HasTarget() then
            for slot, autoshoot in pairs(self._nwdata.autoshoot) do
                if autoshoot then
                    local mdl = self:GetRoom():GetModule(slot)
                    if mdl and mdl:CanShoot() then
                        self:FireWeapon(slot)
                    end
                end
            end
        end
    end
elseif CLIENT then
    SYS.Icon = Material("systems/weapons.png", "smooth")
end
