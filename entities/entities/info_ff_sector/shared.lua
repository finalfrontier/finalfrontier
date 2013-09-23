if SERVER then AddCSLuaFile("shared.lua") end

ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:GetCoordinates()
    return universe:GetUniversePos(self:GetPos())
end

function ENT:GetSectorName()
    return self:GetNWString("name")
end

if SERVER then
    local horzNames = {
        "alpha", "beta",  "gamma",  "delta",   "epsilon", "zeta", "eta",     "theta",
        "iota",  "kappa", "lambda", "mu",      "nu",      "xi",   "omicron", "phi",
        "rho",   "sigma", "tau",    "upsilon", "phi",     "chi",  "psi",     "omega"
    }

    local vertNames = {}
    for i = 1, 24 do vertNames[i] = tostring(i) end

    function ENT:GetPVSPos()
        return self:GetPos() + Vector(0, 0, 64)
    end

    function ENT:SetCoordinates(x, y)
        self:SetPos(universe:GetWorldPos(universe:WrapCoordinates(x + 0.5, y + 0.5)))
        self:SetNWString("name", horzNames[x + 1] .. "-" .. vertNames[y + 1])
    end
elseif CLIENT then
    function ENT:Draw()
        return
    end
end
