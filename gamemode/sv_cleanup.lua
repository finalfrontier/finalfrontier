-- Created by Lawlypops
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

function Cleanup()
    for _, mdl in ipairs(ents.FindByClass("prop_ff_module")) do mdl:Remove() end
    for _, mdl in ipairs(ents.FindByClass("prop_ff_weaponmodule")) do mdl:Remove() end

    for _, obj in ipairs(ents.FindByClass("info_ff_object")) do
        if obj:GetObjectType() ~= objtype.SHIP then
            obj:Remove()
        end
    end

    for _, ship in pairs(ships._dict) do
        ship:Reset()
    end
end

print("LOADED CLEANUP FILE===================================")
local step=CurTime()
local hasbeencleaned = true
local tobecleaned = false
local iscleaning = false
local playercount=table.Count(player.GetAll())

timer.Create( "ff_cleanup_timer", 600, 0, function() 
if GetConVar("ff_autoclean"):GetBool() then
	Cleanup()
end
hasbeencleaned=true iscleaning=false
end )
local initialized=false

function GM:Initialize()
    initialized=true --Prevent grabbing convar ff_autoclean before it exists
end

hook.Add( "Think", "ff_cleanup_think", function()
votecheck()

if step<CurTime() then
playercount=table.Count(player.GetAll())
if playercount==0 then
if initialized then
if GetConVar("ff_autoclean"):GetBool() then
print(playercount .. " Players online")
if timer.TimeLeft("ff_cleanup_timer") != nil then
print(timer.TimeLeft("ff_cleanup_timer") .. " Seconds until next cleanup")
end
else
print("0 players, but Autocleanup is disabled")
end end
end


if playercount==0 then
tobecleaned=true
else
tobecleaned=false
end
if tobecleaned and !iscleaning then
	timer.Start("ff_cleanup_timer")
	iscleaning=true
end
if playercount!=1 then
	timer.Stop("ff_cleanup_timer")
end
step=CurTime()+10

end

end)

local lastvote=CurTime()+600
local votetime=CurTime()
local votes=playercount
local voter=nil
local voted={}
local activevote=false
local updated=true

function GM:PlayerSay(ply, txt, teams)
	if txt=="/votereset" then
		if lastvote > CurTime() then
			ply:ChatPrint( "You must wait " .. math.Round(lastvote - CurTime()) .. " seconds to vote")
		elseif votetime > CurTime() then
			ply:ChatPrint( "There is already an active vote" )
		else
			voter=ply
			for k, plys in pairs( player.GetAll() ) do
				plys:ChatPrint( voter:Nick() .. " started a vote to reset. Type /yes or /no to vote.")
			end
			votetime=CurTime()+25
			votes=playercount+1
			table.Empty(voted)
			activevote=true
			updated=false
			
			timer.Create( "ff_voteingtimer", 5, 4, function()
				for k, voters in pairs( player.GetAll() ) do
					voters:ChatPrint( "Time Remaining on Reset Vote: " .. math.Round(votetime-CurTime()) .. " Seconds." )
				end
			end )
		end
	end
if activevote then
	if ply != voter then
		if !table.HasValue(voted, ply) then
			if txt == "/yes" then
				ply:ChatPrint( "You have voted yes" )
				votes=votes+1
				table.insert( voted, ply )
			elseif txt== "/no" then
				ply:ChatPrint( "You have voted no" )
				votes=votes-1
				table.insert( voted, ply )
			end
		else
			ply:ChatPrint( "You already voted" )
		end
			for k, voters in pairs( player.GetAll() ) do
				voters:ChatPrint( "Svore: " .. votes-playercount .. ".  " .. math.Round(votetime-CurTime()) .. " Seconds Remaining" )
			end
	else
		--ply:ChatPrint( "You started the vote" )
	end
else
	ply:ChatPrint("There is no vote active")
end

return ""
end

function votecheck()
	

if votetime < CurTime() and !updated then
	if votes > playercount then
		for k, voters in pairs( player.GetAll() ) do
			voters:ChatPrint( "Vote completed. Cleaning Up" )
			lastvote=CurTimer()+600
		end
		Cleanup()
	else
		for k, voters in pairs( player.GetAll() ) do
			voters:ChatPrint( "Vote failed. Not Enough Supporters." )
			lastvote=CurTimer()+300
		end
	end
timer.Stop("ff_voteingtimer")
activevote=false
updated=true
end
end
