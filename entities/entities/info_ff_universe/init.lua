universe = nil

ENT.Type = "point"
ENT.Base = "base_point"

ENT._width = 0
ENT._height = 0

ENT._horzSectors = 0
ENT._vertSectors = 0

ENT._sectors = nil

ENT._nwdata = nil

function ENT:KeyValue(key, value)
    if not self._nwdata then self._nwdata = {} end
    if key == "width" then
        self._nwdata.width = tonumber(value)
    elseif key == "height" then
        self._nwdata.height = tonumber(value)
    elseif key == "horzSectors" then
        self._nwdata.horzSectors = tonumber(value)
    elseif key == "vertSectors" then
        self._nwdata.vertSectors = tonumber(value)
    end
end

function ENT:Initialize()
    self._sectors = {}

    if not self._nwdata then self._nwdata = {} end

    self._nwdata.x = self:GetPos().x
    self._nwdata.y = self:GetPos().y
    self._nwdata.z = self:GetPos().z
    self:_UpdateNWData()
end

function ENT:GetHorizontalSectors()
    return self._nwdata.horzSectors
end

function ENT:GetVerticalSectors()
    return self._nwdata.vertSectors
end

function ENT:GetWorldWidth()
    return self._nwdata.width
end

function ENT:GetWorldHeight()
    return self._nwdata.height
end

function ENT:WrapCoordinates(x, y)
    return x - math.floor(x / self:GetHorizontalSectors()) * self:GetHorizontalSectors(),
        y - math.floor(y / self:GetVerticalSectors()) * self:GetVerticalSectors()
end

function ENT:GetDifference(xa, ya, xb, yb)
    xa, ya = self:WrapCoordinates(xa, ya)
    xb, yb = self:WrapCoordinates(xb, yb)
    local dxa, dya = xb - xa, yb - ya
    local dxb, dyb = xa - xb, ya - yb
    local dx, dy = dxa, dya
    if math.abs(dxa) > math.abs(dxb) then dx = dxb end
    if math.abs(dya) > math.abs(dyb) then dy = dyb end
    return dx, dy
end

function ENT:GetDistance(xa, ya, xb, yb)
    local dx, dy = self:GetDifference(xa, ya, xb, yb)
    return math.sqrt(dx * dx + dy * dy)
end

function ENT:GetWorldPos(x, y)
    x, y = ((x / self:GetHorizontalSectors()) - 0.5) * self:GetWorldWidth(),
        ((y / self:GetVerticalSectors()) - 0.5) * self:GetWorldHeight()
    return Vector(x, y, 0) + self:GetPos()
end

function ENT:GetUniversePos(vec)
    local diff = (vec - self:GetPos())
    return ((diff.x / self:GetWorldWidth()) + 0.5) * self:GetHorizontalSectors(),
        ((diff.y / self:GetWorldHeight()) + 0.5) * self:GetVerticalSectors()
end

function ENT:GetSectorPos(vec)
    local x, y = self:GetUniversePos(vec)
    return math.floor(x) + 0.5, math.floor(y) + 0.5
end

function ENT:GetSectorIndex(x, y)
    local xi, yi = self:WrapCoordinates(math.floor(x), math.floor(y))
    return xi + yi * self:GetHorizontalSectors() + 1, xi, yi
end

function ENT:GetSector(x, y)
    return self._sectors[self:GetSectorIndex(x, y)]
end

function ENT:InitPostEntity()
    universe = self
    for x = 0, self:GetHorizontalSectors() - 1 do
        for y = 0, self:GetVerticalSectors() - 1 do
            local sector = ents.Create("info_ff_sector")
            local index, xi, yi = self:GetSectorIndex(x, y)
            sector:SetCoordinates(xi, yi)
            sector:Spawn()
            self._sectors[index] = sector

            --[[local objs = math.floor(math.random() * 4) + 1
            for i = 1, objs do
                local obj = ents.Create("info_ff_object")
                obj:SetPos(self:GetWorldPos(xi + math.random(), yi + math.random()))
                obj:SetRotation(0)
                obj:SetVel(math.random() - 0.5, math.random() - 0.5)
                obj:Spawn()
            end]]
        end
    end
end

function ENT:_UpdateNWData()
    SetGlobalTable("universe", self._nwdata)
end
