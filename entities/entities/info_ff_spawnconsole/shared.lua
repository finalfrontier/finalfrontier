if SERVER then AddCSLuaFile("shared.lua") end

local SCREEN_DRAWSCALE = 16

local UPDATE_FREQ = 0.5
local CURSOR_UPDATE_FREQ = 0.25
local MAX_USE_DISTANCE = 64

local MAIN_GUI_CLASS = "screen"

ENT.Type = "anim"
ENT.Base = "base_anim"

ENT.Width = 0
ENT.Height = 0

ENT.UI = nil
ENT.Layout = nil

if SERVER then
    local enableSounds = {
        "buttons/button9.wav"
    }

    local disableSounds = {
        "buttons/blip1.wav"
    }

    util.AddNetworkString("CursorPos")

    ENT._lastPage = page.ACCESS
    
    ENT.NextGUIID = 1
    ENT.FreeGUIIDs = nil

    function ENT:KeyValue(key, value)
        if key == "respawn" then
            self._respawn = tostring(value)
        end
    end
