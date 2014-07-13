if SERVER then AddCSLuaFile("player_ff_base.lua") end

Class_Manager = {}

Class_Manager.Class = {}

Class_Manager.HeldItems = {}

local _currentClass = #self.Class

local _classname = ""

--Use Before AddClass
function Class_Manager.SetItems(items)
    self.HeldItems = items
end

function Class_Manager.AddClass(classname, displayname, walkspeed, runspeed, models)
    self.Class[_currentClass] = {}
    self.Class[_currentClass].DisplayName = displayname
    self.Class[_currentClass].WalkSpeed = walkspeed
    self.Class[_currentClass].RunSpeed = runspeed
    
    _classname = classname
    
    local _models = models
    
    if SERVER then
        function self.Class[_currentClass]:Init()
            team.AutoAssign(self.Player)
        end 
    
        function self.Class[_currentClass]:Spawn()
            local ship = team.GetShip(self.Player:Team())
            local pad = table.Random(ship:GetSystem("transporter"):GetRoom():GetTransporterPads())

            self.Player:SetPos(pad)
            self.Player:SetShip(ship)

            self.Player:SetCanWalk(true)

            TeleportArriveEffect(self.Player, self.Player:GetPos())
        end
        
        function self.Class[_currentClass]:SetModel()
            self.Player:SetModel(table.Random(_models))
        end

        function self.Class[_currentClass]:Loadout()
            if not Class_Manager.HeldItems then
                self.Player:Give("weapon_crowbar")
                self.Player:Give("weapon_ff_repair_tool")
            else
                for k,v in pairs(Class_Manager.HeldItems) do
                    self.Player:Give(v)
                end
        end
    end

    function self.Class[_currentClass]:SetupDataTables()
        local ply = self.Player or self

        ply:NetworkVar("String", 0, "ShipName")
    
        ply:NetworkVar("Int", 0, "RoomIndex")
    
        ply:NetworkVar("Bool", 0, "UsingScreen")

        ply:NetworkVar("Entity", 0, "CurrentScreen")
        ply:NetworkVar("Entity", 1, "OldWeapon")

        ply._permissions = ply:NetworkTable(0, "Permissions")
    end
    
    SetupPlayerDataTables = self.Class[_currentClass].SetupDataTables
end

player_manager.RegisterClass("player_ff_".._classname, self.Class[_currentClass], "player_default")
