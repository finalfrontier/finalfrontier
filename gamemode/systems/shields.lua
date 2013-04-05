SYS.FullName = "Shield Control"
SYS.SGUIName = "shields"

SYS.Powered = true

if SERVER then
	resource.AddFile("materials/systems/shields.png")

	local RECHARGE_RATE = 5.37
	local SHIELD_POWER_PER_M2 = 0.01462
	
	SYS._distrib = nil
	
	function SYS:Initialize()
		self._distrib = {}
	end

	function SYS:SetDistrib(room, value)
		self._distrib[room:GetName()] = math.Clamp(value, 0, 1)
	end

	function SYS:GetDistrib(room)
		return self._distrib[room:GetName()] or 0
	end
	
	function SYS:CalculatePowerNeeded()
		local totNeeded = 0
		for _, room in ipairs(self.Ship:GetRooms()) do
			totNeeded = totNeeded + room:GetSurfaceArea() * SHIELD_POWER_PER_M2
				* self:GetDistrib(room)
		end
		return totNeeded
	end

	function SYS:Think(dt)
		local needed = self:GetPowerNeeded()
		local ratio = 0
		if needed > 0 then
			ratio = math.min(self:GetPower() / needed, 1)
		end

		for _, room in ipairs(self.Ship:GetRooms()) do
			local val = self:GetDistrib(room) * ratio
			if room:GetShields() < val then
				room:SetUnitShields(room:GetUnitShields() + RECHARGE_RATE * dt)
			end

			if room:GetShields() > val then
				room:SetUnitShields(val * room:GetSurfaceArea())
			end
		end
	end
elseif CLIENT then
	SYS.Icon = Material("systems/shields.png", "smooth")
end
