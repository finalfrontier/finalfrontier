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
    if key == "width" then
        self._width = tonumber(value)
    elseif key == "height" then
        self._height = tonumber(value)
    elseif key == "horzSectors" then
        self._horzSectors = tonumber(value)
    elseif key == "vertSectors" then
        self._vertSectors = tonumber(value)
    end
end

function ENT:Initialize()
    self._sectors = {}

    if not self._nwdata then
        self._nwdata = {}
    end

    self._nwdata.width = self._width
    self._nwdata.height = self._height
    self._nwdata.horzSectors = self._horzSectors
    self._nwdata.vertSectors = self._vertSectors
end

function ENT:WrapCoordinates(x, y)
    return x - math.floor(x / self._horzSectors) * self._horzSectors,
        y - math.floor(y / self._vertSectors) * self._vertSectors
end

function ENT:GetWorldPos(x, y)
    x, y = ((x / self._horzSectors) - 0.5) * self._width,
        ((y / self._vertSectors) - 0.5) * self._height
    return Vector(x, y, 0) + self:GetPos()
end

function ENT:GetUniversePos(vec)
    local diff = (vec - self:GetPos())
    return ((diff.x / self._width) + 0.5) * self._horzSectors,
        ((diff.y / self._height) + 0.5) * self._vertSectors
end

function ENT:GetSectorPos(vec)
    local x, y = self:GetUniversePos(vec)
    return math.floor(x) + 0.5, math.floor(y) + 0.5
end

function ENT:InitPostEntity()
    for x = 0, self._horzSectors - 1 do
        for y = 0, self._vertSectors - 1 do
            local sector = ents.Create("info_ff_sector")
            local index, xi, yi = self:GetSectorIndex(x, y)
            sector:SetCoordinates(xi, yi)
            sector:SetPos(self:GetWorldPos(xi + 0.5, yi + 0.5))
            self._sectors[index] = sector
        end
    end

    universe = self
end

function ENT:GetSectorIndex(x, y)
    local xi, yi = self:WrapCoordinates(math.floor(x), math.floor(y))
    return xi + yi * self._horzSectors + 1, xi, yi
end

function ENT:GetSector(x, y)
    local sector, xi, yi = self._sectors[self:GetSectorIndex(x, y)]

    if not sector then
        sector = Sector(self, xi, yi)
    end

    return sector
end

function ENT:_UpdateNWData()
    SetGlobalTable("universe", self._nwdata)
end
