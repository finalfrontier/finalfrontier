-- Copyright (c) 2014 James King [metapyziks@gmail.com]
-- 
-- This file is part of Final Frontier.
-- 
-- Final Frontier is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
-- 
-- Final Frontier is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with Final Frontier. If not, see <http://www.gnu.org/licenses/>.

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
    self._nwdata = self._nwdata or {}

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
    universe = self
    
    self._sectors = {}

    self._nwdata = NetworkTable("universe", self._nwdata)

    self._nwdata.x = self:GetPos().x
    self._nwdata.y = self:GetPos().y
    self._nwdata.z = self:GetPos().z
    self._nwdata:Update()
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
    local dx, dy = xb - xa, yb - ya
    local wid, hei = self:GetHorizontalSectors(), self:GetVerticalSectors()
    
    if dx >= wid * 0.5 then
        dx = dx - wid
    elseif dx < -wid * 0.5 then
        dx = dx + wid
    end

    if dy >= hei * 0.5 then
        dy = dy - hei
    elseif dy < -hei * 0.5 then
        dy = dy + hei
    end

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
    for x = 0, self:GetHorizontalSectors() - 1 do
        for y = 0, self:GetVerticalSectors() - 1 do
            local sector = ents.Create("info_ff_sector")
            local index, xi, yi = self:GetSectorIndex(x, y)
            sector:SetCoordinates(xi, yi)
            sector:Spawn()
            self._sectors[index] = sector
        end
    end
end
