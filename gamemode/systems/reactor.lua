SYS.FullName = "Reactor"
SYS.SGUIName = "reactor"

SYS.Powered = false

if SERVER then
    resource.AddFile("materials/systems/reactor.png")

    SYS._limits = nil

    function SYS:Initialize()
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
        self:CaculatePower()
    end

    function SYS:GetSystemLimitRatio(system)
        return self._limits[system.Name] or 1.0
    end

    function SYS:GetSystemLimit(system)
        return self:GetSystemLimitRatio(system) * self:GetTotalPower()
    end

    function SYS:CaculatePower()
        local totalneeded = 0
        for _, room in pairs(self.Ship:GetRooms()) do
            if room:GetSystem() and room:GetSystem().Powered then
                local needed = room:GetSystem():GetPowerNeeded()
                local limit = self:GetSystemLimit(room:GetSystem())
                totalneeded = totalneeded + math.min(needed, limit)
            end
        end

        local ratio = 0
        if totalneeded > 0 then
            ratio = math.min(1, self:GetTotalPower() / totalneeded)
        end

        for _, room in pairs(self.Ship:GetRooms()) do
            if room:GetSystem() and room:GetSystem().Powered then
                local needed = room:GetSystem():GetPowerNeeded()
                local limit = self:GetSystemLimit(room:GetSystem())
                room:GetSystem():SetPower(math.min(needed, limit) * ratio)
            end
        end
    end

    function SYS:Think(dt)
        self:CaculatePower()
    end
elseif CLIENT then
    SYS.Icon = Material("systems/reactor.png", "smooth")    
end

function SYS:GetTotalPower()
    return self._nwdata.total
end
