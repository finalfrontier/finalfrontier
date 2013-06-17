SYS.FullName = "Engineering"
SYS.SGUIName = "engineering"

SYS.Powered = true

if SERVER then
    resource.AddFile("materials/systems/engineering.png")

    function SYS:CalculatePowerNeeded(dt)
        return 1
    end
elseif CLIENT then
    SYS.Icon = Material("systems/engineering.png", "smooth")
end
