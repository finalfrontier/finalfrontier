if SERVER then AddCSLuaFile("sh_init.lua") end

-- Global Functions

function math.sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end

function Pulse(period)
    return (math.sin(CurTime() * math.pi * 2 / period) + 1) * 0.5
end

function LerpColour(a, b, t)
    return Color(
        a.r + (b.r - a.r) * t,
        a.g + (b.g - a.g) * t,
        a.b + (b.b - a.b) * t,
        a.a + (b.a - a.a) * t
    )
end

function FormatNum(num, leading, trailing)
    local mul = math.pow(10, trailing)
    num = math.Round(num * mul) / mul

    local str = tostring(num)
    local index = string.find(str, "%.")
    if not index then
        index = string.len(str)
        if trailing > 0 then
            str = str .. "." .. string.rep("0", trailing)
        end
    else
        local dec = string.len(str) - index
        if trailing > dec then
            str = str .. string.rep("0", trailing - dec)
        end
        index = index - 1
    end

    if index < leading then
        str = string.rep("0", leading - index) .. str
    end

    return str
end