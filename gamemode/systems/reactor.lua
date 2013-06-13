SYS.FullName = "Reactor"
SYS.SGUIName = "reactor"

SYS.Powered = false

if SERVER then
    resource.AddFile("materials/systems/reactor.png")

    SYS._limits = nil

    function SYS:Initialize()
        self._nwdata.needed = 0
        self._nwdata.supplied = 0        
        self:SetTotalPower(20)

        self._limits = {}
    end

    function SYS:SetTotalPower(value)
        self._nwdata.total = value
        self:CaculatePower()
        self:_UpdateNWData()
    end

    function SYS:SetSystemLimitRatio(system, limit)
        self._limits[system.Name] = limit
    end

    function SYS:GetSystemLimitRatio(system)
        return self._limits[system.Name] or 1.0
    end

    function SYS:GetSystemLimit(system)
        return self:GetSystemLimitRatio(system) * self:GetTotalPower()
    end

    function SYS:CaculatePower(dt)
        local totalneeded = 0
        for _, room in pairs(self:GetShip():GetRooms()) do
            if room:GetSystem() and room:GetSystem().Powered then
                local needed = room:GetSystem():CalculatePowerNeeded(dt)
                room:GetSystem():SetPowerNeeded(needed)
                local limit = self:GetSystemLimit(room:GetSystem())
                totalneeded = totalneeded + math.min(needed, limit)
            end
        end

        self._nwdata.needed = totalneeded

        local ratio = 0
        if totalneeded > 0 then
            ratio = math.min(1, self:GetTotalPower() / totalneeded)
        end

        self._nwdata.supplied = ratio * totalneeded

        for _, room in pairs(self:GetShip():GetRooms()) do
            if room:GetSystem() and room:GetSystem().Powered then
                local needed = room:GetSystem():GetPowerNeeded()
                local limit = self:GetSystemLimit(room:GetSystem())
                room:GetSystem():SetPower(math.min(needed, limit) * ratio)
            end
        end

        self:_UpdateNWData()
    end

    function SYS:Think(dt)
        self:CaculatePower(dt)
    end
elseif CLIENT then
    SYS.Icon = Material("systems/reactor.png", "smooth")
end

function SYS:GetTotalNeeded()
    return self._nwdata.needed
end

function SYS:GetTotalSupplied()
    return self._nwdata.supplied
end

function SYS:GetTotalPower()
    return self._nwdata.total
end
