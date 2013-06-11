if SERVER then AddCSLuaFile("shared.lua") end

ENT.Type = "anim"
ENT.Base = "base_anim"

objtype = {}
objtype.unknown = 0
objtype.ship = 1

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "TargetRotation")
    self:NetworkVar("Float", 1, "AngularVel")
end

function ENT:Initialize()
    self:SetMoveType(MOVETYPE_NOCLIP)
    self:PhysicsInit(SOLID_NONE)

    self:SetTargetRotation(0)
    self:SetAngularVel(45)
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

    function ENT:SetAngleVel(vel)
        local phys = self:GetPhysicsObject()
        if phys:IsValid() then
            local curr = phys:GetAngleVelocity()
            phys:AddAngleVelocity(vel - curr)
        end
    end

    function ENT:SetObjectType(type)
        self:SetNWInt("objtype", type)
    end

    function ENT:SetObjectName(name)
        self:SetNWString("objname", name)
    end
end

function ENT:GetCoordinates()
    return universe:GetUniversePos(self:GetPos())
end

function ENT:GetRotation()
    return self:GetTargetRotation()
end

function ENT:GetRotationRadians()
    return self:GetAngles().y * math.pi / 180.0
end

function ENT:GetVel()
    local ox, oy = universe:GetUniversePos(Vector(0, 0, 0))
    local nx, ny = universe:GetUniversePos(self:GetVelocity())
    return nx - ox, ny - oy
end

function ENT:GetAngleVel(vel)
    local phys = self:GetPhysicsObject()
    if phys:IsValid() then
        return phys:GetAngleVelocity()
    end
    return 0
end

function ENT:GetObjectType()
    return self:GetNWInt("objtype", objtype.unknown)
end

function ENT:GetObjectName()
    return self:GetNWString("objname", nil)
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
