--[[
	Title: Base

	This file holds central, important functions or features.
]]
module( "UPS", package.seeall )

local values_from_file = {}
if file.Exists( CONFIGFILE, "DATA" ) then
	values_from_file = ULib.parseKeyValues( file.Read( CONFIGFILE, "DATA" ) )
end

local tracked_cvars = {}

--[[
	Function: replicatedWritableSavedCvar

	This is a thin wrapper on top of ULib.replicatedWritableCvar that will allow us to keep track of the cvars we want to save.
]]
function replicatedWritableSavedCvar( sv_cvar, cl_cvar, default_value, ... )
	local cvar = ULib.replicatedWritableCvar( sv_cvar, cl_cvar, default_value, ... )
	tracked_cvars[ sv_cvar ] = default_value
	if values_from_file[ sv_cvar ] then
		game.ConsoleCommand( string.format( "%s %s\n", sv_cvar, values_from_file[ sv_cvar ] ) )
		tracked_cvars[ sv_cvar ] = values_from_file[ sv_cvar ]
	end

	return cvar
end

local function cvarChanged( sv_cvar, cl_cvar, ply, old_value, new_value )
	if tracked_cvars[ sv_cvar ] then
		tracked_cvars[ sv_cvar ] = new_value
		file.Write( CONFIGFILE, ULib.makeKeyValues( tracked_cvars ) )
	end
end
hook.Add( ULib.HOOK_REPCVARCHANGED, "UPSCheckCvar", cvarChanged )


local disableAccess = "ups disableplayers"
ULib.ucl.registerAccess( disableAccess, UPS_ADMIN, "Gives the ability to disable portions of UPS or disable UPS for players", "UPS" )

local cAffectAdmins = replicatedWritableSavedCvar( "ups_affectadmins", "ups_cl_affectadmins", "0", false, false, disableAccess )

--[[
	Function: query

	This is quite possibly the most important function in all of UPS. This is how it decides whether or not to give access to
	someone for any given object. There are pre- and post-hooks if you're looking at modifying the behavior.

	Parameters:

		ply - The player entity requesting access.
		ent - The entity the player wants access to.
		actionid - What action they're trying to perform on the object. (IE, freeze, move, use)
		flags - A table of special instructions for this query. (IE, reassign ownership, no deny sound, etc)

	Returns:

		False if they should not be allowed to perform the action, true otherwise.
]]
function query( ply, ent, actionid, flags )
	if type( actionid ) ~= "string" then
		error( "Bad actionid", 2 ) -- 2 to go up a level
		return
	end

	flags = flags or {}

	-- This is a helper function since we'll be using the gamemode call in several places below. It retuns the value passed to it in order to condense the code.
	local function callPost( returnval )
		if returnval == false and not table.HasValue( flags, QUERY_NOSOUND ) then
			playDenySound( ply )
		end
		gamemode.Call( "UPSPostQuery", ply, ent, actionid, flags, returnval )
		return returnval
	end

	-- Before we do anything, call the prehook.
	local prereturn = gamemode.Call( "UPSPreQuery", ply, ent, actionid, flags )
	if prereturn ~= nil then return callPost( prereturn ) end

	if ent:UPSGetOwner() == OWNERID_UPFORGRABS and table.HasValue( flags, QUERY_TAKEOWNERLESS ) then
		-- TODO: Does this open an exploit where their props aren't counted toward their total props? (would be gmod bug though)
		ent:UPSSetOwnerEnt( ply )
		playTakeOwnershipSound( ply )
	end

	if (not cAffectAdmins:GetBool() and ply:query( "ups_" .. actionid )) or table.HasValue( ignoreList, ent:GetClass() ) then return callPost( true ) end -- Admin check or ignore

	local ownerEnt = ent:UPSGetOwnerEnt()
	if not ownerEnt or (ownerEnt ~= ply and not table.HasValue( ownerEnt:UPSGetFriends(), ply )) then
		return callPost( false )
	end

	return callPost( true )
end


--[[
	Function: queryAll

	This function calls <query> for all entities connected to and including a specified entity. This is useful for actions like right-click remove.

	Parameters:

		ply - The player entity requesting access.
		ent - The entity the player wants access to. Checks the entity chain off this entity.
		actionid - What action they're trying to perform on the object. (IE, freeze, move, use)
		flags - A table of special instructions for this query. (IE, reassign ownership, no deny sound, etc)

	Returns:

		False if they should not be allowed to perform the action, true otherwise.
]]
function queryAll( ply, ent, actionid, flags )
	local checkents = constraint.GetAllConstrainedEntities( ent )
	if not checkents then -- In special circumstances it might be nil. Otherwise it already includes ent.
		checkents = { ent }
	end

	for _, v in pairs( checkents ) do
		if query( ply, v, actionid, flags ) == false then
			return false
		end
	end

	return true
end


--[[
	Function: entSpawn

	*DO NOT CALL DIRECTLY, UPS HANDLES THIS FUNCTION*
	This function is called to assign ownership to the player spawning the object via hooks.

	Parameters:

		ply - The player spawning
		ent - Either the entity spawned or a string depending on the callback.
		ent2 - The entity spawned on certain callbacks. (the function figures out which is the correct argument)
]]
function entSpawn( ply, ent, ent2 )
	if type( ent ) == "string" then ent = ent2 end -- Differing arguments for callbacks
	if ent and ent:IsValid() then
		ent:UPSSetOwnerEnt( ply )
	end
end
hook.Add( "PlayerSpawnedProp", "UPSPropSpawn", entSpawn, 20 )
hook.Add( "PlayerSpawnedRagdoll", "UPSRagdollSpawn", entSpawn, 20 )
hook.Add( "PlayerSpawnedEffect", "UPSEffectSpawn", entSpawn, 20 )
hook.Add( "PlayerSpawnedVehicle", "UPSVehicleSpawn", entSpawn, 20 )
hook.Add( "PlayerSpawnedSENT", "UPSSentSpawn", entSpawn, 20 )
hook.Add( "PlayerSpawnedNPC", "UPSNPCSpawn", entSpawn, 20 )

local playermeta = FindMetaTable( "Player" )

local function init() -- Have to call on initialization or we don't override.
	local oldFn = playermeta.AddCount

--[[
	Function: PLAYER:AddCount

	*DO NOT CALL DIRECTLY, UPS HANDLES THIS FUNCTION*
	We're going to override the AddCount function. This will make it  so we automagically catch objects that don't call hooks like gmod
	buttons and wire stuff. UPS.entSpawn() might get called twice depending on the object, but it doesn't matter if it does.

	Parameters:

		str - The string of the limit being used.
		ent - The entity that was spawned.
]]
	function playermeta:AddCount( str, ent )
		UPS.entSpawn( self, ent )
		oldFn( self, str, ent )
	end

	local cUndo
	local origCreate = undo.Create
	local origAddEntity = undo.AddEntity
	local origSetPlayer = undo.SetPlayer
	local origFinish = undo.Finish

	function undo.Create( txt )
		cUndo = {}
		cUndo.ents = {}

		origCreate( txt )
	end

	function undo.AddEntity( ent )
		if not cUndo then return end
		if not ent or not ent:IsValid() then return end

		table.insert( cUndo.ents, ent )

		origAddEntity( ent )
	end

	function undo.SetPlayer( ply )
		if not cUndo then return end
		if not ply or not ply:IsValid() then return end
		cUndo.ply = ply

		origSetPlayer( ply )
	end

	function undo.Finish( txt )
		if not cUndo then return end
		if not cUndo.ply or not cUndo.ply:IsValid() then return end

		for _, ent in ipairs( cUndo.ents ) do
			UPS.entSpawn( cUndo.ply, ent )
		end
		cUndo = nil

		origFinish( txt )
	end

	function CCSpawnSWEP( player, command, arguments )
		if arguments[ 1 ] == nil then return end

		-- Make sure this is a SWEP
		local swep = weapons.GetStored( arguments[ 1 ] )
		if swep == nil then return end

		-- You're not allowed to spawn this!
		if not swep.Spawnable and  not player:IsAdmin() then
			return
		end

		if not gamemode.Call( "PlayerSpawnSWEP", player, arguments[ 1 ], swep ) then return end

		local tr = player:GetEyeTraceNoCursor()

		if not tr.Hit then return end

		local entity = ents.Create( swep.Classname )

		if ValidEntity( entity ) then
			entity:SetPos( tr.HitPos + tr.HitNormal * 32 )
			entity:Spawn()
		end

		UPS.entSpawn( player, entity )
	end
	concommand.Add( "gm_spawnswep", CCSpawnSWEP )

--[[
	Function: GAMEMODE:UPSPreQuery

	This hook is called before <query> begins any processing. You can completely override <query> by returning true or false from a hook.
	Use this hook with great care and responsibility. Be aware that it is called before admin or sharing checks, or even the ignore list  (IE, you'll get worldspawn).

	Parameters:

		ply - The player entity requesting access.
		ent - The entity the player wants access to.
		actionid - What action they're trying to perform on the object. (IE, freeze, move, use)
		flags - A table of special instructions for this query. (IE, reassign ownership, no deny sound, etc)
]]
	function GAMEMODE:UPSPreQuery( ply, ent, actionid, flags )
	end


--[[
	Function: GAMEMODE:UPSPostQuery

	This *read-only* hook is called after <query> does all of it's processing. It is considered read-only because returning values does nothing to <query>.
	Note that the last parameter is whether or not the player got access.

	Parameters:

		ply - The player entity requesting access.
		ent - The entity the player wants access to.
		actionid - What action they're trying to perform on the object. (IE, freeze, move, use)
		flags - A table of special instructions for this query. (IE, reassign ownership, no deny sound, etc)
		allowed - Whether or not the player acheived access to the requested operation.
]]
	function GAMEMODE:UPSPostQuery( ply, ent, actionid, flags, allowed )
	end

--[[
	Function: GAMEMODE:UPSPlayerLoaded

	This *read-only* hook is called after a player reports that it has loaded UPS.
	This is called directly after the player is assigned a short id and stuck into the name table.

	Parameters:

		ply - The player entity that's loaded
]]
	function GAMEMODE:UPSPlayerLoaded( ply )
	end
end -- End init()
hook.Add( "Initialize", "UPSInitializePlyExt", init )

-- Send our player info table to the client
local function localPlayerReady( ply )
	-- Init player
	umsg.Start( "ups_client_init", ply )
	umsg.End()

	-- Send the player table
	for uid, name in pairs( playerTable ) do
		umsg.Start( "ups_readnames", ply )
			umsg.String( uid )
			umsg.String( name )
		umsg.End()
	end

	-- Now add the new player
	local uid = ply:UniqueID()
	local name = ply:Nick()

	nameToID( uid, name )

	local rp = RecipientFilter()
	local players = ULib.getAllReadyPlayers()
	for i=1, #players do
		rp:AddPlayer( players[ i ] )
	end

	umsg.Start( "ups_readnames", rp )
		umsg.String( uid )
		umsg.String( name )
	umsg.End()

	-- Hook time!
	gamemode.Call( "UPSPlayerLoaded", ply )
end
hook.Add( "ULibLocalPlayerReady", "UPSInit", localPlayerReady, -1 )
