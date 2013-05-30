-- Client Initialization
-- Includes

include("gmtools/nwtable.lua")

include("sh_bounds.lua")
include("sh_matrix.lua")
include("sh_transform2d.lua")
include("sh_sgui.lua")
include("sh_systems.lua")
include("cl_door.lua")
include("cl_room.lua")
include("cl_ship.lua")
include("cl_ships.lua")

WHITE = Material("vgui/white")
PLAYER_DOT = Material("playerdot.png", "smooth")
SHIP_ICON = Material("objects/ship.png", "smooth")
POWER = Material("power.png", "smooth")

-- Global Functions

function Pulse(period)
	return (math.sin(CurTime() * math.pi * 2 / period) + 1) * 0.5
end

function LerpColour(a, b, t)
	return Color(
		a.r + (b.r - a.r) * t,
		a.g + (b.g - a.g) * t,
		a.b + (b.b - a.b) * t,
		a.a + (b.a - a.a) * t
	)
end

function FormatNum(num, leading, trailing)
	local mul = math.pow(10, trailing)
	num = math.Round(num * mul) / mul

	local str = tostring(num)
	local index = string.find(str, "%.")
	if not index then
		index = string.len(str)
		if trailing > 0 then
			str = str .. "." .. string.rep("0", trailing)
		end
	else
		local dec = string.len(str) - index
		if trailing > dec then
			str = str .. string.rep("0", trailing - dec)
		end
		index = index - 1
	end

	if index < leading then
		str = string.rep("0", leading - index) .. str
	end

	return str
end

local sin, cos = math.sin, math.cos
function CreateCircle(x, y, radius)
	local quality = math.min(256, 4 * math.sqrt(radius) + 8)
	local verts = {}
	local ang = 0
	for i = 1, quality do
		ang = i * math.pi * 2 / quality
		verts[i] = { x = x + cos(ang) * radius, y = y + sin(ang) * radius }
	end
	return verts
end

function CreateHollowCircle(x, y, innerRadius, outerRadius, startAngle, rotation)
	rotation = math.min(rotation or (math.pi * 2), math.pi * 2)
	startAngle = startAngle or 0
	local quality = math.min(256, 4 * math.sqrt(outerRadius) + 8)
	local verts = {}
	local angA, angB
	local mul = math.pi * 2 / quality
	local count = quality * rotation / (math.pi * 2)
	for i = 0, count do
		angA = startAngle + i * mul
		angB = angA + mul
		if angB - startAngle > rotation then angB = startAngle + rotation end
		sinA, cosA = sin(angA), cos(angA)
		sinB, cosB = sin(angB), cos(angB)
		verts[i + 1] = {
			{ x = x + cosA * innerRadius, y = y + sinA * innerRadius },
			{ x = x + cosA * outerRadius, y = y + sinA * outerRadius },
			{ x = x + cosB * outerRadius, y = y + sinB * outerRadius },
			{ x = x + cosB * innerRadius, y = y + sinB * innerRadius }
		}
	end
	return verts
end

function WrapAngle(ang)
	return ang - math.floor(ang / (math.pi * 2)) * math.pi * 2
end

function surface.DrawCentredText(x, y, text)
	local wid, hei = surface.GetTextSize(text)
	surface.SetTextPos(x - wid / 2, y - hei / 2)
	surface.DrawText(text)
end

local WHITE = Material("vgui/white")
local CIRCLE = Material("circle.png", "smooth")
function surface.DrawCircle(x, y, radius)
	surface.SetMaterial(CIRCLE)
	surface.DrawTexturedRect(x - radius, y - radius, radius * 2, radius * 2)
	surface.SetMaterial(WHITE)
end

function surface.DrawPoints(points)
    for _, v in ipairs(points) do
        surface.DrawRect(v.x - 0.5, v.y - 0.5, 1, 1)
    end
end

local CONNECTOR = Material("connector.png", "smooth")
function surface.DrawConnector(sx, sy, ex, ey, width)
	local dx = ex - sx
	local dy = ey - sy
	local diff = math.sqrt(dx * dx + dy * dy)
	local ang = -math.atan2(dy, dx) / math.pi * 180
	surface.SetMaterial(CONNECTOR)
	surface.DrawTexturedRectRotated(sx + dx * 0.5, sy + dy * 0.5, diff, width, ang)
	surface.SetMaterial(WHITE)
end

-- TODO: Add check to avoid complex polys in output
function FindConvexPolygons(poly, output)
	output = output or {}
	local cur = {}
	local l = poly[#poly]
	local n = poly[1]
	local i = 1
	while i <= #poly do
		local v = n
		table.insert(cur, v)
		n = poly[(i % #poly) + 1]
		i = i + 1
		
		local la = math.atan2(l.y - v.y, l.x - v.x)
		local subPoly = { v }
		
		while n ~= v do
			table.insert(subPoly, n)
			if i > #poly + 1 then
				table.remove(cur, 1)
			end
			local na = math.atan2(n.y - v.y, n.x - v.x)
			local ang = WrapAngle(na - la)
			
			if ang > math.pi then
				n = poly[(i % #poly) + 1]
				i = i + 1
			else
				if #subPoly > 2 then
					FindConvexPolygons(subPoly, output)
				end
				break
			end
		end
		
		if n == v then
			break
		end
		l = v
	end
	table.insert(output, cur)
	return output
end

function IsPointInsidePoly(poly, x, y)
	for i, v in ipairs(poly) do
		local n = poly[(i % #poly) + 1]
		local ax, ay = n.x - v.x, n.y - v.y
		local bx, by =   x - v.x,   y - v.y
		local cross = ax * by - ay * bx
		if cross < 0 then return false end
	end
	
	return true
end

function IsPointInsidePolyGroup(polys, x, y)
	for _, poly in ipairs(polys) do
		if IsPointInsidePoly(poly, x, y) then return true end
	end
	
	return false
end

-- Gamemode Overrides

function GM:Initialize()
	MsgN("Final Frontier client-side is initializing...")

	self.BaseClass:Initialize()
end

function GM:Think()
	ships.Think()
end

function GM:HUDWeaponPickedUp(weapon)
	if weapon:GetClass() == "weapon_ff_unarmed" then return end
	
	self.BaseClass:HUDWeaponPickedUp(weapon)
end

function GM:PlayerBindPress(ply, bind, pressed)
	if ply ~= LocalPlayer() then return end
	if ply:GetNWBool("usingScreen") then
		local screen = ply:GetNWEntity("screen")
		if screen then
			if bind == "+attack" then
				screen:Click(MOUSE1)
			elseif bind == "+attack2" then
				screen:Click(MOUSE2)
			end
		end
	end
end
