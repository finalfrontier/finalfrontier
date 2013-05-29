if SERVER then AddCSLuaFile("shared.lua") end

local horzNames = {
    "alpha", "beta",  "gamma",  "delta",   "epsilon", "zeta", "eta",     "theta",
    "iota",  "kappa", "lambda", "mu",      "nu",      "xi",   "omicron", "phi",
    "rho",   "sigma", "tau",    "upsilon", "phi",     "chi",  "psi",     "omega"
}

local vertNames = {
    "1",  "2",  "3",  "4",  "5",  "6",  "7",  "8",
    "9",  "10", "11", "12", "13", "14", "15", "16",
    "17", "18", "19", "20", "21", "22", "23", "24"
}

ENT.Type = "anim"
ENT.Base = "base_anim"

function ENT:GetCoordinates()
    return self:GetNWInt("x", 1), self:GetNWInt("y", 1)
end

function ENT:GetSectorName()
    return self:GetNWString("name")
end

if SERVER then
    function ENT:GetPVSPos()
        return self:GetPos()-- + Vector(0, 0, 128)
    end

    function ENT:SetCoordinates(x, y)
        self:SetNWInt("x", x)
        self:SetNWInt("y", y)
        self:SetNWString("name", horzNames[x + 1] .. "-" .. vertNames[y + 1])
    end
elseif CLIENT then
    function ENT:Think()
        print("Hello from " .. self:GetSectorName())
    end
end
