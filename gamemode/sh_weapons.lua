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

if SERVER then AddCSLuaFile("sh_weapons.lua") end

if not weapon then
    weapon = {}
    weapon._dict = {}
    weapon._spawnable = {}
else return end

local _mt = {}
_mt.__index = _mt

_mt._tier = 0

_mt.BaseName = nil
_mt.Base = nil

_mt.Name = nil
_mt.MaxTier = 1

_mt.CanSpawn = false
_mt.Frequency = 100

_mt.LaunchSound = "weapons/rpg/rocketfire1.wav"

if CLIENT then
    _mt.Icon = Material("systems/noicon.png", "smooth")
end

function _mt:GetMaxPower() return 0 end
function _mt:GetMaxCharge() return 0 end
function _mt:GetShotCharge() return 0 end

function _mt:GetTier() return self._tier end

if SERVER then
    function _mt:OnHit(room) return end
elseif CLIENT then
    function _mt:GetFullName() return "unnamed" end
    function _mt:GetTierName()
        return "Mk " .. tostring(self:GetTier())
    end
    function _mt:GetColor() return Color(255, 255, 255, 255) end
end

MsgN("Loading weapons...")
local files = file.Find("finalfrontier/gamemode/weapons/*.lua", "LUA")
for i, file in ipairs(files) do
    local name = string.sub(file, 0, string.len(file) - 4)
    if SERVER then AddCSLuaFile("weapons/" .. file) end

    MsgN("- " .. name)

    WPN = { Name = name }
    WPN.__index = WPN
    WPN.Super = {}
    WPN.Super.__index = WPN.Super
    WPN.Super[name] = WPN
    
    include("weapons/" .. file)

    if not weapon._dict[name] and WPN.CanSpawn then
        table.insert(weapon._spawnable, WPN)
    end

    weapon._dict[name] = WPN

    WPN = nil
end

for _, WPN in pairs(weapon._dict) do
    if WPN.BaseName then
        WPN.Base = weapon._dict[WPN.BaseName]
        setmetatable(WPN, WPN.Base)
        setmetatable(WPN.Super, WPN.Base.Super)
    else
        setmetatable(WPN, _mt)
    end
end

function weapon.GetRandomName()
    local tot = 0
    for _, wpn in ipairs(weapon._spawnable) do
        tot = tot + wpn.Frequency
    end

    local i = math.random() * tot
    for _, wpn in ipairs(weapon._spawnable) do
        i = i - wpn.Frequency
        if i <= 0 then return wpn.Name end
    end
end

function weapon.GetRandomTier(name)
    local wpn = weapon._dict[name]
    return 1 + math.floor(math.pow(math.random(), 3) * wpn.MaxTier)
end

function weapon.Create(name, tier)
    name = name or weapon.GetRandomName()
    local wpn = weapon._dict[name]
    if wpn then
        tier = tier or weapon.GetRandomTier(name)
        return setmetatable({ _tier = tier }, wpn)
    end
    return nil
end

if SERVER then
    local function missilePhysicsSimulate(ent, phys, delta)
        local dx, dy = 0, 0
            
        if not IsValid(ent._target) then
            return Vector(0, 0, 0), Vector(0, 0, 0), SIM_GLOBAL_ACCELERATION
        end

        local speed = ent._weapon:GetSpeed()
        
        local mx, my = ent:GetCoordinates()
        local tx, ty = ent._target:GetCoordinates()

        dx, dy = universe:GetDifference(mx, my, tx, ty)

        if (ent._target ~= ent._owner:GetObject() or CurTime() - ent._shootTime > 1)
            and dx * dx + dy * dy < 1 / (64 * 64) then
            ent._weapon:Hit(ent._target, ent:GetCoordinates())
            ent:Remove()

            return Vector(0, 0, 0), Vector(0, 0, 0), SIM_NOTHING
        end

        local vx, vy = ent._target:GetVel()
        local dist = math.sqrt(dx * dx + dy * dy)
        local dt = dist / speed

        dx = dx + (vx - ent._basedx) * dt
        dy = dy + (vy - ent._basedy) * dt

        local len = math.sqrt(dx * dx + dy * dy)

        if len > 0 then
            dx = dx / len * speed
            dy = dy / len * speed
        end

        vx, vy = ent:GetVel()

        vx = vx - ent._basedx
        vy = vy - ent._basedy

        ent:SetTargetRotation(math.atan2(vy, vx) / math.pi * 180)

        local a = ent._weapon:GetLateral()

        local ax = math.sign(dx - vx) * math.max(0, math.abs(dx - vx)) * a
        local ay = math.sign(dy - vy) * math.max(0, math.abs(dy - vy)) * a

        local acc = universe:GetWorldPos(ax, ay) - universe:GetWorldPos(0, 0)

        return Vector(0, 0, 0), acc, SIM_GLOBAL_ACCELERATION
    end

    function weapon.LaunchMissile(ship, wpn, target, rot)
        local vx, vy = ship:GetObject():GetVel()

        local missile = ents.Create("info_ff_object")
        missile._owner = ship
        missile._weapon = wpn
        missile._target = target
        missile._shootTime = CurTime()
        missile._basedx = vx
        missile._basedy = vy

        missile:SetObjectType(objtype.MISSILE)
        missile:SetCoordinates(ship:GetCoordinates())
        missile.PhysicsSimulate = missilePhysicsSimulate

        missile:Spawn()

        local rad = rot * math.pi / 180
        missile:SetRotation(rot)
        missile:SetMaxAngularVel(180)
        missile:SetVel(math.cos(rad) * wpn:GetSpeed() + vx, math.sin(rad) * wpn:GetSpeed() + vy)

        timer.Simple(wpn:GetLifeTime(), function()
            if IsValid(missile) then missile:Remove() end
        end)

        return missile
    end
end
