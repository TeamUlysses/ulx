------------------
--Public votemap--
------------------
ulx.votemaps = ulx.votemaps or {}
local specifiedMaps = {}

local function init()
	local mode = GetConVarNumber( "ulx_votemapMapmode" ) or 1
	if mode == 1 then -- Add all but specified
		local maps = file.Find( "maps/*.bsp", "GAME" )
		for _, map in ipairs( maps ) do
			map = map:sub( 1, -5 ) -- Take off .bsp
			if not specifiedMaps[ map ] then
				table.insert( ulx.votemaps, map )
			end
		end
	else
		for map, _ in pairs( specifiedMaps ) do
			if ULib.fileExists( "maps/" .. map .. ".bsp" ) then
				table.insert( ulx.votemaps, map )
			end
		end
	end

	-- Now, let's sort!
	table.sort( ulx.votemaps )
end
hook.Add( ulx.HOOK_ULXDONELOADING, "ULXInitConfigs", init ) -- Time for configs

local userMapvote = {} -- Indexed by player.
local mapvotes = {} -- Indexed by map.
ulx.timedVeto = nil

ulx.convar( "votemapEnabled", "1", _, ULib.ACCESS_ADMIN ) -- Enable/Disable the entire votemap command
ulx.convar( "votemapMintime", "10", _, ULib.ACCESS_ADMIN ) -- Time after map change before votes count.
ulx.convar( "votemapWaittime", "5", _, ULib.ACCESS_ADMIN ) -- Time before a user must wait before they can change their vote.
ulx.convar( "votemapSuccessratio", "0.5", _, ULib.ACCESS_ADMIN ) -- Ratio of (votes for map)/(total players) needed to change map. (Rounds up)
ulx.convar( "votemapMinvotes", "3", _, ULib.ACCESS_ADMIN ) -- Number of minimum votes needed to change map (Prevents llamas). This supersedes the above convar on small servers.
ulx.convar( "votemapVetotime", "30", _, ULib.ACCESS_ADMIN ) -- Time in seconds an admin has after a successful votemap to veto the vote. Set to 0 to disable.
ulx.convar( "votemapMapmode", "1", _, ULib.ACCESS_ADMIN ) -- 1 = Use all maps but what's specified below, 2 = Use only the maps specified below.

function ulx.votemapVeto( calling_ply )
	if not ulx.timedVeto then
		ULib.tsayError( calling_ply, "There's nothing to veto!", true )
		return
	end

	timer.Remove( "ULXVotemap" )
	ulx.timedVeto = nil
	hook.Call( ulx.HOOK_VETO )
	ULib.tsay( _, "Votemap changelevel halted.", true )
	ulx.logServAct( calling_ply, "#A vetoed the votemap" )
end
-- The command is defined at the end of vote.lua

function ulx.votemapAddMap( map )
	specifiedMaps[ map ] = true
end

function ulx.clearVotemaps()
	table.Empty( specifiedMaps )
end

function ulx.votemap( calling_ply, map )
	if not ULib.toBool( GetConVarNumber( "ulx_votemapEnabled" ) ) then
		ULib.tsayError( calling_ply, "The votemap command has been disabled by a server admin.", true )
		return
	end

	if not calling_ply:IsValid() then
		Msg( "You can't use votemap from the dedicated server console.\n" )
		return
	end

	if ulx.timedVeto then
		ULib.tsayError( calling_ply, "You cannot vote right now, another map has already won and is pending approval.", true )
		return
	end

	if not map or map == "" then
		ULib.tsay( calling_ply, "Map list printed to console", true )
		ULib.console( calling_ply, "Use \"votemap <id>\" to vote for a map. Map list:" )
		for id, map in ipairs( ulx.votemaps ) do
			ULib.console( calling_ply, "  " .. id .. " -\t" .. map )
		end
		return
	end

	local mintime = tonumber( GetConVarString( "ulx_votemapMintime" ) ) or 10
	if CurTime() < mintime * 60 then -- Minutes -> seconds
		ULib.tsayError( calling_ply, "Sorry, you must wait " .. mintime .. " minutes after a map change before you can vote for another map.", true )
		local timediff = mintime*60 - CurTime()
		ULib.tsayError( calling_ply, "That means you must wait " .. string.FormattedTime( math.fmod( timediff, 3600 ), (mintime < 60) and "%02i:%02i" or math.floor( timediff/3600 ) .. " hour(s) and %02i:%02i" ) .. " more minutes.", true )
		return
	end

	if userMapvote[ calling_ply ] then
		local waittime = tonumber( GetConVarString( "ulx_votemapWaittime" ) ) or 5
		if CurTime() - userMapvote[ calling_ply ].time < waittime * 60 then -- Minutes -> seconds
			ULib.tsayError( calling_ply, "Sorry, you must wait " .. waittime .. " minutes before changing your vote.", true )
			local timediff = waittime*60 - (CurTime() - userMapvote[ calling_ply ].time)
			ULib.tsayError( calling_ply, "That means you must wait " .. string.FormattedTime( math.fmod( timediff, 3600 ), (waittime < 60) and "%02i:%02i" or math.floor( timediff/3600 ) .. " hour(s) and %02i:%02i" ) .. " more minutes.", true )
			return
		end
	end


	local mapid
	if tonumber( map ) then
		mapid = tonumber( map )
		if not ulx.votemaps[ mapid ] then
			ULib.tsayError( calling_ply, "Invalid map id!", true )
			return
		end
	else
		if string.sub( map, -4 ) == ".bsp" then
			map = string.sub( map, 1, -5 ) -- Take off the .bsp
		end

		mapid = ULib.findInTable( ulx.votemaps, map )
		if not mapid then
			ULib.tsayError( calling_ply, "Invalid map!", true )
			return
		end
	end

	if userMapvote[ calling_ply ] then -- Take away from their previous vote
		mapvotes[ userMapvote[ calling_ply ].mapid ] = mapvotes[ userMapvote[ calling_ply ].mapid ] - 1
	end

	userMapvote[ calling_ply ] = { mapid=mapid, time=CurTime() }
	mapvotes[ mapid ] = mapvotes[ mapid ] or 0
	mapvotes[ mapid ] = mapvotes[ mapid ] + 1

	local minvotes = tonumber( GetConVarString( "ulx_votemapMinvotes" ) ) or 0
	local successratio = tonumber( GetConVarString( "ulx_votemapSuccessratio" ) ) or 0.5

	local votes_needed = math.ceil( math.max( minvotes, successratio * #player.GetAll() ) ) -- Round up whatever the largest is.

	-- TODO, color?
	ULib.tsay( _, string.format( "%s voted for %s (%i/%i). Say \"!votemap %i\" to vote for this map too.", calling_ply:Nick(), ulx.votemaps[ mapid ], mapvotes[ mapid ], votes_needed, mapid ), true )
	ulx.logString( string.format( "%s voted for %s (%i/%i)", calling_ply:Nick(), ulx.votemaps[ mapid ], mapvotes[ mapid ], votes_needed ) )

	if mapvotes[ mapid ] >= votes_needed then
		local vetotime = tonumber( GetConVarString( "ulx_votemapVetotime" ) ) or 30

		local admins = {}
		local players = player.GetAll()
		for _, player in ipairs( players ) do
			if player:IsConnected() then
				if ULib.ucl.query( player, "ulx veto" ) then
					table.insert( admins, player )
				end
			end
		end

		if #admins <= 0 or vetotime < 1 then
			ULib.tsay( _, "Vote for map " .. ulx.votemaps[ mapid ] .. " successful! Changing levels now.", true ) -- TODO, color?
			ulx.logString( "Votemap for " .. ulx.votemaps[ mapid ] .. " won." )
			game.ConsoleCommand( "changelevel " .. ulx.votemaps[ mapid ] .. "\n" )
		else
			ULib.tsay( _, "Vote for map " .. ulx.votemaps[ mapid ] .. " successful! Now pending admin approval. (" .. vetotime .. " seconds)", true ) -- TODO, color?
			for _, player in ipairs( admins ) do
				ULib.tsay( player, "To veto this vote, just say \"!veto\"", true ) -- TODO, color?
			end
			ulx.logString( "Votemap for " .. ulx.votemaps[ mapid ] .. " won. Pending admin veto." )
			ulx.timedVeto = true
			hook.Call( ulx.HOOK_VETO )
			timer.Create( "ULXVotemap", vetotime, 1, function() game.ConsoleCommand( "changelevel " .. ulx.votemaps[ mapid ] .. "\n" ) end )
		end
	end
end
-- This command is defined at the bottom of vote.lua

function ulx.votemap_disconnect( ply ) -- We use this to clear out old people's votes
	if userMapvote[ ply ] then -- Take away from their previous vote
		mapvotes[ userMapvote[ ply ].mapid ] = mapvotes[ userMapvote[ ply ].mapid ] - 1
		userMapvote[ ply ] = nil
	end
end
hook.Add( "PlayerDisconnected", "ULXVoteDisconnect", ulx.votemap_disconnect )
