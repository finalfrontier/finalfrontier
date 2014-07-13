local BASE = "base"

GUI.BaseName = BASE

GUI.CanClick = true

GUI.DisabledColor = Color(86,86,86)
GUI.Color = Color(244,244,244)

GUI._direction = 0

local _currentPage = 0
local _amountOfPages = 1

local _directionTable = {-1 = "◄", 1 = "►"}

function GUI:OnClick(x, y, button)
	_currentPage = _currentPage + self._direction
end

--Using Direction requires either 0 (left) or 2 (right) for now
function GUI:SetDirection(direction)
	if _directionTable[direction] then
		self.Text = _directionTable[direction]
		self._direction = direction - 1
	end
end

function GUI:SetPageAmount(amount)
	_amountOfPages = amount
end

function GUI:SetCurrentPage(page)
	_currentPage = page	
end

function GUI:GetCurrentPage()
	return _currentPage	
end

if CLIENT then
	function GUI:Draw()
		surface.SetDrawColor(self.Color)
		if self:HasParent() and self:GetParent():GetCurrent() == self then
			surface.DrawRect(self:GetGlobalRect())
			surface.SetTextColor(BLACK)
		else
			if self.CanClick and self:IsCursorInside() then
				surface.DrawOutlinedRect(self:GetGlobalRect())
			end
			if self.CanClick then
				surface.SetTextColor(self.Color)
			else
				surface.SetTextColor(self.DisabledColor)
			end
		end

		local x, y = self:GetGlobalCentre()
		surface.SetFont("CTextSmall")
		surface.DrawCentredText(x, y, self.Text)

		self.Super[BASE].Draw(self)
	end
end
