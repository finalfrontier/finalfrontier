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

if SERVER then
    function ENT:SetCoordinates(x, y)
        self:SetPos(universe:GetWorldPos(universe:WrapCoordinates(x, y)))
    end

    function ENT:SetRotation(angle)
        self:SetAngles(Angle(0, angle, 0))
    end

    function ENT:SetVel(dx, dy)
        local orig = universe:GetWorldPos(0, 0)
        local next = universe:GetWorldPos(dx, dy)
        self:SetLocalVelocity(next - orig)
    end
end

function ENT:GetCoordinates()
    return universe:GetUniversePos(self:GetPos())
end

function ENT:GetRotation()
    return self:GetAngles().y
end

function ENT:GetRotationRadians()
    return self:GetAngles().y * math.pi / 180.0
end

if SERVER then
    function ENT:Think()
        local x, y = self:GetCoordinates()
        local wx, wy = universe:WrapCoordinates(x, y)
        if math.abs(wx - x) >= 1 or math.abs(wy - y) >= 1 then
            self:SetCoordinates(wx, wy)
        end
    end
elseif CLIENT then
    function ENT:Draw()
        return
    end
end
