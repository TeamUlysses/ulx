-- This module holds any type of chatting functions
CATEGORY_NAME = "Chat"

------------------------------ Psay ------------------------------
function ulx.psay( calling_ply, target_ply, message )
	if calling_ply:GetNWBool( "ulx_muted", false ) then
		ULib.tsayError( calling_ply, "You are muted, and therefore cannot speak! Use asay for admin chat if urgent.", true )
		return
	end

	ulx.fancyLog( { target_ply, calling_ply }, "#P to #P: " .. message, calling_ply, target_ply )
end
local psay = ulx.command( CATEGORY_NAME, "ulx psay", ulx.psay, "!p", true )
psay:addParam{ type=ULib.cmds.PlayerArg, target="!^", ULib.cmds.ignoreCanTarget }
psay:addParam{ type=ULib.cmds.StringArg, hint="message", ULib.cmds.takeRestOfLine }
psay:defaultAccess( ULib.ACCESS_ALL )
psay:help( "Send a private message to target." )

------------------------------ Asay ------------------------------
local seeasayAccess = "ulx seeasay"
if SERVER then ULib.ucl.registerAccess( seeasayAccess, ULib.ACCESS_OPERATOR, "Ability to see 'ulx asay'", "Other" ) end -- Give operators access to see asays echoes by default

function ulx.asay( calling_ply, message )
	local format
	local me = "/me "
	if message:sub( 1, me:len() ) == me then
		format = "(ADMINS) *** #P #s"
		message = message:sub( me:len() + 1 )
	else
		format = "#P to admins: #s"
	end

	local players = player.GetAll()
	for i=#players, 1, -1 do
		local v = players[ i ]
		if not ULib.ucl.query( v, seeasayAccess ) and v ~= calling_ply then -- Calling player always gets to see the echo
			table.remove( players, i )
		end
	end

	ulx.fancyLog( players, format, calling_ply, message )
end
local asay = ulx.command( CATEGORY_NAME, "ulx asay", ulx.asay, "@", true, true )
asay:addParam{ type=ULib.cmds.StringArg, hint="message", ULib.cmds.takeRestOfLine }
asay:defaultAccess( ULib.ACCESS_ALL )
asay:help( "Send a message to currently connected admins." )

------------------------------ Tsay ------------------------------
function ulx.tsay( calling_ply, message )
	ULib.tsay( _, message )

	if ULib.toBool( GetConVarNumber( "ulx_logChat" ) ) then
		ulx.logString( string.format( "(tsay from %s) %s", calling_ply:IsValid() and calling_ply:Nick() or "Console", message ) )
	end
end
local tsay = ulx.command( CATEGORY_NAME, "ulx tsay", ulx.tsay, "@@", true, true )
tsay:addParam{ type=ULib.cmds.StringArg, hint="message", ULib.cmds.takeRestOfLine }
tsay:defaultAccess( ULib.ACCESS_ADMIN )
tsay:help( "Send a message to everyone in the chat box." )

------------------------------ Csay ------------------------------
function ulx.csay( calling_ply, message )
	ULib.csay( _, message )

	if ULib.toBool( GetConVarNumber( "ulx_logChat" ) ) then
		ulx.logString( string.format( "(csay from %s) %s", calling_ply:IsValid() and calling_ply:Nick() or "Console", message ) )
	end
end
local csay = ulx.command( CATEGORY_NAME, "ulx csay", ulx.csay, "@@@", true, true )
csay:addParam{ type=ULib.cmds.StringArg, hint="message", ULib.cmds.takeRestOfLine }
csay:defaultAccess( ULib.ACCESS_ADMIN )
csay:help( "Send a message to everyone in the middle of their screen." )

------------------------------ Thetime ------------------------------
local waittime = 60
local lasttimeusage = -waittime
function ulx.thetime( calling_ply )
	if lasttimeusage + waittime > CurTime() then
		ULib.tsayError( calling_ply, "I just told you what time it is! Please wait " .. waittime .. " seconds before using this command again", true )
		return
	end

	lasttimeusage = CurTime()
	ulx.fancyLog( "The time is now #s.", os.date( "%I:%M %p") )
end
local thetime = ulx.command( CATEGORY_NAME, "ulx thetime", ulx.thetime, "!thetime" )
thetime:defaultAccess( ULib.ACCESS_ALL )
thetime:help( "Shows you the server time." )


------------------------------ Adverts ------------------------------
ulx.adverts = ulx.adverts or {}
local adverts = ulx.adverts -- For XGUI, too lazy to change all refs

local function doAdvert( group, id )

	if adverts[ group ][ id ] == nil then
		if adverts[ group ].removed_last then
			adverts[ group ].removed_last = nil
			id = 1
		else
			id = #adverts[ group ]
		end
	end

	local info = adverts[ group ][ id ]

	local message = string.gsub( info.message, "%%curmap%%", game.GetMap() )
	message = string.gsub( message, "%%host%%", GetConVarString( "hostname" ) )
	message = string.gsub( message, "%%ulx_version%%", ULib.pluginVersionStr( "ULX" ) )

	if not info.len then -- tsay
		local lines = ULib.explode( "\\n", message )

		for i, line in ipairs( lines ) do
			local trimmed = line:Trim()
			if trimmed:len() > 0 then
				ULib.tsayColor( _, true, info.color, trimmed ) -- Delaying runs one message every frame (to ensure correct order)
			end
		end
	else
		ULib.csay( _, message, info.color, info.len )
	end

	ULib.queueFunctionCall( function()
		local nextid = math.fmod( id, #adverts[ group ] ) + 1
		timer.Remove( "ULXAdvert" .. type( group ) .. group )
		timer.Create( "ULXAdvert" .. type( group ) .. group, adverts[ group ][ nextid ].rpt, 1, function() doAdvert( group, nextid ) end )
	end )
end

-- Whether or not it's a csay is determined by whether there's a value specified in "len"
function ulx.addAdvert( message, rpt, group, color, len )
	local t

	if group then
		t = adverts[ tostring( group ) ]
		if not t then
			t = {}
			adverts[ tostring( group ) ] = t
		end
	else
		group = table.insert( adverts, {} )
		t = adverts[ group ]
	end

	local id = table.insert( t, { message=message, rpt=rpt, color=color, len=len } )

	if not timer.Exists( "ULXAdvert" .. type( group ) .. group ) then
		timer.Create( "ULXAdvert" .. type( group ) .. group, rpt, 1, function() doAdvert( group, id ) end )
	end
end

------------------------------ Gimp ------------------------------
ulx.gimpSays = ulx.gimpSays or {} -- Holds gimp says
local gimpSays = ulx.gimpSays -- For XGUI, too lazy to change all refs
local ID_GIMP = 1
local ID_MUTE = 2

function ulx.addGimpSay( say )
	table.insert( gimpSays, say )
end

function ulx.clearGimpSays()
	table.Empty( gimpSays )
end

function ulx.gimp( calling_ply, target_plys, should_ungimp )
	for i=1, #target_plys do
		local v = target_plys[ i ]
		if should_ungimp then
			v.gimp = nil
		else
			v.gimp = ID_GIMP
		end
		v:SetNWBool("ulx_gimped", not should_ungimp)
	end

	if not should_ungimp then
		ulx.fancyLogAdmin( calling_ply, "#A gimped #T", target_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A ungimped #T", target_plys )
	end
end
local gimp = ulx.command( CATEGORY_NAME, "ulx gimp", ulx.gimp, "!gimp" )
gimp:addParam{ type=ULib.cmds.PlayersArg }
gimp:addParam{ type=ULib.cmds.BoolArg, invisible=true }
gimp:defaultAccess( ULib.ACCESS_ADMIN )
gimp:help( "Gimps target(s) so they are unable to chat normally." )
gimp:setOpposite( "ulx ungimp", {_, _, true}, "!ungimp" )

------------------------------ Mute ------------------------------
function ulx.mute( calling_ply, target_plys, should_unmute )
	for i=1, #target_plys do
		local v = target_plys[ i ]
		if should_unmute then
			v.gimp = nil
		else
			v.gimp = ID_MUTE
		end
		v:SetNWBool("ulx_muted", not should_unmute)
	end

	if not should_unmute then
		ulx.fancyLogAdmin( calling_ply, "#A muted #T", target_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A unmuted #T", target_plys )
	end
end
local mute = ulx.command( CATEGORY_NAME, "ulx mute", ulx.mute, "!mute" )
mute:addParam{ type=ULib.cmds.PlayersArg }
mute:addParam{ type=ULib.cmds.BoolArg, invisible=true }
mute:defaultAccess( ULib.ACCESS_ADMIN )
mute:help( "Mutes target(s) so they are unable to chat." )
mute:setOpposite( "ulx unmute", {_, _, true}, "!unmute" )

if SERVER then
	local function gimpCheck( ply, strText )
		if ply.gimp == ID_MUTE then return "" end
		if ply.gimp == ID_GIMP then
			if #gimpSays < 1 then return nil end
			return gimpSays[ math.random( #gimpSays ) ]
		end
	end
	hook.Add( "PlayerSay", "ULXGimpCheck", gimpCheck, HOOK_LOW )
end

------------------------------ Gag ------------------------------
function ulx.gag( calling_ply, target_plys, should_ungag )
	local players = player.GetAll()
	for i=1, #target_plys do
		local v = target_plys[ i ]
		v.ulx_gagged = not should_ungag
		v:SetNWBool("ulx_gagged", v.ulx_gagged)
	end

	if not should_ungag then
		ulx.fancyLogAdmin( calling_ply, "#A gagged #T", target_plys )
	else
		ulx.fancyLogAdmin( calling_ply, "#A ungagged #T", target_plys )
	end
end
local gag = ulx.command( CATEGORY_NAME, "ulx gag", ulx.gag, "!gag" )
gag:addParam{ type=ULib.cmds.PlayersArg }
gag:addParam{ type=ULib.cmds.BoolArg, invisible=true }
gag:defaultAccess( ULib.ACCESS_ADMIN )
gag:help( "Gag target(s), disables microphone." )
gag:setOpposite( "ulx ungag", {_, _, true}, "!ungag" )

local function gagHook( listener, talker )
	if talker.ulx_gagged then
		return false
	end
end
hook.Add( "PlayerCanHearPlayersVoice", "ULXGag", gagHook )

-- Anti-spam stuff
if SERVER then
	local chattime_cvar = ulx.convar( "chattime", "1.5", "<time> - Players can only chat every x seconds (anti-spam). 0 to disable.", ULib.ACCESS_ADMIN )
	local function playerSay( ply )
		if not ply.lastChatTime then ply.lastChatTime = 0 end

		local chattime = chattime_cvar:GetFloat()
		if chattime <= 0 then return end

		if ply.lastChatTime + chattime > CurTime() then
			return ""
		else
			ply.lastChatTime = CurTime()
			return
		end
	end
	hook.Add( "PlayerSay", "ulxPlayerSay", playerSay, HOOK_LOW )

	local function meCheck( ply, strText, bTeam )
		local meChatEnabled = GetConVarNumber( "ulx_meChatEnabled" )

		if ply.gimp or meChatEnabled == 0 or (meChatEnabled ~= 2 and GAMEMODE.Name ~= "Sandbox") then return end -- Don't mess

		if strText:sub( 1, 4 ) == "/me " then
			strText = string.format( "*** %s %s", ply:Nick(), strText:sub( 5 ) )
			if not bTeam then
				ULib.tsay( _, strText )
			else
				strText = "(TEAM) " .. strText
				local teamid = ply:Team()
				local players = team.GetPlayers( teamid )
				for _, ply2 in ipairs( players ) do
					ULib.tsay( ply2, strText )
				end
			end

			if game.IsDedicated() then
				Msg( strText .. "\n" ) -- Log to console
			end
			if ULib.toBool( GetConVarNumber( "ulx_logChat" ) ) then
				ulx.logString( strText )
			end

			return ""
		end

	end
	hook.Add( "PlayerSay", "ULXMeCheck", meCheck, HOOK_LOW ) -- Extremely low priority
end

local function showWelcome( ply )
	local message = GetConVarString( "ulx_welcomemessage" )
	if not message or message == "" then return end

	message = string.gsub( message, "%%curmap%%", game.GetMap() )
	message = string.gsub( message, "%%host%%", GetConVarString( "hostname" ) )
	message = string.gsub( message, "%%ulx_version%%", ULib.pluginVersionStr( "ULX" ) )

	ply:ChatPrint( message ) -- We're not using tsay because ULib might not be loaded yet. (client side)
end
hook.Add( "PlayerInitialSpawn", "ULXWelcome", showWelcome )
if SERVER then
	ulx.convar( "meChatEnabled", "1", "Allow players to use '/me' in chat. 0 = Disabled, 1 = Sandbox only (Default), 2 = Enabled", ULib.ACCESS_ADMIN )
	ulx.convar( "welcomemessage", "", "<msg> - This is shown to players on join.", ULib.ACCESS_ADMIN )
end
