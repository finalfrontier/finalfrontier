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

local _optimalGrids = NetworkTable("optimalGrids")

ENT.Base = "prop_ff_modulebase"

ENT._grid = nil

function ENT:SetupDataTables()
    self.BaseClass.SetupDataTables(self)

    self._grid = self:NetworkTable(0, "Grid")
end

if SERVER then
    ENT._lastEffect = 0

    function GenerateModuleGrid(grid, dmg)
        if type(grid) == "number" then
            dmg = grid
            grid = nil
        end

        grid = grid or {}
        dmg = dmg or 0

        for i = 1, 4 do
            grid[i] = {}
            for j = 1, 4 do
                if math.random() < dmg then
                    grid[i][j] = -1
                elseif math.random() < 0.5 then
                    grid[i][j] = 0
                else
                    grid[i][j] = 1
                end
            end
        end

        return grid
    end

    function ENT:SetToOptimal()
        for i = 1, 4 do
            self._grid[i] = {}
            for j = 1, 4 do
                self._grid[i][j] = _optimalGrids[self:GetModuleType()][i][j]
            end
        end
        self._grid:Update()
    end

    for t = 0, 2 do
        _optimalGrids[t] = GenerateModuleGrid()
    end
    _optimalGrids:Update()
end

function ENT:GetDamaged()
    if CLIENT and not self:IsGridLoaded() then return 0 end

    local grid = self:GetGrid()

    local count = 0
    for i = 1, 4 do
        for j = 1, 4 do
            if grid[i][j] == -1 then
                count = count + 1
            end
        end
    end

    return count
end

function ENT:GetScore()
    if CLIENT and not self:IsGridLoaded() then return 0 end

    local grid = self:GetGrid()
    local optimal = _optimalGrids[self:GetModuleType()]

    local score = 0
    for i = 1, 4 do
        for j = 1, 4 do
            if grid[i][j] == optimal[i][j] then
                score = score + 4
            elseif grid[i][j] ~= -1 then
                score = score + 1
            end
        end
    end

    return score / (4 * 4 * 4)
end

function ENT:GetPlayerTargetedTile(ply)
    if CLIENT then
        ply = ply or LocalPlayer()
    end

    local ang = self:GetAngles()
    ang:RotateAroundAxis(ang:Up(), -90)

    local p0 = self:GetPos() + ang:Up() * 11
    local n = ang:Up()
    local l0 = ply:GetShootPos()
    local l = ply:GetAimVector()
    
    local d = (p0 - l0):Dot(n) / l:Dot(n)

    local hitpos = (l0 + l * d) - p0
    local xvec = ang:Forward()
    local yvec = ang:Right()
    
    local x = math.floor(hitpos:DotProduct(xvec) / 5) + 3
    local y = math.floor(hitpos:DotProduct(yvec) / 5) + 3

    if x < 1 or x > 4 or y < 1 or y > 4 then return nil end

    return x, y
end

if SERVER then
    function ENT:Initialize()
        self.BaseClass.Initialize(self)

        self:_RandomizeGrid()
    end

    function ENT:GetGrid()
        return self._grid
    end

    function ENT:_RandomizeGrid()
        GenerateModuleGrid(self._grid)
        self._grid:Update()
    end

    function ENT:SetDefaultGrid(ship)
        local default = ship:GetDefaultGrid()
        for i = 1, 4 do
            self._grid[i] = {}
            for j = 1, 4 do
                self._grid[i][j] = default[i][j]
            end
        end
        self._grid:Update()
    end

    function ENT:OnTakeDamage(dmg)
        local amount = dmg:GetDamage() / 100
        local threshold = math.pow(math.random(), 2)
        local damaged = false
        while threshold < amount do
            if self:_DamageRandomTile() then
                damaged = true
            else break end

            amount = amount - threshold
            threshold = math.pow(math.random(), 2)
        end

        if damaged then
            self._grid:Update()

            if self:IsInSlot() and self:GetSlotType() < moduletype.REPAIR_1 then
                self:GetRoom():GetShip():SetHazardMode(true, 10)
            end
        end
    end

    function ENT:DamageRandomTiles(count)
        for i = 1, count do
            if not self:_DamageRandomTile() then break end
        end
        self._grid:Update()
    end

    function ENT:_DamageRandomTile()
        local canDamage = {}
        for i = 1, 4 do
            for j = 1, 4 do
                if self._grid[i][j] > -1 then
                    table.insert(canDamage, {i = i, j = j})
                end
            end
        end

        if self:IsInSlot() then
            if #canDamage <= 1 then return false end
        else
            if #canDamage <= 1 then
                local ed = EffectData()
                ed:SetOrigin(self:GetPos())
                ed:SetScale(1)
                util.Effect("Explosion", ed)
                self:Remove()
                return true
            end
        end

        local pos = table.Random(canDamage)
        self._grid[pos.i][pos.j] = -1

        return true
    end

    function ENT:SetTile(x, y, val)
        self._grid[x][y] = val
        self._grid:Update()
    end

    function ENT:GetTile(x, y)
        return self._grid[x][y]
    end

    function ENT:_FindXY(index)
        local y = math.floor((index - 1) / 4) + 1
        local x = index - (y - 1) * 4
        return x, y
    end

    function ENT:IsDamaged(index)
        local x, y = self:_FindXY(index)
        return self._grid[x][y] == -1
    end

    function ENT:Splice(other, index)
        local x, y = self:_FindXY(index)

        if self._grid[x][y] == -1 and other._grid[x][y] > -1 then
            self._grid[x][y] = other._grid[x][y]
            self._grid:Update()
        end
    end

    function ENT:Transcribe(other, index)
        local x, y = self:_FindXY(index)

        if self._grid[x][y] > -1 and other._grid[x][y] == -1 then
            self._grid[x][y] = -1
            self._grid:Update()
        end
    end

    function ENT:CanInsertIntoSlot(slot)
        return slot:GetModuleType() == self:GetModuleType() or slot:IsRepairSlot()
    end

    function ENT:Think()
        if not IsValid(self) then return end
        
        self.BaseClass.Think(self)

        if self:IsInSlot() then
            if self:GetDamaged() < 2 or self:GetSlotType() >= moduletype.REPAIR_1 then return end
            if CurTime() - self._lastEffect < 17 - ((math.random() * 0.5 + 0.5) * self:GetDamaged()) then return end

            local ed = EffectData()
            ed:SetEntity(self)
            ed:SetMagnitude(math.random() * self:GetDamaged())
            ed:SetOrigin(self:GetPos() + Vector(0, 0, 8))
            util.Effect("module_sparks", ed, true, true)

            self._lastEffect = CurTime()
        end
    end
elseif CLIENT then
    modulematerials = {
        Material("systems/lifesupport.png", "smooth"),
        Material("systems/shields.png", "smooth"),
        Material("power.png", "smooth"),
        Material("systems/noicon.png", "smooth")
    }

    function ENT:IsGridLoaded()
        local grid = self:GetGrid()
        return grid and #grid == 4
    end

    function ENT:GetGrid()
        return self._grid
    end

    function ENT:Draw()
        self.BaseClass.Draw(self)

        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), -90)

        draw.NoTexture()
        
        cam.Start3D2D(self:GetPos() + ang:Up() * 11, ang, 0.5)
            surface.SetDrawColor(Color(0, 0, 0, 255))
            surface.DrawRect(-24, -24, 48, 48)

            if self:IsGridLoaded() then
                local grid = self:GetGrid()
                for i = 1, 4 do
                    local x = (i - 2.5) * 10
                    for j = 1, 4 do
                        local y = (j - 2.5) * 10
                        local val = grid[i][j]

                        if val == 0 then
                            surface.SetDrawColor(Color(51, 172, 45, 255))
                            surface.DrawRect(x - 4, y - 4, 8, 8)
                        elseif val == 1 then
                            surface.SetDrawColor(Color(45, 51, 172, 255))
                            surface.DrawRect(x - 4, y - 4, 8, 8)
                        else
                            surface.SetDrawColor(Color(172, 45, 51, Pulse(1) * 63 + 32))
                            surface.DrawRect(x - 4, y - 4, 8, 8)
                        end
                    end
                end
            end

            surface.SetDrawColor(Color(255, 255, 255, 16))
            surface.SetMaterial(modulematerials[self:GetModuleType() + 1])
            surface.DrawTexturedRect(-20, -20, 40, 40)
        cam.End3D2D()
    end
end
