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

local BASE = "container"

page = {}
page.STATUS   = 1
page.ACCESS   = 2
page.SYSTEM   = 3
page.SECURITY = 4
page.OVERRIDE = 5

GUI.BaseName = BASE

GUI.Permission = 0

GUI.Pages = nil
GUI.TabMenu = nil
GUI.Tabs = nil

GUI.TabHeight = 48
GUI.TabMargin = 8

GUI._curpage = 0

function GUI:Initialize()
    self.Super[BASE].Initialize(self)

    self:SetWidth(self:GetScreen():GetWidth())
    self:SetHeight(self:GetScreen():GetHeight())
    self:SetCentre(0, 0)

    self.Pages = {}
    self.Pages[page.STATUS] = sgui.Create(self:GetScreen(), "statuspage")
    self.Pages[page.ACCESS] = sgui.Create(self:GetScreen(), "accesspage")
    if self:GetSystem() and self:GetSystem().SGUIName ~= "page" then
        self.Pages[page.SYSTEM] = sgui.Create(self:GetScreen(), self:GetSystem().SGUIName)
    end
    self.Pages[page.SECURITY] = sgui.Create(self:GetScreen(), "securitypage")
    self.Pages[page.OVERRIDE] = sgui.Create(self:GetScreen(), "overridepage")

    self.TabMenu = sgui.Create(self:GetScreen(), "tabmenu")
    self.TabMenu:SetSize(self:GetWidth() - self.TabMargin * 2, self.TabHeight)
    self.TabMenu:SetCentre(self:GetWidth() / 2, self.TabHeight / 2 + self.TabMargin)

    self.Tabs = {}
    self.Tabs[page.ACCESS] = self.TabMenu:AddTab("ACCESS")
    if self.Pages[page.SYSTEM] then
        self.Tabs[page.SYSTEM] = self.TabMenu:AddTab("SYSTEM")
    end
    self.Tabs[page.SECURITY] = self.TabMenu:AddTab("SECURITY")
    self.Tabs[page.OVERRIDE] = self.TabMenu:AddTab("OVERRIDE")

    if SERVER then
        local old = self.TabMenu.OnChangeCurrent
        self.TabMenu.OnChangeCurrent = function(tabmenu)
            old(tabmenu)
            self:SetCurrentPageIndex(page[tabmenu:GetCurrent().Text])
        end
    end

    self:UpdatePermissions()
    self:SetCurrentPageIndex(page.STATUS)
end

function GUI:UpdatePermissions()
    if self.Pages[page.SYSTEM] then
        self.Tabs[page.SYSTEM].CanClick = self.Permission >= permission.SYSTEM
    end
    self.Tabs[page.SECURITY].CanClick = self.Permission >= permission.SECURITY
end

function GUI:GetCurrentPageIndex()
    return self._curpage
end

function GUI:SetCurrentPageIndex(newpage)
    if newpage == self._curpage then return end

    local curpage = self:GetCurrentPage()
    if curpage then
        curpage:Leave()
        self:RemoveChild(curpage)

        if curpage ~= self.Pages[page.STATUS] then
            self.TabMenu:Remove()
        end
    end

    self._curpage = newpage

    curpage = self:GetCurrentPage()
    if curpage then
        if curpage ~= self.Pages[page.STATUS] then
            if not self.TabMenu:HasParent() then
                self:AddChild(self.TabMenu)
            end

            curpage:SetHeight(self:GetHeight() - self.TabHeight - self.TabMargin * 2)
            curpage:SetOrigin(0, self.TabHeight + self.TabMargin * 2)
        else
            curpage:SetHeight(self:GetHeight())
            curpage:SetOrigin(0, 0)
        end

        self:AddChild(curpage)
        curpage:Enter()
    end

    self.TabMenu:SetCurrent(self.Tabs[newpage])

    if SERVER then
        self:GetScreen():UpdateLayout()
    end
end

function GUI:GetCurrentPage()
    return self.Pages[self._curpage]
end

if SERVER then
    function GUI:UpdateLayout(layout)
        self.Super[BASE].UpdateLayout(self, layout)

        layout.permission = self.Permission

        if layout.curpage ~= self._curpage then
            layout.curpage = self._curpage
        end
    end
end

if CLIENT then
    function GUI:UpdateLayout(layout)
        if self.Permission ~= layout.permission then
            self.Permission = layout.permission
            self:UpdatePermissions()
        end

        self:SetCurrentPageIndex(layout.curpage)

        self.Super[BASE].UpdateLayout(self, layout)
    end
end
