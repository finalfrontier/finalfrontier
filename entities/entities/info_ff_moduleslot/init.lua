ENT.Type = "point"
ENT.Base = "base_point"

local types

ENT._roomName = nil
ENT._hatchName = nil
ENT._moduleType = 0

ENT._room = nil
ENT._hatch = nil

ENT._open = false

function ENT:GetRoom()
    return self._room
end

function ENT:GetModule()
    return self._room:GetModule(self:GetModuleType())
end

function ENT:GetModuleType()
    return self._moduleType
end

function ENT:KeyValue(key, value)
    if key == "room" then
        self._roomName = tostring(value)
    elseif key == "hatch" then
        self._hatchName = tostring(value)
    elseif key == "type" then
        self._moduleType = tonumber(value)
    end
end

function ENT:AcceptInput(name, activator, caller, data)
    if name == "Opening" then
        self._open = true
    elseif name == "Closing" then
        self._open = false
    elseif name == "Used" then
        local ply = activator
        if not IsValid(ply) or not ply:HasPermission(self._room, permission.SYSTEM) then return end
        if self:GetModuleType() >= moduletype.repair1 then return end
        if self._open and self:GetModule() then self:Close() elseif not self._open then self:Open() end
    end
end

function ENT:Open()
    self._hatch:Fire("Unlock", "", 0)
    self._hatch:Fire("Open", "", 0)
    self._hatch:Fire("Lock", "", 0)
end

function ENT:Close()
    self._hatch:Fire("Unlock", "", 0)
    self._hatch:Fire("Close", "", 0)
    self._hatch:Fire("Lock", "", 0)
end

function ENT:InitPostEntity()
    if self._roomName then
        local rooms = ents.FindByName(self._roomName)
        if #rooms > 0 then
            self._room = rooms[1]
            self._room:AddModuleSlot(self:GetPos(), self._moduleType)
        end
    end

    if self._hatchName then
        local hatches = ents.FindByName(self._hatchName)
        if #hatches > 0 then
            self._hatch = hatches[1]
        end
    end
end

function ENT:Think()
    if self:GetModuleType() >= moduletype.repair1 then
        local system = self._room:GetSystem()
        if self._open and system:IsPerformingAction() then
            if self:GetModule() then
                self:GetModule():EmitSound("ambient/alarms/klaxon1.wav", 110, 100)
            end
            self:Close()
        elseif not self._open and not system:IsPerformingAction() then
            if self:GetModule() then
                self:GetModule():EmitSound("plats/elevbell1.wav", 105, 120)
            end
            self._open = true
            timer.Simple(0.5, function()
                if self:GetModule() then
                    local sound = CreateSound(self:GetModule(), "npc/env_headcrabcanister/hiss.wav")
                    sound:PlayEx(1, 110)
                    sound:ChangeVolume(0, 1.5)
                    timer.Simple(2, function()
                        sound:Stop()
                    end)
                    local ed = EffectData()
                    ed:SetEntity(self:GetModule())
                    ed:SetMagnitude(0.25 + math.random() * 0.25)
                    ed:SetFlags(1)
                    ed:SetOrigin(self:GetPos())
                    util.Effect("module_smoke", ed, true, true)
                end
                self:Open()
            end)
        end
    elseif self._open and self:GetModule() and #self._room:GetPlayers() == 0 then
        self:Close()
    end
end
