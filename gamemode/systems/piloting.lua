SYS.FullName = "Piloting"
SYS.SGUIName = "piloting"

SYS.Powered = false

SYS._targetX = 0
SYS._targetY = 0
SYS._directional = false

if SERVER then
    -- resource.AddFile("materials/systems/piloting.png")

    function SYS:SetTargetCoordinates(x, y, directional)
        self._directional = directional

        if directional then
            local sx, sy = self:GetShip():GetCoordinates()
            self._targetX, self._targetY = universe:GetDifference(sx, sy, x, y)
        else
            self._targetX = x
            self._targetY = y
        end

        print("tx: " .. FormatNum(self._targetX, 1, 2) .. ", ty: " .. FormatNum(self._targetY, 1, 2) .. ", d: " .. tostring(self._directional))
    end

    function SYS:GetAcceleration()
        return 0.01
    end

    function SYS:Initialize()
        self._targetX, self._targetY = self:GetShip():GetCoordinates()
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
        local tx, ty = 0, 0
        if self._directional then
            tx, ty = x + self._targetX, y + self._targetY
        else
            tx, ty = self._targetX, self._targetY
        end
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
