local BASE = "page"

GUI.BaseName = BASE

GUI.StatusDial = nil

function GUI:Initialize()
	self.Super[BASE].Initialize(self)

	self.StatusDial = gui.Create(self, "statusdial")
end
