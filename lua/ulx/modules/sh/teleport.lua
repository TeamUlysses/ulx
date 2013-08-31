CATEGORY_NAME = "Teleport"

-- Utility function for bring, goto, and send
local function playerSend( from, to, force )
	if not to:IsInWorld() and not force then return false end -- No way we can do this one

	local yawForward = to:EyeAngles().yaw
	local directions = { -- Directions to try
		math.NormalizeAngle( yawForward - 180 ), -- Behind first
		math.NormalizeAngle( yawForward + 90 ), -- Right
		math.NormalizeAngle( yawForward - 90 ), -- Left
		yawForward,
	}

	local t = {}
	t.start = to:GetPos() + Vector( 0, 0, 32 ) -- Move them up a bit so they can travel across the ground
	t.filter = { to, from }

	local i = 1
	t.endpos = to:GetPos() + Angle( 0, directions[ i ], 0 ):Forward() * 47 -- (33 is player width, this is sqrt( 33^2 * 2 ))
	local tr = util.TraceEntity( t, from )
	while tr.Hit do -- While it's hitting something, check other angles
		i = i + 1
		if i > #directions then	 -- No place found
			if force then
				from.ulx_prevpos = from:GetPos()
				from.ulx_prevang = from:EyeAngles()
				return to:GetPos() + Angle( 0, directions[ 1 ], 0 ):Forward() * 47
			else
				return false
			end
		end

		t.endpos = to:GetPos() + Angle( 0, directions[ i ], 0 ):Forward() * 47

		tr = util.TraceEntity( t, from )
	end

	from.ulx_prevpos = from:GetPos()
	from.ulx_prevang = from:EyeAngles()
	return tr.HitPos
end

function ulx.bring( calling_ply, target_ply )
	if not calling_ply:IsValid() then
		Msg( "If you brought someone to you, they would instantly be destroyed by the awesomeness that is console.\n" )
		return
	end

	if ulx.getExclusive( calling_ply, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( calling_ply, calling_ply ), true )
		return
	end

	if ulx.getExclusive( target_ply, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( target_ply, calling_ply ), true )
		return
	end

	if not target_ply:Alive() then
		ULib.tsayError( calling_ply, target_ply:Nick() .. " is dead!", true )
		return
	end

	if not calling_ply:Alive() then
		ULib.tsayError( calling_ply, "You are dead!", true )
		return
	end

	if calling_ply:InVehicle() then
		ULib.tsayError( calling_ply, "Please leave the vehicle first!", true )
		return
	end

	local newpos = playerSend( target_ply, calling_ply, target_ply:GetMoveType() == MOVETYPE_NOCLIP )
	if not newpos then
		ULib.tsayError( calling_ply, "Can't find a place to put the target!", true )
		return
	end

	if target_ply:InVehicle() then
		target_ply:ExitVehicle()
	end

	local newang = (calling_ply:GetPos() - newpos):Angle()

	target_ply:SetPos( newpos )
	target_ply:SetEyeAngles( newang )
	target_ply:SetLocalVelocity( Vector( 0, 0, 0 ) ) -- Stop!

	ulx.fancyLogAdmin( calling_ply, "#A brought #T", target_ply )
end
local bring = ulx.command( CATEGORY_NAME, "ulx bring", ulx.bring, "!bring" )
bring:addParam{ type=ULib.cmds.PlayerArg, target="!^" }
bring:defaultAccess( ULib.ACCESS_ADMIN )
bring:help( "Brings target to you." )

function ulx.goto( calling_ply, target_ply )
	if not calling_ply:IsValid() then
		Msg( "You may not step down into the mortal world from console.\n" )
		return
	end

	if ulx.getExclusive( calling_ply, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( calling_ply, calling_ply ), true )
		return
	end

	if not target_ply:Alive() then
		ULib.tsayError( calling_ply, target_ply:Nick() .. " is dead!", true )
		return
	end

	if not calling_ply:Alive() then
		ULib.tsayError( calling_ply, "You are dead!", true )
		return
	end

	if target_ply:InVehicle() and calling_ply:GetMoveType() ~= MOVETYPE_NOCLIP then
		ULib.tsayError( calling_ply, "Target is in a vehicle! Noclip and use this command to force a goto.", true )
		return
	end

	local newpos = playerSend( calling_ply, target_ply, calling_ply:GetMoveType() == MOVETYPE_NOCLIP )
	if not newpos then
		ULib.tsayError( calling_ply, "Can't find a place to put you! Noclip and use this command to force a goto.", true )
		return
	end

	if calling_ply:InVehicle() then
		calling_ply:ExitVehicle()
	end

	local newang = (target_ply:GetPos() - newpos):Angle()

	calling_ply:SetPos( newpos )
	calling_ply:SetEyeAngles( newang )
	calling_ply:SetLocalVelocity( Vector( 0, 0, 0 ) ) -- Stop!

	ulx.fancyLogAdmin( calling_ply, "#A teleported to #T", target_ply )
end
local goto = ulx.command( CATEGORY_NAME, "ulx goto", ulx.goto, "!goto" )
goto:addParam{ type=ULib.cmds.PlayerArg, target="!^", ULib.cmds.ignoreCanTarget }
goto:defaultAccess( ULib.ACCESS_ADMIN )
goto:help( "Goto target." )

function ulx.send( calling_ply, target_from, target_to )
	if target_from == target_to then
		ULib.tsayError( calling_ply, "You listed the same target twice! Please use two different targets.", true )
		return
	end

	if ulx.getExclusive( target_from, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( target_from, calling_ply ), true )
		return
	end

	if ulx.getExclusive( target_to, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( target_to, calling_ply ), true )
		return
	end

	local nick = target_from:Nick() -- Going to use this for our error (if we have one)

	if not target_from:Alive() or not target_to:Alive() then
		if not target_to:Alive() then
			nick = target_to:Nick()
		end
		ULib.tsayError( calling_ply, nick .. " is dead!", true )
		return
	end

	if target_to:InVehicle() and target_from:GetMoveType() ~= MOVETYPE_NOCLIP then
		ULib.tsayError( calling_ply, "Target is in a vehicle!", true )
		return
	end

	local newpos = playerSend( target_from, target_to, target_from:GetMoveType() == MOVETYPE_NOCLIP )
	if not newpos then
		ULib.tsayError( calling_ply, "Can't find a place to put them!", true )
		return
	end

	if target_from:InVehicle() then
		target_from:ExitVehicle()
	end

	local newang = (target_from:GetPos() - newpos):Angle()

	target_from:SetPos( newpos )
	target_from:SetEyeAngles( newang )
	target_from:SetLocalVelocity( Vector( 0, 0, 0 ) ) -- Stop!

	ulx.fancyLogAdmin( calling_ply, "#A transported #T to #T", target_from, target_to )
end
local send = ulx.command( CATEGORY_NAME, "ulx send", ulx.send, "!send" )
send:addParam{ type=ULib.cmds.PlayerArg, target="!^" }
send:addParam{ type=ULib.cmds.PlayerArg, target="!^" }
send:defaultAccess( ULib.ACCESS_ADMIN )
send:help( "Goto target." )

function ulx.teleport( calling_ply, target_ply )
	if not calling_ply:IsValid() then
		Msg( "You are the console, you can't teleport or teleport others since you can't see the world!\n" )
		return
	end

	if ulx.getExclusive( target_ply, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( target_ply, calling_ply ), true )
		return
	end

	if not target_ply:Alive() then
		ULib.tsayError( calling_ply, target_ply:Nick() .. " is dead!", true )
		return
	end

	local t = {}
	t.start = calling_ply:GetPos() + Vector( 0, 0, 32 ) -- Move them up a bit so they can travel across the ground
	t.endpos = calling_ply:GetPos() + calling_ply:EyeAngles():Forward() * 16384
	t.filter = target_ply
	if target_ply ~= calling_ply then
		t.filter = { target_ply, calling_ply }
	end
	local tr = util.TraceEntity( t, target_ply )

	local pos = tr.HitPos

	if target_ply == calling_ply and pos:Distance( target_ply:GetPos() ) < 64 then -- Laughable distance
		return
	end

	target_ply.ulx_prevpos = target_ply:GetPos()
	target_ply.ulx_prevang = target_ply:EyeAngles()

	if target_ply:InVehicle() then
		target_ply:ExitVehicle()
	end

	target_ply:SetPos( pos )
	target_ply:SetLocalVelocity( Vector( 0, 0, 0 ) ) -- Stop!

	if target_ply ~= calling_ply then
		ulx.fancyLogAdmin( calling_ply, "#A teleported #T", target_ply ) -- We don't want to log otherwise
	end
end
local teleport = ulx.command( CATEGORY_NAME, "ulx teleport", ulx.teleport, {"!tp", "!teleport"} )
teleport:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional }
teleport:defaultAccess( ULib.ACCESS_ADMIN )
teleport:help( "Teleports target." )

function ulx.retrn( calling_ply, target_ply )
	if not target_ply:IsValid() then
		Msg( "Return where? The console may never return to the mortal realm.\n" )
		return
	end

	if not target_ply.ulx_prevpos then
		ULib.tsayError( calling_ply, target_ply:Nick() .. " does not have any previous locations to send them to.", true )
		return
	end

	if ulx.getExclusive( target_ply, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( target_ply, calling_ply ), true )
		return
	end

	if not target_ply:Alive() then
		ULib.tsayError( calling_ply, target_ply:Nick() .. " is dead!", true )
		return
	end

	if target_ply:InVehicle() then
		target_ply:ExitVehicle()
	end

	target_ply:SetPos( target_ply.ulx_prevpos )
	target_ply:SetEyeAngles( target_ply.ulx_prevang )
	target_ply.ulx_prevpos = nil
	target_ply.ulx_prevang = nil
	target_ply:SetLocalVelocity( Vector( 0, 0, 0 ) ) -- Stop!

	ulx.fancyLogAdmin( calling_ply, "#A returned #T to their original position", target_ply )
end
local retrn = ulx.command( CATEGORY_NAME, "ulx return", ulx.retrn, "!return" )
retrn:addParam{ type=ULib.cmds.PlayerArg, ULib.cmds.optional }
retrn:defaultAccess( ULib.ACCESS_ADMIN )
retrn:help( "Returns target to last position before a teleport." )
