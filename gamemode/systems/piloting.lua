SYS.FullName = "Piloting"
SYS.SGUIName = "piloting"

SYS.Powered = false

SYS._targetX = 0
SYS._targetY = 0
SYS._targetRot = 0

if SERVER then
    -- resource.AddFile("materials/systems/piloting.png")

    function SYS:SetTargetCoordinates(x, y)
        self._targetX = x
        self._targetY = y
    end

    function SYS:SetTargetRotation(angle)
        self._targetRot = angle
    end

    function SYS:GetAcceleration()
        return 0.05
    end

    function SYS:Initialize()
        self._targetX, self._targetY = self:GetShip():GetCoordinates()
        self._targetRot = self:GetShip():GetRotation()
    end

    function math.sign(x)
        if x > 0 then return 1 end
        if x < 0 then return -1 end
        return 0
    end

    function SYS:_FindAccel1D(g, a, p, u)
        local s = g - p
        local v = math.sqrt(2 * a * math.abs(s)) * math.sign(s)
        if u < v then return math.min(a, v - u) end
        if u > v then return math.max(-a, v - u) end
        return 0
    end

    function SYS:Think(dt)
        local x, y = self:GetShip():GetCoordinates()
        local dx, dy = self._targetX - x, self._targetY - y
        local vx, vy = self:GetShip():GetVel()
        if dx * dx + dy * dy <= 1.0 / 1024.0 and vx * vx + vy * vy <= 1.0 / 8192.0 then
            self:GetShip():GetObject():SetCoordinates(self._targetX, self._targetY)
            self:GetShip():GetObject():SetVel(0, 0)
            return
        end
        vx = vx * 0.99
        vy = vy * 0.99

        local a = self:GetAcceleration() * math.sqrt(0.5)

        local ax = self:_FindAccel1D(self._targetX, a, x, vx)
        local ay = self:_FindAccel1D(self._targetY, a, y, vy)

        local angle = math.atan2(-vy, vx) / math.pi * 180.0
        self:GetShip():GetObject():SetRotation(angle)

        self:GetShip():GetObject():SetVel(vx + ax, vy + ay)
    end
elseif CLIENT then
    -- SYS.Icon = Material("systems/piloting.png", "smooth")
end
