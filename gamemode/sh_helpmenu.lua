if SERVER then
	util.AddNetworkString("ShowAbout")
	--[[function GM:ShowHelp(ply)
		print("SendToPly")
		net.Start("ShowAbout")
		net.Send(ply)
	end]]
	function HelpShow( ply )
		print("SendToPly")
		net.Start("ShowAbout")
		net.Send(ply)
	end
	hook.Add("ShowHelp", "HelpShow", HelpShow)
	 
	end

if CLIENT then
	function Panels()
	end
	Panels()
	surface.CreateFont( "AboutTitle",
	{
	font	= "Helvetica", --"CloseCaption_Bold", --Helvetica
	size	= 30,
	weight	= 800,
	blursize = .5,
	antialias = false--,
	--shadow = true
	})

	surface.CreateFont( "AboutBody",
	{
	font	= "Helvetica", --"CloseCaption_Bold", --Helvetica
	size	= 20,
	weight	= 800,
	blursize = .5,
	antialias = false--,
	--shadow = true
	})

	surface.CreateFont( "AboutSubBody",
	{
	font	= "Helvetica", --"CloseCaption_Bold", --Helvetica
	size	= 15,
	weight	= 800,
	blursize = .5,
	antialias = false--,
	--shadow = true
	})

	function SheetOne(derm)
		local SheetItem = vgui.Create( "DPanel" )
		SheetItem:SetDrawBackground(false)
		SheetItem:SetSize(derm:GetWide(), derm:GetTall()-20)
		local DLabel = vgui.Create("DLabel", SheetItem)
		--DLabel:SetSize(derm:GetWide(), derm:GetTall()-20)
		DLabel:SetText([[The point of this game is to fgt.
Please fgt.
Never fgt.]])
		DLabel:SetFont("AboutBody")
		DLabel:SizeToContents()
		DLabel:Center()
		DLabel:SetTextColor(Color(0,0,0,255))
		return SheetItem
	end
	
	function SheetTwo(derm)
		local SheetItem = vgui.Create( "DPanel" )
		SheetItem:SetDrawBackground(false)
		SheetItem:SetSize(derm:GetWide(), derm:GetTall()-20)
		local DLabel = vgui.Create("DLabel", SheetItem)
		--DLabel:SetSize(derm:GetWide(), derm:GetTall()-20)
		DLabel:SetText([[Always Engineer properly, guioses.
Never engineer badly.
Forever hold your engineering in high regard.]])
		DLabel:SetFont("AboutBody")
		DLabel:SizeToContents()
		DLabel:Center()
		DLabel:SetTextColor(Color(0,0,0,255))
		return SheetItem
	end
	
	function SheetThree(derm)
		local SheetItem = vgui.Create( "DPanel" )
		SheetItem:SetDrawBackground(false)
		SheetItem:SetSize(derm:GetWide(), derm:GetTall()-20)
		local DLabel = vgui.Create("DLabel", SheetItem)
		--DLabel:SetSize(derm:GetWide(), derm:GetTall()-20)
		DLabel:SetText([[To console, you must first console.
Do not  the console.
  the console.]])
		DLabel:SetFont("AboutBody")
		DLabel:SizeToContents()
		DLabel:Center()
		DLabel:SetTextColor(Color(0,0,0,255))
		return SheetItem
	end
	
	function DInfo()
		local DermaBG = vgui.Create("DPanel")
		local Derma = vgui.Create("DPanel")
		--local Derma = vgui.Create("DFrame")
		Derma:SetSize( ScrW()-20, ScrH()-20 )
		DermaBG:SetSize( ScrW()-17, ScrH()-17 )
		Derma:Center()
		DermaBG:Center()
		--Derma:SetBackgroundColor(Color(0,0,0,255))
		DermaBG:SetBackgroundColor(Color(0,0,0,255))
		DermaBG:MakePopup()
		Derma:MakePopup()
		
		local DermaButton = vgui.Create( "DButton", Derma )
		DermaButton:SetText( "Close" )
		DermaButton:SetPos( (ScrW()-20)/2-75, ScrH()-20-75 )
		DermaButton:SetSize( 150, 50 )
		--DermaButton:SetTextColor(Color(255,255,255,255))
		DermaButton.DoClick = function ()
			DermaBG:Remove()
			Derma:Remove()
		end
		
		local PropertySheet = vgui.Create( "DPropertySheet", Derma )
		PropertySheet:SetSize( Derma:GetSize() )
		PropertySheet:SetFadeTime(0.1)
		
		--SheetItemOne:SizeToContents()
		PropertySheet:AddSheet( "Introduction", SheetOne(Derma), "icon16/user.png", false, false, "Swaet babby jeases" )
		PropertySheet:AddSheet( "Engineering", SheetTwo(Derma), "icon16/wrench.png", false, false, "Eheeheheheh")
		--PropertySheet:AddSheet( "Consoles", SheetThree(Derma), "icon16/check_off", false, false, "So much sweg")
		PropertySheet:AddSheet( "Consoles", SheetThree(Derma), "icon16/application_xp_terminal.png", false, false, "So much sweg (Just kidding, broke to hell)")
		local DermaButton = vgui.Create( "DButton", Derma )
		DermaButton:SetText( "Close" )
		DermaButton:SetPos( (ScrW()-20)/2-75, ScrH()-20-75 )
		DermaButton:SetSize( 150, 50 )
		--DermaButton:SetTextColor(Color(255,255,255,255))
		DermaButton.DoClick = function ()
			DermaBG:Remove()
			Derma:Remove()
		end
	end
	net.Receive("ShowAbout", DInfo)
end
