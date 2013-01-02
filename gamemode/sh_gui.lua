MsgN("Loading gui...")
local files = file.Find("finalfrontier/gamemode/gui/*.lua", "LUA")
for i, file in ipairs(files) do	
	local name = string.sub(file, 0, string.len(file) - 4)

	if SERVER then
		MsgN("  Found gui element " .. name)
		AddCSLuaFile("gui/" .. file)
	end
	if CLIENT then
		MsgN("  Loading gui element " .. name)
		include("gui/" .. file)
	end
end
