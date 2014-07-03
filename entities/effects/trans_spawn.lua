-- Copyright (c) 2014 James King [metapyziks@gmail.com]
-- 
-- This file is part of Final Frontier.
-- 
-- Final Frontier is free software: you can redistribute it and/or modify
-- it under the terms of the GNU Lesser General Public License as
-- published by the Free Software Foundation, either version 3 of
-- the License, or (at your option) any later version.
-- 
-- Final Frontier is distributed in the hope that it will be useful,
-- but WITHOUT ANY WARRANTY; without even the implied warranty of
-- MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
-- GNU General Public License for more details.
-- 
-- You should have received a copy of the GNU Lesser General Public License
-- along with Final Frontier. If not, see <http://www.gnu.org/licenses/>.

local matRefract = Material("models/spawn_effect")
local matLight = Material("models/spawn_effect2")

EFFECT._time = 0
EFFECT._lifeTime = 0
EFFECT._parentEntity = nil
EFFECT._oldpos = nil

function EFFECT:Init(data)
    self._time = 0.5
    self._lifeTime = CurTime() + self._time
    
    local ent = data:GetEntity()
    
    if not IsValid(ent) or not ent:GetModel() then return end
    
    self._parentEntity = ent
    self:SetModel(ent:GetModel())    
    self:SetPos(ent:GetPos())
    self:SetAngles(ent:GetAngles())
    self:SetParent(ent)

    self._oldpos = data:GetOrigin()
    
    self._parentEntity.RenderOverride = self.RenderParent
    self._parentEntity._spawnEffect = self
end

function EFFECT:Think()
    if not IsValid(self._parentEntity) then return false end
    
    local pos = self._parentEntity:GetPos();
    self:SetPos(pos + (EyePos() - pos):GetNormal())
    
    if self._lifeTime > CurTime() then return true end
    
    self._parentEntity.RenderOverride = nil
    self._parentEntity._spawnEffect = nil
            
    return false
end

function EFFECT:Render()
    return
end

function EFFECT:RenderOverlay(entity)
    local t = (self._lifeTime - CurTime()) / self._time
    t = math.Clamp(t, 0, 1)
    
    local pos = EyePos() + (entity:GetPos() - EyePos()) * 0.01
    
    local wasClipping = self:StartClip(entity, 1.2)
    cam.Start3D(pos, EyeAngles())
    if render.GetDXLevel() >= 80 then
        render.UpdateRefractTexture()
        
        matRefract:SetFloat("$refractamount", t * 0.1)
    
        render.MaterialOverride(matRefract)
        entity:DrawModel()
        render.MaterialOverride(0)
    end
    cam.End3D()
    render.PopCustomClipPlane()
    render.EnableClipping(wasClipping);
end

function EFFECT:RenderParent()
    local wasClipping = self._spawnEffect:StartClip(self, 1)
    self:DrawModel()
    render.PopCustomClipPlane()
    render.EnableClipping(wasClipping);
    
    self._spawnEffect:RenderOverlay(self)
end

function EFFECT:StartClip(model, spd)
    local mn, mx = model:GetRenderBounds()
    mx.x = mn.x
    mx.y = mn.y
    local up = (mx-mn):GetNormal()
    local bottom = model:GetPos() + mn;
    local top = model:GetPos() + mx;
    
    local t = (self._lifeTime - CurTime()) / self._time
    t = math.Clamp(t / spd, 0, 1)
    
    local lerped = LerpVector(t, bottom, top)
    local distance = up:Dot(lerped);
        
    local wasClipping = render.EnableClipping(true);
    render.PushCustomClipPlane(up, distance);
    return wasClipping
end
