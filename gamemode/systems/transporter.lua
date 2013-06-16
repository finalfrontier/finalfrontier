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
            return 2
        end
        return 0
    end

    function SYS:Initialize()
        self._nwdata.maxcharge = 1
        self._nwdata.charge = 1
        self._nwdata.maxshields = 0.25
        self:_UpdateNWData()
    end

    function SYS:Think(dt)
        self._nwdata.maxcharge = math.max(1, self:GetRoom():GetModuleScore(moduletype.systempower) * 4)

        if self._nwdata.charge < self._nwdata.maxcharge then
            self._nwdata.charge = math.min(self._nwdata.maxcharge, self._nwdata.charge
                + RECHARGE_RATE * dt * self:GetPower())
            self:_UpdateNWData()
        elseif self._nwdata.charge > self._nwdata.maxcharge then
            self._nwdata.charge = self._nwdata.maxcharge
            self:_UpdateNWData()
        end
    end

    function SYS:GetChargeCost(ent)
        if ent:IsPlayer() then return 1.0 end
        if ent:GetClass() == "prop_physics" then return 0.2 end
        if ent:GetClass() == "prop_ff_module" then return 0.35 end
        return self._nwdata.maxcharge + 1
    end

    function SYS:CanTeleportEntity(ent)
        return IsValid(ent) and self:GetChargeCost(ent) <= self:GetCurrentCharge()
    end

    function SYS:StartTeleport(room)
        if self._teleporting then return end

        sound.Play(table.Random(warmupSounds), self:GetRoom():GetPos(), 100, 70)
        timer.Simple(2.5, function() self:TryTeleport(room) end)

        self._teleporting = true
    end

    function SYS:TryTeleport(room)
        self._teleporting = false

        local pads = self:GetRoom():GetTransporterPads()
        local sent = {}

        if room:GetShip() == self:GetShip() or room:GetShields() < self:GetShieldThreshold() then
            local toSend = {}
            local available = room:GetAvailableTransporterTargets()
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

                if added then
                    local index = math.floor(math.random() * #available) + 1
                    dests[i] = available[index]
                    table.remove(available, index)
                end
            end

            while #toSend > 0 do
                local index = math.floor(math.random() * #toSend) + 1
                local ent = toSend[index].ent
                local pad = toSend[index].pad
                table.remove(toSend, index)
                if dests[pad] and self:TeleportEntity(ent, pads[pad], dests[pad]) then
                    sent[index] = true
                end
            end
        end

        for i, pad in ipairs(pads) do
            if not sent[i] then
                local ed = EffectData()
                ed:SetOrigin(pad)
                ed:SetMagnitude(0.5 + math.random())
                ed:SetScale(32)
                util.Effect("trans_fail", ed, true, true)
            end
        end
    end

    function SYS:TeleportEntity(ent, pad, dest)
        if not self:CanTeleportEntity(ent) then return false end

        self._nwdata.charge = self._nwdata.charge - self:GetChargeCost(ent)
        self:_UpdateNWData()

        local oldpos = ent:GetPos()
        local newpos = ent:GetPos() - pad + dest

        ent:SetPos(newpos)

        if ent:IsPlayer() then
            local ship = ships.FindCurrentShip(ent)
            if ship then ent:SetShip(ship) end
        else
            local phys = ent:GetPhysicsObject()
            if phys and IsValid(phys) then
                phys:Wake()
            end
        end

        sound.Play(table.Random(transmitSounds), oldpos, 75, 100 + math.random() * 20)
        sound.Play(table.Random(receiveSounds), newpos, 85, 100 + math.random() * 20)

        local ed = EffectData()
        ed:SetEntity(ent)
        ed:SetOrigin(oldpos)
        util.Effect("trans_sparks", ed, true, true)

        ed = EffectData()
        ed:SetEntity(ent)
        ed:SetOrigin(oldpos)
        util.Effect("trans_spawn", ed, true, true)

        ed = EffectData()
        ed:SetEntity(ent)
        ed:SetOrigin(newpos)
        util.Effect("trans_sparks", ed, true, true)

        return true
    end
elseif CLIENT then
    SYS.Icon = Material("systems/transporter.png", "smooth")
end