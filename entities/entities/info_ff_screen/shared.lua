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

local SCREEN_DRAWSCALE = 16

local UPDATE_FREQ = 0.5
local CURSOR_UPDATE_FREQ = 0.25
local MAX_USE_DISTANCE = 64

local MAIN_GUI_CLASS = "screen"

local ALARM_TIME = 120

ENT.Type = "anim"
ENT.Base = "base_anim"
    
ENT._ship = nil
ENT._room = nil

ENT._ui = nil
ENT._layout = nil

function ENT:SetupDataTables()
    self:NetworkVarElement("Vector", 0, "x", "AlarmCountingDown")
    self:NetworkVarElement("Vector", 0, "y", "AlarmCountStartTime")
    self:NetworkVarElement("Vector", 0, "z", "AlarmCountInitialTime")

    self:NetworkVarElement("Vector", 1, "x", "Width")
    self:NetworkVarElement("Vector", 1, "y", "Height")

    self:NetworkVarElement("Vector", 2, "x", "CursorX")
    self:NetworkVarElement("Vector", 2, "y", "CursorY")

    self:NetworkVar("String", 0, "ShipName")
    self:NetworkVar("String", 1, "RoomName")

    self:NetworkVar("Bool", 0, "BeingUsed")

    self:NetworkVar("Entity", 0, "UsingPlayer")

    self._layout = self:NetworkTable(0, "Layout")
end

function ENT:GetShip()
    return self._ship
end

function ENT:GetRoom()
    return self._room
end

function ENT:GetLayout()
    return self._layout
end

function ENT:GetUIRoot()
    return self._ui
end

function ENT:IsAlarmCountingDown()
    return self:GetAlarmCountingDown() ~= 0
end

function ENT:GetAlarmCounter()
    return math.max(0, self:GetAlarmCountInitialTime() - CurTime() + self:GetAlarmCountStartTime())
end

function ENT:GetFormattedAlarmCounter()
    if self:IsAlarmCountingDown() then
        return "T-" .. FormatNum(self:GetAlarmCounter(), 1, 0) .. "s"
    else
        return ""
    end
end

if SERVER then
    local enableSounds = {
        "buttons/button9.wav"
    }

    local disableSounds = {
        "buttons/blip1.wav"
    }

    util.AddNetworkString("CursorPos")
    
    ENT._roomName = nil

    ENT._lastPage = page.ACCESS

    ENT.OverrideNodeCount = 6
    ENT.OverrideTimePerNode = 0.5

    ENT.OverrideNodePositions = nil
    ENT.OverrideGoalSequence = nil
    ENT.OverrideCurrSequence = nil

    ENT.NextGUIID = 1
    ENT.FreeGUIIDs = nil

    function ENT:KeyValue(key, value)
        if key == "room" then
            self._roomName = tostring(value)
        elseif key == "width" then
            self:SetWidth(tonumber(value) * SCREEN_DRAWSCALE)
        elseif key == "height" then
            self:SetHeight(tonumber(value) * SCREEN_DRAWSCALE)
        end
    end
    
    function ENT:Initialize()
        self:DrawShadow(false)
    end

    function ENT:InitPostEntity()
        if self._roomName then
            local rooms = ents.FindByName(self._roomName)
            if #rooms > 0 then
                self._room = rooms[1]
                self._room:AddScreen(self)
                self._ship = self._room:GetShip()
            end
        end
        
        if not self._room then
            Error("Screen at " .. tostring(self:GetPos()) .. " (" .. self:GetName() .. ") has no room!\n")
            return
        end

        self:SetShipName(self._room:GetShipName())
        self:SetRoomName(self._roomName)
        self:SetBeingUsed(false)
        self:SetUsingPlayer(nil)

        self:GenerateOverrideSequence()
        self:ShuffleCurrentOverrideSequence()

        self.FreeGUIIDs = {}

        self._ui = sgui.Create(self, MAIN_GUI_CLASS)
        self._ui:AllocateNewID()
        self:UpdateLayout()
    end

    function ENT:FreeGUIID(id)
        if id == self.NextGUIID - 1 then
            self.NextGUIID = id
            while #self.FreeGUIIDs > 0 and self.FreeGUIIDs[#self.FreeGUIIDs] == id - 1 do
                table.remove(self.FreeGUIIDs, #self.FreeGUIIDs)
                id = id - 1
                self.NextGUIID = id
            end
        else
            table.insert(self.FreeGUIIDs, id)
        end
    end

    function ENT:GenerateOverrideNodePositions(bounds)
        self.OverrideNodePositions = {}
        local left, top, width, height = bounds:GetRect()
        for i = 1, self.OverrideNodeCount do
            local bestScore = 0
            local bestx, besty
            for j = 1, 1024 do
                local x = left + math.random() * width
                local y = top + math.random() * height
                local min = width * width + height * height
                for k, pos in pairs(self.OverrideNodePositions) do
                    local xd, yd = pos.x - x, pos.y - y
                    local d2 = xd * xd + yd * yd
                    if d2 < min then
                        min = d2
                    end
                end
                if min >= bestScore then
                    bestScore = min
                    bestx = x
                    besty = y
                end
            end
            self.OverrideNodePositions[i] = { x = bestx, y = besty }
        end
        table.sort(self.OverrideNodePositions, function(a, b)
            return b.x > a.x
        end)
    end

    function ENT:GenerateOverrideSequence()
        local temp = {}
        for i = 1, self.OverrideNodeCount do
            table.insert(temp, i)
        end

        table.remove(temp, math.random(#temp))

        self.OverrideGoalSequence = {}
        self.OverrideCurrSequence = {}
        while #temp > 0 do
            local index = math.random(#temp)
            table.insert(self.OverrideGoalSequence, temp[index])
            table.insert(self.OverrideCurrSequence, temp[index])
            table.remove(temp, index)
        end
    end

    function ENT:SwapOverrideNodes(index)
        if index < 1 or index > #self.OverrideCurrSequence then return end
        for i = 1, self.OverrideNodeCount do
            if not table.HasValue(self.OverrideCurrSequence, i) then
                self.OverrideCurrSequence[index] = i
                break
            end
        end
    end

    function ENT:GetCurrentOverrideSequenceScore()
        local correct = 0
        for i = 1, #self.OverrideGoalSequence do
            if self.OverrideGoalSequence[i] == self.OverrideCurrSequence[i] then
                correct = correct + 1
            end
        end
        return correct
    end

    function ENT:IsOverrideWellShuffled(score)
        score = score or self:GetCurrentOverrideSequenceScore()
        local limit = 0
        return self:GetCurrentOverrideSequenceScore() <= limit
    end

    function ENT:CloneCurrentOverrideSequence()
        local clone = {}
        for i, v in ipairs(self.OverrideCurrSequence) do
            clone[i] = v
        end
        return clone
    end

    function ENT:ShuffleCurrentOverrideSequence()
        local tries = 0
        local best = self:CloneCurrentOverrideSequence()
        local bestScore = self:GetCurrentOverrideSequenceScore()
        while tries < 256 do
            self:SwapOverrideNodes(math.random(1, #self.OverrideCurrSequence))

            if tries >= 2 * #self.OverrideCurrSequence then
                local score = self:GetCurrentOverrideSequenceScore()
                if self:IsOverrideWellShuffled(score) then
                    return
                elseif score < bestScore then
                    best = self:CloneCurrentOverrideSequence()
                    bestScore = score
                end
            end

            tries = tries + 1
        end

        self.OverrideCurrSequence = best
    end

    function ENT:SetOverrideSequence()
        for i, v in ipairs(self.OverrideCurrSequence) do
            self.OverrideGoalSequence[i] = v
        end
    end

    function ENT:SetIsAlarmCountingDown(val)
        self:SetAlarmCountingDown(val and 1 or 0)
    end

    function ENT:StartAlarmCountdown()
        if self:GetAlarmCountInitialTime() > 0 then return end

        self:SetIsAlarmCountingDown(true)
        self:SetAlarmCountStartTime(CurTime())
        self:SetAlarmCountInitialTime(ALARM_TIME)
    end

    function ENT:StopAlarmCountdown()
        self:SetIsAlarmCountingDown(false)
        self:SetAlarmCountStartTime(0)
        self:SetAlarmCountInitialTime(0)
    end

    function ENT:PauseAlarmCountdown()
        self:SetAlarmCountInitialTime(self:GetAlarmCounter())
        if self:GetAlarmCountInitialTime() <= 0 then 
            self:StopAlarmCountdown()
            return
        end
        self:SetIsAlarmCountingDown(false)
        self:SetAlarmCountStartTime(0)
    end

    function ENT:UnpauseAlarmCountdown()
        if self:GetAlarmCountInitialTime() <= 0 then return end
        if self:IsAlarmCountingDown() then return end

        self:SetIsAlarmCountingDown(true)
        self:SetAlarmCountStartTime(CurTime())
    end

    function ENT:UpdateLayout()
        if not self._ui then return end

        self._ui:UpdateLayout(self._layout)
        self._layout:Update()
    end

    function ENT:Think()
        if self:GetBeingUsed() then
            if self:IsAlarmCountingDown() and self:GetAlarmCounter() <= 0 then
                self:GetShip():SetHazardMode(true, 10)
                self:StopAlarmCountdown()
            end

            local ply = self:GetUsingPlayer()
            if not ply:IsValid() or not ply:Alive() or self:GetPos():Distance(ply:EyePos()) > MAX_USE_DISTANCE
                or self:GetAngles():Forward():Dot(ply:GetAimVector()) >= 0 then
                self:StopUsing()
            end
        end
    end
    
    function ENT:Use(activator, caller)
        if activator:IsPlayer() then
            if not self:GetBeingUsed() and self:GetPos():Distance(activator:EyePos()) <= MAX_USE_DISTANCE then
                self:StartUsing(activator)
            elseif self:GetUsingPlayer() == activator then
                self:StopUsing()
            end
        end
    end
    
    function ENT:StartUsing(ply)
        if self:GetBeingUsed() then return end
        if not IsValid(ply) then return end

        self:SetBeingUsed(true)
        self:SetUsingPlayer(ply)

        ply:SetUsingScreen(true)
        ply:SetCurrentScreen(self)
        ply:SetOldWeapon(ply:GetActiveWeapon())
        
        ply:SetWalkSpeed(50)
        ply:SetCanWalk(false)
        ply:CrosshairDisable()
        ply:Give("weapon_ff_unarmed")
        ply:SelectWeapon("weapon_ff_unarmed")

        if not self._room:HasPlayerWithSecurityPermission() then
            self._ui.Permission = permission.SECURITY
        else
            self._ui.Permission = ply:GetPermission(self._room)
        end

        self._ui:UpdatePermissions()

        if (self._lastPage == page.SECURITY and not ply:HasPermission(self._room, permission.SECURITY))
            or (self._lastPage == page.SYSTEM and not ply:HasPermission(self._room, permission.SYSTEM)) then
            self._lastPage = page.ACCESS
        end

        if ply:HasPermission(self._room, permission.SECURITY) then
            self:StopAlarmCountdown()
        end

        self._ui:SetCurrentPageIndex(self._lastPage)
        self:UpdateLayout()

        if self._room:HasSystem() then
            self._room:GetSystem():StartControlling(self, ply)
        end

        self:EmitSound(table.Random(enableSounds), 95, 100)
    end
    
    function ENT:StopUsing()
        if not self:GetBeingUsed() then return end

        self:SetBeingUsed(false)
        
        local ply = self:GetUsingPlayer()
        if IsValid(ply) then
            ply:SetUsingScreen(false)
            local oldWep = ply:GetOldWeapon()
            if oldWep and oldWep:IsValid() then
                ply:SetActiveWeapon(oldWep)
            end
            
            ply:StripWeapon("weapon_ff_unarmed")
            
            ply:SetWalkSpeed(175)
            ply:SetCanWalk(true)
            ply:CrosshairEnable()
        end

        self._lastPage = self._ui:GetCurrentPageIndex()
        self._ui:SetCurrentPageIndex(page.STATUS)
        self:UpdateLayout()

        if self._room:HasSystem() then
            self._room:GetSystem():StopControlling(self, ply)
        end

        self:EmitSound(table.Random(disableSounds), 75, 100)
    end

    function ENT:GetCursorPos()
        return self:GetCursorX(), self:GetCursorY()
    end

    function ENT:Click(button)
        if self._ui then
            self._ui:Click(self:GetCursorPos())
        end
    end

    net.Receive("CursorPos", function(len, ply)
        local screen = net.ReadEntity()
        if screen:GetUsingPlayer() == ply then
            screen:SetCursorX(net.ReadFloat())
            screen:SetCursorY(net.ReadFloat())
        end
    end)
elseif CLIENT then
    ENT._using = false

    ENT._lastCursorUpdate = 0
    ENT._cursorx = 0
    ENT._cursory = 0
    ENT._lastCursorx = 0
    ENT._lastCursory = 0
    ENT._nextCursorx = 0
    ENT._nextCursory = 0
    
    function ENT:UpdateLayout()        
        if not self._layout:IsCurrent() then return end
        if not self._ship or not self._ship:IsCurrent() then return end
        if not self._room or not self._room:IsCurrent() then return end

        if not self._ui then
            self._ui = sgui.Create(self, MAIN_GUI_CLASS)
        end

        self._ui:UpdateLayout(self._layout)
    end

    function ENT:Think()
        if self._ship and not self._ship:IsValid() then
            self._ship = nil
            self._room = nil
        end

        if not self._ship and self:GetShipName() and string.len(self:GetShipName()) > 0 then
            self._ship = ships.GetByName(self:GetShipName())
        end

        if not self._room and self._ship and self:GetRoomName() and string.len(self:GetRoomName()) > 0 then
            self._room = self._ship:GetRoomByName(self:GetRoomName())
        end

        self:UpdateLayout()
        
        if not self._using and self:GetBeingUsed() and self:GetUsingPlayer() == LocalPlayer() then
            self._using = true
        elseif self._using and (not self:GetBeingUsed() or self:GetUsingPlayer() ~= LocalPlayer()) then
            self._using = false
        end
    end

    function ENT:GetCursorPos()
        return self._cursorx, self._cursory
    end

    function ENT:FindCursorPosition()
        if self._using then
            local ang = self:GetAngles()
            local ply = LocalPlayer()
            local p0 = self:GetPos()
            local n = ang:Forward()
            local l0 = ply:GetShootPos()
            local l = ply:GetAimVector()
            
            local d = (p0 - l0):Dot(n) / l:Dot(n)
        
            local hitpos = (l0 + l * d) - p0
            local xvec = ang:Right()
            local yvec = ang:Up()
            
            self._cursorx = -hitpos:DotProduct(xvec) * SCREEN_DRAWSCALE
            self._cursory = -hitpos:DotProduct(yvec) * SCREEN_DRAWSCALE
            
            local curTime = CurTime()
            if (curTime - self._lastCursorUpdate) > CURSOR_UPDATE_FREQ then
                net.Start("CursorPos")
                    net.WriteEntity(self)
                    net.WriteFloat(self._cursorx)
                    net.WriteFloat(self._cursory)
                net.SendToServer()
                self._lastCursorUpdate = curTime
            end
        else
            local cx, cy = self:GetCursorPos()
            
            if cx ~= self._lastCursorx or cy ~= self._lastCursory then
                local t = (CurTime() - self._lastCursorUpdate) / CURSOR_UPDATE_FREQ
                
                if t >= 1 then
                    self._lastCursorx = self._nextCursorx
                    self._lastCursory = self._nextCursory
                    self._cursorx = self._nextCursorx
                    self._cursory = self._nextCursory
                    self._nextCursorx = cx
                    self._nextCursory = cy
                    self._lastCursorUpdate = CurTime()
                else
                    self._cursorx = self._lastCursorx + (self._nextCursorx - self._lastCursorx) * t
                    self._cursory = self._lastCursory + (self._nextCursory - self._lastCursory) * t
                end
            end
        end
    end
    
    function ENT:DrawCursor()
        local halfwidth = self:GetWidth() * 0.5
        local halfheight = self:GetHeight() * 0.5
        
        local boxSize = SCREEN_DRAWSCALE
        
        local x = self._cursorx
        local y = self._cursory
        
        x = math.Clamp(x, -halfwidth + boxSize * 0.5, halfwidth - boxSize * 0.5)
        y = math.Clamp(y, -halfheight + boxSize * 0.5, halfheight - boxSize * 0.5)
        
        surface.SetDrawColor(Color(255, 255, 255, 16))
        surface.DrawLine(x, -halfheight, x, halfheight)
        surface.DrawLine(-halfwidth, y, halfwidth, y)
        
        surface.SetDrawColor(Color(255, 255, 255, 64))
        surface.DrawOutlinedRect(x - boxSize * 0.5, y - boxSize * 0.5, boxSize, boxSize)
    end

    function ENT:Draw()
        local ang = self:GetAngles()
        ang:RotateAroundAxis(ang:Up(), 90)
        ang:RotateAroundAxis(ang:Forward(), 90)
        
        draw.NoTexture()
        
        cam.Start3D2D(self:GetPos(), ang, 1 / SCREEN_DRAWSCALE)
        if self._ui then
            self._ui:Draw()
        end
        if self:GetBeingUsed() then
            self:FindCursorPosition()
            self:DrawCursor()
        end
        cam.End3D2D()
    end

    function ENT:Click(button)
        if self._ui then
            local x, y = self:GetCursorPos()
            self._ui:Click(x, y, button)
        end
    end
end
