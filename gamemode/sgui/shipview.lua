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

local BASE = "container"

GUI.BaseName = BASE

GUI._ship = nil
if CLIENT then
    GUI._shipSynced = false
end

GUI._rooms = nil
GUI._doors = nil

GUI._canClickRooms = false
GUI._canClickDoors = false

if SERVER then
    GUI._roomOnClickHandler = nil
    GUI._doorOnClickHandler = nil
elseif CLIENT then
    GUI._roomColourFunction = nil
end

function GUI:GetCanClickRooms()
    return self._canClickRooms
end

function GUI:SetCanClickRooms(canClick)
    self._canClickRooms = canClick
    self:_UpdateElements()
end

function GUI:GetCanClickDoors()
    return self._canClickDoors
end

function GUI:SetCanClickDoors(canClick)
    self._canClickDoors = canClick
    self:_UpdateElements()
end

function GUI:GetCurrentShip()
    return self._ship
end

if SERVER then
    function GUI:SetRoomOnClickHandler(func)
        self._roomOnClickHandler = func
        self:_UpdateElements()
    end

    function GUI:SetDoorOnClickHandler(func)
        self._doorOnClickHandler = func
        self:_UpdateElements()
    end
elseif CLIENT then
    function GUI:SetRoomColourFunction(func)
        self._roomColourFunction = func
        self:_UpdateElements()
    end
end

function GUI:SetCurrentShip(ship)
    if self._ship == ship then return end

    self._ship = ship

    if CLIENT then
        self._shipSynced = false
    end

    if not ship then
        self:RemoveAllChildren()

        self._rooms = nil
        self._doors = nil
    else
        self._doors = {}
        self._rooms = {}

        if SERVER or ship:IsCurrent() then
            self:_SetupShip()
        end
    end
end

function GUI:_SetupShip()
    for i, door in ipairs(self._ship:GetDoors()) do
        local doorview = sgui.Create(self, "doorview")
        doorview:SetCurrentDoor(door)
        self._doors[i] = doorview
    end

    for i, room in ipairs(self._ship:GetRooms()) do
        local roomview = sgui.Create(self, "roomview")
        roomview:SetCurrentRoom(room)
        self._rooms[i] = roomview
    end

    if CLIENT then
        self._shipSynced = true
        self:FindTransform()
    end

    self:_UpdateElements()
end

function GUI:_UpdateElements()
    if CLIENT and not self._shipSynced then return end

    for i, door in ipairs(self._doors) do
        door.Enabled = self._canClickDoors
        door.NeedsPermission = not self._canClickDoors

        if SERVER then
            if self._canClickDoors and self._doorOnClickHandler then
                door.OnClick = self._doorOnClickHandler
            end
        end
    end

    for i, room in ipairs(self._rooms) do
        room.CanClick = self._canClickRooms

        if SERVER then
            if self._canClickRooms and self._roomOnClickHandler then
                room.OnClick = self._roomOnClickHandler
            end
        elseif CLIENT and self._roomColourFunction then
            room.GetRoomColor = self._roomColourFunction
        end
    end
end

function GUI:GetRoomElements()
    return self._rooms
end

function GUI:GetDoorElements()
    return self._doors
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if self._ship then
            layout.ship = self._ship:GetName()
        else
            layout.ship = nil
        end
    end
end

if CLIENT then
    GUI._transform = nil

    function GUI:SetBounds(bounds)
        self.Super[BASE].SetBounds(self, bounds)
        self:FindTransform()
    end

    function GUI:FindTransform()
        if not self._ship or not self._shipSynced then return end

        self:ApplyTransform(FindBestTransform(self._ship:GetBounds(),
            self:GetGlobalBounds(), true, true))
    end

    function GUI:ApplyTransform(transform)
        if self._transform == transform or not self._ship or not self._shipSynced then return end

        self._transform = transform

        for _, room in pairs(self._rooms) do
            room:ApplyTransform(transform, true)
        end

        for _, door in pairs(self._doors) do
            door:ApplyTransform(transform)
        end
    end

    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        if layout.ship then
            if not self._ship or self._ship:GetName() ~= layout.ship then
                self:SetCurrentShip(ships.GetByName(layout.ship))
            end
        else
            self._ship = nil
        end

        if self._ship and not self._shipSynced and self._ship:IsCurrent() then
            self:_SetupShip()
        end
    end
end
