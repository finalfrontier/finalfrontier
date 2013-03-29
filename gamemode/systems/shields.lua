local RECHARGE_RATE = 1 / 60.0

SYS.FullName = "Shield Control"

SYS.Powered = true

if SERVER then
	resource.AddFile("materials/systems/shields.png")

	local SHIELD_POWER_PER_M2 = 0.01462
	
	SYS.PowerUsage = nil
	SYS.Ditribution = nil
	
	function SYS:Initialize()
		self.Distribution = {}
	end
	
	function SYS:Think(dt)
		local totPower = 8
		local totNeeded = 0
		for _, room in ipairs(self.Ship:GetRooms()) do
			totNeeded = totNeeded + room.SurfaceArea * SHIELD_POWER_PER_M2 * (self.Distribution[room] or 0)
		end
		
		local ratio = math.min(totPower / totNeeded, 1)
		self.PowerUsage = totNeeded / totPower
		
		for _, room in ipairs(self.Ship:GetRooms()) do
			local val = (self.Distribution[room] or 0) * ratio
			if room:GetShields() < val then
				room:SetShields(room:GetShields() + RECHARGE_RATE * dt)
				
				if room:GetShields() > val then
					room:SetShields(val)
				end
			end
		end
	end
elseif CLIENT then
	SYS.Icon = Material("systems/shields.png", "smooth")
end
