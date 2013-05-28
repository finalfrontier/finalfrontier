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

function ENT:InitPostEntity()
    return
end

function ENT:GetSectorIndex(x, y)
    local xi = math.floor(x) - math.floor(x / self._horzSectors) * self._horzSectors
    local yi = math.floor(y) - math.floor(y / self._vertSectors) * self._vertSectors

    return xi + yi * self._horzSectors, xi, yi
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
