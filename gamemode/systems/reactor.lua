SYS.FullName = "Reactor"
SYS.SGUIName = "reactor"

SYS.Powered = false

if SERVER then
    resource.AddFile("materials/systems/reactor.png")

    SYS._systemTotal = 0
    SYS._systemWeights = nil

    function SYS:GetTotalPower()
        return 73.0 -- Placeholder
    end

    function SYS:SetSystemWeight(system, weight)
        self._systemTotal = self._systemTotal - self:GetSystemWeight(system)
        self._systemWeights[system] = weight
        self._systemTotal = self._systemTotal + weight
    end

    function SYS:GetSystemWeight(system, weight)
        return self._systemWeights[system] or 0
    end

    function SYS:GetSystemRatio(system)
        if self._systemTotal <= 0.0 then
            return 0.0
        else
            return self:GetSystemWeight(system) / self._systemTotal
        end
    end

    function SYS:GetSystemPower(system)
        return self:GetTotalPower() * self:GetSystemRatio(system)
    end
elseif CLIENT then
    SYS.Icon = Material("systems/reactor.png", "smooth")    
end

function SYS:Initialize()
    if SERVER then
        self._systemWeights = {}
        for _, room in pairs(self.Ship:GetRooms()) do
            if room:GetSystem() and room:GetSystem().Powered then
                self:SetSystemWeight(room:GetSystemName(), 0.5)
            end
        end
    end
end
