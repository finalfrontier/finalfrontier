SYS.FullName = "Transporter"
SYS.SGUIName = "transporter"

SYS.Powered = false

if SERVER then
    -- resource.AddFile("materials/systems/transporter.png")

    function SYS:CanTeleportEntity(ent)
        return IsValid(ent) and (ent:IsPlayer(ent) or ent:GetClass() == "prop_physics")
    end

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

    function SYS:StartTeleport(room)
        sound.Play(table.Random(warmupSounds), self:GetRoom():GetPos(), 100, 70)

        timer.Simple(2.5, function()
            for _, pad in pairs(self:GetRoom():GetTransporterPads()) do
                for _, ent in pairs(ents.FindInSphere(pad, 64)) do
                    if self:TeleportEntity(ent, room) then
                        return
                    end
                end
            end

            for _, pad in pairs(self:GetRoom():GetTransporterPads()) do
                sound.Play(table.Random(failedSounds), pad, 70, 110)
            end
        end)
    end

    function SYS:TeleportEntity(ent, room)
        if not self:CanTeleportEntity(ent) then return false end

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