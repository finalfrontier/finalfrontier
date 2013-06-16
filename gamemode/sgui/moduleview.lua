local BASE = "base"

GUI.BaseName = BASE

GUI._slot = nil



if CLIENT then
    function GUI:Draw()

        
        self.Super[BASE].Draw(self)
    end
end
