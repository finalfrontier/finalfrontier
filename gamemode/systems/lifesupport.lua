SYS.FullName = "Life Support"
SYS.SGUIName = "lifesupport"

SYS.Powered = true

if SERVER then
	resource.AddFile("materials/systems/lifesupport.png")

    local TEMP_POWER_PER_METER3 = 0.005
    local TEMP_RECHARGE_RATE = 10
    local ATMO_POWER_PER_METER3 = 0.005
    local ATMO_RECHARGE_RATE = 5

    SYS._atmo = nil
    SYS._temp = nil

    function SYS:Initialize()
        self._atmo = {}
        self._temp = {}
    end

    function SYS:SetGoalAtmosphere(room, value)
        self._atmo[room:GetName()] = value
    end

    function SYS:GetGoalAtmosphere(room)
        return self._atmo[room:GetName()] or 1.0
    end

    function SYS:SetGoalTemperature(room, value)
        self._temp[room:GetName()] = value
    end

    function SYS:GetGoalTemperature(room)
        return self._temp[room:GetName()] or 300
    end

    function SYS:CalculatePowerNeeded(dt)
        --[[
        local totNeeded = 0
        for _, room in ipairs(self.Ship:GetRooms()) do
            local goalUnits = self:GetGoalTemperature(room) / 600 * room:GetVolume()
            local needed = math.Clamp(math.abs(room:GetUnitTemperature() - goalUnits) / TEMP_RECHARGE_RATE * dt, 0, 1)
            totNeeded = totNeeded + TEMP_POWER_PER_METER3 * needed

            goalUnits = self:GetGoalAtmosphere(room) * room:GetVolume()
            needed = math.Clamp(math.abs(room:GetAirVolume() - goalUnits) / ATMO_RECHARGE_RATE * dt, 0, 1)
            totNeeded = totNeeded + ATMO_POWER_PER_METER3 * needed
        end
        return totNeeded
        --]]

        return #self.Ship:GetRooms()
    end

    function SYS:Think(dt)
        if self:GetPower() <= 0 then return end

        --[[
        local needed = self:GetPowerNeeded()
        local ratio = 0
        if needed > 0 then
            ratio = math.min(self:GetPower() / needed, 1)
        end
        --]]
        for _, room in ipairs(self.Ship:GetRooms()) do
            --[[
            if math.abs(room:GetTemperature() - self:GetGoalTemperature(room)) > 0.001 then
                if room:GetTemperature() < self:GetGoalTemperature(room) then
                    room:SetUnitTemperature(room:GetUnitTemperature() + TEMP_RECHARGE_RATE * ratio * dt)
                    if room:GetTemperature() > self:GetGoalTemperature(room) then
                        room:SetUnitTemperature(room:GetVolume() * self:GetGoalTemperature(room) / 600)
                    end
                else
                    room:SetUnitTemperature(room:GetUnitTemperature() - TEMP_RECHARGE_RATE * ratio * dt)
                    if room:GetTemperature() < self:GetGoalTemperature(room) then
                        room:SetUnitTemperature(room:GetVolume() * self:GetGoalTemperature(room) / 600)
                    end
                end
            end
            if math.abs(room:GetAtmosphere() - self:GetGoalAtmosphere(room)) > 0.001 then
                if room:GetAtmosphere() < self:GetGoalAtmosphere(room) then
                    room:SetAirVolume(room:GetAirVolume() + ATMO_RECHARGE_RATE * ratio * dt)
                    if room:GetAtmosphere() > self:GetGoalAtmosphere(room) then
                        room:SetAirVolume(room:GetVolume() * self:GetGoalAtmosphere(room))
                    end
                else
                    room:SetAirVolume(room:GetAirVolume() - ATMO_RECHARGE_RATE * ratio * dt)
                    if room:GetAtmosphere() < self:GetGoalAtmosphere(room) then
                        room:SetAirVolume(room:GetVolume() * self:GetGoalAtmosphere(room))
                    end
                end
            end
            --]]
            room:SetUnitTemperature(room:GetVolume() * self:GetGoalTemperature(room) / 600)
            room:SetAirVolume(room:GetVolume() * self:GetGoalAtmosphere(room))
        end
        --]]
    end
elseif CLIENT then
	SYS.Icon = Material("systems/lifesupport.png", "smooth")
end
