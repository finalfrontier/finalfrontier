
--[[---------------------------------------------------------
   Initializes the effect. The data is a table of data 
   which was passed from the server.
-----------------------------------------------------------]]
function EFFECT:Init( data )

	local TargetEntity = data:GetEntity()
	if ( !TargetEntity || !TargetEntity:IsValid() ) then return end
	
	local vOffset = data:GetOrigin()
	local Low, High = TargetEntity:WorldSpaceAABB()
	Low = Low - TargetEntity:GetPos() + vOffset
	High = High - TargetEntity:GetPos() + vOffset

	local NumParticles = TargetEntity:BoundingRadius()
	NumParticles = NumParticles * 8
	
	NumParticles = math.Clamp( NumParticles, 32, 256 )
		
	local emitter = ParticleEmitter( vOffset )
	
		for i=0, NumParticles do
		
			local vPos = Vector( math.Rand(Low.x,High.x), math.Rand(Low.y,High.y), math.Rand(Low.z,High.z) )
			local particle = emitter:Add( "effects/spark", vPos )
			if (particle) then
				if math.random() < 0.5 then
					particle:SetVelocity( (vPos - vOffset) * (5 + math.random() * 10))
					particle:SetGravity( Vector( 0, 0, -600 ) )
					particle:SetAirResistance( 25 )
					particle:SetDieTime( math.Rand( 1.5, 2.5 ) )
				else
					particle:SetVelocity( (vPos - vOffset) * 1 )
					particle:SetGravity( Vector( 0, 0, -100 ) )
					particle:SetAirResistance( 100 )
					particle:SetDieTime( math.Rand( 0.5, 1.0 ) )
				end

				particle:SetLifeTime( 0 )
				particle:SetStartAlpha( math.Rand( 200, 255 ) )
				particle:SetEndAlpha( 0 )
				particle:SetStartSize( 2 )
				particle:SetEndSize( 0 )
				particle:SetRoll( math.Rand(0, 360) )
				particle:SetRollDelta( 0 )
				
				particle:SetCollide( true )
				particle:SetBounce( 0.3 )
				
			end
			
		end
		
	emitter:Finish()
	
end


--[[---------------------------------------------------------
   THINK
-----------------------------------------------------------]]
function EFFECT:Think( )
	return false
end

--[[---------------------------------------------------------
   Draw the effect
-----------------------------------------------------------]]
function EFFECT:Render()
end
