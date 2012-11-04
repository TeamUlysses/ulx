module( "UPS", package.seeall )

function canEnterVehicle( ply, vehicle )
	if not vehicle or not vehicle:IsValid() then -- Something removed the ent
		return
	end
	
	if not query( ply, vehicle, ACTID_ENTERVEHICLE, { QUERY_NOSOUND, QUERY_TAKEOWNERLESS } ) then
		return false
	end
end
hook.Add( "CanPlayerEnterVehicle", "UPSCanEnterVehicle", canEnterVehicle, -15 )

function canUnfreeze( ply, ent )
	if not ent or not ent:IsValid() then -- Something removed the ent
		return
	end
	
	if not query( ply, ent, ACTID_UNFREEZE ) then
		return false
	end
end
hook.Add( "CanPlayerUnfreeze", "UPSCanUnfreeze", canUnfreeze, -15 )

function canTool( ply, tr, toolmode, second )
	if not tr.Entity or not tr.Entity:IsValid() then -- Something removed the ent
		return
	end
	
	-- In the case of the nail gun, let's check the entity they're nailing TO first.
	if toolmode == "nail" and not second then
		local tr2 = {}
		tr2.start = tr.HitPos
		tr2.endpos = tr.HitPos + ply:GetAimVector() * 16
		tr2.filter = { ply, tr.Entity }
		local trace = util.TraceLine( tr2 )

		if trace.Entity and trace.Entity:IsValid() and not trace.Entity:IsPlayer() then
			if canTool( ply, trace, toolmode, true ) == false then
				return false
			end
		end
	end
	
	-- In the case of alternate hydraulic, let's check the entity they're constraining TO first.
	if toolmode == "hydraulic" and not second and ply:KeyDown( IN_ATTACK2 ) and not ply:KeyDownLast( IN_ATTACK2 ) then
		local trace = {}
		trace.start = tr.HitPos
		trace.endpos = trace.start + (tr.HitNormal * 16384)
		trace.filter = { ply }
		if tr.Entity:IsValid() then
			table.insert( trace.filter, tr.Entity )
		end
		
		local tr2 = util.TraceLine( trace )
		
		-- This if statement looks really odd, but we're trying to replicate the hydraulic's choosing behavoir as closely as possible.
		if tr2.Hit and 
				not (tr.HitWorld and tr2.HitWorld) and
				not (tr.Entity:IsValid() and tr.Entity:IsPlayer()) and
				not (tr2.Entity:IsValid() and tr2.Entity:IsPlayer()) then

			if canTool( ply, tr2, toolmode, true ) == false then
				return false
			end
		end
	end

	-- In the case of the remover, we have to make sure they're not trying to right click remove one of the no delete ents
	if toolmode == "remover" and ply:KeyDown( IN_ATTACK2 ) and not ply:KeyDownLast( IN_ATTACK2 ) then
		if not queryAll( ply, tr.Entity, ACTID_REMOVE ) then
			return false
		end
		return
	end

	if not table.HasValue( moveWhitelist, toolmode ) then
		if canPhysgun( ply, tr.Entity ) == false then
			return false
		end	
	end

	if not table.HasValue( delWhitelist, toolmode ) then
		if not query( ply, tr.Entity, ACTID_REMOVE ) then
			return false
		end
	end
	
	-- Otherwise, do a general check!
	if not query( ply, tr.Entity, ACTID_TOOL ) then
		return false
	end
end
hook.Add( "CanTool", "UPSCanTool", canTool, -15 )

function canDamage( ent, dmginfo )
	local inflicter = dmginfo:GetInflictor()
	local attacker = dmginfo:GetAttacker()
	
	if not ent or not ent:IsValid() or not inflictor or not inflictor:IsValid() then -- Something deleted it along the way
		return
	end
	
	if attacker:GetClass() == "prop_combine_ball" then -- cballs don't report attacker right
		attacker = inflictor:GetOwner()
	elseif attacker:UPSGetOwnerEnt() then -- Players might try to destroy props with other props
		attacker = attacker:UPSGetOwnerEnt()
	end
	
	if not attacker:IsValid() or not attacker:IsPlayer() then -- Let non-players be on their merry way
		if ent:IsOnFire() then ent.UPSFire = CurTime() end -- Record fires for anti-fire protection	
		return
	end
	
	if not query( attacker, ent, ACTID_DAMAGE, { QUERY_NOSOUND } ) then
		dmginfo:ScaleDamage( 0 )
		if not ent.UPSFire or ent.UPSFire > CurTime() + 0.5 then -- If not previously on fire or the fire was old, put it out!
			ent.UPSFire = nil
			ent:Extinguish()
			ULib.queueFunctionCall( ent.Extinguish, ent ) -- RPG delays the ignite for some reason...
		end
		return false
	end	
end
hook.Add( "EntityTakeDamage", "UPSCanDamage", canDamage, -15 )

function canPickup( ply, ent )
	if not ent or not ent:IsValid() then -- For some reason garry allowed null ents in here.
		return
	end
		
	if not query( ply, ent, ACTID_PHYSGUN, { QUERY_NOSOUND, QUERY_TAKEOWNERLESS } ) then
		return false
	end
end
hook.Add( "GravGunPickupAllowed", "UPSCanPickup", canPickup, -15 )
hook.Add( "GravGunPunt", "UPSCanPunt", canPickup, -15 )

function canFreeze( weapon, physobj, ent, ply )
	if not query( ply, ent, ACTID_FREEZE ) then
		return false
	end
end
hook.Add( "OnPhysgunFreeze", "UPSCanFreeze", canFreeze, -15 )

function canPhysgun( ply, ent )
	if not ent or not ent:IsValid() then -- Something removed the ent
		return
	end
	
	local physobj = ent:GetPhysicsObject()
	if physobj:IsValid() and not physobj:IsMoveable() and 
			not query( ply, ent, ACTID_UNFREEZE, { QUERY_TAKEOWNERLESS } ) then -- If it's frozen check for frozen permission first.
		return false
	end

	if not queryAll( ply, ent, ACTID_PHYSGUN, { QUERY_TAKEOWNERLESS } ) then
		return false
	end
end
hook.Add( "PhysgunPickup", "UPSCanPhysgun", canPhysgun, -15 )

function canUse( ply, ent )
	if not ent or not ent:IsValid() then -- Something removed the ent
		return
	end
	
	if ent:IsVehicle() then -- If this a vehicle, we want to use the vehicle hook.
		return
	end
	
	if not query( ply, ent, ACTID_USE, { QUERY_TAKEOWNERLESS } ) then
		return false
	end
end
hook.Add( "PlayerUse", "UPSCanUse", canUse, -15 )

--[[
Meg's notes to self on each callback:
	* Allow a client cvar to disable/enable individual compartments (IE, vehicle blocks) as well as entirety.
	* Additional toggle for admin perms to override.
	* Take possesion of a prop on usage attempt if it's up for grabs (GRAB STRUCTURE NOT JUST ENT).
	* lua_run Entity( 1 ):GetEyeTrace().Entity:UPSClearOwner()
	* lua_run print( Entity( 1 ):GetEyeTrace().Entity:UPSGetOwner() )
	* lua_run Entity( 1 ):GetEyeTrace().Entity:UPSSetOwnerEnt( Entity( 2 ) )
	* lua_run UPS.nameToID( Entity( 2 ):UniqueID(), Entity( 2 ):Nick() ) UPS.createID( Entity( 2 ) )
	* lua_run hook.Add( "UPSPostQuery", "UPSMapProtection2", print )
	* lua_run hook.Add( "UPSPostQuery", "UPSMapProtection2", function( a, b, c ) print( a, b, c ) print( debug.traceback( "here", 2 ) ) end )
	* Recap: Three strings of notice change between each callback... admin perm string, admin allowed to override cvar, client allowing it anyways cvar.
	
TODO later (maybe):
	* Client can specify per-prop whether it falls under protection or not
]]--
