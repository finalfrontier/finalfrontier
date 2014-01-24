TEAM = {}
TEAM[1] = {number = 1, name = "Orange", color = Color(222,127,18,255), joinable = true}
TEAM[2] = {number = 2, name = "Blue", color = Color(0,0,255,255), joinable = true}
nextTeam = 3
team.SetUp(TEAM[1].number, TEAM[1].name, Color(222,127,18,255), TEAM[1].joinable)
team.SetUp(TEAM[2].number, TEAM[2].name, Color(0,0,255,255), TEAM[2].joinable)


local ShipPos = {}
ShipPos[TEAM[1].number] = Vector(-4720, 3883, 1208) 
ShipPos[TEAM[2].number] = Vector( 4720, 7973, 1208)

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
	
	plySetPos(GetSpawn(ply))

end

function GetSpawn(ply)
	
	plyTeam = ply:Team()
	return ShipPos[TEAM[plyTeam].number]
	
end

function CreateTeam(num, nam)
	if num == nil or num < nextTeam or TEAM[num] != nil then return end
	if name == nil then return end
	TEAM[num] = {number = num, name = nam, color = Color(0, 255, 255, 255), joinable = true}
	ShipPos[TEAM[num].number = Vector(-4720, 3883, 1208)
	team.Setup(TEAM[num])
	nextTeam = nextTeam + 1
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
