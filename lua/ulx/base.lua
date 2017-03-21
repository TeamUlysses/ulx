--[[
	Title: Base

	Sets up some things for ulx.
]]

ulx.cvars = ulx.cvars or {} -- Used to decipher spaced cvars into actual implementation of underscored cvars (see below)

--[[
	Function: convar

	This is what will set up ULX's convars, it makes them under the command "ulx"

	Parameters:

		command - The console command. IE, "sv_kickminge".
		value - The value to start off at.
		help - *(Optional)* A help string for using the command.
		access - *(Optional, defaults to ACCESS_ALL)* Restricted access.
]]
function ulx.convar( command, value, help, access )
	help = help or ""
	access = access or ULib.ACCESS_ALL
	ULib.ucl.registerAccess( "ulx " .. command, access, help, "Cvar" )

	-- table.insert( ulx.convarhelp[ currentCategory ], { cmd=command, access=access, help=help } ) -- TODO

	local nospaceCommand = command:gsub( " ", "_" )
	local cvarName = "ulx_" .. nospaceCommand
	local obj = ULib.replicatedWritableCvar( cvarName, cvarName, value, false, false, "ulx " .. command )
	ulx.cvars[ command:lower() ] = { help=help, cvar=nospaceCommand, original=command, obj=obj }

	return obj
end

function ulx.addToHelpManually( category, cmd, string, access_tag )
	ulx.cmdsByCategory[ category ] = ulx.cmdsByCategory[ category ] or {}
	for i=#ulx.cmdsByCategory[ category ],1,-1 do
		existingCmd = ulx.cmdsByCategory[ category ][i]
		if existingCmd.cmd == cmd and existingCmd.manual == true then
			table.remove( ulx.cmdsByCategory[ category ], i)
			break
		end
	end
	table.insert( ulx.cmdsByCategory[ category ], { access_tag=access_tag, cmd=cmd, helpStr=string, manual=true } )
end

--------------------------------------
--Now for boring initilization stuff--
--------------------------------------

-- Setup the maps table
do
	ulx.maps = {}
	local maps = file.Find( "maps/*.bsp", "GAME" )

	for _, map in ipairs( maps ) do
		table.insert( ulx.maps, map:sub( 1, -5 ):lower() ) -- Take off the .bsp
	end
	table.sort( ulx.maps ) -- Make sure it's alphabetical

	ulx.gamemodes = {}
	local fromEngine = engine.GetGamemodes()
	for i=1, #fromEngine do
		table.insert( ulx.gamemodes, fromEngine[ i ].name:lower() )
	end

	table.sort( ulx.gamemodes ) -- Alphabetize
end

ulx.common_kick_reasons = ulx.common_kick_reasons or {}
function ulx.addKickReason( reason )
	table.insert( ulx.common_kick_reasons, reason )
	table.sort( ulx.common_kick_reasons )
end

local function sendAutocompletes( ply )
	if ply:query( "ulx map" ) or ply:query( "ulx votemap2" ) then -- Only send if they have access to this.
		ULib.clientRPC( ply, "ulx.populateClMaps", ulx.maps )
		ULib.clientRPC( ply, "ulx.populateClGamemodes", ulx.gamemodes )
	end

	ULib.clientRPC( ply, "ulx.populateClVotemaps", ulx.votemaps )
	ULib.clientRPC( ply, "ulx.populateKickReasons", ulx.common_kick_reasons )
end
hook.Add( ULib.HOOK_UCLAUTH, "sendAutoCompletes", sendAutocompletes )
hook.Add( "PlayerInitialSpawn", "sendAutoCompletes", sendAutocompletes )

-- Cvar saving
function cvarChanged( sv_cvar, cl_cvar, ply, old_value, new_value )
	if not sv_cvar:find( "^ulx_" ) then return end
	local command = sv_cvar:gsub( "^ulx_", "" ):lower() -- Strip it off for lookup below
	if not ulx.cvars[ command ] then return end
	sv_cvar = ulx.cvars[ command ].original -- Make sure we have intended casing
	local path = "data/ulx/config.txt"
	if not ULib.fileExists( path ) then
		Msg( "[ULX ERROR] Config doesn't exist at " .. path .. "\n" )
		return
	end

	sv_cvar = sv_cvar:gsub( "_", " " ) -- Convert back to space notation

	if new_value:find( "[%s:']" ) then new_value = string.format( "%q", new_value ) end
	local replacement = string.format( "%s %s ", sv_cvar, new_value:gsub( "%%", "%%%%" ) ) -- Because we're feeding it through gsub below, need to expand '%'s
	local config = ULib.fileRead( path )
	config, found = config:gsub( ULib.makePatternSafe( sv_cvar ):gsub( "%a", function( c ) return "[" .. c:lower() .. c:upper() .. "]" end ) .. "%s+[^;\r\n]*", replacement ) -- The gsub makes us case neutral
	if found == 0 then -- Configuration option does not exist in config- append it
		newline = config:match("\r?\n") or "\n"
		if not config:find("\r?\n$") then config = config .. newline end
		config = config .. "ulx " .. replacement .. "; " .. ulx.cvars[ command ].help .. newline
	end
	ULib.fileWrite( path, config )
end
hook.Add( ulx.HOOK_ULXDONELOADING, "AddCvarHook", function() hook.Add( ULib.HOOK_REPCVARCHANGED, "ULXCheckCvar", cvarChanged ) end ) -- We're not interested in changing cvars till after load
