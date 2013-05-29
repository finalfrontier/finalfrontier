local BASE = "page"

GUI.BaseName = BASE

GUI._label = nil

function GUI:Enter()
    self.Super[BASE].Enter(self)

    self._label = sgui.Create(self, "label")
    self._label:SetOrigin(8, 8)
end

if CLIENT then
    function GUI:UpdateLayout(layout)
        local sectors = ents.FindByClass("info_ff_sector")

        if #sectors > 0 then
            self._label.Text = tostring(#sectors) " sectors detected :D"
        else
            self._label.Text = "No sectors detected :("
        end

        self.Super[BASE].UpdateLayout(self, layout)
    end
end
