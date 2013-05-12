if SERVER then AddCSLuaFile("sh_universe.lua") end

if universe then return end

universe = {}
universe._sectors = {}

function universe.GetSectorIndex(x, y)
    x = math.floor(x)
    y = math.floor(y)

    x = x - math.floor(x / 24) * 24
    y = y - math.floor(y / 24) * 24

    return x + y * 24 + 1
end

function universe.GetSector(x, y)
    local index = universe.GetSectorIndex(x, y)
    if not universe._sectors[index] then
        universe._sectors[index] = Sector(x, y)
    end

    return universe._sectors[index]
end
