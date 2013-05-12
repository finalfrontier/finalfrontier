OBJ._ship = nil

function OBJ:GetShipName()
    return self._nwdata.shipname
end

function OBJ:GetShip()
    if not self._ship then
        self._ship = ships.GetByName(self:GetShipName())
    end

    return self._ship
end

if SERVER then
    resource.AddFile("materials/objects/ship.png")

    function OBJ:SetShip(ship)
        self._ship = ship
        self._nwdata.shipname = ship:GetName()

        self:_UpdateNWData()
    end
elseif CLIENT then
    OBJ.Icon = Material("objects/ship.png", "smooth")
end
