SYS.FullName = "Shield Control"
SYS.SGUIName = "shields"

SYS.Powered = true

if SERVER then
	resource.AddFile("materials/systems/shields.png")

	local SHIELD_RECHARGE_RATE = 2.5
	local SHIELD_POWER_PER_M2 = 0.008
	
	SYS._distrib = nil
	
	function SYS:Initialize()
		self._distrib = {}
	end

	function SYS:SetDistrib(room, value)
		self._distrib[room:GetName()] = math.Clamp(value, 0, 1)
	end

	function SYS:GetDistrib(room)
		return self._distrib[room:GetName()] or 1.0
	end
	
	function SYS:CalculatePowerNeeded()
		local totNeeded = 0
		for _, room in ipairs(self:GetShip():GetRooms()) do
			if self:GetDistrib(room) > 0 then
				-- TODO: make continuous
				local needed = room:GetSurfaceArea() * SHIELD_POWER_PER_M2
				if room:GetShields() < self:GetDistrib(room) - 0.001 then
					totNeeded = totNeeded + needed * 2
				elseif room:GetShields() < self:GetDistrib(room) + 0.001 then
					totNeeded = totNeeded + needed
				end
			end
		end
		return totNeeded
	end

	function SYS:Think(dt)
		local needed = self:GetPowerNeeded()
		local ratio = 0
		if needed > 0 then
			ratio = math.min(self:GetPower() / needed, 1)
		end

		for _, room in ipairs(self:GetShip():GetRooms()) do
			if self:GetDistrib(room) > 0 then
				local rate = ratio * 2 - 1
				if room:GetShields() < self:GetDistrib(room) - 0.001 or rate < 0 then
					room:SetUnitShields(room:GetUnitShields() + SHIELD_RECHARGE_RATE * rate * dt)
				end
			end
			if room:GetShields() > self:GetDistrib(room) then
				room:SetUnitShields(self:GetDistrib(room) * room:GetSurfaceArea())
			end
		end
	end
elseif CLIENT then
	SYS.Icon = Material("systems/shields.png", "smooth")
end
