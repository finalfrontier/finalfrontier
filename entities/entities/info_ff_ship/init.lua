ENT.Type = "point"
ENT.Base = "base_point"

ENT._roomdict = nil
ENT._roomlist = nil
ENT._doors = nil
ENT._bounds = nil

ENT._defaultGrids = nil

ENT._systems = nil

ENT._players = nil

ENT._nwdata = nil
ENT._object = nil

ENT._mainLightName = nil
ENT._warnLightName = nil

ENT._mainLights = nil
ENT._warnLights = nil

ENT._hazardEnd = 0

function ENT:KeyValue(key, value)
    if key == "health" then
        self:_SetBaseHealth(tonumber(value))
    elseif key == "mainlight" then
        self._mainLightName = tostring(value)
    elseif key == "warnlight" then
        self._warnLightName = tostring(value)
    end
end

function ENT:Initialize()
    self._roomdict = {}
    self._roomlist = {}
    self._doors = {}
    self._bounds = Bounds()

    self._systems = {}

    self._players = {}

    if not self._nwdata then
        self._nwdata = {}
    end

    self._nwdata.roomnames = {}
    self._nwdata.doornames = {}

    self._nwdata.name = self:GetName()
    self._nwdata.range = 0.25

    self._nwdata.hazardmode = true

    if not self:GetBaseHealth() then
        self:_SetBaseHealth(1)
    end

    self._defaultGrid = GenerateModuleGrid()
end

function ENT:GetDefaultGrid()
    return self._defaultGrid
end

function ENT:GetObject()
    return self._nwdata.object
end

function ENT:IsObjectInRange(obj)
    local ox, oy = obj:GetCoordinates()
    local sx, sy = self:GetCoordinates()
    return universe:GetDistance(ox, oy, sx, sy) <= self:GetRange()
end

function ENT:GetCoordinates()
    return self._nwdata.object:GetCoordinates()
end

function ENT:GetRotation()
    return self._nwdata.object:GetRotation()
end

function ENT:GetRotationRadians()
    return self._nwdata.object:GetRotationRadians()
end

function ENT:GetVel()
    return self._nwdata.object:GetVel()
end

function ENT:GetRange()
    return self._nwdata.range
end

function ENT:SetRange(range)
    self._nwdata.range = value
    self:_UpdateNWData()
end

function ENT:InitPostEntity()
    self._nwdata.object = ents.Create("info_ff_object")
    self._nwdata.object:SetCoordinates(5 + math.random() * 0.2 - 0.1, 9 + math.random() * 0.2 - 0.1)
    self._nwdata.object:SetRotation(38)
    -- self._nwdata.object:SetVel(math.cos(self:GetRotationRadians()) * 0.2, -math.sin(self:GetRotationRadians()) * 0.2)
    self._nwdata.object:SetObjectType(objtype.ship)
    self._nwdata.object:SetObjectName(self:GetName())
    self._nwdata.object:Spawn()
    self:_UpdateNWData()

    self._mainLights = ents.FindByName(self._mainLightName)
    self._warnLights = ents.FindByName(self._warnLightName)

    ships.Add(self)

    self:SetHazardMode(false)
end

function ENT:Think()
    if self:GetHazardMode() and CurTime() > self._hazardEnd then
        self:SetHazardMode(false)
    end
end

function ENT:SetHazardMode(value, duration)
    if value and CurTime() + duration > self._hazardEnd then
        self._hazardEnd = CurTime() + duration
    end

    if self._nwdata.hazardmode ~= value then
        self._nwdata.hazardmode = value
        self:_UpdateNWData()

        for _, light in pairs(self._mainLights) do
            if value then
                light:Fire("turnoff", "", 0)
            else
                light:Fire("turnon", "", 0)
            end
        end

        for _, light in pairs(self._warnLights) do
            if value then
                light:Fire("turnon", "", 0)
            else
                light:Fire("turnoff", "", 0)
            end
        end
    end
end

function ENT:GetHazardMode()
    return self._nwdata.hazardmode
end

function ENT:GetBounds()
    return self._bounds
end

function _mt:GetOrigin()
    return self._nwdata.x, self._nwdata.y
end

function ENT:_SetBaseHealth(health)
    if not self._nwdata then self._nwdata = {} end

    self._nwdata.basehealth = health
    self:_UpdateNWData()
end

function ENT:GetBaseHealth()
    return self._nwdata.basehealth
end

function ENT:AddRoom(room)
    local name = room:GetName()
    if not name or self:GetRoomByName(name) then return end

    self._roomdict[name] = room
    table.insert(self._roomlist, room)
    self:GetBounds():AddBounds(room:GetBounds())
    
    room:SetIndex(#self._roomlist)

    self._nwdata.roomnames[room:GetIndex()] = name
    self:_UpdateNWData()
end

function ENT:GetRoomNames()
    return self._nwdata.roomnames
end

function ENT:GetRooms()
    return self._roomlist
end

function ENT:GetRoomByName(name)
    return self._roomdict[name]
end

function ENT:GetRoomByIndex(index)
    return self._roomlist[index]
end

function ENT:GetSystem(name)
    if not self._systems[name] then
        for _, room in pairs(self._roomlist) do
            if room:GetSystemName() == name then
                self._systems[name] = room:GetSystem()
                return room:GetSystem()
            end
        end
    end

    return self._systems[name]
end

function ENT:AddDoor(door)
    if not table.HasValue(self._doors, door) then
        table.insert(self._doors, door)
        door:SetIndex(#self._doors)

        self._nwdata.doornames[door:GetIndex()] = door:GetName()
        self:_UpdateNWData()
    end
end

function ENT:GetDoorNames()
    return self._nwdata.doornames
end

function ENT:GetDoors()
    return self._doors
end

function ENT:GetDoorByIndex(index)
    return self._doors[index]
end

local ply_mt = FindMetaTable("Player")
function ply_mt:SetShip(ship)
    if self._ship == ship then return end
    if self._ship then
        self._ship:_RemovePlayer(self)
    end
    ship:_AddPlayer(self)
    self._ship = ship
    self:SetNWString("ship", ship:GetName())
end

function ply_mt:GetShip()
    return self._ship
end

function ENT:_AddPlayer(ply)
    if not table.HasValue(self._players, ply) then
        table.insert(self._players, ply)
    end
end

function ENT:_RemovePlayer(ply)
    if table.HasValue(self._players, ply) then
        table.remove(self._players, table.KeyFromValue(self._players, ply))
    end
end

function ENT:IsPointInside(x, y)
    return self:GetBounds():IsPointInside(x, y)
end

function ENT:_UpdateNWData()
    SetGlobalTable(self:GetName(), self._nwdata)
end
