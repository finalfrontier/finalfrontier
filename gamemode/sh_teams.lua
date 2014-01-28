TEAM = {}
TEAM[1] = {number = 1, name = "Orange", color = {222,127,18,255}, joinable = true}
TEAM[2] = {number = 2, name = "Blue", color = {0,0,255,255}, joinable = true}
nextTeam = 3
team.SetUp(TEAM[1].number, TEAM[1].name, Color(222,127,18,255), TEAM[1].joinable)
team.SetUp(TEAM[2].number, TEAM[2].name, Color(0,0,255,255), TEAM[2].joinable)

local teamAddAllowed = false

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

function TEAM:GetName(tNum)
    return TEAM[tNum].name
end

function TEAM:IsName(tN)
   
    if self:GetName(tN) == TEAM[tN].name
        return true
    else
        return false
    end
    
end

function TEAM:GetNumber(tName)
   for v, b = table.Count(TEAM),1 do
       if TEAM[v].name == tName then
           return TEAM[v].number
       end
   end
   
end

function CheckTeams()
	--print(team.BestAutoJoinTeam())
	if team.NumPlayers(1)>team.NumPlayers(2) then
		return 2
	else
		return 1
	end
end

function SetTeam(ply, team)
    
    if teamAddAllowed == true then
        if ply:IsPlayer() then
            for v=0, 9, 1 do
                tNumCheck = string.StartWith(team, v)
                if tNumCheck == true
                    break
                end
            end
            if tNumCheck == true then
                TEAM:GetName(team)
                ply:SetTeam(team)
            end
            if tNumCheck == false then
               teamNumbs = TEAM:GetNumber(team)
               ply:SetTeam(teamNumbs)
            end
    end
    
end

function ModTeam(modType, teamN, modBy)
    
    teamBool = TEAM:IsName(teamN)
    if teamBool == true
        teamNumber = TEAM:GetNumber(teamN)
        teamName = teamN
    else
        teamNumber = teamN
        teamName = TEAM:GetName(teamN)
    end
    teamRed = TEAM[teamNumber].color[1]
    teamBlue = TEAM[teamNumber].color[2]
    teamGreen = TEAM[teamNumber].color[3]
    teamAlpha = TEAM[teamNumber].color[4]
    teamJoin = TEAM
    if string.lower(modType) == "r" then
        teamRed = modBy
        modColor = true
    elseif string.lower(modType) == "b" then
        teamBlue = modBy
        modColor = true
    elseif string.lower(modType) == "g" then
        teamGreen = modBy
        modColor = true
    elseif string.lower(modType) == "a" then
        teamAlpha = modBy
        modColor = true
        if teamAlpha < 145 then
            teamAlpha = 145
        end
    elseif string.lower(modType) == "na"
        teamName = modType
    elseif string.lower(modType) == "jo"
        teamJoin = modType
    end
    if teamNumber != nil and teamName != nil and teamRed != nil and teamBlue != nil and teamGreen != nil teamAlpha != nil then
        team.SetUp(teamNumber, teamName, Color(teamRed, teamGreen, teamBlue, teamAlpha), teamJoin)
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

function CreateETeam(nam)
	
	CreateTeam(nextTeam, nam)
	
end

function CreateTeam(num, nam)
	if num == nil or num < nextTeam or TEAM[num] != nil then return end
	if name == nil then return end
	TEAM[num] = {number = num, name = nam, color = {0, 255, 255, 255}, joinable = true}
	ShipPos[TEAM[num].number = Vector(-4720, 3883, 1208)
	team.Setup(TEAM[num].number, TEAM[num].name, Color(TEAM[num].color), TEAM[num].joinable )
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
