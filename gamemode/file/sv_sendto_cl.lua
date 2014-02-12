local SVMesssage = {}
SVMessage.players = {}
SVMessage.sv_table = {}
SVMessage.sv_string = {}
SVMessage.sv_integer = {}
SVMessage.sv_entity = {}
SVMessage.sv_extras = {}

Message = {}
Message.netStr = ""

--Set Players to send to
function Message:SetPlayers(plyTable)
    self.ply = plyTable
    SVMessage.players = plyTable
end

function Message:SetPlayerGroups(groupTable)
    for k,v in pairs(groupTable) do
        for c,b in pairs(players.GetAll) do
            if b.IsUserGroup(groupTable[v]) then
                self:SetPlayers(b)
            end
        end
    end
end

--Writing Methods
function Message:WriteTable(plyTable)
    self.tble =  plyTable
    SVMessage.sv_table
end

function Message:WriteString(plyTable)
    self.str = plyTable
    SVMessage.sv_string = plyTable
end

function Message:WriteInteger(plyTable)
    self.inte = plyTable
    SVMessage.sv_integer = plyTable
end

function Message:WriteEntity(plyTable)
    self.enti = plyTable
    SVMessage.sv_entity = plyTable
end

function Message:WriteExtras(plyTable)
    self.mEX = plyTable
    SVMessage.sv_extras = plyTable
end

function Message:NetworkString(str)
    Message.netStr = str    
end
--End of writing

function Message:Send()
    if Message.netStr == "" then
        util.AddNetworkString("Server_Message")
    else
        util.AddNetworkString(Message.netStr)
    end
    
    
end

