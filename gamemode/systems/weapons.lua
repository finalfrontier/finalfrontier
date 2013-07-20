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
    	for slot = moduletype.weapon1, moduletype.weapon3 do
    		local weapon = self:GetRoom():GetModule(slot)
    		if weapon then

    		end
    	end
    end
elseif CLIENT then
    -- SYS.Icon = Material("systems/weapons.png", "smooth")
end
