SYS.FullName = "Weapons"
SYS.SGUIName = "weapons"

SYS.Powered = true

if SERVER then
    -- resource.AddFile("materials/systems/weapons.png")

    function SYS:CalculatePowerNeeded()
        local tot = 0
        for slot = moduletype.weapon1, moduletype.weapon3 do
            local mdl = self:GetRoom():GetModule(slot)
            if mdl then
                local weapon = mdl:GetWeapon()
                tot = tot + weapon:GetMaxPower()
            end
        end
        return tot
    end

    function SYS:Think(dt)
        local power = self:GetPower()
        local needed = self:GetPowerNeeded()
        if needed > 0 then
            local ratio = power / needed
            for slot = moduletype.weapon1, moduletype.weapon3 do
                local mdl = self:GetRoom():GetModule(slot)
                if mdl then mdl:AddCharge(ratio * dt) end
            end
        end
    end
elseif CLIENT then
    -- SYS.Icon = Material("systems/weapons.png", "smooth")
end
