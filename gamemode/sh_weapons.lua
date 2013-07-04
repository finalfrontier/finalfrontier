if SERVER then AddCSLuaFile("sh_weapons.lua") end

if not weapon then
    weapon = {}
    weapon._dict = {}
else return end

local _mt = {}
_mt.__index = _mt

_mt.BaseName = nil
_mt.Base = nil

_mt.Name = nil
_mt.FullName = "unnamed"

function _mt:GetMaxPower() return 0 end
function _mt:GetMaxCharge() return 0 end
function _mt:GetShotCharge() return 0 end

if SERVER then
    function _mt:OnHit(room)
        return
    end
end

MsgN("Loading weapons...")
local files = file.Find("finalfrontier/gamemode/weapons/*.lua", "LUA")
for i, file in ipairs(files) do
    local name = string.sub(file, 0, string.len(file) - 4)
    if SERVER then AddCSLuaFile("weapons/" .. file) end

    MsgN("  Loading weapon " .. name)

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

function weapon.Create(name)
    if weapon._dict[name] then
        return setmetatable({}, weapon._dict[name])
    end
    return nil
end
