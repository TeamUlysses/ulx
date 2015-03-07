ULib = ULib or {} -- Init table

include( "ulib/shared/defines.lua" )
include( "ulib/shared/misc.lua" )
include( "ulib/shared/util.lua" )
include( "ulib/shared/hook.lua" )
include( "ulib/shared/tables.lua" )
include( "ulib/client/commands.lua" )
include( "ulib/shared/messages.lua" )
include( "ulib/shared/player.lua" )
include( "ulib/client/cl_util.lua" )
include( "ulib/client/draw.lua" )
include( "ulib/shared/commands.lua" )
include( "ulib/shared/sh_ucl.lua" )

Msg( string.format( "You are running ULib version %.2f.\n", ULib.VERSION ) )

--Shared modules
local files = file.Find( "ulib/modules/*.lua", "LUA" )
if #files > 0 then
	for _, file in ipairs( files ) do
		Msg( "[ULIB] Loading SHARED module: " .. file .. "\n" )
		include( "ulib/modules/" .. file )
	end
end

--Client modules
local files = file.Find( "ulib/modules/client/*.lua", "LUA" )
if #files > 0 then
	for _, file in ipairs( files ) do
		Msg( "[ULIB] Loading CLIENT module: " .. file .. "\n" )
		include( "ulib/modules/client/" .. file )
	end
end

local needs_auth = {}

local function onEntCreated( ent )
	if ent:IsPlayer() and needs_auth[ ent:UserID() ] then
		hook.Call( ULib.HOOK_UCLAUTH, _, ent ) -- Because otherwise the server might call this before the player is created
		needs_auth[ ent:UserID() ] = nil
	end
end
hook.Add( "OnEntityCreated", "ULibPlayerAuthCheck", onEntCreated, -20 ) -- Listen for player creations

local function onInitPostEntity()
	if LocalPlayer():IsValid() then
		hook.Call( ULib.HOOK_LOCALPLAYERREADY, _, LocalPlayer() )
		RunConsoleCommand( "ulib_cl_ready" )
	end
end
hook.Add( "InitPostEntity", "ULibLocalPlayerReady", onInitPostEntity, -20 ) -- Flag server when LocalPlayer() should be valid

-- We're trying to make sure that the player auths after the player object is created, this function is part of that check
function authPlayerIfReady( ply, userid )
	if ply and ply:IsValid() then
		hook.Call( ULib.HOOK_UCLAUTH, _, ply ) -- Call hook
	else
		needs_auth[ userid ] = true
	end
end
