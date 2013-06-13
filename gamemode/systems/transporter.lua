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
    -- resource.AddFile("materials/systems/transporter.png")

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
        return 2
    end

    function SYS:Initialize()
        self._nwdata.maxcharge = 1
        self._nwdata.charge = 0
        self._nwdata.maxshields = 0.25
        self:_UpdateNWData()
    end

    function SYS:Think(dt)
        if self._nwdata.charge < self._nwdata.maxcharge then
            self._nwdata.charge = math.min(self._nwdata.maxcharge, self._nwdata.charge
                + RECHARGE_RATE * dt * self:GetPower())
            self:_UpdateNWData()
        end
    end

    function SYS:GetChargeCost(ent)
        if ent:IsPlayer() then return 1.0 end
        if ent:GetClass() == "prop_physics" then return 0.5 end
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

        if room:GetShip() == self:GetShip() or room:GetShields() < self:GetShieldThreshold() then
            for _, pad in pairs(self:GetRoom():GetTransporterPads()) do
                for _, ent in pairs(ents.FindInSphere(pad, 64)) do
                    if self:TeleportEntity(ent, room) then return end
                end
            end
        end

        -- Nothing was teleported...
        for _, pad in pairs(self:GetRoom():GetTransporterPads()) do
            sound.Play(table.Random(failedSounds), pad, 70, 110)
        end
    end

    function SYS:TeleportEntity(ent, room)
        if not self:CanTeleportEntity(ent) then return false end

        self._nwdata.charge = self._nwdata.charge - self:GetChargeCost(ent)
        self:_UpdateNWData()

        local oldpos = ent:GetPos()
        local newpos = room:GetTransporterTarget()

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
    -- SYS.Icon = Material("systems/transporter.png", "smooth")
end