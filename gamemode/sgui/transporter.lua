local BASE = "page"

GUI.BaseName = BASE

GUI._inspected = nil
GUI._oldScale = 0

GUI._zoomLabel = nil
GUI._zoomSlider = nil
GUI._selectedLabel = nil
GUI._inspectButton = nil
GUI._coordLabel = nil
GUI._sectorLabel = nil
GUI._grid = nil

GUI._shipView = nil
GUI._closeButton = nil

local delay_beamup = 1
local delay_beamdown = 1
local zap = Sound("ambient/levels/labs/electric_explosion4.wav")
local unzap = Sound("ambient/levels/labs/electric_explosion2.wav")

local function ShouldCollide(ent)
    local g = ent:GetCollisionGroup()
    return (g != COLLISION_GROUP_WEAPON and
        g != COLLISION_GROUP_DEBRIS and
        g != COLLISION_GROUP_DEBRIS_TRIGGER and
        g != COLLISION_GROUP_INTERACTIVE_DEBRIS)
end

local function CanTeleportToPos(ply, pos)
    -- first check if we can teleport here at all, because any solid object or
    -- brush will make us stuck and therefore kills/blocks us instead, so the
    -- trace checks for anything solid to players that isn't a player
    local tr = nil
    local tres = {start=pos, endpos=pos, mask=MASK_PLAYERSOLID, filter=player.GetAll()}
    local collide = false

    -- This thing is unnecessary if we can supply a collision group to trace
    -- functions, like we can in source and sanity suggests we should be able
    -- to do so, but I have not found a way to do so yet. Until then, re-trace
    -- while extending our filter whenever we hit something we don't want to
    -- hit (like weapons or ragdolls).
    repeat
        tr = util.TraceEntity(tres, ply)

        if tr.HitWorld then
        collide = true
        elseif IsValid(tr.Entity) then
        if ShouldCollide(tr.Entity) then
        collide = true
        else
        table.insert(tres.filter, tr.Entity)
        end
        end
    until (not tr.Hit) or collide

    if collide then
        --Telefrag(ply, ply)
        return true, nil
    else
        -- find all players in the place where we will be and telefrag them
        local blockers = ents.FindInBox(pos + Vector(-16, -16, 0),
        pos + Vector(16, 16, 64))

        local blocking_plys = {}

        for _, block in pairs(blockers) do
            if IsValid(block) and block:IsPlayer() and block != ply and block:Alive() then
                table.insert(blocking_plys, block)
            end
        end

        return false, blocking_plys
    end

    return false, nil
end

local function TeleportPlayer(ply, teleport)
    local oldpos = ply:GetPos()
    local pos = teleport.pos
    local ang = teleport.ang

    -- perform teleport
    ply:SetPos(pos)
    if ply:IsPlayer() then
        ply:SetEyeAngles(ang) -- ineffective due to freeze...
    else
        local phys = ply:GetPhysicsObject()
        if phys:IsValid() then phys:Wake() end
    end

    timer.Simple(delay_beamdown, function ()
        if IsValid(ply) and ply:IsPlayer() then
            ply:Freeze(false)
        end
    end)

    sound.Play(zap, oldpos, 65, 100)
    sound.Play(unzap, pos, 55, 100)
end

local function DoTeleport(ply, teleport)
    if IsValid(ply) and teleport then
        local fail = false

        local block_world, block_plys = CanTeleportToPos(ply, teleport.pos)

        if block_world or (block_plys and #block_plys > 0) then
            fail = true
        end

        if not fail then
            TeleportPlayer(ply, teleport)
            return         
        end
    elseif not IsValid(ply) then
        return
    end
    if ply:IsPlayer() then
        ply:Freeze(false)
        LANG.Msg(ply, "tele_failed")
    end
end

local function StartTeleport(ply, teleport)
    if (not IsValid(ply)) or (not teleport) then return end

    teleport.ang = ply:EyeAngles()

    timer.Simple(delay_beamup, function() DoTeleport(ply, teleport) end)

    local ang = ply:GetAngles()

    local edata_up = EffectData()
    edata_up:SetOrigin(ply:GetPos())
    ang = Angle(0, ang.y, ang.r) -- deep copy
    edata_up:SetAngles(ang)
    edata_up:SetEntity(ply)
    edata_up:SetMagnitude(delay_beamup)
    edata_up:SetRadius(delay_beamdown)

    util.Effect("teleport_beamup", edata_up)

    local edata_dn = EffectData()
    edata_up:SetOrigin(teleport.pos)
    ang = Angle(0, ang.y, ang.r) -- deep copy
    edata_up:SetAngles(ang)
    edata_up:SetEntity(ply)
    edata_up:SetMagnitude(delay_beamup)
    edata_up:SetRadius(delay_beamdown)

    util.Effect("teleport_beamdown", edata_dn)
end

function GUI:Inspect(obj)
    self:RemoveAllChildren()
    if obj then
        self._inspected = obj
        self._oldScale = self._grid:GetScale()

        self._zoomLabel = nil
        self._zoomSlider = nil
        self._selectedLabel = nil
        self._inspectButton = nil
        self._coordLabel = nil
        self._sectorLabel = nil
        self._grid = nil

        self._shipView = sgui.Create(self, "shipview")
        self._shipView:SetCurrentShip(ships.GetByName(obj:GetObjectName()))
        self._shipView:SetBounds(Bounds(16, 8, self:GetWidth() - 32, self:GetHeight() - 88))

        for _ , room in pairs(self._shipView:GetRoomElements()) do
           --print(room:GetCurrentRoom():GetName())
            room.CanClick = true
            if SERVER then
                function room.OnClick(this, x, y, button)
                    for _, pad in pairs(self:GetRoom():GetTransporterPads()) do
                        for _, ent in pairs(ents.FindInSphere(pad, 64)) do
                            StartTeleport(ent, {pos = room:GetCurrentRoom():GetTransporterTarget(), ang = 0})
                        end
                    end
                   --print(room:GetCurrentRoom():GetName()) 
                end
            end

        end

        self._closeButton = sgui.Create(self, "button")
        self._closeButton:SetOrigin(16, self:GetHeight() - 48 - 16)
        self._closeButton:SetSize(self:GetWidth() - 32, 48)
        self._closeButton.Text = "Return to Sector View"

        if SERVER then
            function self._closeButton.OnClick(btn, x, y, button)
                self:Inspect(nil)
                self._grid:SetCentreObject(obj)
                self:GetScreen():UpdateLayout()
            end
        end
    else
        self._inspected = nil
        self._shipView = nil
        self._closeButton = nil

        self._grid = sgui.Create(self, "sectorgrid")
        self._grid:SetOrigin(8, 8)
        self._grid:SetSize(self:GetWidth() * 0.6 - 16, self:GetHeight() - 16)
        self._grid:SetCentreObject(nil)
        self._grid:SetScale(math.max(self._grid:GetMinScale(), self._oldScale))

        self._zoomLabel = sgui.Create(self, "label")
        self._zoomLabel.AlignX = TEXT_ALIGN_CENTER
        self._zoomLabel.AlignY = TEXT_ALIGN_CENTER
        self._zoomLabel:SetOrigin(self._grid:GetRight() + 16, 16)
        self._zoomLabel:SetSize(self:GetWidth() * 0.4 - 16, 32)
        self._zoomLabel.Text = "View Zoom"

        self._zoomSlider = sgui.Create(self, "slider")
        self._zoomSlider:SetOrigin(self._grid:GetRight() + 16, self._zoomLabel:GetBottom() + 8)
        self._zoomSlider:SetSize(self:GetWidth() * 0.4 - 16, 48)

        if SERVER then
            local min = self._grid:GetMinScale()
            local max = self._grid:GetMaxScale()
            self._zoomSlider.Value = math.sqrt((self._grid:GetScale() - min) / (max - min))
            function self._zoomSlider.OnValueChanged(slider, value)
                min = self._grid:GetMinScale()
                max = self._grid:GetMaxScale()
                self._grid:SetScale(min + math.pow(value, 2) * (max - min))
            end
        end

        self._selectedLabel = sgui.Create(self, "label")
        self._selectedLabel.AlignX = TEXT_ALIGN_CENTER
        self._selectedLabel.AlignY = TEXT_ALIGN_CENTER
        self._selectedLabel:SetOrigin(self._grid:GetRight() + 16, self._zoomSlider:GetBottom() + 48)
        self._selectedLabel:SetSize(self:GetWidth() * 0.4 - 16, 32)
        self._selectedLabel.Text = "This Ship"

        self._inspectButton = sgui.Create(self, "button")
        self._inspectButton:SetOrigin(self._grid:GetRight() + 16, self._selectedLabel:GetBottom() + 8)
        self._inspectButton:SetSize(self:GetWidth() * 0.4 - 16, 48)
        self._inspectButton.Text = "Inspect"

        if SERVER then
            self._inspectButton.OnClick = function(btn, button)
                if self._grid:GetCentreObject():GetObjectType() == objtype.ship then
                    self:Inspect(self._grid:GetCentreObject())
                    self:GetScreen():UpdateLayout()
                end
            end
        end

        self._coordLabel = sgui.Create(self, "label")
        self._coordLabel.AlignX = TEXT_ALIGN_CENTER
        self._coordLabel.AlignY = TEXT_ALIGN_CENTER
        self._coordLabel:SetOrigin(self._grid:GetRight() + 16, self:GetHeight() - 48)
        self._coordLabel:SetSize(self:GetWidth() * 0.4 - 16, 32)

        self._sectorLabel = sgui.Create(self, "label")
        self._sectorLabel.AlignX = TEXT_ALIGN_CENTER
        self._sectorLabel.AlignY = TEXT_ALIGN_CENTER
        self._sectorLabel:SetOrigin(self._grid:GetRight() + 16, self._coordLabel:GetTop() - 48)
        self._sectorLabel:SetSize(self:GetWidth() * 0.4 - 16, 32)
    end
end

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self:Inspect(nil)
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        layout.inspected = self._inspected
    end
elseif CLIENT then
    function GUI:Draw()
        if not self._inspected then
            local obj = self._grid:GetCentreObject()
            local x, y = obj:GetCoordinates()

            self._selectedLabel.Text = obj:GetObjectName()
            self._coordLabel.Text = "x: " .. FormatNum(x, 1, 2) .. ", y: " .. FormatNum(y, 1, 2)
        end

        self.Super[BASE].Draw(self)
    end

    function GUI:UpdateLayout(layout)
        if self._inspected ~= layout.inspected then
            self:Inspect(layout.inspected)
        end

        self.Super[BASE].UpdateLayout(self, layout)

        if not self._inspected then
            local sectors = ents.FindByClass("info_ff_sector")
            local sx, sy = self:GetShip():GetCoordinates()
            sx = math.floor(sx)
            sy = math.floor(sy)
            for _, sector in pairs(sectors) do
                local x, y = sector:GetCoordinates()
                x = math.floor(x)
                y = math.floor(y)
                if math.abs(x - sx) < 0.5 and math.abs(y - sy) < 0.5 then
                    self._sectorLabel.Text = sector:GetSectorName()
                    break
                end
            end

            self._inspectButton.CanClick = self._grid:GetCentreObject():GetObjectType() == objtype.ship
        end
    end
end


