local BASE = "missilebase"

WPN.BaseName = BASE

WPN.MaxTier = 5

WPN.MaxPower = { 1, 3 }
WPN.MaxCharge = { 8, 16 }
WPN.ShotCharge = { 8, 12 }

WPN.Homing = true
WPN.Speed = { 1 / 16, 1 / 16 }
WPN.Lateral = { 1, 1 }
WPN.LifeTime = { 6, 8 }

WPN.BaseDamage = { 10, 50 }
WPN.PierceRatio = { 0, 0 }
WPN.ShieldMult = { 4, 4 }

if CLIENT then
    WPN.FullName = "Janus Missile"
    WPN.Color = Color(255, 255, 255, 255)
end
