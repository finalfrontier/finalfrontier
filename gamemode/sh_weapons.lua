if SERVER then AddCSLuaFile("sh_weapons.lua") end

if not weapon then
    weapon = {}
    weapon._dict = {}
else return end

local _mt = {}
_mt.__index = _mt

_mt._tier = 0

_mt.BaseName = nil
_mt.Base = nil

_mt.Name = nil
_mt.MaxTier = 1

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

function weapon.Create(name, tier)
    if weapon._dict[name] then
        tier = tier or (1 + math.floor(math.random() * weapon._dict[name].MaxTier))
        return setmetatable({ _tier = tier }, weapon._dict[name])
    end
    return nil
end

if SERVER then
    local function missilePhysicsSimulate(ent, phys, delta)
        local dx, dy = 0, 0
        if ent._target then
            local mx, my = ent:GetCoordinates()
            local tx, ty = ent._target:GetCoordinates()
            dx, dy = universe:GetDifference(mx, my, tx, ty)

            if (ent._target ~= ent._owner or CurTime() - ent._shootTime > 1)
                and dx * dx + dy * dy < 1 / (128 * 128) then
                ent._weapon:Hit(ent._target, ent:GetCoordinates())
                ent:Remove()
            end

            local dest = math.atan2(dy, dx)
            local curr = ent:GetRotation() * math.pi / 180
            local diff = FindAngleDifference(dest, curr)
            local newr = (curr + math.sign(diff) * ent._weapon:GetLateral() * delta) / math.pi * 180

            ent:SetRotation(newr)
            ent:SetTargetRotation(newr)
        end
        local ang = ent:GetRotation() * math.pi / 180
        local speed = ent._weapon:GetSpeed()
        dx = math.cos(ang) * speed
        dy = math.sin(ang) * speed
        local vel = universe:GetWorldPos(dx, dy) - universe:GetWorldPos(0, 0)
        return Vector(0, 0, 0), vel - phys:GetVelocity(), SIM_GLOBAL_ACCELERATION
    end

    function weapon.LaunchMissile(ship, wpn, target, rot)
        local missile = ents.Create("info_ff_object")
        missile._owner = ship
        missile._weapon = wpn
        missile._target = target
        missile._shootTime = CurTime()
        missile:SetObjectType(objtype.missile)
        missile:SetCoordinates(ship:GetCoordinates())
        missile.PhysicsSimulate = missilePhysicsSimulate

        missile:Spawn()

        local rad = rot * math.pi / 180
        missile:SetRotation(rot)
        missile:SetTargetRotation(rot)
        missile:SetVel(math.cos(rad) * wpn:GetSpeed(), math.sin(rad) * wpn:GetSpeed())

        return missile
    end
end
