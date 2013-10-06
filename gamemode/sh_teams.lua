TEAM_Or = 1
team.SetUp(TEAM_Or, "Orange", Color(222,127,18,255), true)
TEAM_Bl = 2
team.SetUp(TEAM_Bl, "Blue", Color(0,0,255,255), true)

local ShipPos = {}
ShipPos[TEAM_Or] = Vector(-4720, 3883, 1208) 
ShipPos[TEAM_Bl] = Vector( 4720, 7984, 1208)

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
		ply:SetPos(ShipPos[TEAM_OR])
	else
		ply:SetPos(ShipPos[TEAM_Bl])
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

