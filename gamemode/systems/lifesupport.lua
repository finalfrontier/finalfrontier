SYS.FullName = "Life Support"
SYS.SGUIName = "lifesupport"

SYS.Powered = true

if SERVER then
	resource.AddFile("materials/systems/lifesupport.png")

    local TEMP_POWER_PER_METER3 = 0.0005
    local TEMP_RECHARGE_RATE = 5
    local ATMO_POWER_PER_METER3 = 0.0005
    local ATMO_RECHARGE_RATE = 50

    SYS._atmo = nil
    SYS._temp = nil

    function SYS:Initialize()
        self._atmo = {}
        self._temp = {}
    end

    function SYS:GetGoalAtmosphere(room)
        return self._atmo[room:GetName()] or 1.0
    end

    function SYS:GetGoalTemperature(room)
        return self._temp[room:GetName()] or 300
    end

    function SYS:CalculatePowerNeeded()
        local totNeeded = 0
        for _, room in ipairs(self.Ship:GetRooms()) do
            if self:GetGoalTemperature(room) > 0 then
                local needed = room:GetVolume() * TEMP_POWER_PER_METER3
                if room:GetTemperature() < self:GetGoalTemperature(room) - 0.001 then
                    totNeeded = totNeeded + needed * 2
                elseif room:GetTemperature() < self:GetGoalTemperature(room) + 0.001 then
                    totNeeded = totNeeded + needed
                end
            end
            if self:GetGoalAtmosphere(room) > 0 then
                local needed = room:GetVolume() * ATMO_POWER_PER_METER3
                if room:GetAtmosphere() < self:GetGoalAtmosphere(room) - 0.001 then
                    totNeeded = totNeeded + needed * 2
                elseif room:GetAtmosphere() < self:GetGoalAtmosphere(room) + 0.001 then
                    totNeeded = totNeeded + needed
                end
            end
        end
        return totNeeded
    end

    --[[
    function SYS:Think(dt)
        local needed = self:GetPowerNeeded()
        local ratio = 0
        if needed > 0 then
            ratio = math.min(self:GetPower() / needed, 1)
        end

        for _, room in ipairs(self.Ship:GetRooms()) do
            if self:GetGoalTemperature(room) > 0 then
                local rate = ratio * 2 - 1
                if room:GetTemperature() < self:GetGoalTemperature(room) - 0.001 or rate < 0 then
                    room:SetUnitTemperature(room:GetUnitTemperature() + SHIELD_RECHARGE_RATE * rate * dt)
                end
            end
            if room:GetShields() > self:GetDistrib(room) then
                room:SetUnitShields(self:GetDistrib(room) * room:GetSurfaceArea())
            end
        end
    end
    ]]--
elseif CLIENT then
	SYS.Icon = Material("systems/lifesupport.png", "smooth")
end
