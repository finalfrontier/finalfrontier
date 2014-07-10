SWEP.PrintName = "Repair Tool"
SWEP.Slot      = 1
SWEP.HoldType = "pistol"
SWEP.ViewModelFOV = 70
SWEP.ViewModelFlip = false
SWEP.ViewModel = "models/weapons/v_toolgun.mdl"
SWEP.WorldModel = "models/weapons/w_toolgun.mdl"
SWEP.ShowViewModel = true
SWEP.ShowWorldModel = true

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

SWEP.AllowDelete = false
SWEP.AllowDrop = false

SWEP.COOLDOWN = 5
SWEP.MAX_DISTANCE = 128
SWEP.THINK_STEP = 0.1
SWEP.nextThinkStamp = CurTime()+SWEP.THINK_STEP

function SWEP:Initialize()
    self.Owner:SetNWInt( "repairMode", -1 ) 
    self.Owner:SetNWInt( "greenBoxes", 0 ) 
    self.Owner:SetNWInt( "blueBoxes", 0 ) 
    self.Owner:SetNWBool( "usingWelder", false ) 
end

function SWEP:SecondaryAttack()
    if self.Owner:GetNWInt( "repairMode", -1 ) == 0 then
        self.Owner:SetNWInt( "repairMode", 1 ) 
    elseif self.Owner:GetNWInt( "repairMode", -1 ) == 1 then
        self.Owner:SetNWInt( "repairMode", -1 ) 
    else
        self.Owner:SetNWInt( "repairMode", 0 ) 
    end
end

function SWEP:Think()
    if (CurTime()<self.nextThinkStamp) then return end
    if (self.Owner:GetNWBool( "usingWelder", false )) then
        local trace = self.Owner:GetEyeTraceNoCursor()
        
        local effectData = EffectData()
        effectData:SetOrigin( trace.HitPos )
        effectData:SetNormal( trace.HitNormal )
        util.Effect( "stunstickimpact", effectData, true, true )    
    end
    
    self.nextThinkStamp = CurTime()+self.THINK_STEP
end
    
if SERVER then
    util.AddNetworkString( "usingWelder" )
    util.AddNetworkString( "manipulateModule" )
    
    net.Receive( "usingWelder", function( len, ply )
        ply:SetNWBool( "usingWelder", net.ReadBit()==1 )
        if (ply:GetNWBool( "usingWelder", false)) then
            ply.weldingSound = CreateSound(ply, "ambient/machines/electric_machine.wav")
            ply.weldingSound:PlayEx(0.5, 150)
        else
            ply.weldingSound:Stop()
        end
    end )
    
    net.Receive( "manipulateModule", function( len, ply )
        local ent = net.ReadEntity()
        local gridx = net.ReadInt(4)
        local gridy = net.ReadInt(4)
        
        if (ply:GetNWInt( "repairMode", -1 ) == -1) then
            if (ent._grid[gridx][gridy] == 0) then
                ply:SetNWInt( "greenBoxes", ply:GetNWInt( "greenBoxes", 0 ) + 1 ) 
            elseif (ent._grid[gridx][gridy] == 1) then
                ply:SetNWInt( "blueBoxes", ply:GetNWInt( "blueBoxes", 0 ) + 1 ) 
            end
        else
            if (ply:GetNWInt( "repairMode", -1 ) == 0) then
                ply:SetNWInt( "greenBoxes", ply:GetNWInt( "greenBoxes", 0 ) - 1 ) 
            elseif (ply:GetNWInt( "repairMode", -1 ) == 1) then
                ply:SetNWInt( "blueBoxes", ply:GetNWInt( "blueBoxes", 0 ) - 1 ) 
            end
        end
        
        ent._grid[gridx][gridy] = ply:GetNWInt( "repairMode", -1 )
        ent:_UpdateGrid()
    end )
end
if CLIENT then
    SWEP.timestampCompleted = 0
    SWEP.manEntity = nil
    SWEP.manX = nil
    SWEP.manY = nil
    function SWEP:Think()
        if (CurTime()<self.nextThinkStamp) then return end
        
        local trace = self.Owner:GetEyeTraceNoCursor()
        
        if (input.IsMouseDown( MOUSE_LEFT ) && self.Owner:GetShootPos():Distance(trace.HitPos)<self.MAX_DISTANCE) then
            local possible, gridx, gridy, ent = self:actionTrace()
            if (!self.Owner:GetNWBool( "usingWelder", false )) then
                net.Start( "usingWelder" )
                    net.WriteBit( true )
                net.SendToServer()
            end
            if (!self:actionTrace()) then 
                self.timestampCompleted = 0 
                self.manEntity = nil
                self.manX = nil
                self.manY = nil
            else
                if (self.manEntity == ent && self.manX == gridx && self.manY == gridy) then
                    if (CurTime()>self.timestampCompleted) then
                        net.Start( "manipulateModule" )
                            net.WriteEntity( self.manEntity )
                            net.WriteInt( self.manX, 4)
                            net.WriteInt( self.manY, 4)
                        net.SendToServer()
                        self.manEntity = nil
                        self.manX = nil
                        self.manY = nil
                    end
                else
                    self.manEntity = ent 
                    self.manX = gridx 
                    self.manY = gridy
                    self.timestampCompleted = CurTime() + self.COOLDOWN
                end
            end
        elseif (self.Owner:GetNWBool( "usingWelder", false )) then
            net.Start( "usingWelder" )
                net.WriteBit( false )
            net.SendToServer()
            self.manEntity = nil
            self.manX = nil
            self.manY = nil
        end
        self.nextThinkStamp = CurTime()+self.THINK_STEP
    end
    
    local matScreen     = Material( "models/weapons/v_toolgun/screen" )

    -- GetRenderTarget returns the texture if it exists, or creates it if it doesn't
    local rtTexture     = GetRenderTarget( "GModToolgunScreen", 256, 256 )

    surface.CreateFont( "RepairToolDesc", {
        font    = "Helvetica",
        size    = 40,
        weight    = 900
    } )
    surface.CreateFont( "RepairToolNumber", {
        font    = "Helvetica",
        size    = 150,
        weight    = 900
    } )
    --[[---------------------------------------------------------
        We use this opportunity to draw to the toolmode
            screen's rendertarget texture.
    -----------------------------------------------------------]]
    function SWEP:RenderScreen()
        
        local TEX_SIZE = 256
        local oldW = ScrW()
        local oldH = ScrH()
        
        -- Set the material of the screen to our render target
        matScreen:SetTexture( "$basetexture", rtTexture )
        
        local oldRT = render.GetRenderTarget()
        
        -- Set up our view for drawing to the texture
        render.SetRenderTarget( rtTexture )
        render.SetViewPort( 0, 0, TEX_SIZE, TEX_SIZE )
        cam.Start2D()
            local backgroundColor
            local text = "REPAIR"
            local textNumber = false
            if self.Owner:GetNWInt( "repairMode", -1 ) == 0 then
                backgroundColor = Color( 51, 172, 45, 255 )
                textNumber = self.Owner:GetNWInt( "greenBoxes", 0 ) 
            elseif self.Owner:GetNWInt( "repairMode", -1 ) == 1 then
                backgroundColor = Color( 45, 51, 172, 255 ) 
                textNumber = self.Owner:GetNWInt( "blueBoxes", 0 ) 
            else
                backgroundColor = Color( 172, 45, 51, 255 )

                text = "REMOVE"
            end
            surface.SetDrawColor( backgroundColor )
            surface.DrawRect( 0, 0, TEX_SIZE, TEX_SIZE )
            
            self:drawShadowedText(text, TEX_SIZE / 2, 32, "RepairToolDesc")
            if textNumber != false then
                self:drawShadowedText(textNumber, TEX_SIZE / 2, TEX_SIZE / 2, "RepairToolNumber")
            end
            
            local totbars = 10
            local barspacing = 2
            local width = TEX_SIZE - 8
            local barsize = (width - 8 + barspacing) / totbars
            local bars = 10
            if (self.Owner:GetNWBool( "usingWelder", false )) then
                bars = math.Clamp(((CurTime()-self.timestampCompleted+self.COOLDOWN)/self.COOLDOWN) * totbars,0,totbars)
            end
            
            surface.SetDrawColor(Color(100, 100, 100, 255))

            local possible = self:actionTrace()
            for i = 0, bars - 1 do
                    if (possible) then surface.SetDrawColor(LerpColour(Color(255, 255, 255, 255), Color(255, 255, 159, 255), Pulse(0.5, -i / totbars / 4))) end

                surface.DrawRect(8 + i * barsize,
                    TEX_SIZE - 40, barsize - barspacing, 32)
            end

        cam.End2D()
        render.SetRenderTarget( oldRT )
        render.SetViewPort( 0, 0, oldW, oldH )
        
    end
    
    function SWEP:drawShadowedText(text, x, y, font)
        draw.SimpleText( text, font, x + 3, y + 3, Color(0, 0, 0, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER ) 
        
        draw.SimpleText( text, font, x , y , Color(255, 255, 255, 255), TEXT_ALIGN_CENTER, TEXT_ALIGN_CENTER ) 
    end
    
    function SWEP:actionTrace()
        local trace = self.Owner:GetEyeTraceNoCursor()
        if (trace.Entity:GetClass()=="prop_ff_module") then 
            local gridx, gridy = trace.Entity:GetPlayerTargetedTile(ply)
            if (!gridx || !gridy) then return false end
            
            local grid = trace.Entity:GetGrid()
            
            if (self.Owner:GetNWInt( "repairMode", -1 ) == -1 && grid[gridx][gridy] >= 0) then
                return true, gridx, gridy, trace.Entity
            elseif ( self.Owner:GetNWInt( "repairMode", -1 ) >= 0 && grid[gridx][gridy] < 0 ) then
                if ((self.Owner:GetNWInt( "repairMode", -1 ) == 0 && self.Owner:GetNWInt( "greenBoxes", 0 ) > 0) || (self.Owner:GetNWInt( "repairMode", -1 ) == 1 && self.Owner:GetNWInt( "blueBoxes", 0 ) > 0)) then
                    return true, gridx, gridy, trace.Entity
                end
            end
        end
    end
    
end


