module( "UPS", package.seeall )

local servercvarprefix = "ups_disableplayer"
local clientcvarprefix = "ups_cl_disableplayer"

local serverglobalcvarprefix = "ups_disableglobal"
local clientglobalcvarprefix = "ups_cl_disableglobal"

UPSDisabledPlayers = ULib.parseKeyValues( file.Read( DISABLEDFILE ) or "" )
local disableAccess = "ups disableplayers"
ULib.ucl.registerAccess( disableAccess, UPS_ADMIN, "Gives the ability to disable portions of UPS or disable UPS for players", "UPS" )
local globalDisableAccess = "ups globaldisable"
ULib.ucl.registerAccess( globalDisableAccess, UPS_ADMIN, "Gives the ability to globally disable UPS", "UPS" )

local function totallyDisabledCvarChanged( cvar, oldvalue, newvalue )
	local id = cvar:gsub( servercvarprefix, "" )
	id = tonumber( id )
	local bool = tonumber( newvalue )
	if not id or not bool then return end -- Error, ignore

	local ent = Entity( id )
	if not ent:IsValid() or not ent:IsPlayer() then return end -- Error, ignore

	UPSDisabledPlayers = ULib.parseKeyValues( file.Read( DISABLEDFILE ) or "" )
	local steamid = ent:SteamID()
	UPSDisabledPlayers[ steamid ] = UPSDisabledPlayers[ steamid ] or {}
	if bool ~= 0 then
		UPSDisabledPlayers[ steamid ].all = true
	else
		UPSDisabledPlayers[ steamid ].all = nil
		if table.Count( UPSDisabledPlayers[ steamid ] ) == 0 then
			UPSDisabledPlayers[ steamid ] = nil
		end
	end
	file.Write( DISABLEDFILE, ULib.makeKeyValues( UPSDisabledPlayers ) )
end

local function disabledCvarChanged( cvar, oldvalue, newvalue )
	local str = cvar:gsub( servercvarprefix .. "_", "" )
	local id = str:sub( -1 )
	local actionid = str:sub( 1, -2 )
	id = tonumber( id )
	local bool = tonumber( newvalue )
	if not id or not bool then return end -- Error, ignore

	if tonumber( str:sub( -2 ) ) then
		id = tonumber( str:sub( -2 ) )
		actionid = str:sub( 1, -3 )
	end

	local ent = Entity( id )
	if not ent:IsValid() or not ent:IsPlayer() then return end -- Error, ignore

	UPSDisabledPlayers = ULib.parseKeyValues( file.Read( DISABLEDFILE ) or "" )
	local steamid = ent:SteamID()
	UPSDisabledPlayers[ steamid ] = UPSDisabledPlayers[ steamid ] or {}
	if bool ~= 0 then
		UPSDisabledPlayers[ steamid ][ actionid ] = true
	else
		UPSDisabledPlayers[ steamid ][ actionid ] = nil
		if table.Count( UPSDisabledPlayers[ steamid ] ) == 0 then
			UPSDisabledPlayers[ steamid ] = nil
		end
	end
	file.Write( DISABLEDFILE, ULib.makeKeyValues( UPSDisabledPlayers ) )
end


-- Create necessary cvars
for i=1, MaxPlayers() do
	ULib.replicatedWritableCvar( servercvarprefix .. i, clientcvarprefix .. i, "0", false, false, disableAccess )
	ULib.queueFunctionCall( game.ConsoleCommand, servercvarprefix .. i .. " 0\n" ) -- We overload console if not queued
	cvars.AddChangeCallback( servercvarprefix .. i, totallyDisabledCvarChanged )

	for _, id in ipairs( accessIds ) do
		ULib.replicatedWritableCvar( servercvarprefix .. "_" .. id .. i, clientcvarprefix .. "_" .. id .. i, "0", false, false, disableAccess )
		ULib.queueFunctionCall( game.ConsoleCommand, servercvarprefix .. "_" .. id .. i .. " 0\n" ) -- We overload console if not queued
		cvars.AddChangeCallback( servercvarprefix .. "_" .. id .. i, disabledCvarChanged )
	end
end

local global_deny = {}
global_deny.all = replicatedWritableSavedCvar( serverglobalcvarprefix, clientglobalcvarprefix, "0", false, false, globalDisableAccess )
for _, id in ipairs( accessIds ) do
	global_deny[ id ] = replicatedWritableSavedCvar( serverglobalcvarprefix .. "_" .. id, clientglobalcvarprefix .. "_" .. id, "0", false, false, globalDisableAccess )
end

--[[
	Function: playerDisabledQuery

	This is a prequery (see <query>) hook in order to allow players to disable UPS on themselves and allow admins to disable them.

	Parameters:

		ply - The player entity requesting access.
		ent - The entity the player wants access to.
		actionid - What action they're trying to perform on the object. (IE, freeze, move, use)
		flags - A table of special instructions for this query. (IE, reassign ownership, no deny sound, etc)
]]
function playerDisabledQuery( ply, ent, actionid, flags )
	local ownerEnt = ent:UPSGetOwnerEnt()
	if ownerEnt then
		-- Is this globally denied?
		-- print( global_deny.all:GetBool(), global_deny[ actionid ]:GetBool() )
		if global_deny.all:GetBool() or global_deny[ actionid ]:GetBool() then
			return true
		end

		-- Has the player disabled it on themselves?
		if ULib.toBool( ownerEnt:GetInfo( clientcvarprefix ) ) or ULib.toBool( ownerEnt:GetInfo( clientcvarprefix .. "_" .. actionid ) ) then
			return true
		end

		-- Has an admin disabled it on them?
		local steamid = ownerEnt:SteamID()
		if UPSDisabledPlayers[ steamid ] and (UPSDisabledPlayers[ steamid ].all or UPSDisabledPlayers[ steamid ][ actionid ]) then
			return true
		end
	end
end
hook.Add( "UPSPreQuery", "UPSPlayerDisabledQuery", playerDisabledQuery )

-- This function just resets all our cvars on a join
local function onSpawn( ply )
	local steamid = ply:SteamID()
	local entid = ply:EntIndex()

	if not UPSDisabledPlayers[ steamid ] or not UPSDisabledPlayers[ steamid ].all then
		game.ConsoleCommand( servercvarprefix .. entid .. " 0\n" )
	else
		game.ConsoleCommand( servercvarprefix .. entid .. " 1\n" )
	end

	for _, id in ipairs( accessIds ) do
		if not UPSDisabledPlayers[ steamid ] or not UPSDisabledPlayers[ steamid ][ id ] then
			ULib.queueFunctionCall( game.ConsoleCommand, servercvarprefix .. "_" .. id .. entid .. " 0\n" ) -- Queue just to be safe
		else
			ULib.queueFunctionCall( game.ConsoleCommand, servercvarprefix .. "_" .. id .. entid .. " 1\n" ) -- Queue just to be safe
		end
	end
end
hook.Add( "PlayerInitialSpawn", "UPSSpawnClearDisabled", onSpawn )
