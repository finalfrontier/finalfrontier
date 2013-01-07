SYS.FullName = "Door Control"
SYS.SGUIName = "doorcontrol"

if SERVER then
	resource.AddFile("materials/systems/doorcontrol.png")
elseif CLIENT then
	SYS.Icon = Material("systems/doorcontrol.png", "smooth")
end
