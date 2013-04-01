SYS.FullName = "Door Control"
SYS.SGUIName = "doorcontrol"

SYS.Powered = true

if SERVER then
	resource.AddFile("materials/systems/doorcontrol.png")

    function SYS:GetPowerNeeded()
        return 2
    end
elseif CLIENT then
	SYS.Icon = Material("systems/doorcontrol.png", "smooth")
end
