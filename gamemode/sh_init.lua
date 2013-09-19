if SERVER then AddCSLuaFile("sh_init.lua") end

GM.Name = "Final Frontier"
GM.Author = "Metapyziks"
GM.Email = "N/A"
GM.Website = "N/A"

function GM:Initialize()
end 

-- Global Functions

function math.sign(x)
    if x > 0 then return 1 end
    if x < 0 then return -1 end
    return 0
end

function Pulse(period, phase)
    return (math.sin((CurTime() + (phase or 0)) * math.pi * 2 / period) + 1) * 0.5
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

function FormatBearing(angle)
    angle = 90 - angle
    angle = angle - math.floor(angle / 360) * 360
    return FormatNum(angle, 3, 0)
end

function WrapAngle(ang, alwaysPositive)
    if not alwaysPositive then ang = ang + math.pi end
    ang = ang - math.floor(ang / (math.pi * 2)) * math.pi * 2
    if not alwaysPositive then ang = ang - math.pi end
    return ang
end

function FindAngleDifference(a, b)
    return WrapAngle(WrapAngle(a) - WrapAngle(b))
end

-- TODO: Add check to avoid complex polys in output
function FindConvexPolygons(poly, output)
    output = output or {}
    local cur = {}
    local l = poly[#poly]
    local n = poly[1]
    local i = 1
    while i <= #poly do
        local v = n
        table.insert(cur, v)
        n = poly[(i % #poly) + 1]
        i = i + 1
        
        local la = math.atan2(l.y - v.y, l.x - v.x)
        local subPoly = { v }
        
        while n ~= v do
            table.insert(subPoly, n)
            if i > #poly + 1 then
                table.remove(cur, 1)
            end
            local na = math.atan2(n.y - v.y, n.x - v.x)
            local ang = WrapAngle(na - la, true)
            
            if ang > math.pi then
                n = poly[(i % #poly) + 1]
                i = i + 1
            else
                if #subPoly > 2 then
                    FindConvexPolygons(subPoly, output)
                end
                break
            end
        end
        
        if n == v then
            break
        end
        l = v
    end
    table.insert(output, cur)
    return output
end

function IsPointInsidePoly(poly, x, y)
    for i, v in ipairs(poly) do
        local n = poly[(i % #poly) + 1]
        local ax, ay = n.x - v.x, n.y - v.y
        local bx, by =   x - v.x,   y - v.y
        local cross = ax * by - ay * bx
        if CLIENT and cross < 0 then return false end -- uhhh
        if SERVER and cross > 0 then return false end -- yeah
    end
    
    return true
end

function IsPointInsidePolyGroup(polys, x, y)
    for _, poly in ipairs(polys) do
        if IsPointInsidePoly(poly, x, y) then return true end
    end
    
    return false
end
