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

if SERVER then AddCSLuaFile("shared.lua") end

ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:SetupDataTables()
	self:NetworkVar( "String", 0, "SectorName" )
end

function ENT:GetCoordinates()
    return universe:GetUniversePos(self:GetPos())
end

function ENT:GetSectorName()
    return self:GetSectorName()
end

function ENT:GetBoundingBox()
    local cx, cy = self:GetCoordinates()
    
    return
        universe:GetWorldPos(cx + 0, cy + 0) - Vector(0, 0, 8),
        universe:GetWorldPos(cx + 1, cy + 1) + Vector(0, 0, 8)
end

if SERVER then
    local horzNames = {
        "alpha", "beta",  "gamma",  "delta",   "epsilon", "zeta", "eta",     "theta",
        "iota",  "kappa", "lambda", "mu",      "nu",      "xi",   "omicron", "phi",
        "rho",   "sigma", "tau",    "upsilon", "phi",     "chi",  "psi",     "omega"
    }

    local vertNames = {}
    for i = 1, 24 do vertNames[i] = tostring(i) end

    local RESPAWN_DELAY = 15

    ENT._lastVisit = 0

    function ENT:GetPVSPos()
        return self:GetPos() + Vector(0, 0, 64)
    end

    function ENT:SetCoordinates(x, y)
        self:SetPos(universe:GetWorldPos(universe:WrapCoordinates(x + 0.5, y + 0.5)))
        self:SetSectorName(horzNames[x + 1] .. "-" .. vertNames[y + 1])
    end

    function ENT:Purge()
        for _, ent in ipairs(ents.FindInBox(self:GetBoundingBox())) do
            if IsValid(ent) and ent:GetClass() == "info_ff_object"
                and (not ent.GetObjectType or ent:GetObjectType() ~= objtype.SHIP) then
                ent:Remove()
            end
        end
    end

    function ENT:Populate()
        self:Purge()

        local x, y = self:GetCoordinates()
        local count, max = 0, math.ceil(math.random() * 8)

        while math.random() < 0.25 and count < max do
            count = count + 1
        end

        for i = 1, count do
            local obj = ents.Create("info_ff_object")
            obj:SetCoordinates(x + math.random(), y + math.random())
            obj:Spawn()

            if math.random() < 0.75 then
                obj:AssignRoomModule(table.Random({
                    moduletype.LIFE_SUPPORT,
                    moduletype.SHIELDS,
                    moduletype.SYSTEM_POWER
                }), nil)
            else
                obj:AssignWeaponModule()
            end
        end
    end

    function ENT:Visit()
        if self._lastVisit == 0 or CurTime() - self._lastVisit >= RESPAWN_DELAY then
            self:Populate()
        end

        self._lastVisit = CurTime()
    end

    function ENT:Think()
        if self._lastVisit > 0 and CurTime() - self._lastVisit >= RESPAWN_DELAY then
            self:Purge()
            self._lastVisit = 0
        end
    end
elseif CLIENT then
    function ENT:Draw()
        return
    end
end
