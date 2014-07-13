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

SYS.FullName = "Transporter"
SYS.SGUIName = "transporter"

SYS.Powered = true

function SYS:GetMaximumCharge()
    return self._nwdata.maxcharge
end

function SYS:GetCurrentCharge()
    return math.min(self._nwdata.charge, self._nwdata.maxcharge)
end

function SYS:GetShieldThreshold()
    return self._nwdata.maxshields
end

function SYS:IsEntityTeleportable(ent)
    return IsValid(ent) and (ent:IsPlayer()
        or ent:GetClass() == "prop_physics"
        or ent:GetClass() == "prop_ff_module"
        or ent:GetClass() == "prop_ff_weaponmodule")
end

function SYS:IsObjectTeleportable(obj)
    return IsValid(obj) and obj:GetClass() == "info_ff_object"
        and self:GetShip():IsObjectInRange(obj)
        and (CLIENT or obj._module)
end

if SERVER then
    resource.AddFile("materials/systems/transporter.png")

    local warmupSounds = {
        "ambient/levels/citadel/zapper_warmup1.wav",
        "ambient/levels/citadel/zapper_warmup4.wav"
    }

    local failedSounds = {
        "ambient/energy/zap7.wav",
        "ambient/energy/zap8.wav"
    }

    local transmitSounds = {
        "ambient/machines/teleport1.wav",
        "ambient/machines/teleport3.wav",
        "ambient/machines/teleport4.wav"
    }

    local receiveSounds = {
        "ambient/levels/labs/electric_explosion1.wav",
        "ambient/levels/labs/electric_explosion2.wav",
        "ambient/levels/labs/electric_explosion3.wav",
        "ambient/levels/labs/electric_explosion4.wav"
    }

    local RECHARGE_RATE = 1.0 / 60.0

    SYS._teleporting = false

    function SYS:CalculatePowerNeeded()
        if self:GetCurrentCharge() < self:GetMaximumCharge() then
            return 1 + self:GetRoom():GetModuleScore(moduletype.SYSTEM_POWER) * 2
        end
        return 0
    end

    function SYS:Initialize()
        self._nwdata.maxcharge = 0
        self._nwdata.charge = 0
        self._nwdata.maxshields = 0.1
        self._nwdata:Update()
    end

    SYS._oldScore = 0

    function SYS:Think(dt)
        local score = self:GetRoom():GetModuleScore(moduletype.SYSTEM_POWER)
        local changed = false

        if score ~= self._oldScore then
            self._oldScore = score

            if self._nwdata.maxcharge == 0 then
                self._nwdata.charge = 1 + score * 3
            end

            self._nwdata.maxcharge = 1 + score * 3

            changed = true
        end

        if self._nwdata.charge < self._nwdata.maxcharge then
            self._nwdata.charge = math.min(self._nwdata.maxcharge, self._nwdata.charge
                + RECHARGE_RATE * dt * self:GetPower())

            changed = true
        elseif self._nwdata.charge > self._nwdata.maxcharge then
            self._nwdata.charge = self._nwdata.maxcharge
            changed = true
        end
        
        if changed then self._nwdata:Update() end
    end

    function SYS:GetChargeCost(ent)
        if ent:IsPlayer() then return 1.0 end
        if ent:GetClass() == "prop_physics" then return 0.25 end
        if ent:GetClass() == "prop_ff_module" then return 0.35 end
        if ent:GetClass() == "prop_ff_weaponmodule" then return 0.5 end
        return self._nwdata.maxcharge + 1
    end

    function SYS:CanTeleportEntity(ent)
        return IsValid(ent) and self:GetChargeCost(ent) <= self:GetCurrentCharge()
    end

    function SYS:StartTeleport(roomOrObj)
        if self._teleporting then return end

        if IsValid(roomOrObj) and roomOrObj:GetClass() == "info_ff_object"
            and not self:IsObjectTeleportable(roomOrObj) then
            return
        end

        sound.Play(table.Random(warmupSounds), self:GetRoom():GetPos(), 100, 70)
        timer.Simple(2.5, function() self:TryTeleport(roomOrObj) end)

        self._teleporting = true
    end

    function SYS:TryTeleport(roomOrObj)
        self._teleporting = false
        
        local pads = self:GetRoom():GetTransporterPads()

        if not IsValid(roomOrObj) or roomOrObj:GetClass() == "info_ff_room" then
            local room = roomOrObj
            local sent = {}

            if not IsValid(room) or room:GetShip() == self:GetShip() or room:GetShields() < self:GetShieldThreshold() then
                local toSend = {}
                local available = (IsValid(room) and room:GetAvailableTransporterTargets()) or nil
                local dests = {}
                for i, pad in ipairs(pads) do
                    local inRange = ents.FindInSphere(pad, 32)
                    local added = false
                    for _, ent in pairs(inRange) do
                        if self:CanTeleportEntity(ent) then
                            added = true
                            table.insert(toSend, {pad = i, ent = ent})
                        end
                    end

                    if added and available then
                        if #available > 0 then
                            local index = math.floor(math.random() * #available) + 1
                            dests[i] = available[index]
                            table.remove(available, index)
                        else
                            dests[i] = table.Random(room:GetAvailableTransporterTargets())
                        end
                    end
                end

                while #toSend > 0 do
                    local index = math.floor(math.random() * #toSend) + 1
                    local ent = toSend[index].ent
                    local pad = toSend[index].pad
                    table.remove(toSend, index)

                    if IsValid(room) and dests[pad] and self:TeleportEntity(ent, pads[pad], dests[pad]) then
                        sent[pad] = true
                    elseif self:TeleportEntity(ent, pads[pad], nil) then
                        sent[pad] = true
                    end
                end
            end

            for i, pad in ipairs(pads) do
                if not sent[i] then self:TeleportFailEffect(pad) end
            end

            return
        elseif roomOrObj:GetClass() == "info_ff_object" then
            local obj = roomOrObj

            if not self:IsObjectTeleportable(obj) then self:TeleportFailEffect() return end
            
            local mdl = obj:RetrieveModule()

            if not self:TeleportEntity(mdl, mdl:GetPos(), table.Random(pads)) then
                mdl:Remove()
                self:TeleportFailEffect()
            else
                obj:Remove()
            end
        end
    end

    function SYS:TeleportFailEffect(pos)
        if not pos then
            for _, pad in ipairs(self:GetRoom():GetTransporterPads()) do
                self:TeleportFailEffect(pad)
            end
            return
        end

        local ed = EffectData()
        ed:SetOrigin(pos)
        ed:SetMagnitude(0.5 + math.random())
        ed:SetScale(32)
        util.Effect("trans_fail", ed, true, true)
    end

    function TeleportDepartEffect(ent, pos)
        sound.Play(table.Random(receiveSounds), pos, 85, 100 + math.random() * 20)

        local low, high = ent:WorldSpaceAABB()

        local ed = EffectData()
        ed:SetOrigin(low)
        ed:SetStart(high)
        util.Effect("trans_sparks", ed, true, true)
    end

    function TeleportArriveEffect(ent, pos)
        sound.Play(table.Random(receiveSounds), pos, 85, 100 + math.random() * 20)

        local low, high = ent:WorldSpaceAABB()

        local ed = EffectData()
        ed:SetOrigin(low)
        ed:SetStart(high)
        util.Effect("trans_sparks", ed, true, true)

        ed = EffectData()
        ed:SetEntity(ent)
        ed:SetOrigin(pos)
        util.Effect("trans_spawn", ed, true, true)
    end

    function SYS:TeleportEntity(ent, pad, dest)
        if not self:CanTeleportEntity(ent) then return false end
        if not IsValid(ent) then return false end

        self._nwdata.charge = self._nwdata.charge - self:GetChargeCost(ent)
        self._nwdata:Update()

        local oldpos = ent:GetPos()
        local newpos = ent:GetPos() - pad + (dest or Vector(0, 0, 0))

        TeleportDepartEffect(ent, oldpos)

        if dest then
            ent:SetPos(newpos)
            TeleportArriveEffect(ent, newpos)

            if ent:IsPlayer() then
                local ship = ships.FindCurrentShip(ent)
                if ship then ent:SetShip(ship) end
            elseif IsValid(ent) then
                local phys = ent:GetPhysicsObject()
                if phys and IsValid(phys) then phys:Wake() end
            end
        else
            if ent:IsPlayer() then
                return false
            else
                timer.Simple(1 / 30, function()
                    if not IsValid(ent) then return end
                    if ent:GetClass() == "prop_ff_module" or ent:GetClass() == "prop_ff_weaponmodule" then
                        local obj = ents.Create("info_ff_object")
                        obj:SetCoordinates(self:GetShip():GetCoordinates())
                        obj:AssignModule(ent)
                        obj:Spawn()

                        local vx, vy = self:GetShip():GetVel()
                        local dir = (math.random() * 2 - 1) * math.pi

                        if vx * vx + vy * vy >= 1 / (64 * 64) then
                            dir = dir / 8 + math.atan2(-vy, -vx)
                        end

                        obj:SetVel(vx + math.cos(dir) / 64, vy + math.sin(dir) / 64)
                    else
                        ent:Remove()
                    end
                end)
            end
        end

        return true
    end
elseif CLIENT then
    SYS.Icon = Material("systems/transporter.png", "smooth")
end