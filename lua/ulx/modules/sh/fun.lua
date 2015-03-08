local CATEGORY_NAME = "Fun"

------------------------------ Slap ------------------------------
function ulx.slap( calling_ply, target_plys, dmg )
	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]
		if v:IsFrozen() then
			ULib.tsayError( calling_ply, v:Nick() .. " is frozen!", true )
		else
			ULib.slap( v, dmg )
			table.insert( affected_plys, v )
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A slapped #T with #i damage", affected_plys, dmg )
end

local slap = ulx.command( CATEGORY_NAME, "ulx slap", ulx.slap, "!slap" )
slap:addParam{ type=ULib.cmds.PlayersArg }
slap:addParam{ type=ULib.cmds.NumArg, min=0, default=0, hint="damage", ULib.cmds.optional, ULib.cmds.round }
slap:defaultAccess( ULib.ACCESS_ADMIN )
slap:help( "Slaps target(s) with given damage." )

------------------------------ Whip ------------------------------
function ulx.whip( calling_ply, target_plys, times, dmg )
	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]

		if v.whipped then
			ULib.tsayError( calling_ply, v:Nick() .. " is already being whipped by " .. v.whippedby, true )
		elseif v:IsFrozen() then
			ULib.tsayError( calling_ply, v:Nick() .. " is frozen!", true )
		else
			local dtime = 0
			v.whipped = true
			v.whippedby = calling_ply:IsValid() and calling_ply:Nick() or "(Console)"
			v.whipcount = 0
			v.whipamt = times

			timer.Create( "ulxWhip" .. v:EntIndex(), 0.5, 0, function() -- Repeat forever, we have an unhooker inside.
				if not v:IsValid() then timer.Remove( "ulxWhip" .. v:EntIndex() ) return end  -- Gotta make sure they're still there since this is a timer.
				if v.whipcount == v.whipamt or not v:Alive() then
					v.whipped = nil
					v.whippedby = nil
					v.whipcount = nil
					v.whipamt = nil
					timer.Remove( "ulxWhip" .. v:EntIndex() )
				else
					ULib.slap( v, dmg )
					v.whipcount = v.whipcount + 1
				end
			end )

			table.insert( affected_plys, v )
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A whipped #T #i times with #i damage", affected_plys, times, dmg )
end
local whip = ulx.command( CATEGORY_NAME, "ulx whip", ulx.whip, "!whip" )
whip:addParam{ type=ULib.cmds.PlayersArg }
whip:addParam{ type=ULib.cmds.NumArg, min=2, max=100, default=10, hint="times", ULib.cmds.optional, ULib.cmds.round }
whip:addParam{ type=ULib.cmds.NumArg, min=0, default=0, hint="damage", ULib.cmds.optional, ULib.cmds.round }
whip:defaultAccess( ULib.ACCESS_ADMIN )
whip:help( "Slaps target(s) x times with given damage each time." )

------------------------------ Slay ------------------------------
function ulx.slay( calling_ply, target_plys )
	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]

		if ulx.getExclusive( v, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
		elseif not v:Alive() then
			ULib.tsayError( calling_ply, v:Nick() .. " is already dead!", true )
		elseif v:IsFrozen() then
			ULib.tsayError( calling_ply, v:Nick() .. " is frozen!", true )
		else
			v:Kill()
			table.insert( affected_plys, v )
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A slayed #T", affected_plys )
end
local slay = ulx.command( CATEGORY_NAME, "ulx slay", ulx.slay, "!slay" )
slay:addParam{ type=ULib.cmds.PlayersArg }
slay:defaultAccess( ULib.ACCESS_ADMIN )
slay:help( "Slays target(s)." )

------------------------------ Sslay ------------------------------
function ulx.sslay( calling_ply, target_plys )
	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]

		if ulx.getExclusive( v, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
		elseif not v:Alive() then
			ULib.tsayError( calling_ply, v:Nick() .. " is already dead!", true )
		elseif v:IsFrozen() then
			ULib.tsayError( calling_ply, v:Nick() .. " is frozen!", true )
		else
			if v:InVehicle() then
				v:ExitVehicle()
			end

			v:KillSilent()
			table.insert( affected_plys, v )
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A silently slayed #T", affected_plys )
end
local sslay = ulx.command( CATEGORY_NAME, "ulx sslay", ulx.sslay, "!sslay" )
sslay:addParam{ type=ULib.cmds.PlayersArg }
sslay:defaultAccess( ULib.ACCESS_ADMIN )
sslay:help( "Silently slays target(s)." )

------------------------------ Ignite ------------------------------
function ulx.ignite( calling_ply, target_plys, seconds, should_extinguish )
	local affected_plys = {}

	for i=1, #target_plys do
		local v = target_plys[ i ]

		if not should_extinguish then
			v:Ignite( seconds )
			v.ulx_ignited_until = CurTime() + seconds
			table.insert( affected_plys, v )
		elseif v:IsOnFire() then
			v:Extinguish()
			v.ulx_ignited_until = nil
			table.insert( affected_plys, v )
		end
	end

	if not should_extinguish then
		ulx.fancyLogAdmin( calling_ply, "#A ignited #T for #i seconds", affected_plys, seconds )
	else
		ulx.fancyLogAdmin( calling_ply, "#A extinguished #T", affected_plys )
	end
end
local ignite = ulx.command( CATEGORY_NAME, "ulx ignite", ulx.ignite, "!ignite" )
ignite:addParam{ type=ULib.cmds.PlayersArg }
ignite:addParam{ type=ULib.cmds.NumArg, min=1, max=300, default=300, hint="seconds", ULib.cmds.optional, ULib.cmds.round }
ignite:addParam{ type=ULib.cmds.BoolArg, invisible=true }
ignite:defaultAccess( ULib.ACCESS_ADMIN )
ignite:help( "Ignites target(s)." )
ignite:setOpposite( "ulx unignite", {_, _, _, true}, "!unignite" )

local function checkFireDeath( ply )
	if ply.ulx_ignited_until and ply.ulx_ignited_until >= CurTime() and ply:IsOnFire() then
		ply:Extinguish()
		ply.ulx_ignited_until = nil
	end
end
hook.Add( "PlayerDeath", "ULXCheckFireDeath", checkFireDeath )

------------------------------ Unigniteall ------------------------------
function ulx.unigniteall( calling_ply )
	local flame_ents = ents.FindByClass( 'entityflame' )
	for _,v in ipairs( flame_ents ) do
		if v:IsValid() then
			v:Remove()
		end
	end

	local plys = player.GetAll()
	for _, v in ipairs( plys ) do
		if v:IsOnFire() then
			v:Extinguish()
			v.ulx_ignited_until = nil
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A extinguished everything" )
end
local unigniteall = ulx.command( CATEGORY_NAME, "ulx unigniteall", ulx.unigniteall, "!unigniteall" )
unigniteall:defaultAccess( ULib.ACCESS_ADMIN )
unigniteall:help( "Extinguishes all players and all entities." )

------------------------------ Playsound ------------------------------
function ulx.playsound( calling_ply, sound )
	if not ULib.fileExists( "sound/" .. sound ) then
		ULib.tsayError( calling_ply, "That sound doesn't exist on the server!", true )
		return
	end

	umsg.Start( "ulib_sound" )
		umsg.String( Sound( sound ) )
	umsg.End()

	ulx.fancyLogAdmin( calling_ply, "#A played sound #s", sound )
end
local playsound = ulx.command( CATEGORY_NAME, "ulx playsound", ulx.playsound )
playsound:addParam{ type=ULib.cmds.StringArg, hint="sound", autocomplete_fn=ulx.soundComplete }
playsound:defaultAccess( ULib.ACCESS_ADMIN )
playsound:help( "Plays a sound (relative to sound dir)." )

------------------------------ Freeze ------------------------------
function ulx.freeze( calling_ply, target_plys, should_unfreeze )
	local affected_plys = {}
	for i=1, #target_plys do
		if not should_unfreeze and ulx.getExclusive( target_plys[ i ], calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( target_plys[ i ], calling_ply ), true )
		else
			local v = target_plys[ i ]
			if v:InVehicle() then
				v:ExitVehicle()
			end

			if not should_unfreeze then
				v:Lock()
				v.frozen = true
				ulx.setExclusive( v, "frozen" )
			else
				v:UnLock()
				v.frozen = nil
				ulx.clearExclusive( v )
			end

			v:DisallowSpawning( not should_unfreeze )
			ulx.setNoDie( v, not should_unfreeze )
			table.insert( affected_plys, v )

			if v.whipped then
				v.whipcount = v.whipamt -- Will make it remove
			end
		end
	end

	if not should_unfreeze then
		ulx.fancyLogAdmin( calling_ply, "#A froze #T", affected_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unfroze #T", affected_plys )
	end
end
local freeze = ulx.command( CATEGORY_NAME, "ulx freeze", ulx.freeze, "!freeze" )
freeze:addParam{ type=ULib.cmds.PlayersArg }
freeze:addParam{ type=ULib.cmds.BoolArg, invisible=true }
freeze:defaultAccess( ULib.ACCESS_ADMIN )
freeze:help( "Freezes target(s)." )
freeze:setOpposite( "ulx unfreeze", {_, _, true}, "!unfreeze" )

------------------------------ God ------------------------------
function ulx.god( calling_ply, target_plys, should_revoke )
	if not target_plys[ 1 ]:IsValid() then
		if not should_revoke then
			Msg( "You are the console, you are already god.\n" )
		else
			Msg( "Your position of god is irrevocable; if you don't like it, leave the matrix.\n" )
		end
		return
	end

	local affected_plys = {}
	for i=1, #target_plys do
		local v = target_plys[ i ]

		if ulx.getExclusive( v, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
		else
			if not should_revoke then
				v:GodEnable()
				v.ULXHasGod = true
			else
				v:GodDisable()
				v.ULXHasGod = nil
			end
			table.insert( affected_plys, v )
		end
	end

	if not should_revoke then
		ulx.fancyLogAdmin( calling_ply, "#A granted god mode upon #T", affected_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A revoked god mode from #T", affected_plys )
	end
end
local god = ulx.command( CATEGORY_NAME, "ulx god", ulx.god, "!god" )
god:addParam{ type=ULib.cmds.PlayersArg, ULib.cmds.optional }
god:addParam{ type=ULib.cmds.BoolArg, invisible=true }
god:defaultAccess( ULib.ACCESS_ADMIN )
god:help( "Grants god mode to target(s)." )
god:setOpposite( "ulx ungod", {_, _, true}, "!ungod" )

------------------------------ Hp ------------------------------
function ulx.hp( calling_ply, target_plys, amount )
	for i=1, #target_plys do
		target_plys[ i ]:SetHealth( amount )
	end
	ulx.fancyLogAdmin( calling_ply, "#A set the hp for #T to #i", target_plys, amount )
end
local hp = ulx.command( CATEGORY_NAME, "ulx hp", ulx.hp, "!hp" )
hp:addParam{ type=ULib.cmds.PlayersArg }
hp:addParam{ type=ULib.cmds.NumArg, min=1, max=2^32/2-1, hint="hp", ULib.cmds.round }
hp:defaultAccess( ULib.ACCESS_ADMIN )
hp:help( "Sets the hp for target(s)." )

------------------------------ Armor ------------------------------
function ulx.armor( calling_ply, target_plys, amount )
	for i=1, #target_plys do
		target_plys[ i ]:SetArmor( amount )
	end
	ulx.fancyLogAdmin( calling_ply, "#A set the armor for #T to #i", target_plys, amount )
end
local armor = ulx.command( CATEGORY_NAME, "ulx armor", ulx.armor, "!armor" )
armor:addParam{ type=ULib.cmds.PlayersArg }
armor:addParam{ type=ULib.cmds.NumArg, min=0, max=255, hint="armor", ULib.cmds.round }
armor:defaultAccess( ULib.ACCESS_ADMIN )
armor:help( "Sets the armor for target(s)." )

------------------------------ Cloak ------------------------------
function ulx.cloak( calling_ply, target_plys, amount, should_uncloak )
	if not target_plys[ 1 ]:IsValid() then
		Msg( "You are always invisible.\n" )
		return
	end

	amount = 255 - amount

	for i=1, #target_plys do
		ULib.invisible( target_plys[ i ], not should_uncloak, amount )
	end

	if not should_uncloak then
		ulx.fancyLogAdmin( calling_ply, "#A cloaked #T by amount #i", target_plys, amount )
	else
		ulx.fancyLogAdmin( calling_ply, "#A uncloaked #T", target_plys )
	end
end
local cloak = ulx.command( CATEGORY_NAME, "ulx cloak", ulx.cloak, "!cloak" )
cloak:addParam{ type=ULib.cmds.PlayersArg, ULib.cmds.optional }
cloak:addParam{ type=ULib.cmds.NumArg, min=0, max=255, default=255, hint="amount", ULib.cmds.round, ULib.cmds.optional }
cloak:addParam{ type=ULib.cmds.BoolArg, invisible=true }
cloak:defaultAccess( ULib.ACCESS_ADMIN )
cloak:help( "Cloaks target(s)." )
cloak:setOpposite( "ulx uncloak", {_, _, _, true}, "!uncloak" )

------------------------------ Blind ------------------------------
function ulx.blind( calling_ply, target_plys, amount, should_unblind )
	for i=1, #target_plys do
		local v = target_plys[ i ]
		umsg.Start( "ulx_blind", v )
			umsg.Bool( not should_unblind )
			umsg.Short( amount )
		umsg.End()

		if should_unblind then
			if v.HadCamera then
				v:Give( "gmod_camera" )
			end
			v.HadCamera = nil
		else
			if v.HadCamera == nil then -- In case blind is run twice
				v.HadCamera = v:HasWeapon( "gmod_camera" )
			end
			v:StripWeapon( "gmod_camera" )
		end
	end

	if not should_unblind then
		ulx.fancyLogAdmin( calling_ply, "#A blinded #T by amount #i", target_plys, amount )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unblinded #T", target_plys )
	end
end
local blind = ulx.command( CATEGORY_NAME, "ulx blind", ulx.blind, "!blind" )
blind:addParam{ type=ULib.cmds.PlayersArg }
blind:addParam{ type=ULib.cmds.NumArg, min=0, max=255, default=255, hint="amount", ULib.cmds.round, ULib.cmds.optional }
blind:addParam{ type=ULib.cmds.BoolArg, invisible=true }
blind:defaultAccess( ULib.ACCESS_ADMIN )
blind:help( "Blinds target(s)." )
blind:setOpposite( "ulx unblind", {_, _, _, true}, "!unblind" )

------------------------------ Jail ------------------------------
local doJail
local jailableArea
function ulx.jail( calling_ply, target_plys, seconds, should_unjail )
	local affected_plys = {}
	for i=1, #target_plys do
		local v = target_plys[ i ]

		if not should_unjail then
			if ulx.getExclusive( v, calling_ply ) then
				ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
			elseif not jailableArea( v:GetPos() ) then
				ULib.tsayError( calling_ply, v:Nick() .. " is not in an area where a jail can be placed!", true )
			else
				doJail( v, seconds )

				table.insert( affected_plys, v )
			end
		elseif v.jail then
			v.jail.unjail()
			v.jail = nil
			table.insert( affected_plys, v )
		end
	end

	if not should_unjail then
		local str = "#A jailed #T"
		if seconds > 0 then
			str = str .. " for #i seconds"
		end
		ulx.fancyLogAdmin( calling_ply, str, affected_plys, seconds )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unjailed #T", affected_plys )
	end
end
local jail = ulx.command( CATEGORY_NAME, "ulx jail", ulx.jail, "!jail" )
jail:addParam{ type=ULib.cmds.PlayersArg }
jail:addParam{ type=ULib.cmds.NumArg, min=0, default=0, hint="seconds, 0 is forever", ULib.cmds.round, ULib.cmds.optional }
jail:addParam{ type=ULib.cmds.BoolArg, invisible=true }
jail:defaultAccess( ULib.ACCESS_ADMIN )
jail:help( "Jails target(s)." )
jail:setOpposite( "ulx unjail", {_, _, _, true}, "!unjail" )

------------------------------ Jail TP ------------------------------
function ulx.jailtp( calling_ply, target_ply, seconds )
	local t = {}
	t.start = calling_ply:GetPos() + Vector( 0, 0, 32 ) -- Move them up a bit so they can travel across the ground
	t.endpos = calling_ply:GetPos() + calling_ply:EyeAngles():Forward() * 16384
	t.filter = target_ply
	if target_ply ~= calling_ply then
		t.filter = { target_ply, calling_ply }
	end
	local tr = util.TraceEntity( t, target_ply )

	local pos = tr.HitPos

	if ulx.getExclusive( target_ply, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( target_ply, calling_ply ), true )
		return
	elseif not target_ply:Alive() then
		ULib.tsayError( calling_ply, target_ply:Nick() .. " is dead!", true )
		return
	elseif not jailableArea( pos ) then
		ULib.tsayError( calling_ply, "That is not an area where a jail can be placed!", true )
		return
	else
		target_ply.ulx_prevpos = target_ply:GetPos()
		target_ply.ulx_prevang = target_ply:EyeAngles()

		if target_ply:InVehicle() then
			target_ply:ExitVehicle()
		end

		target_ply:SetPos( pos )
		target_ply:SetLocalVelocity( Vector( 0, 0, 0 ) ) -- Stop!

		doJail( target_ply, seconds )
	end

	local str = "#A teleported and jailed #T"
	if seconds > 0 then
		str = str .. " for #i seconds"
	end
	ulx.fancyLogAdmin( calling_ply, str, target_ply, seconds )
end
local jailtp = ulx.command( CATEGORY_NAME, "ulx jailtp", ulx.jailtp, "!jailtp" )
jailtp:addParam{ type=ULib.cmds.PlayerArg }
jailtp:addParam{ type=ULib.cmds.NumArg, min=0, default=0, hint="seconds, 0 is forever", ULib.cmds.round, ULib.cmds.optional }
jailtp:defaultAccess( ULib.ACCESS_ADMIN )
jailtp:help( "Teleports, then jails target(s)." )

local function jailCheck()
	local remove_timer = true
	local players = player.GetAll()
	for i=1, #players do
		local ply = players[ i ]
		if ply.jail then
			remove_timer = false
		end
		if ply.jail and (ply.jail.pos-ply:GetPos()):LengthSqr() >= 6500 then
			ply:SetPos( ply.jail.pos )
			if ply.jail.jail_until then
				doJail( ply, ply.jail.jail_until - CurTime() )
			else
				doJail( ply, 0 )
			end
		end
	end

	if remove_timer then
		timer.Remove( "ULXJail" )
	end
end

jailableArea = function( pos )
	entList = ents.FindInBox( pos - Vector( 35, 35, 5 ), pos + Vector( 35, 35, 110 ) )
	for i=1, #entList do
		if entList[ i ]:GetClass() == "trigger_remove" then
			return false
		end
	end

	return true
end

local mdl1 = Model( "models/props_building_details/Storefront_Template001a_Bars.mdl" )
local jail = {
	{ pos = Vector( 0, 0, -5 ), ang = Angle( 90, 0, 0 ), mdl=mdl1 },
	{ pos = Vector( 0, 0, 97 ), ang = Angle( 90, 0, 0 ), mdl=mdl1 },
	{ pos = Vector( 21, 31, 46 ), ang = Angle( 0, 90, 0 ), mdl=mdl1 },
	{ pos = Vector( 21, -31, 46 ), ang = Angle( 0, 90, 0 ), mdl=mdl1 },
	{ pos = Vector( -21, 31, 46 ), ang = Angle( 0, 90, 0 ), mdl=mdl1 },
	{ pos = Vector( -21, -31, 46), ang = Angle( 0, 90, 0 ), mdl=mdl1 },
	{ pos = Vector( -52, 0, 46 ), ang = Angle( 0, 0, 0 ), mdl=mdl1 },
	{ pos = Vector( 52, 0, 46 ), ang = Angle( 0, 0, 0 ), mdl=mdl1 },
}
doJail = function( v, seconds )
	if v.jail then -- They're already jailed
		v.jail.unjail()
	end

	if v:InVehicle() then
		local vehicle = v:GetParent()
		v:ExitVehicle()
		vehicle:Remove()
	end

	-- Force other players to let go of this player
	if v.physgunned_by then
		for ply, v in pairs( v.physgunned_by ) do
			if ply:IsValid() and ply:GetActiveWeapon():IsValid() and ply:GetActiveWeapon():GetClass() == "weapon_physgun" then
				ply:ConCommand( "-attack" )
			end
		end
	end

	if v:GetMoveType() == MOVETYPE_NOCLIP then -- Take them out of noclip
		v:SetMoveType( MOVETYPE_WALK )
	end

	local pos = v:GetPos()

	local walls = {}
	for _, info in ipairs( jail ) do
		local ent = ents.Create( "prop_physics" )
		ent:SetModel( info.mdl )
		ent:SetPos( pos + info.pos )
		ent:SetAngles( info.ang )
		ent:Spawn()
		ent:GetPhysicsObject():EnableMotion( false )
		ent:SetMoveType( MOVETYPE_NONE )
		ent.jailWall = true
		table.insert( walls, ent )
	end

	local key = {}
	local function unjail()
		if not v:IsValid() or not v.jail or v.jail.key ~= key then -- Nope
			return
		end

		for _, ent in ipairs( walls ) do
			if ent:IsValid() then
				ent:DisallowDeleting( false )
				ent:Remove()
			end
		end
		if not v:IsValid() then return end -- Make sure they're still connected

		v:DisallowNoclip( false )
		v:DisallowMoving( false )
		v:DisallowSpawning( false )
		v:DisallowVehicles( false )

		ulx.clearExclusive( v )
		ulx.setNoDie( v, false )

		v.jail = nil
	end
	if seconds > 0 then
		timer.Simple( seconds, unjail )
	end

	local function newWall( old, new )
		table.insert( walls, new )
	end

	for _, ent in ipairs( walls ) do
		ent:DisallowDeleting( true, newWall )
		ent:DisallowMoving( true )
	end
	v:DisallowNoclip( true )
	v:DisallowMoving( true )
	v:DisallowSpawning( true )
	v:DisallowVehicles( true )
	v.jail = { pos=pos, unjail=unjail, key=key }
	if seconds > 0 then
		v.jail.jail_until = CurTime() + seconds
	end
	ulx.setExclusive( v, "in jail" )
	ulx.setNoDie( v, true )

	timer.Create( "ULXJail", 1, 0, jailCheck )
end

local function jailDisconnectedCheck( ply )
	if ply.jail then
		ply.jail.unjail()
	end
end
hook.Add( "PlayerDisconnected", "ULXJailDisconnectedCheck", jailDisconnectedCheck, -20 )

local function playerPickup( ply, ent )
	if CLIENT then return end
	if ent:IsPlayer() then
		ent.physgunned_by = ent.physgunned_by or {}
		ent.physgunned_by[ ply ] = true
	end
end
hook.Add( "PhysgunPickup", "ulxPlayerPickupJailCheck", playerPickup, -20 )

local function playerDrop( ply, ent )
	if CLIENT then return end
	if ent:IsPlayer() then
		ent.physgunned_by[ ply ] = nil
	end
end
hook.Add( "PhysgunDrop", "ulxPlayerDropJailCheck", playerDrop )

------------------------------ Ragdoll ------------------------------
function ulx.ragdoll( calling_ply, target_plys, should_unragdoll )
	local affected_plys = {}
	for i=1, #target_plys do
		local v = target_plys[ i ]

		if not should_unragdoll then
			if ulx.getExclusive( v, calling_ply ) then
				ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )
			elseif not v:Alive() then
				ULib.tsayError( calling_ply, v:Nick() .. " is dead and cannot be ragdolled!", true )
			else
				if v:InVehicle() then
					local vehicle = v:GetParent()
					v:ExitVehicle()
				end

				ULib.getSpawnInfo( v ) -- Collect information so we can respawn them in the same state.

				local ragdoll = ents.Create( "prop_ragdoll" )
				ragdoll.ragdolledPly = v

				ragdoll:SetPos( v:GetPos() )
				local velocity = v:GetVelocity()
				ragdoll:SetAngles( v:GetAngles() )
				ragdoll:SetModel( v:GetModel() )
				ragdoll:Spawn()
				ragdoll:Activate()
				v:SetParent( ragdoll ) -- So their player ent will match up (position-wise) with where their ragdoll is.
				-- Set velocity for each peice of the ragdoll
				local j = 1
				while true do -- Break inside
					local phys_obj = ragdoll:GetPhysicsObjectNum( j )
					if phys_obj then
						phys_obj:SetVelocity( velocity )
						j = j + 1
					else
						break
					end
				end

				v:Spectate( OBS_MODE_CHASE )
				v:SpectateEntity( ragdoll )
				v:StripWeapons() -- Otherwise they can still use the weapons.

				ragdoll:DisallowDeleting( true, function( old, new )
					v.ragdoll = new
				end )
				v:DisallowSpawning( true )

				v.ragdoll = ragdoll
				ulx.setExclusive( v, "ragdolled" )

				table.insert( affected_plys, v )
			end
		elseif v.ragdoll then -- Only if they're ragdolled...
			v:DisallowSpawning( false )
			v:SetParent()

			v:UnSpectate() -- Need this for DarkRP for some reason, works fine without it in sbox

			local ragdoll = v.ragdoll
			v.ragdoll = nil -- Gotta do this before spawn or our hook catches it

			if not ragdoll:IsValid() then -- Something must have removed it, just spawn
				ULib.spawn( v, true )

			else
				local pos = ragdoll:GetPos()
				pos.z = pos.z + 10 -- So they don't end up in the ground

				ULib.spawn( v, true )
				v:SetPos( pos )
				v:SetVelocity( ragdoll:GetVelocity() )
				local yaw = ragdoll:GetAngles().yaw
				v:SetAngles( Angle( 0, yaw, 0 ) )
				ragdoll:DisallowDeleting( false )
				ragdoll:Remove()
			end

			ulx.clearExclusive( v )

			table.insert( affected_plys, v )
		end
	end

	if not should_unragdoll then
		ulx.fancyLogAdmin( calling_ply, "#A ragdolled #T", affected_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unragdolled #T", affected_plys )
	end
end
local ragdoll = ulx.command( CATEGORY_NAME, "ulx ragdoll", ulx.ragdoll, "!ragdoll" )
ragdoll:addParam{ type=ULib.cmds.PlayersArg }
ragdoll:addParam{ type=ULib.cmds.BoolArg, invisible=true }
ragdoll:defaultAccess( ULib.ACCESS_ADMIN )
ragdoll:help( "ragdolls target(s)." )
ragdoll:setOpposite( "ulx unragdoll", {_, _, true}, "!unragdoll" )


local function ragdollSpawnCheck( ply )
	if ply.ragdoll then
		timer.Simple( 0.01, function() -- Doesn't like us using it instantly
			if not ply:IsValid() then return end -- Make sure they're still here
			ply:Spectate( OBS_MODE_CHASE )
			ply:SpectateEntity( ply.ragdoll )
			ply:StripWeapons() -- Otherwise they can still use the weapons.
		end )
	end
end
hook.Add( "PlayerSpawn", "ULXRagdollSpawnCheck", ragdollSpawnCheck )

local function ragdollDisconnectedCheck( ply )
	if ply.ragdoll then
		ply.ragdoll:DisallowDeleting( false )
		ply.ragdoll:Remove()
	end
end
hook.Add( "PlayerDisconnected", "ULXRagdollDisconnectedCheck", ragdollDisconnectedCheck )

------------------------------ Maul ------------------------------
local zombieDeath -- We need these registered up here because functions reference each other.
local checkMaulDeath

local function newZombie( pos, ang, ply, b )
		local ent = ents.Create( "npc_fastzombie" )
		ent:SetPos( pos )
		ent:SetAngles( ang )
		ent:Spawn()
		ent:Activate()
		ent:AddRelationship("player D_NU 98") -- Don't attack other players
		ent:AddEntityRelationship( ply, D_HT, 99 ) -- Hate target

		ent:DisallowDeleting( true, _, true )
		ent:DisallowMoving( true )

		if not b then
			ent:CallOnRemove( "NoDie", zombieDeath, ply )
		end

		return ent
end

-- Utility function
zombieDeath = function( ent, ply )
	if ply.maul_npcs then -- Recreate!
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		ULib.queueFunctionCall( function() -- Create it next frame because 1. Old NPC won't be in way and 2. We won't overflow the server while shutting down with someone being mauled
			if not ply:IsValid() then return end -- Player left

			local ent2 = newZombie( pos, ang, ply )
			table.insert( ply.maul_npcs, ent2 ) -- Don't worry about removing the old one, doesn't matter.

			-- Make sure we didn't make a headcrab!
			local ents = ents.FindByClass( "npc_headcrab_fast" )
			for _, ent in ipairs( ents ) do
				dist = ent:GetPos():Distance( pos )
				if dist < 128 then -- Assume it's from the zombies
					ent:Remove()
				end
			end
		end )
	end
end

-- Another utility for maul
local function maulMoreDamage()
	local players = player.GetAll()
	for _, ply in ipairs( players ) do
		if ply.maul_npcs and ply:Alive() then
			if CurTime() > ply.maulStart + 10 then
				local damage = math.ceil( ply.maulStartHP / 10 ) -- Damage per second
				damage = damage * FrameTime() -- Damage this frame
				damage = math.ceil( damage )
				local newhp = ply:Health() - damage
				if newhp < 1 then newhp = 1 end
				ply:SetHealth( newhp ) -- We don't use takedamage because the player slides across the ground.
				if CurTime() > ply.maulStart + 20 then
					ply:Kill() -- Worst case senario.
					checkMaulDeath( ply ) -- Just in case the death hook is broken
				end
			end
			ply.maul_lasthp = ply:Health()
		end
	end
end

function ulx.maul( calling_ply, target_plys )
	local affected_plys = {}
	for i=1, #target_plys do
		local v = target_plys[ i ]

		if ulx.getExclusive( v, calling_ply ) then
			ULib.tsayError( calling_ply, ulx.getExclusive( v, calling_ply ), true )

		elseif not v:Alive() then
			ULib.tsayError( calling_ply, v:Nick() .. " is dead!", true )

		else
			local pos = {}
			local testent = newZombie( Vector( 0, 0, 0 ), Angle( 0, 0, 0 ), v, true ) -- Test ent for traces

			local yawForward = v:EyeAngles().yaw
			local directions = { -- Directions to try
				math.NormalizeAngle( yawForward - 180 ), -- Behind first
				math.NormalizeAngle( yawForward + 90 ), -- Right
				math.NormalizeAngle( yawForward - 90 ), -- Left
				yawForward,
			}

			local t = {}
			t.start = v:GetPos() + Vector( 0, 0, 32 ) -- Move them up a bit so they can travel across the ground
			t.filter = { v, testent }

			for i=1, #directions do -- Check all directions
				t.endpos = v:GetPos() + Angle( 0, directions[ i ], 0 ):Forward() * 47 -- (33 is player width, this is sqrt( 33^2 * 2 ))
				local tr = util.TraceEntity( t, testent )

				if not tr.Hit then
					table.insert( pos, v:GetPos() + Angle( 0, directions[ i ], 0 ):Forward() * 47 )
				end
			end

			testent:DisallowDeleting( false )
			testent:Remove() -- Don't forget to remove our friend now!

			if #pos > 0 then
				v.maul_npcs = {}
				for _, newpos in ipairs( pos ) do
					local newang = (v:GetPos() - newpos):Angle()

					local ent = newZombie( newpos, newang, v )
					table.insert( v.maul_npcs, ent )
				end

				v:SetMoveType( MOVETYPE_WALK )
				v:DisallowNoclip( true )
				v:DisallowSpawning( true )
				v:DisallowVehicles( true )
				v:GodDisable()
				v:SetArmor( 0 ) -- Armor takes waaaay too long for them to take down
				v.maulOrigWalk = v:GetWalkSpeed()
				v.maulOrigSprint = v:GetRunSpeed()
				v:SetWalkSpeed(1)
				v:SetRunSpeed(1)

				v.maulStart = CurTime()
				v.maulStartHP = v:Health()
				hook.Add( "Think", "MaulMoreDamageThink", maulMoreDamage )

				ulx.setExclusive( v, "being mauled" )

				table.insert( affected_plys, v )
			else
				ULib.tsayError( calling_ply, "Can't find a place to put the npcs for " .. v:Nick(), true )
			end
		end
	end

	ulx.fancyLogAdmin( calling_ply, "#A mauled #T", affected_plys )
end
local maul = ulx.command( CATEGORY_NAME, "ulx maul", ulx.maul, "!maul" )
maul:addParam{ type=ULib.cmds.PlayersArg }
maul:defaultAccess( ULib.ACCESS_SUPERADMIN )
maul:help( "Maul target(s)." )

checkMaulDeath = function( ply, weapon, killer )
	if ply.maul_npcs then
		if killer == ply and CurTime() < ply.maulStart + 20 then -- Suicide
			ply:AddFrags( 1 ) -- Won't show on scoreboard
			local pos = ply:GetPos()
			local ang = ply:EyeAngles()
			ULib.queueFunctionCall( function()
				if not ply:IsValid() then return end -- They left

				ply:Spawn()
				ply:SetPos( pos )
				ply:SetEyeAngles( ang )
				ply:SetArmor( 0 )
				ply:SetHealth( ply.maul_lasthp )
				timer.Simple( 0.1, function()
					if not ply:IsValid() then return end -- They left
					ply:SetCollisionGroup( COLLISION_GROUP_WORLD )
					ply:SetWalkSpeed(1)
					ply:SetRunSpeed(1)
				end )
			end )
			return true -- Don't register their death on HUD
		end

		local npcs = ply.maul_npcs
		ply.maul_npcs = nil -- We have to do it this way to signal that we're done mauling
		for _, ent in ipairs( npcs ) do
			if ent:IsValid() then
				ent:DisallowDeleting( false )
				ent:Remove()
			end
		end
		ulx.clearExclusive( ply )
		ply.maulStart = nil
		ply.maul_lasthp = nil

		ply:DisallowNoclip( false )
		ply:DisallowSpawning( false )
		ply:DisallowVehicles( false )
		ply:SetWalkSpeed(ply.maulOrigWalk)
		ply:SetRunSpeed(ply.maulOrigSprint)
		ply.maulOrigWalk = nil
		ply.maulOrigSprint = nil

		ulx.clearExclusive( ply )

		-- Now let's check if there's still players being mauled
		local players = player.GetAll()
		for _, ply in ipairs( players ) do
			if ply.maul_npcs then
				return
			end
		end

		-- No more? Remove hook.
		hook.Remove( "Think", "MaulMoreDamageThink" )
	end
end
hook.Add( "PlayerDeath", "ULXCheckMaulDeath", checkMaulDeath, -15 ) -- Hook it first because we're changing speed. Want others to override us.

local function maulDisconnectedCheck( ply )
	checkMaulDeath( ply ) -- Just run it through the death function
end
hook.Add( "PlayerDisconnected", "ULXMaulDisconnectedCheck", maulDisconnectedCheck )

------------------------------ Strip ------------------------------
function ulx.stripweapons( calling_ply, target_plys )
	for i=1, #target_plys do
		target_plys[ i ]:StripWeapons()
	end

	ulx.fancyLogAdmin( calling_ply, "#A stripped weapons from #T", target_plys )
end
local strip = ulx.command( CATEGORY_NAME, "ulx strip", ulx.stripweapons, "!strip" )
strip:addParam{ type=ULib.cmds.PlayersArg }
strip:defaultAccess( ULib.ACCESS_ADMIN )
strip:help( "Strip weapons from target(s)." )
