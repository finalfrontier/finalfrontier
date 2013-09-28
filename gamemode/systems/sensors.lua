SYS.FullName = "Sensors"
SYS.SGUIName = "sensors"

SYS.Powered = true

function SYS:GetMaximumCharge()
    --return self._nwdata.maxcharge
    return 10.0
end

function SYS:GetCurrentCharge()
    --return math.min(self._nwdata.charge, self._nwdata.maxcharge)
    return 5.0
end

if SERVER then
    resource.AddFile("materials/systems/sensors.png")
elseif CLIENT then
    SYS.Icon = Material("systems/sensors.png", "smooth")
end
