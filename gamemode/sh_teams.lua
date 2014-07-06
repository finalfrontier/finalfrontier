-- Copyright (c) 2014 Spartan322 [Spartan322@live.com]
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

TEAM_Or = 1
team.SetUp(TEAM_Or, "Orange", Color(222,127,18,255), true)
TEAM_Bl = 2
team.SetUp(TEAM_Bl, "Blue", Color(0,0,255,255), true)

local ShipPos = {}
ShipPos[TEAM_Or] = Vector(-4720, 3883, 1208) 
ShipPos[TEAM_Bl] = Vector( 4720, 7973, 1208)

function TableShuffle(t)
	math.randomseed(CurTime())
	local n = #t
	while n > 2 do
		local k = math.random(1, n)
		t[n], t[k] = t[k], t[n]
		n = n - 1
	end
	return t
end

function CheckTeams()
	--print(team.BestAutoJoinTeam())
	if team.NumPlayers(1)>team.NumPlayers(2) then
		return 2
	else
		return 1
	end
end
if SERVER then
function ShipSet(ply)
	if ply:Team() == TEAM_Or then
		ply:SetPos(Vector(-4720, 3883, 1208))
	else
		ply:SetPos(Vector( -4717, 7984, 1208))
	end
end
end

if SERVER then
function ShuffleTeams()
	for k, v in pairs(player:GetAll()) do
		v:SetTeam(10)
		--v:ChatPrint("SpecTeam + "..team.GetName(v:Team()))
	end
	local TeamShuffle = TableShuffle(player:GetAll())
	for k, v in pairs(TeamShuffle) do
		v:SetTeam(CheckTeams())
		--v:ChatPrint(team.GetName(v:Team()))
	end
	TeamShuffle = {}
end
end
