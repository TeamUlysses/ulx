--[[
	Title: Physics Helpers

	Various functions to make dealing with the HL2 physics engine a little easier.
]]


--[[
	Function: applyAccel

	Parameters:

		ent - The entity to apply the acceleration to
		magnitude - The amount of acceleration ( Use nil if the magnitude is specified in the direction )
		direction - The direction to apply the acceleration in ( if the magnitude is part of the direction, specify nil for the magnitude )
		dTime - *(Optional, defaults to 1)* The time passed since the last update in seconds ( IE: 0.5 for dTime would only apply half the acceleration )
]]
function ULib.applyAccel( ent, magnitude, direction, dTime )
	if dTime == nil then dTime = 1 end

	if magnitude ~= nil then
		direction:Normalize()
	else
		magnitude = 1
	end

	-- Times it by the time elapsed since the last update.
	local accel = magnitude * dTime
	-- Convert our scalar accel to a vector accel
	accel = direction * accel

	if ent:GetMoveType() == MOVETYPE_VPHYSICS then
		-- a = f/m , so times by mass to get the force.
		local force = accel * ent:GetPhysicsObject():GetMass()
		ent:GetPhysicsObject():ApplyForceCenter( force )
	else
		ent:SetVelocity( accel ) -- As it turns out, SetVelocity() is actually SetAccel() in GM10
	end
end


--[[
	Function: applyForce

	Parameters:

		ent - The entity to apply the force to
		magnitude - The amount of force ( Use nil if the magnitude is specified in the direction )
		direction - The direction to apply the force in ( if the magnitude is part of the direction, specify nil for the magnitude )
		dTime - *(Optional, defaults to 1)* The time passed since the last update in seconds ( IE: 0.5 for dTime would only apply half the force )
]]
function ULib.applyForce( ent, magnitude, direction, dTime )
	if dTime == nil then dTime = 1 end

	if magnitude ~= nil then
		direction:Normalize()
	else
		magnitude = 1
	end

	-- Times it by the time elapsed since the last update.
	local force = magnitude * dTime
	-- Convert our scalar force to a vector force
	force = direction * force

	if ent:GetMoveType() == MOVETYPE_VPHYSICS then
		ent:GetPhysicsObject():ApplyForceCenter( force )
	else
		-- Because we're not dealing with objects that have vphysics, they might not have a mass. This would cause errors, let's catch them here.
		local mass = ent:GetPhysicsObject():GetMass()
		if not mass then
			mass = 1
			Msg( "applyForce was called with a non-physics entity that doesn't have a mass. To continue calculations, we're assuming it has a mass of one. This could very well produce unrealistic looking physics!\n")
		end
		-- f = m*a, so divide it by mass to get the accel
		local accel = force * 1/mass
		ent:SetVelocity( accel ) -- As it turns out, SetVelocity() is actually SetAccel() in GM10
	end
end


--[[
	Function: applyAccelInCurDirection

	Applies an acceleration in the entities current *velocity* direction ( not the entity's heading ). See <applyAccel>.
        Basically makes the entity go faster or slower ( if a negative magnitude is passed ).

	Parameters:

		ent - The entity to apply the force to
		magnitude - The amount of acceleration
		dTime - *(Optional, defaults to 1)* The time passed since the last update in seconds ( IE: 0.5 for dTime would only apply half the acceleration )
]]
function ULib.applyAccelInCurDirection( ent, magnitude, dTime )
	local direction = ent:GetVelocity( entid ):GetNormalized()
	ULib.applyAccel( entid, magnitude, direction, dTime )
end


--[[
	Function: applyForceInCurDirection

	Applies a force in the entities current *velocity* direction ( not the entity's heading ). See <applyForce>.
        Basically makes the entity go faster or slower ( if a negative magnitude is passed ).

	Parameters:

		ent - The entity to apply the force to
		magnitude - The amount of force
		dTime - *(Optional, defaults to 1)* The time passed since the last update in seconds ( IE: 0.5 for dTime would only apply half the force )
]]
function ULib.applyForceInCurDirection( ent, magnitude, dTime )
	local direction = ent:GetVelocity( entid ):GetNormalized()
	ULib.applyForce( entid, magnitude, direction, dTime )
end