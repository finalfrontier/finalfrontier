SYS.FullName = "Sensors"
SYS.SGUIName = "sensors"

SYS.Powered = false

if SERVER then
    resource.AddFile("materials/systems/sensors.png")
elseif CLIENT then
    SYS.Icon = Material("systems/sensors.png", "smooth")
end
