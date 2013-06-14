if SERVER then AddCSLuaFile("shared.lua") end

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT._lastLerpTime = 0
ENT._lastTargetRotation = 0
ENT._currRotation = 0
ENT._lastRotation = 0

objtype = {}
objtype.unknown = 0
objtype.ship = 1

function ENT:SetupDataTables()
    self:NetworkVar("Float", 0, "TargetRotation")
    self:NetworkVar("Float", 45, "AngularVel")
end

function ENT:Initialize()
    if SERVER then
        self:SetMoveType(MOVETYPE_NOCLIP)
        self:PhysicsInit(SOLID_NONE)

        self:SetTargetRotation(0)
        self:SetAngularVel(45)
    end

    self._lastLerpTime = CurTime()
end

if SERVER then
    function ENT:SetCoordinates(x, y)
        self:SetPos(universe:GetWorldPos(universe:WrapCoordinates(x, y)))
    end

    function ENT:SetRotation(angle)
        self._currRotation = angle
    end

    function ENT:SetVel(dx, dy)
        local orig = universe:GetWorldPos(0, 0)
        local next = universe:GetWorldPos(dx, dy)
        self:SetLocalVelocity(next - orig)
    end

    function ENT:SetObjectType(type)
        self:SetNWInt("objtype", type)
    end

    function ENT:SetObjectName(name)
        self:SetNWString("objname", name)
    end
end

local function FindAngleDifference(a, b)
    local diff = b - a
    if diff >= 180 then
        return diff - 360
    elseif diff < -180 then
        return diff + 360
    end
    return diff
end

function ENT:GetRotation()
    if self._lastTargetRotation ~= self:GetTargetRotation() then
        self._lastTargetRotation = self:GetTargetRotation()
        self._lastRotation = self._currRotation
        self._lastLerpTime = CurTime()
    end

    local diff = FindAngleDifference(self._currRotation, self:GetTargetRotation())
    if math.abs(diff) >= 0.1 then
        local t = (CurTime() - self._lastLerpTime)
        local vel = math.sign(diff) * math.min(math.abs(diff), t * self:GetAngularVel())
        self._currRotation = self._lastRotation + vel
    else
        self._currRotation = self:GetTargetRotation()
        self._lastRotation = self._currRotation
        self._lastLerpTime = CurTime()
    end
    return self._currRotation
end

function ENT:GetCoordinates()
    return universe:GetUniversePos(self:GetPos())
end

function ENT:GetRotationRadians()
    return self:GetRotation() * math.pi / 180.0
end

function ENT:GetVel()
    local ox, oy = universe:GetUniversePos(Vector(0, 0, 0))
    local nx, ny = universe:GetUniversePos(self:GetVelocity())
    return nx - ox, ny - oy
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
    function ENT:Think()
        return
    end

    function ENT:Draw()
        return
    end
end
