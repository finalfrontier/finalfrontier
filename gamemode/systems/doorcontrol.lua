SYS.FullName = "Door Control"
SYS.SGUIName = "doorcontrol"

SYS.Powered = true

if SERVER then
    local POWER_PER_DOOR = 0.2

	resource.AddFile("materials/systems/doorcontrol.png")

    function SYS:GetPowerNeeded()
        local needed = 0
        for _, door in pairs(self:GetShip():GetDoors()) do
            if door:IsUnlocked() then
                needed = needed + POWER_PER_DOOR
            end
        end
        return needed
    end

    function SYS:Think()
        local power = self:GetPower()
        for _, door in pairs(self:GetShip():GetDoors()) do
            if door:IsUnlocked() then
                power = power - POWER_PER_DOOR
                door:SetIsPowered(power >= 0)
            end
        end
    end
elseif CLIENT then
	SYS.Icon = Material("systems/doorcontrol.png", "smooth")
end
