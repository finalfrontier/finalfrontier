if SERVER then AddCSLuaFile("shared.lua") end

ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:Initialize()
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        print("init phys")
        phys:EnableGravity(false)
        phys:EnableCollisions(false)
        phys:EnableDrag(false)
        phys:EnableMotion(true)
    end
    self:SetMoveType(MOVETYPE_NOCLIP)
end

function ENT:GetCoordinates()
    return universe:GetUniversePos(self:GetPos())
end

function ENT:GetRotation()
    return self:GetAngles().y
end

if SERVER then
    function ENT:Think()
        
    end
elseif CLIENT then
    function ENT:Draw()
        return
    end
end
