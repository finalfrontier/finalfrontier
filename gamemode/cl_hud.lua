-- Copyright (c) 2014 James King [metapyziks@gmail.com]
-- 
-- This file is part of Final Frontier.
-- 
-- Final Frontier is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
-- 
-- Final Frontier is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with Final Frontier. If not, see <http://www.gnu.org/licenses/>.

local barhp=400
local delay=CurTime()
local barheight=30
local blinktick=CurTime()

local prevarmor=100
local armblink=255
local armhide=255

function GM:HUDPaint()
local ply = LocalPlayer()
local hp=ply:Health()
if delay < CurTime() then
    if barhp < hp*4 then
        barhp=barhp+1
        hurting=false
    else
    if barhp > hp*4 then
        barhp=barhp-1
        hurting=true
    else
    hurting=false
    end end
    
    if barhp==400 and barheight>=0 then
    barheight=barheight-1
    else if barheight<=30 then
    barheight=barheight+1
    end end
    
    delay = CurTime() + 0.01
end
hev = ply:GetNWInt("HEV")
if hp > 0 and ply:Alive() then
    --HP
    surface.SetDrawColor( 40, 0, 0, 150 )
    surface.DrawRect( 5, (ScrH()-5)-barheight, 400, barheight )
    if hp<30 then
    surface.SetDrawColor( ((blinktick-CurTime())*200)+170, 0, 0, 100 )
    else
    surface.SetDrawColor( 200, 0, 0, 100 )
    end
    surface.DrawRect( 5, (ScrH()-5)-barheight, (barhp/400)*400, barheight )
    if blinktick<CurTime() then blinktick=CurTime()+0.5 end
	
    --HEV
    if prevarmor > ply:Armor() then
    armblink=0
    prevarmor=ply:Armor()
    elseif ply:Armor() > 0 then
    armblink=armblink+5
    end
    if ply:Armor() >= 100 then
    armhide= armhide-5
    else
    armhide= 255
    end
    draw.SimpleText( "HEV: " .. ply:Armor(), "CTextMedium", 20, 5, Color( 255, armblink, armblink, armhide ), TEXT_ALIGN_LEFT, TEXT_ALIGN_TOP )
	
	--NameTags
	
end end

function hidehud(name) -- Removing the default HUD
	for k, v in pairs({"CHudHealth", "CHudBattery", "CHudAmmo", "CHudSecondaryAmmo", })do
		if name == v then return false end
	end
end
hook.Add("HUDShouldDraw", "HideOurHud:D", hidehud)

local teamcol=Color( 0, 0, 0 )

function GM:PostDrawOpaqueRenderables()
local ply=LocalPlayer()
local tr=ply:GetEyeTraceNoCursor().Entity
if tr:IsValid() and tr:IsPlayer() then
teamcol=team.GetColor(tr:Team())

	cam.Start3D2D(tr:GetPos() + Vector(0,0,80), ply:EyeAngles():Right():Angle() + Angle(0,0,90), 0.1)
		draw.SimpleText( tr:Nick(), "CTextMedium", 0, 0, teamcol, TEXT_ALIGN_CENTER, TEXT_ALIGN_TOP )
	cam.End3D2D()
end
end