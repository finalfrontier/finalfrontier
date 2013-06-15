if SERVER then AddCSLuaFile("shared.lua") end

ENT.Type = "anim"
ENT.Base = "base_anim"

moduletype = {}
moduletype.lifesupport = 0
moduletype.shields = 1
moduletype.systempower = 2

ENT._grid = nil

function ENT:GetModuleType()
    return self:GetNWInt("type", 0)
end

function ENT:IsInSlot()
    return self:GetNWInt("room", -1) > -1
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

if SERVER then
    ENT._lastEffect = 0

    function ENT:SetModuleType(type)
        self:SetNWInt("type", type)
    end

    function ENT:Initialize()
        self:SetModel("models/props_c17/consolebox01a.mdl")
        self:PhysicsInit(SOLID_VPHYSICS)
        self:SetMoveType(MOVETYPE_VPHYSICS)
        self:SetSolid(SOLID_VPHYSICS)

        local phys = self:GetPhysicsObject()
        if IsValid(phys) then
            phys:Wake()
        end

        self:_RandomizeGrid()
        self:_UpdateGrid()
    end

    function ENT:GetGrid()
        return self._grid
    end

    function ENT:_RandomizeGrid()
        if not self._grid then self._grid = {} end
        for i = 1, 4 do
            if not self._grid[i] then self._grid[i] = {} end
            for j = 1, 4 do
                if math.random() < 0.5 then
                    self._grid[i][j] = 0
                else
                    self._grid[i][j] = 1
                end
            end
        end
    end

    function ENT:_UpdateGrid()
        self:SetNWTable("grid", self._grid)
    end

    function ENT:InsertIntoSlot(room, slot)
        if not self:IsInSlot() then
            self:SetNWString("ship", room:GetShipName())
            self:SetNWInt("room", room:GetIndex())

            local phys = self:GetPhysicsObject()
            if IsValid(phys) then
                phys:EnableMotion(false)
            end

            self:SetPos(slot - Vector(0, 0, 4))
            self:SetAngles(Angle(0, 0, 0))
        end
    end

    function ENT:RemoveFromSlot(ply)
        if self:IsInSlot() then
            local phys = self:GetPhysicsObject()

            self:SetPos(self:GetPos() + Vector(0, 0, 12))

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

    function ENT:OnTakeDamage(dmg)
        if math.random() * math.random() < dmg:GetDamage() / 100 then
            local canDamage = {}
            for i = 1, 4 do
                for j = 1, 4 do
                    if self._grid[i][j] > -1 then
                        table.insert(canDamage, {i = i, j = j})
                    end
                end
            end

            if #canDamage == 0 then return end

            local pos = table.Random(canDamage)
            self._grid[pos.i][pos.j] = -1
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
                if v:GetClass() == "info_ff_moduleslot"
                    and v:GetModuleType() == self:GetModuleType() then
                    self:InsertIntoSlot(v:GetRoom(), v:GetPos())
                end
            end
        else
            if self:GetDamaged() < 2 then return end
            if CurTime() - self._lastEffect < 17 - ((math.random() * 0.5 + 0.5) * self:GetDamaged()) then return end

            local ed = EffectData()
            ed:SetEntity(self)
            ed:SetMagnitude(math.random() * self:GetDamaged())
            util.Effect("module_sparks", ed)

            self._lastEffect = CurTime()
        end
    end
elseif CLIENT then
    local typeMaterials = {
        Material("systems/lifesupport.png", "smooth"),
        Material("systems/shields.png", "smooth"),
        Material("power.png", "smooth")
    }

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
            surface.SetMaterial(typeMaterials[self:GetModuleType() + 1])
            surface.DrawTexturedRect(-20, -20, 40, 40)
        cam.End3D2D()
    end
end
