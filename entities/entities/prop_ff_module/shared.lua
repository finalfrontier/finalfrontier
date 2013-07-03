if SERVER then AddCSLuaFile("shared.lua") end

ENT.Type = "anim"
ENT.Base = "base_anim"

moduletype = {}
moduletype.lifesupport = 0
moduletype.shields = 1
moduletype.systempower = 2
moduletype.repair1 = 3
moduletype.repair2 = 4

ENT._grid = nil

local optimalGrids = nil

if SERVER then
    ENT._lastEffect = 0

    function ENT:GenerateGrid()
        local grid = {}
        for i = 1, 4 do
            grid[i] = {}
            for j = 1, 4 do
                if math.random() < 0.5 then
                    grid[i][j] = 0
                else
                    grid[i][j] = 1
                end
            end
        end
        return grid
    end

    GenerateModuleGrid = ENT.GenerateGrid

    function ENT:SetToOptimal()
        self._grid = {}
        for i = 1, 4 do
            self._grid[i] = {}
            for j = 1, 4 do
                self._grid[i][j] = optimalGrids[self:GetModuleType()][i][j]
            end
        end
        self:_UpdateGrid()
    end

    optimalGrids = {}
    for _, t in pairs(moduletype) do
        optimalGrids[t] = ENT.GenerateGrid(nil)
    end
    SetGlobalTable("optimalGrids", optimalGrids)
elseif CLIENT then
    optimalGrids = GetGlobalTable("optimalGrids")
end

function ENT:GetModuleType()
    return self:GetNWInt("type", 0)
end

function ENT:IsInSlot()
    return self:GetNWInt("room", -1) > -1
end

function ENT:GetSlotType()
    if not self:IsInSlot() then return nil end
    return self:GetRoom():GetSlot(self)
end

function ENT:GetRoom()
    if not self:IsInSlot() then return nil end
    local ship = ships.GetByName(self:GetNWString("ship"))
    return ship:GetRoomByIndex(self:GetNWInt("room"))
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
    local optimal = optimalGrids[self:GetModuleType()]

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

if SERVER then
    function ENT:SetModuleType(type)
        self:SetNWInt("type", type)
    end

    function ENT:Initialize()
        self:SetUseType(SIMPLE_USE)

        self:SetModel("models/props_c17/consolebox01a.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end

        if not self._grid then self:_RandomizeGrid() end
    end

    function ENT:GetGrid()
        return self._grid
    end

    function ENT:_RandomizeGrid()
        self._grid = self:GenerateGrid()
        self:_UpdateGrid()
    end

    function ENT:SetDefaultGrid(ship)
        local default = ship:GetDefaultGrid()
        self._grid = {}
        for i = 1, 4 do
            self._grid[i] = {}
            for j = 1, 4 do
                self._grid[i][j] = default[i][j]
            end
        end
        self:_UpdateGrid()
    end

    function ENT:_UpdateGrid()
        self:SetNWTable("grid", self._grid)
    end

    function ENT:InsertIntoSlot(room, type, slot)
        if not self:IsInSlot() and not self:IsPlayerHolding() and not room:GetModule(type) then
            self:SetNWString("ship", room:GetShipName())
            self:SetNWInt("room", room:GetIndex())

            room:SetModule(type, self)

            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
            end

            self:SetPos(slot - Vector(0, 0, 4))

            local yaw = self:GetAngles().y
            yaw = math.Round(yaw / 90) * 90

            self:SetAngles(Angle(0, yaw, 0))
        end
    end

    function ENT:RemoveFromSlot(ply)
        if self:IsInSlot() and self:GetRoom():RemoveModule(self) then
            self:SetPos(self:GetPos() + Vector(0, 0, 12))

            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(true)
                phys:Wake()

                local vel = Vector(0, 0, 128)
                if IsValid(ply) then
                    local diff = self:GetPos() - ply:GetPos()
                    vel.x = vel.x + diff.x
                    vel.y = vel.y + diff.y
                end

                phys:SetVelocity(vel)
            end

            self:SetNWString("ship", "")
            self:SetNWInt("room", -1)
        end
    end

    function ENT:Use(ply)
        if not IsValid(ply) or not ply:IsPlayer() then return end

        if self:IsInSlot() then
            self:RemoveFromSlot(ply)
        end

        if not self:IsPlayerHolding() then
            self:SetAngles(Angle(0, self:GetAngles().y, 0))
            ply:PickupObject(self)
        end
    end

    function ENT:OnTakeDamage(dmg)
        local amount = dmg:GetDamage() / 100
        local threshold = math.random() * math.random()
        local damaged = false
        while threshold < amount do
            local canDamage = {}
            for i = 1, 4 do
                for j = 1, 4 do
                    if self._grid[i][j] > -1 then
                        table.insert(canDamage, {i = i, j = j})
                    end
                end
            end

            if #canDamage == 0 then break end

            local pos = table.Random(canDamage)
            self._grid[pos.i][pos.j] = -1

            damaged = true

            amount = amount - threshold
            threshold = math.random() * math.random()
        end

        if damaged then
            self:_UpdateGrid()

            if self:IsInSlot() and self:GetSlotType() < moduletype.repair1 then
                self:GetRoom():GetShip():SetHazardMode(true, 10)
            end
        end
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
            self:_UpdateGrid()
        end
    end

    function ENT:Mirror(other, index)
        local x, y = self:_FindXY(index)

        if self._grid[x][y] > -1 and other._grid[x][y] == -1 then
            self._grid[x][y] = -1
            self:_UpdateGrid()
        end
    end

    function ENT:Think()
        if not self:IsInSlot() then
            local min, max = self:GetCollisionBounds()
            min = min + self:GetPos() - Vector(0, 0, 8)
            max = max + self:GetPos()
            local near = ents.FindInBox(min, max)
            for _, v in pairs(near) do
                if v:GetClass() == "info_ff_moduleslot" then
                    local type = v:GetModuleType()
                    if type == self:GetModuleType() or type == moduletype.repair1 or type == moduletype.repair2 then
                        self:InsertIntoSlot(v:GetRoom(), type, v:GetPos())
                        return
                    end
                end
            end
        else
            if self:GetDamaged() < 2 or self:GetSlotType() >= moduletype.repair1 then return end
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

    function ENT:Initialize()
        self:SetCustomCollisionCheck(true)
    end

    function ENT:IsGridLoaded()
        local grid = self:GetGrid()
        return grid and #grid == 4
    end

    function ENT:GetGrid()
        if not self._grid then
            self._grid = self:GetNWTable("grid")
        end

        return self._grid
    end

    function ENT:Draw()
        self:DrawModel()

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
