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
