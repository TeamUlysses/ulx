local CATEGORY_NAME = "Utility"

------------------------------ Who ------------------------------
function ulx.who( calling_ply, steamid )
	if not steamid or steamid == "" then
		ULib.console( calling_ply, "ID Name                            Group" )

		local players = player.GetAll()
		for _, player in ipairs( players ) do
			local id = tostring( player:UserID() )
			local nick = utf8.force( player:Nick() )
			local text = string.format( "%i%s %s%s ", id, string.rep( " ", 2 - id:len() ), nick, string.rep( " ", 31 - utf8.len( nick ) ) )

			text = text .. player:GetUserGroup()

			ULib.console( calling_ply, text )
		end
	else
		data = ULib.ucl.getUserInfoFromID( steamid )

		if not data then
			ULib.console( calling_ply, "No information for provided id exists" )
		else
			ULib.console( calling_ply, "   ID: " .. steamid )
			ULib.console( calling_ply, " Name: " .. data.name )
			ULib.console( calling_ply, "Group: " .. data.group )
		end


	end
end
local who = ulx.command( CATEGORY_NAME, "ulx who", ulx.who )
who:addParam{ type=ULib.cmds.StringArg, hint="steamid", ULib.cmds.optional }
who:defaultAccess( ULib.ACCESS_ALL )
who:help( "See information about currently online users." )

------------------------------ Version ------------------------------
function ulx.versionCmd( calling_ply )
	ULib.tsay( calling_ply, "ULib " .. ULib.pluginVersionStr("ULib"), true )
	ULib.tsay( calling_ply, "ULX " .. ULib.pluginVersionStr("ULX"), true )
end
local version = ulx.command( CATEGORY_NAME, "ulx version", ulx.versionCmd, "!version" )
version:defaultAccess( ULib.ACCESS_ALL )
version:help( "See version information." )

------------------------------ Map ------------------------------
function ulx.map( calling_ply, map, gamemode )
	if not gamemode or gamemode == "" then
		ulx.fancyLogAdmin( calling_ply, "#A changed the map to #s", map )
	else
		ulx.fancyLogAdmin( calling_ply, "#A changed the map to #s with gamemode #s", map, gamemode )
	end
	if gamemode and gamemode ~= "" then
		game.ConsoleCommand( "gamemode " .. gamemode .. "\n" )
	end
	game.ConsoleCommand( "changelevel " .. map ..  "\n" )
end
local map = ulx.command( CATEGORY_NAME, "ulx map", ulx.map, "!map" )
map:addParam{ type=ULib.cmds.StringArg, completes=ulx.maps, hint="map", error="invalid map \"%s\" specified", ULib.cmds.restrictToCompletes }
map:addParam{ type=ULib.cmds.StringArg, completes=ulx.gamemodes, hint="gamemode", error="invalid gamemode \"%s\" specified", ULib.cmds.restrictToCompletes, ULib.cmds.optional }
map:defaultAccess( ULib.ACCESS_ADMIN )
map:help( "Changes map and gamemode." )

function ulx.kick( calling_ply, target_ply, reason )
	if target_ply:IsListenServerHost() then
		ULib.tsayError( calling_ply, "This player is immune to kicking", true )
		return
	end

	if reason and reason ~= "" then
		ulx.fancyLogAdmin( calling_ply, "#A kicked #T (#s)", target_ply, reason )
	else
		reason = nil
		ulx.fancyLogAdmin( calling_ply, "#A kicked #T", target_ply )
	end
	-- Delay by 1 frame to ensure the chat hook finishes with player intact. Prevents a crash.
	ULib.queueFunctionCall( ULib.kick, target_ply, reason, calling_ply )
end
local kick = ulx.command( CATEGORY_NAME, "ulx kick", ulx.kick, "!kick" )
kick:addParam{ type=ULib.cmds.PlayerArg }
kick:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
kick:defaultAccess( ULib.ACCESS_ADMIN )
kick:help( "Kicks target." )

------------------------------ Ban ------------------------------
function ulx.ban( calling_ply, target_ply, minutes, reason )
	if target_ply:IsListenServerHost() or target_ply:IsBot() then
		ULib.tsayError( calling_ply, "This player is immune to banning", true )
		return
	end

	local time = "for #s"
	if minutes == 0 then time = "permanently" end
	local str = "#A banned #T " .. time
	if reason and reason ~= "" then str = str .. " (#s)" end
	ulx.fancyLogAdmin( calling_ply, str, target_ply, minutes ~= 0 and ULib.secondsToStringTime( minutes * 60 ) or reason, reason )
	-- Delay by 1 frame to ensure any chat hook finishes with player intact. Prevents a crash.
	ULib.queueFunctionCall( ULib.kickban, target_ply, minutes, reason, calling_ply )
end
local ban = ulx.command( CATEGORY_NAME, "ulx ban", ulx.ban, "!ban", false, false, true )
ban:addParam{ type=ULib.cmds.PlayerArg }
ban:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
ban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
ban:defaultAccess( ULib.ACCESS_ADMIN )
ban:help( "Bans target." )

------------------------------ BanID ------------------------------
function ulx.banid( calling_ply, steamid, minutes, reason )
	steamid = steamid:upper()
	if not ULib.isValidSteamID( steamid ) then
		ULib.tsayError( calling_ply, "Invalid steamid." )
		return
	end

	local name, target_ply
	local plys = player.GetAll()
	for i=1, #plys do
		if plys[ i ]:SteamID() == steamid then
			target_ply = plys[ i ]
			name = target_ply:Nick()
			break
		end
	end

	if target_ply and (target_ply:IsListenServerHost() or target_ply:IsBot()) then
		ULib.tsayError( calling_ply, "This player is immune to banning", true )
		return
	end

	local time = "for #s"
	if minutes == 0 then time = "permanently" end
	local str = "#A banned steamid #s "
	displayid = steamid
	if name then
		displayid = displayid .. "(" .. name .. ") "
	end
	str = str .. time
	if reason and reason ~= "" then str = str .. " (#4s)" end
	ulx.fancyLogAdmin( calling_ply, str, displayid, minutes ~= 0 and ULib.secondsToStringTime( minutes * 60 ) or reason, reason )
	-- Delay by 1 frame to ensure any chat hook finishes with player intact. Prevents a crash.
	ULib.queueFunctionCall( ULib.addBan, steamid, minutes, reason, name, calling_ply )
end
local banid = ulx.command( CATEGORY_NAME, "ulx banid", ulx.banid, nil, false, false, true )
banid:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
banid:addParam{ type=ULib.cmds.NumArg, hint="minutes, 0 for perma", ULib.cmds.optional, ULib.cmds.allowTimeString, min=0 }
banid:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
banid:defaultAccess( ULib.ACCESS_SUPERADMIN )
banid:help( "Bans steamid." )

function ulx.unban( calling_ply, steamid )
	steamid = steamid:upper()
	if not ULib.isValidSteamID( steamid ) then
		ULib.tsayError( calling_ply, "Invalid steamid." )
		return
	end

	name = ULib.bans[ steamid ] and ULib.bans[ steamid ].name

	ULib.unban( steamid, calling_ply )
	if name then
		ulx.fancyLogAdmin( calling_ply, "#A unbanned steamid #s", steamid .. " (" .. name .. ")" )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unbanned steamid #s", steamid )
	end
end
local unban = ulx.command( CATEGORY_NAME, "ulx unban", ulx.unban, nil, false, false, true )
unban:addParam{ type=ULib.cmds.StringArg, hint="steamid" }
unban:defaultAccess( ULib.ACCESS_ADMIN )
unban:help( "Unbans steamid." )

------------------------------ Noclip ------------------------------
function ulx.noclip( calling_ply, target_plys )
	if not target_plys[ 1 ]:IsValid() then
		Msg( "You are god, you are not constrained by walls built by mere mortals.\n" )
		return
	end

	local affected_plys = {}
	for i=1, #target_plys do
		local v = target_plys[ i ]

		if v.NoNoclip then
			ULib.tsayError( calling_ply, v:Nick() .. " can't be noclipped right now.", true )
		else
			if v:GetMoveType() == MOVETYPE_WALK then
				v:SetMoveType( MOVETYPE_NOCLIP )
				table.insert( affected_plys, v )
			elseif v:GetMoveType() == MOVETYPE_NOCLIP then
				v:SetMoveType( MOVETYPE_WALK )
				table.insert( affected_plys, v )
			else -- Ignore if they're an observer
				ULib.tsayError( calling_ply, v:Nick() .. " can't be noclipped right now.", true )
			end
		end
	end
end
local noclip = ulx.command( CATEGORY_NAME, "ulx noclip", ulx.noclip, "!noclip" )
noclip:addParam{ type=ULib.cmds.PlayersArg, ULib.cmds.optional }
noclip:defaultAccess( ULib.ACCESS_ADMIN )
noclip:help( "Toggles noclip on target(s)." )

function ulx.spectate( calling_ply, target_ply )
	if not calling_ply:IsValid() then
		Msg( "You can't spectate from dedicated server console.\n" )
		return
	end

	-- Check if player is already spectating. If so, stop spectating so we can start again
	local hookTable = hook.GetTable()["KeyPress"]
	if hookTable and hookTable["ulx_unspectate_" .. calling_ply:EntIndex()] then
		-- Simulate keypress to properly exit spectate.
		hook.Call( "KeyPress", _, calling_ply, IN_FORWARD )
	end

	if ulx.getExclusive( calling_ply, calling_ply ) then
		ULib.tsayError( calling_ply, ulx.getExclusive( calling_ply, calling_ply ), true )
		return
	end

	ULib.getSpawnInfo( calling_ply )

	local pos = calling_ply:GetPos()
	local ang = calling_ply:GetAngles()
	
	local wasAlive = calling_ply:Alive()

	local function stopSpectate( player )
		if player ~= calling_ply then -- For the spawning, make sure it's them doing the spawning
			return
		end

		hook.Remove( "PlayerSpawn", "ulx_unspectatedspawn_" .. calling_ply:EntIndex() )
		hook.Remove( "KeyPress", "ulx_unspectate_" .. calling_ply:EntIndex() )
		hook.Remove( "PlayerDisconnected", "ulx_unspectatedisconnect_" .. calling_ply:EntIndex() )

		if player.ULXHasGod then player:GodEnable() end -- Restore if player had ulx god.
		player:UnSpectate() -- Need this for DarkRP for some reason, works fine without it in sbox
		ulx.fancyLogAdmin( calling_ply, true, "#A stopped spectating #T", target_ply )
		ulx.clearExclusive( calling_ply )
	end
	hook.Add( "PlayerSpawn", "ulx_unspectatedspawn_" .. calling_ply:EntIndex(), stopSpectate, HOOK_MONITOR_HIGH )

	local function unspectate( player, key )
		if calling_ply ~= player then return end -- Not the person we want
		if key ~= IN_FORWARD and key ~= IN_BACK and key ~= IN_MOVELEFT and key ~= IN_MOVERIGHT then return end -- Not a key we're interested in

		hook.Remove( "PlayerSpawn", "ulx_unspectatedspawn_" .. calling_ply:EntIndex() ) -- Otherwise spawn would cause infinite loop
		if wasAlive then -- We don't want to spawn them if they were already dead.
		    ULib.spawn( player, true ) -- Get out of spectate.
		end
		stopSpectate( player )
		player:SetPos( pos )
		player:SetAngles( ang )
	end
	hook.Add( "KeyPress", "ulx_unspectate_" .. calling_ply:EntIndex(), unspectate, HOOK_MONITOR_LOW )

	local function disconnect( player ) -- We want to watch for spectator or target disconnect
		if player == target_ply or player == calling_ply then -- Target or spectator disconnecting
			unspectate( calling_ply, IN_FORWARD )
		end
	end
	hook.Add( "PlayerDisconnected", "ulx_unspectatedisconnect_" .. calling_ply:EntIndex(), disconnect, HOOK_MONITOR_HIGH )

	calling_ply:Spectate( OBS_MODE_IN_EYE )
	calling_ply:SpectateEntity( target_ply )
	calling_ply:StripWeapons() -- Otherwise they can use weapons while spectating

	ULib.tsay( calling_ply, "To get out of spectate, move forward.", true )
	ulx.setExclusive( calling_ply, "spectating" )

	ulx.fancyLogAdmin( calling_ply, true, "#A began spectating #T", target_ply )
end
local spectate = ulx.command( CATEGORY_NAME, "ulx spectate", ulx.spectate, "!spectate", true )
spectate:addParam{ type=ULib.cmds.PlayerArg, target="!^" }
spectate:defaultAccess( ULib.ACCESS_ADMIN )
spectate:help( "Spectate target." )

function ulx.addForcedDownload( path )
	if ULib.fileIsDir( path ) then
		files = ULib.filesInDir( path )
		for _, v in ipairs( files ) do
			ulx.addForcedDownload( path .. "/" .. v )
		end
	elseif ULib.fileExists( path ) then
		resource.AddFile( path )
	else
		Msg( "[ULX] ERROR: Tried to add nonexistent or empty file to forced downloads '" .. path .. "'\n" )
	end
end

function ulx.debuginfo( calling_ply )
	local str = string.format( "ULX version: %s\nULib version: %s\n", ULib.pluginVersionStr( "ULX" ), ULib.pluginVersionStr( "ULib" ) )
	str = str .. string.format( "Gamemode: %s\nMap: %s\n", GAMEMODE.Name, game.GetMap() )
	str = str .. "Dedicated server: " .. tostring( game.IsDedicated() ) .. "\n\n"

	local players = player.GetAll()
	str = str .. string.format( "Currently connected players:\nNick%s steamid%s uid%s id lsh\n", str.rep( " ", 27 ), str.rep( " ", 12 ), str.rep( " ", 7 ) )
	for _, ply in ipairs( players ) do
		local id = string.format( "%i", ply:EntIndex() )
		local steamid = ply:SteamID()
		local uid = tostring( ply:UniqueID() )
		local name = utf8.force( ply:Nick() )

		local plyline = name .. str.rep( " ", 32 - utf8.len( name ) ) -- Name
		plyline = plyline .. steamid .. str.rep( " ", 20 - steamid:len() ) -- Steamid
		plyline = plyline .. uid .. str.rep( " ", 11 - uid:len() ) -- Steamid
		plyline = plyline .. id .. str.rep( " ", 3 - id:len() ) -- id
		if ply:IsListenServerHost() then
			plyline = plyline .. "y	  "
		else
			plyline = plyline .. "n	  "
		end

		str = str .. plyline .. "\n"
	end

	local gmoddefault = ULib.parseKeyValues( ULib.stripComments( ULib.fileRead( "settings/users.txt", true ), "//" ) ) or {}
	str = str .. "\n\nULib.ucl.users (#=" .. table.Count( ULib.ucl.users ) .. "):\n" .. ulx.dumpTable( ULib.ucl.users, 1 ) .. "\n\n"
	str = str .. "ULib.ucl.groups (#=" .. table.Count( ULib.ucl.groups ) .. "):\n" .. ulx.dumpTable( ULib.ucl.groups, 1 ) .. "\n\n"
	str = str .. "ULib.ucl.authed (#=" .. table.Count( ULib.ucl.authed ) .. "):\n" .. ulx.dumpTable( ULib.ucl.authed, 1 ) .. "\n\n"
	str = str .. "Garrysmod default file (#=" .. table.Count( gmoddefault ) .. "):\n" .. ulx.dumpTable( gmoddefault, 1 ) .. "\n\n"

	str = str .. "Active workshop addons on this server:\n"
	local addons = engine.GetAddons()
	for i=1, #addons do
		local addon = addons[i]
		if addon.mounted then
			local name = utf8.force( addon.title )
			str = str .. string.format( "%s%s workshop ID %s\n", name, str.rep( " ", 32 - utf8.len( name ) ), addon.file:gsub( "%D", "" ) )
		end
	end
	str = str .. "\n"

	str = str .. "Active legacy addons on this server:\n"
	local _, possibleaddons = file.Find( "addons/*", "GAME" )
	for _, addon in ipairs( possibleaddons ) do
		if not ULib.findInTable( {"checkers", "chess", "common", "go", "hearts", "spades"}, addon:lower() ) then -- Not sure what these addon folders are
			local name = addon
			local author, version, date
			if ULib.fileExists( "addons/" .. addon .. "/addon.txt" ) then
				local t = ULib.parseKeyValues( ULib.stripComments( ULib.fileRead( "addons/" .. addon .. "/addon.txt" ), "//" ) )
				if t and t.AddonInfo then
					t = t.AddonInfo
					if t.name then name = t.name end
					if t.version then version = t.version end
					if tonumber( version ) then version = string.format( "%g", version ) end -- Removes innaccuracy in floating point numbers
					if t.author_name then author = t.author_name end
					if t.up_date then date = t.up_date end
				end
			end

			name = utf8.force( name )
			str = str .. name .. str.rep( " ", 32 - utf8.len( name ) )
			if author then
				str = string.format( "%s by %s%s", str, author, version and "," or "" )
			end

			if version then
				str = str .. " version " .. version
			end

			if date then
				str = string.format( "%s (%s)", str, date )
			end
			str = str .. "\n"
		end
	end

	ULib.fileWrite( "data/ulx/debugdump.txt", str )
	Msg( "Debug information written to garrysmod/data/ulx/debugdump.txt on server.\n" )
end
local debuginfo = ulx.command( CATEGORY_NAME, "ulx debuginfo", ulx.debuginfo )
debuginfo:help( "Dump some debug information." )

function ulx.resettodefaults( calling_ply, param )
	if param ~= "FORCE" then
		local str = "Are you SURE about this? It will remove ulx-created temporary bans, configs, groups, EVERYTHING!"
		local str2 = "If you're sure, type \"ulx resettodefaults FORCE\""
		if calling_ply:IsValid() then
			ULib.tsayError( calling_ply, str, true )
			ULib.tsayError( calling_ply, str2, true )
		else
			Msg( str .. "\n" )
			Msg( str2 .. "\n" )
		end
		return
	end

	ULib.fileDelete( "data/ulx/adverts.txt" )
	ULib.fileDelete( "data/ulx/banreasons.txt" )
	ULib.fileDelete( "data/ulx/config.txt" )
	ULib.fileDelete( "data/ulx/downloads.txt" )
	ULib.fileDelete( "data/ulx/gimps.txt" )
	ULib.fileDelete( "data/ulx/sbox_limits.txt" )
	ULib.fileDelete( "data/ulx/votemaps.txt" )
	ULib.fileDelete( "data/ulib/bans.txt" )
	ULib.fileDelete( "data/ulib/groups.txt" )
	ULib.fileDelete( "data/ulib/misc_registered.txt" )
	ULib.fileDelete( "data/ulib/users.txt" )

	local str = "Please change levels to finish the reset"
	if calling_ply:IsValid() then
		ULib.tsayError( calling_ply, str, true )
	else
		Msg( str .. "\n" )
	end

	ulx.fancyLogAdmin( calling_ply, "#A reset all ULX and ULib configuration" )
end
local resettodefaults = ulx.command( CATEGORY_NAME, "ulx resettodefaults", ulx.resettodefaults )
resettodefaults:addParam{ type=ULib.cmds.StringArg, ULib.cmds.optional }
resettodefaults:help( "Resets ALL ULX and ULib configuration!" )

if SERVER then
	local ulx_kickAfterNameChanges = 			ulx.convar( "kickAfterNameChanges", "0", "<number> - Players can only change their name x times every ulx_kickAfterNameChangesCooldown seconds. 0 to disable.", ULib.ACCESS_ADMIN )
	local ulx_kickAfterNameChangesCooldown = 	ulx.convar( "kickAfterNameChangesCooldown", "60", "<time> - Players can change their name ulx_kickAfterXNameChanges times every x seconds.", ULib.ACCESS_ADMIN )
	local ulx_kickAfterNameChangesWarning = 	ulx.convar( "kickAfterNameChangesWarning", "1", "<1/0> - Display a warning to users to let them know how many more times they can change their name.", ULib.ACCESS_ADMIN )
	ulx.nameChangeTable = ulx.nameChangeTable or {}

	local function checkNameChangeLimit( ply, oldname, newname )
		local maxAttempts = ulx_kickAfterNameChanges:GetInt()
		local duration = ulx_kickAfterNameChangesCooldown:GetInt()
		local showWarning = ulx_kickAfterNameChangesWarning:GetInt()

		if maxAttempts ~= 0 then
			if not ulx.nameChangeTable[ply:SteamID()] then
				ulx.nameChangeTable[ply:SteamID()] = {}
			end

			for i=#ulx.nameChangeTable[ply:SteamID()], 1, -1 do
				if CurTime() - ulx.nameChangeTable[ply:SteamID()][i] > duration then
					table.remove( ulx.nameChangeTable[ply:SteamID()], i )
				end
			end

			table.insert( ulx.nameChangeTable[ply:SteamID()], CurTime() )

			local curAttempts = #ulx.nameChangeTable[ply:SteamID()]

			if curAttempts >= maxAttempts then
				ULib.kick( ply, "Changed name too many times" )
			else
				if showWarning == 1 then
					ULib.tsay( ply, "Warning: You have changed your name " .. curAttempts .. " out of " .. maxAttempts .. " time" .. ( maxAttempts ~= 1 and "s" ) .. " in the past " .. duration .. " second" .. ( duration ~= 1 and "s" ) )
				end
			end
		end
	end
	hook.Add( "ULibPlayerNameChanged", "ULXCheckNameChangeLimit", checkNameChangeLimit )
end

--------------------
--	   Hooks	  --
--------------------
-- This cvar also exists in DarkRP (thanks, FPtje)
local cl_cvar_pickup = "cl_pickupplayers"
if CLIENT then CreateClientConVar( cl_cvar_pickup, "1", true, true ) end
local function playerPickup( ply, ent )
	local access, tag = ULib.ucl.query( ply, "ulx physgunplayer" )
	if ent:GetClass() == "player" and ULib.isSandbox() and access and not ent.NoNoclip and not ent.frozen and ply:GetInfoNum( cl_cvar_pickup, 1 ) == 1 then
		-- Extra restrictions! UCL wasn't designed to handle this sort of thing so we're putting it in by hand...
		local restrictions = {}
		ULib.cmds.PlayerArg.processRestrictions( restrictions, ply, {}, tag and ULib.splitArgs( tag )[ 1 ] )
		if restrictions.restrictedTargets == false or (restrictions.restrictedTargets and not table.HasValue( restrictions.restrictedTargets, ent )) then
			return
		end

		ent:SetMoveType( MOVETYPE_NONE ) -- So they don't bounce
		return true
	end
end
hook.Add( "PhysgunPickup", "ulxPlayerPickup", playerPickup, HOOK_HIGH ) -- Allow admins to move players. Call before the prop protection hook.
if SERVER then ULib.ucl.registerAccess( "ulx physgunplayer", ULib.ACCESS_ADMIN, "Ability to physgun other players", "Other" ) end

local function playerDrop( ply, ent )
	if ent:GetClass() == "player" then
		ent:SetMoveType( MOVETYPE_WALK )
	end
end
hook.Add( "PhysgunDrop", "ulxPlayerDrop", playerDrop )
