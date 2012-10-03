if SERVER then
   AddCSLuaFile( "shared.lua" )
end

SWEP.HoldType = "normal"

if CLIENT then
   SWEP.PrintName = "Unarmed"
   SWEP.Slot      = 5

   SWEP.ViewModelFOV = 10
end

SWEP.Base = "weapon_base"
SWEP.ViewModel  = "models/weapons/v_crowbar.mdl"
SWEP.WorldModel = "models/weapons/w_crowbar.mdl"

SWEP.Primary.ClipSize       = -1
SWEP.Primary.DefaultClip    = -1
SWEP.Primary.Automatic      = false
SWEP.Primary.Ammo           = "none"
SWEP.Secondary.ClipSize     = -1
SWEP.Secondary.DefaultClip  = -1
SWEP.Secondary.Automatic    = false
SWEP.Secondary.Ammo         = "none"

SWEP.AllowDelete = false
SWEP.AllowDrop = false

function SWEP:Initialize()
	self:SetWeaponHoldType( "pistol" )
end

function SWEP:GetClass()
   return "weapon_ff_unarmed"
end

function SWEP:OnDrop()
   self:Remove()
end

function SWEP:ShouldDropOnDie()
   return false
end

function SWEP:PrimaryAttack()
   self.Owner:SetAnimation( PLAYER_ATTACK1 )
end

function SWEP:SecondaryAttack()
end

function SWEP:Reload()
end

function SWEP:Deploy()
   if SERVER and IsValid(self.Owner) then
      self.Owner:DrawViewModel(false)
   end
   return true
end

function SWEP:Holster()
   return not self.Owner:GetNWBool( "usingScreen" )
end

function SWEP:HUDShouldDraw()
	return element ~= "CHudWeaponSelection"
end

function SWEP:DrawWorldModel()
end

function SWEP:DrawWorldModelTranslucent()
end
