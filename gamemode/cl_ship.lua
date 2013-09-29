local _mt = {}
_mt.__index = _mt

_mt._roomdict = nil
_mt._roomlist = nil
_mt._doorlist = nil

_mt._systems = nil

_mt._bounds = nil

_mt._nwdata = nil

_mt._valid = true

function _mt:IsCurrent()
    return self._valid and self:GetName() and IsGlobalTableCurrent(self:GetName())
        and self:GetBounds() and self:GetRange()
        and table.Count(self:GetRooms()) >= table.Count(self:GetRoomNames())
        and table.Count(self:GetDoors()) >= table.Count(self:GetDoorNames())
end

function _mt:IsValid()
    return self._valid
end

function _mt:GetName()
    return self._nwdata.name
end

function _mt:GetObject()
    return self._nwdata.object
end

function _mt:GetHazardMode()
    return self._nwdata.hazardmode
end

function _mt:IsObjectInRange(obj)
    local ox, oy = obj:GetCoordinates()
    local sx, sy = self:GetCoordinates()

    local range = self:GetRange()
    local sensor = self:GetSystem('sensors')
    if sensor and sensor:IsScanning() then
        range = sensor:GetActiveScanDistance()
    end
    return universe:GetDistance(ox, oy, sx, sy) <= range
end

function _mt:GetCoordinates()
    if self:GetObject() and self:GetObject():IsValid() then
        return self:GetObject():GetCoordinates()
    else
        return 0, 0
    end
end

function _mt:GetRotation()
    return self._nwdata.object:GetRotation()
end

function _mt:GetRotationRadians()
    return self._nwdata.object:GetRotationRadians()
end

function _mt:GetVel()
    return self._nwdata.object:GetVel()
end

function _mt:GetRange()
    return self._nwdata.range
end

function _mt:_UpdateBounds()
    local bounds = Bounds()
    for _, room in pairs(self:GetRooms()) do
        if not room:GetBounds() then return end
        bounds:AddBounds(room:GetBounds())
    end
    self._bounds = bounds
end

function _mt:GetBounds()
    return self._bounds
end

function _mt:GetOrigin()
    return self._nwdata.x, self._nwdata.y
end

function _mt:GetRoomNames()
    return self._nwdata.roomnames or {}
end

function _mt:_UpdateRooms()
    for index, name in pairs(self:GetRoomNames()) do
        if self._roomdict[name] then return end

        local room = Room(name, self, index)
        self._roomdict[name] = room
        self._roomlist[index] = room
    end
end

function _mt:GetRooms()
    return self._roomlist
end

function _mt:GetRoomByName(name)
    return self._roomdict[name]
end

function _mt:GetRoomByIndex(index)
    return self._roomlist[index]
end

function _mt:GetSystem(name)
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

function _mt:_UpdateDoors()
    for index, name in pairs(self:GetDoorNames()) do
        if self._doorlist[index] then return end
        
        self._doorlist[index] = Door(name, self, index)
    end
end

function _mt:AddDoor(door)
    self._doorlist[door:GetIndex()] = door
end

function _mt:GetDoorNames()
    return self._nwdata.doornames or {}
end

function _mt:GetDoors()
    return self._doorlist
end

function _mt:GetDoorByIndex(index)
    return self._doorlist[index]
end

function _mt:GetDoorByName(name)
    for _, door in pairs(self:GetDoors()) do
        if door:GetName() == name then return door end
    end
    return nil
end

function _mt:FindTransform(screen, x, y, width, height)
    local bounds = Bounds(x, y, width, height)
    return FindBestTransform(self:GetBounds(), bounds, true, true)
end

function _mt:ApplyTransform(transform)
    for _, room in pairs(self:GetRooms()) do
        room:ApplyTransform(transform)
    end

    for _, door in ipairs(self:GetDoors()) do
        door:ApplyTransform(transform)
    end
end

function _mt:Think()
    if not self._valid then return end

    if table.Count(self:GetRooms()) < table.Count(self:GetRoomNames()) then
        self:_UpdateRooms()
    end

    if table.Count(self:GetDoors()) < table.Count(self:GetDoorNames()) then
        self:_UpdateDoors()
    end

    if not self:GetBounds() and table.Count(self:GetRoomNames()) > 0 and
        table.Count(self:GetRooms()) == table.Count(self:GetRoomNames()) then
        self:_UpdateBounds()
    end

    for _, room in pairs(self:GetRooms()) do
        room:Think()
    end

    for _, door in ipairs(self:GetDoors()) do
        door:Think()
    end

    local ply = LocalPlayer()
    if self == ply:GetShip() then
        if self:GetHazardMode() and not ply._hazardalarm then
            local sound = CreateSound(ply, "ambient/alarms/apc_alarm_loop1.wav")
            sound:PlayEx(0.25, 100)
            ply._hazardalarm = sound
            ply._hazardship = self
        elseif ply._hazardalarm and (not self:GetHazardMode() or ply._hazardship ~= self) then
            ply._hazardalarm:FadeOut(1)
            ply._hazardalarm = nil
            ply._hazardship = nil
        end
    end
end

function _mt:Remove()
    self._valid = false
    ForgetGlobalTable(self:GetName())

    for _, room in pairs(self:GetRooms()) do
        room:Remove()
    end

    for _, door in ipairs(self:GetDoors()) do
        door:Remove()
    end
end

local ply_mt = FindMetaTable("Player")
function ply_mt:GetShipName()
    return self:GetNWString("ship")
end

function ply_mt:GetShip()
    if not self:GetNWString("ship") then return nil end
    return ships.GetByName(self:GetNWString("ship"))
end

function Ship(name)
    local ship = {}

    ship._roomdict = {}
    ship._roomlist = {}
    ship._doorlist = {}

    ship._systems = {}

    ship._nwdata = GetGlobalTable(name)
    ship._nwdata.name = name

    return setmetatable(ship, _mt)
end
