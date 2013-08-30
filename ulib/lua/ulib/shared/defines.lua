--[[
	Title: Defines

	Holds some defines used on both client and server.
]]

ULib = ULib or {}


ULib.VERSION = 2.51

ULib.ACCESS_ALL = "user"
ULib.ACCESS_OPERATOR = "operator"
ULib.ACCESS_ADMIN = "admin"
ULib.ACCESS_SUPERADMIN = "superadmin"

ULib.DEFAULT_ACCESS = ULib.ACCESS_ALL

ULib.DEFAULT_TSAY_COLOR = Color( 151, 211, 255 ) -- Found by using MS Paint


--[[
	Section: Umsg Helpers

	These are ids for the ULib umsg functions, so the client knows what they're getting.
]]
ULib.TYPE_ANGLE = 1
ULib.TYPE_BOOLEAN = 2
ULib.TYPE_CHAR = 3
ULib.TYPE_ENTITY = 4
ULib.TYPE_FLOAT = 5
ULib.TYPE_LONG = 6
ULib.TYPE_SHORT = 7
ULib.TYPE_STRING = 8
ULib.TYPE_VECTOR = 9
-- These following aren't actually datatypes, we handle them ourselves
ULib.TYPE_TABLE_BEGIN = 10
ULib.TYPE_TABLE_END = 11
ULib.TYPE_NIL = 12

ULib.RPC_UMSG_NAME = "URPC"

ULib.TYPE_SIZE = {
	[ULib.TYPE_ANGLE] = 12, -- 3 floats
	[ULib.TYPE_BOOLEAN] = 1,
	[ULib.TYPE_CHAR] = 1,
	[ULib.TYPE_ENTITY] = 4, -- Found through trial and error
	[ULib.TYPE_FLOAT] = 4,
	[ULib.TYPE_LONG] = 4,
	[ULib.TYPE_SHORT] = 2,
	[ULib.TYPE_VECTOR] = 12, -- 3 floats
	[ULib.TYPE_NIL] = 0, -- Not technically a type but we handle it anyways
}

ULib.MAX_UMSG_BYTES = 255

--[[
	Section: Hooks

	These are the hooks that ULib has created that other modders are free to make use of.
]]

--[[
	Hook: UCLAuthed

	Called *on both server and client* when a player has been (re)authenticated by UCL. Called for ALL players, regardless of access.

	Parameters passed to callback:

		ply - The player that got (re)authenticated.

	Revisions:

		v2.40 - Initial
]]
ULib.HOOK_UCLAUTH = "UCLAuthed"

--[[
	Hook: UCLChanged

	Called *on both server and client* when anything in ULib.ucl.users, ULib.ucl.authed, or ULib.ucl.groups changes. No parameters are passed to callbacks.

	Revisions:

		v2.40 - Initial
]]
ULib.HOOK_UCLCHANGED = "UCLChanged"

--[[
	Hook: ULibReplicatedCvarChanged

	Called *on both client and server* when a replicated cvar changes or is created.

	Parameters passed to callback:

		sv_cvar - The name of the server-side cvar.
		cl_cvar - The name of the client-side cvar.
		ply - The player changing the cvar or nil on initial value.
		old_value - The previous value of the cvar, nil if this call is to set the initial value.
		new_value - The new value of the cvar.

	Revisions:

		v2.40 - Initial
		v2.50 - Removed nil on client side restriction.
]]
ULib.HOOK_REPCVARCHANGED = "ULibReplicatedCvarChanged"

--[[
	Hook: ULibLocalPlayerReady

	Called *on both client and server* when a player entity is created. (can now run commands). Only works for local
	player on the client side.

	Parameters passed to callback:

		ply - The player that's ready (local player on client side).

	Revisions:

		v2.40 - Initial
]]
ULib.HOOK_LOCALPLAYERREADY = "ULibLocalPlayerReady"

--[[
	Hook: ULibCommandCalled

	Called *on server* whenever a ULib command is run, return false to override and not allow, true to stop executing callbacks and allow.

	Parameters passed to callback:

		ply - The player attempting to execute the command.
		commandName - The command that's being executed.
		args - The table of args for the command.

	Revisions:

		v2.40 - Initial
]]
ULib.HOOK_COMMAND_CALLED = "ULibCommandCalled"

--[[
	Hook: ULibPlayerTarget

	Called whenever one player is about to target another player. Called *BEFORE* any other validation
	takes place. Return false and error message to disallow target completely, return true to
	override any other validation logic and allow the target to take place, return a player to force
	the target to be the specified player.

	Parameters passed to callback:

		ply - The player attempting to execute the command.
		commandName - The command that's being executed.
		target - The proposed target of the command before any other validation logic takes place.

	Revisions:

		v2.40 - Initial
]]
ULib.HOOK_PLAYER_TARGET = "ULibPlayerTarget"

--[[
	Hook: ULibPlayerTargets

	Called whenever one player is about to target another set of players. Called *BEFORE* any other validation
	takes place. Return false and error message to disallow target completely, return true to
	override any other validation logic and allow the target to take place, return a table of players to force
	the targets to be the specified players.

	Parameters passed to callback:

		ply - The player attempting to execute the command.
		commandName - The command that's being executed.
		targets - The proposed targets of the command before any other validation logic takes place.

	Revisions:

		v2.40 - Initial
]]
ULib.HOOK_PLAYER_TARGETS = "ULibPlayerTargets" -- Exactly the same as the above but used when the player is using a command that can target multiple players.

--[[
	Hook: ULibPostTranslatedCommand

	*Server hook*. Called after a translated command (ULib.cmds.TranslatedCommand) has been successfully
	verified. This hook directly follows the callback for the command itself.

	Parameters passed to callback:

		ply - The player that executed the command.
		commandName - The command that's being executed.
		translated_args - A table of the translated arguments, as passed into the callback function itself.

	Revisions:

		v2.40 - Initial
]]
ULib.HOOK_POST_TRANSLATED_COMMAND = "ULibPostTranslatedCommand"

--[[
	Hook: ULibPlayerNameChanged

	Called within one second of a player changing their name.

	Parameters passed to callback:

		ply - The player that changed names.
		oldName - The player's old name, before the change.
		newName - The player's new name, after the change.

	Revisions:

		v2.40 - Initial
]]
ULib.HOOK_PLAYER_NAME_CHANGED = "ULibPlayerNameChanged"

--[[
	Section: UCL Helpers

	These defines are server-only, to help with UCL.
]]
if SERVER then
ULib.UCL_LOAD_DEFAULT = true -- Set this to false to ignore the SetUserGroup() call.
ULib.UCL_USERS = "data/ulib/users.txt"
ULib.UCL_GROUPS = "data/ulib/groups.txt"
ULib.UCL_REGISTERED = "data/ulib/misc_registered.txt" -- Holds access strings that ULib has already registered
ULib.BANS_FILE = "data/ulib/bans.txt"
ULib.VERSION_FILE = "data/ulib/version.txt"

ULib.DEFAULT_GRANT_ACCESS = { allow={}, deny={}, guest=true }

hook.Add( "Initialize", "ULibCheckFileInit", function()
	if ULib.fileExists( ULib.UCL_REGISTERED ) and ULib.fileExists( "addons/ulib/data/" .. ULib.UCL_GROUPS ) and ULib.fileRead( ULib.UCL_GROUPS ) == ULib.fileRead( "addons/ulib/data/" .. ULib.UCL_GROUPS ) then
	  -- File has been reset, delete registered
		ULib.deleteFile( ULib.UCL_REGISTERED )
	end
end)
end

--[[
	Section: Net pooled strings

	These defines are server-only, to help with the networking library.
]]
if SERVER then
	util.AddNetworkString( "URPC" )
end
