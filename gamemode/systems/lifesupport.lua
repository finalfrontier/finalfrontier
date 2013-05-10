SYS.FullName = "Life Support"
SYS.SGUIName = "lifesupport"

SYS.Powered = true

if SERVER then
	resource.AddFile("materials/systems/lifesupport.png")

    local TEMP_POWER_PER_METER3 = 2
    local TEMP_RECHARGE_RATE = 2
    local ATMO_POWER_PER_METER3 = 1
    local ATMO_RECHARGE_RATE = 10

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
        local totNeeded = 0
        for _, room in ipairs(self.Ship:GetRooms()) do
            totNeeded = totNeeded + CalculatePowerCost(
                room:GetUnitTemperature(),
                self:GetGoalTemperature(room) / 600 * room:GetVolume(),
                TEMP_RECHARGE_RATE * dt,
                TEMP_POWER_PER_METER3) + CalculatePowerCost(
                room:GetAirVolume(),
                self:GetGoalAtmosphere(room) * room:GetVolume(),
                ATMO_RECHARGE_RATE * dt,
                ATMO_POWER_PER_METER3)
        end
        return totNeeded
    end

    function SYS:Think(dt)
        if self:GetPower() <= 0 then return end

        local needed = self:GetPowerNeeded()
        local ratio = 0
        if needed > 0 then
            ratio = math.min(self:GetPower() / needed, 1)
        end

        for _, room in ipairs(self.Ship:GetRooms()) do
            room:SetUnitTemperature(CalculateNextValue(
                room:GetUnitTemperature(),
                self:GetGoalTemperature(room) / 600 * room:GetVolume(),
                TEMP_RECHARGE_RATE * dt,
                ratio))
            room:SetAirVolume(CalculateNextValue(
                room:GetAirVolume(),
                self:GetGoalAtmosphere(room) * room:GetVolume(),
                ATMO_RECHARGE_RATE * dt,
                ratio))
        end
    end
elseif CLIENT then
	SYS.Icon = Material("systems/lifesupport.png", "smooth")
end
