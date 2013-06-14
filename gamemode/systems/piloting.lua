SYS.FullName = "Piloting"
SYS.SGUIName = "piloting"

SYS.Powered = false

function SYS:GetTargetCoordinates()
    if self:IsRelative() then
        local sx, sy = self:GetShip():GetCoordinates()
        return sx + self._nwdata.targetx, sy + self._nwdata.targety
    end
    return self._nwdata.targetx, self._nwdata.targety
end

function SYS:IsRelative()
    return self._nwdata.relative
end

if SERVER then
    -- resource.AddFile("materials/systems/piloting.png")

    function SYS:Initialize()
        self._nwdata.targetx = 0
        self._nwdata.targety = 0
        self._nwdata.relative = true
        self:_UpdateNWData()
    end

    function SYS:SetTargetCoordinates(x, y, relative)
        self._nwdata.relative = relative

        if relative then
            local sx, sy = self:GetShip():GetCoordinates()
            self._nwdata.targetx, self._nwdata.targety = universe:GetDifference(sx, sy, x, y)
        else
            self._nwdata.targetx = x
            self._nwdata.targety = y
        end
        
        self:_UpdateNWData()
    end

    function SYS:GetAcceleration()
        return 0.01
    end

    function SYS:_FindAccel1D(g, a, p, u)
        local s = g - p
        local v = math.sqrt(2 * a * math.abs(s)) * math.sign(s)
        if u < v then return math.min(a, v - u) end
        if u > v then return math.max(-a, v - u) end
        return 0
    end

    function SYS:Think(dt)
        local obj = self:GetShip():GetObject()

        local x, y = obj:GetCoordinates()
        local tx, ty = self:GetTargetCoordinates()
        local dx, dy = universe:GetDifference(x, y, tx, ty)

        local vx, vy = obj:GetVel()
        if dx * dx + dy * dy <= 1.0 / 8192.0 and vx * vx + vy * vy <= 1.0 / 65536.0 then
            obj:SetCoordinates(tx, ty)
            obj:SetVel(0, 0)
            return
        end
        vx = vx * 0.99
        vy = vy * 0.99

        local a = self:GetAcceleration() * math.sqrt(0.5)

        local ax = self:_FindAccel1D(tx, a, x, vx)
        local ay = self:_FindAccel1D(ty, a, y, vy)

        obj:SetVel(vx + ax, vy + ay)
        obj:SetTargetRotation(math.atan2(-vy - ay, vx + ax) / math.pi * 180.0)
    end
elseif CLIENT then
    -- SYS.Icon = Material("systems/piloting.png", "smooth")
end
