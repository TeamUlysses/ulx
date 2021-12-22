local CATEGORY_NAME = "Voting"

---------------
--Public vote--
---------------
if SERVER then ulx.convar( "voteEcho", "0", _, ULib.ACCESS_SUPERADMIN ) end -- Echo votes?

if SERVER then
	util.AddNetworkString( "ulx_vote" )
end
-- First, our helper function to make voting so much easier!
function ulx.doVote( title, options, callback, timeout, filter, noecho, ... )
	timeout = timeout or 20
	if ulx.voteInProgress then
		Msg( "Error! ULX tried to start a vote when another vote was in progress!\n" )
		return false
	end

	if not options[ 1 ] or not options[ 2 ] then
		Msg( "Error! ULX tried to start a vote without at least two options!\n" )
		return false
	end

	local voters = 0
	local rp = RecipientFilter()
	if not filter then
		rp:AddAllPlayers()
		voters = #player.GetAll()
	else
		for _, ply in ipairs( filter ) do
			rp:AddPlayer( ply )
			voters = voters + 1
		end
	end
	
	
	net.Start("ulx_vote")
		net.WriteString( title )
		net.WriteInt( timeout, 16 )
		net.WriteTable( options )
	net.Send(rp)
	

	ulx.voteInProgress = { callback=callback, options=options, title=title, results={}, voters=voters, votes=0, noecho=noecho, args={...} }

	timer.Create( "ULXVoteTimeout", timeout, 1, ulx.voteDone )

	return true
end

function ulx.voteCallback( ply, command, argv )
	if not ulx.voteInProgress then
		ULib.tsayError( ply, "There is not a vote in progress" )
		return
	end

	if not argv[ 1 ] or not tonumber( argv[ 1 ] ) or not ulx.voteInProgress.options[ tonumber( argv[ 1 ] ) ] then
		ULib.tsayError( ply, "Invalid or out of range vote." )
		return
	end

	if ply.ulxVoted then
		ULib.tsayError( ply, "You have already voted!" )
		return
	end

	local echo = ULib.toBool( GetConVarNumber( "ulx_voteEcho" ) )
	local id = tonumber( argv[ 1 ] )
	ulx.voteInProgress.results[ id ] = ulx.voteInProgress.results[ id ] or 0
	ulx.voteInProgress.results[ id ] = ulx.voteInProgress.results[ id ] + 1

	ulx.voteInProgress.votes = ulx.voteInProgress.votes + 1

	ply.ulxVoted = true -- Tag them as having voted

	local str = ply:Nick() .. " voted for: " .. ulx.voteInProgress.options[ id ]
	if echo and not ulx.voteInProgress.noecho then
		ULib.tsay( _, str ) -- TODO, color?
	end
	ulx.logString( str )
	if game.IsDedicated() then Msg( str .. "\n" ) end

	if ulx.voteInProgress.votes >= ulx.voteInProgress.voters then
		ulx.voteDone()
	end
end
if SERVER then concommand.Add( "ulx_vote", ulx.voteCallback ) end

function ulx.voteDone( cancelled )
	local players = player.GetAll()
	for _, ply in ipairs( players ) do -- Clear voting tags
		ply.ulxVoted = nil
	end

	local vip = ulx.voteInProgress
	ulx.voteInProgress = nil
	timer.Remove( "ULXVoteTimeout" )
	if not cancelled then
		ULib.pcallError( vip.callback, vip, unpack( vip.args, 1, 10 ) ) -- Unpack is explicit in length to avoid odd LuaJIT quirk.
	end
end
-- End our helper functions





local function voteDone( t )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local str
	if not winner then
		str = "Vote results: No option won because no one voted!"
	else
		str = "Vote results: Option '" .. t.options[ winner ] .. "' won. (" .. winnernum .. "/" .. t.voters .. ")"
	end
	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	Msg( str .. "\n" )
end

function ulx.vote( calling_ply, title, ... )
	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true )
		return
	end

	ulx.doVote( title, { ... }, voteDone )
	ulx.fancyLogAdmin( calling_ply, "#A started a vote (#s)", title )
end
local vote = ulx.command( CATEGORY_NAME, "ulx vote", ulx.vote, "!vote" )
vote:addParam{ type=ULib.cmds.StringArg, hint="title" }
vote:addParam{ type=ULib.cmds.StringArg, hint="options", ULib.cmds.takeRestOfLine, repeat_min=2, repeat_max=10 }
vote:defaultAccess( ULib.ACCESS_ADMIN )
vote:help( "Starts a public vote." )

-- Stop a vote in progress
function ulx.stopVote( calling_ply )
	if not ulx.voteInProgress then
		ULib.tsayError( calling_ply, "There is no vote currently in progress.", true )
		return
	end

	ulx.voteDone( true )
	ulx.fancyLogAdmin( calling_ply, "#A has stopped the current vote." )
end
local stopvote = ulx.command( CATEGORY_NAME, "ulx stopvote", ulx.stopVote, "!stopvote" )
stopvote:defaultAccess( ULib.ACCESS_SUPERADMIN )
stopvote:help( "Stops a vote in progress." )

local function voteMapDone2( t, changeTo, ply )
	local shouldChange = false

	if t.results[ 1 ] and t.results[ 1 ] > 0 then
		ulx.logServAct( ply, "#A approved the votemap" )
		shouldChange = true
	else
		ulx.logServAct( ply, "#A denied the votemap" )
	end

	if shouldChange then
		ULib.consoleCommand( "changelevel " .. changeTo .. "\n" )
	end
end

local function voteMapDone( t, argv, ply )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local ratioNeeded = GetConVarNumber( "ulx_votemap2Successratio" )
	local minVotes = GetConVarNumber( "ulx_votemap2Minvotes" )
	local str
	local changeTo
	-- Figure out the map to change to, if we're changing
	if #argv > 1 then
		changeTo = t.options[ winner ]
	else
		changeTo = argv[ 1 ]
	end

	if (#argv < 2 and winner ~= 1) or not winner or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
		str = "Vote results: Vote was unsuccessful."
	elseif ply:IsValid() then
		str = "Vote results: Option '" .. t.options[ winner ] .. "' won, changemap pending approval. (" .. winnernum .. "/" .. t.voters .. ")"

		ulx.doVote( "Accept result and changemap to " .. changeTo .. "?", { "Yes", "No" }, voteMapDone2, 30000, { ply }, true, changeTo, ply )
	else -- It's the server console, let's roll with it
		str = "Vote results: Option '" .. t.options[ winner ] .. "' won. (" .. winnernum .. "/" .. t.voters .. ")"
		ULib.tsay( _, str )
		ulx.logString( str )
		ULib.consoleCommand( "changelevel " .. changeTo .. "\n" )
		return
	end

	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	if game.IsDedicated() then Msg( str .. "\n" ) end
end

function ulx.votemap2( calling_ply, ... )
	local argv = { ... }

	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true )
		return
	end

	for i=2, #argv do
	    if ULib.findInTable( argv, argv[ i ], 1, i-1 ) then
	        ULib.tsayError( calling_ply, "Map " .. argv[ i ] .. " was listed twice. Please try again" )
	        return
	    end
	end

	if #argv > 1 then
		ulx.doVote( "Change map to..", argv, voteMapDone, _, _, _, argv, calling_ply )
		ulx.fancyLogAdmin( calling_ply, "#A started a votemap with options" .. string.rep( " #s", #argv ), ... )
	else
		ulx.doVote( "Change map to " .. argv[ 1 ] .. "?", { "Yes", "No" }, voteMapDone, _, _, _, argv, calling_ply )
		ulx.fancyLogAdmin( calling_ply, "#A started a votemap for #s", argv[ 1 ] )
	end
end
local votemap2 = ulx.command( CATEGORY_NAME, "ulx votemap2", ulx.votemap2, "!votemap2" )
votemap2:addParam{ type=ULib.cmds.StringArg, completes=ulx.maps, hint="map", error="invalid map \"%s\" specified", ULib.cmds.restrictToCompletes, ULib.cmds.takeRestOfLine, repeat_min=1, repeat_max=10 }
votemap2:defaultAccess( ULib.ACCESS_ADMIN )
votemap2:help( "Starts a public map vote." )
if SERVER then ulx.convar( "votemap2Successratio", "0.5", _, ULib.ACCESS_ADMIN ) end -- The ratio needed for a votemap2 to succeed
if SERVER then ulx.convar( "votemap2Minvotes", "3", _, ULib.ACCESS_ADMIN ) end -- Minimum votes needed for votemap2



local function voteKickDone2( t, target, time, ply, reason )
	local shouldKick = false

	if t.results[ 1 ] and t.results[ 1 ] > 0 then
		ulx.logUserAct( ply, target, "#A approved the votekick against #T (" .. (reason or "") .. ")" )
		shouldKick = true
	else
		ulx.logUserAct( ply, target, "#A denied the votekick against #T" )
	end

	if shouldKick then
		if reason and reason ~= "" then
			ULib.kick( target, "Vote kick successful. (" .. reason .. ")" )
		else
			ULib.kick( target, "Vote kick successful." )
		end
	end
end

local function voteKickDone( t, target, time, ply, reason )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local ratioNeeded = GetConVarNumber( "ulx_votekickSuccessratio" )
	local minVotes = GetConVarNumber( "ulx_votekickMinvotes" )
	local str
	if winner ~= 1 or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
		str = "Vote results: User will not be kicked. (" .. (results[ 1 ] or "0") .. "/" .. t.voters .. ")"
	else
		if not target:IsValid() then
			str = "Vote results: User voted to be kicked, but has already left."
		elseif ply:IsValid() then
			str = "Vote results: User will now be kicked, pending approval. (" .. winnernum .. "/" .. t.voters .. ")"
			ulx.doVote( "Accept result and kick " .. target:Nick() .. "?", { "Yes", "No" }, voteKickDone2, 30000, { ply }, true, target, time, ply, reason )
		else -- Vote from server console, roll with it
			str = "Vote results: User will now be kicked. (" .. winnernum .. "/" .. t.voters .. ")"
			ULib.kick( target, "Vote kick successful." )
		end
	end

	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	if game.IsDedicated() then Msg( str .. "\n" ) end
end

function ulx.votekick( calling_ply, target_ply, reason )
	if target_ply:IsListenServerHost() then
		ULib.tsayError( calling_ply, "This player is immune to kicking", true )
		return
	end

	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true )
		return
	end

	local msg = "Kick " .. target_ply:Nick() .. "?"
	if reason and reason ~= "" then
		msg = msg .. " (" .. reason .. ")"
	end

	ulx.doVote( msg, { "Yes", "No" }, voteKickDone, _, _, _, target_ply, time, calling_ply, reason )
	if reason and reason ~= "" then
		ulx.fancyLogAdmin( calling_ply, "#A started a votekick against #T (#s)", target_ply, reason )
	else
		ulx.fancyLogAdmin( calling_ply, "#A started a votekick against #T", target_ply )
	end
end
local votekick = ulx.command( CATEGORY_NAME, "ulx votekick", ulx.votekick, "!votekick" )
votekick:addParam{ type=ULib.cmds.PlayerArg }
votekick:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
votekick:defaultAccess( ULib.ACCESS_ADMIN )
votekick:help( "Starts a public kick vote against target." )
if SERVER then ulx.convar( "votekickSuccessratio", "0.6", _, ULib.ACCESS_ADMIN ) end -- The ratio needed for a votekick to succeed
if SERVER then ulx.convar( "votekickMinvotes", "2", _, ULib.ACCESS_ADMIN ) end -- Minimum votes needed for votekick



local function voteBanDone2( t, nick, steamid, time, ply, reason )
	local shouldBan = false

	if t.results[ 1 ] and t.results[ 1 ] > 0 then
		ulx.fancyLogAdmin( ply, "#A approved the voteban against #s (#s minutes) (#s))", nick, time, reason or "" )
		shouldBan = true
	else
		ulx.fancyLogAdmin( ply, "#A denied the voteban against #s", nick )
	end

	if shouldBan then
		ULib.addBan( steamid, time, reason, nick, ply )
	end
end

local function voteBanDone( t, nick, steamid, time, ply, reason )
	local results = t.results
	local winner
	local winnernum = 0
	for id, numvotes in pairs( results ) do
		if numvotes > winnernum then
			winner = id
			winnernum = numvotes
		end
	end

	local ratioNeeded = GetConVarNumber( "ulx_votebanSuccessratio" )
	local minVotes = GetConVarNumber( "ulx_votebanMinvotes" )
	local str
	if winner ~= 1 or winnernum < minVotes or winnernum / t.voters < ratioNeeded then
		str = "Vote results: User will not be banned. (" .. (results[ 1 ] or "0") .. "/" .. t.voters .. ")"
	else
		reason = ("[ULX Voteban] " .. (reason or "")):Trim()
		if ply:IsValid() then
			str = "Vote results: User will now be banned, pending approval. (" .. winnernum .. "/" .. t.voters .. ")"
			ulx.doVote( "Accept result and ban " .. nick .. "?", { "Yes", "No" }, voteBanDone2, 30000, { ply }, true, nick, steamid, time, ply, reason )
		else -- Vote from server console, roll with it
			str = "Vote results: User will now be banned. (" .. winnernum .. "/" .. t.voters .. ")"
			ULib.addBan( steamid, time, reason, nick, ply )
		end
	end

	ULib.tsay( _, str ) -- TODO, color?
	ulx.logString( str )
	Msg( str .. "\n" )
end

function ulx.voteban( calling_ply, target_ply, minutes, reason )
	if target_ply:IsListenServerHost() or target_ply:IsBot() then
		ULib.tsayError( calling_ply, "This player is immune to banning", true )
		return
	end

	if ulx.voteInProgress then
		ULib.tsayError( calling_ply, "There is already a vote in progress. Please wait for the current one to end.", true )
		return
	end

	local msg = "Ban " .. target_ply:Nick() .. " for " .. minutes .. " minutes?"
	if reason and reason ~= "" then
		msg = msg .. " (" .. reason .. ")"
	end

	ulx.doVote( msg, { "Yes", "No" }, voteBanDone, _, _, _, target_ply:Nick(), target_ply:SteamID(), minutes, calling_ply, reason )
	if reason and reason ~= "" then
		ulx.fancyLogAdmin( calling_ply, "#A started a voteban of #i minute(s) against #T (#s)", minutes, target_ply, reason )
	else
		ulx.fancyLogAdmin( calling_ply, "#A started a voteban of #i minute(s) against #T", minutes, target_ply )
	end
end
local voteban = ulx.command( CATEGORY_NAME, "ulx voteban", ulx.voteban, "!voteban" )
voteban:addParam{ type=ULib.cmds.PlayerArg }
voteban:addParam{ type=ULib.cmds.NumArg, min=0, default=1440, hint="minutes", ULib.cmds.allowTimeString, ULib.cmds.optional }
voteban:addParam{ type=ULib.cmds.StringArg, hint="reason", ULib.cmds.optional, ULib.cmds.takeRestOfLine, completes=ulx.common_kick_reasons }
voteban:defaultAccess( ULib.ACCESS_ADMIN )
voteban:help( "Starts a public ban vote against target." )
if SERVER then ulx.convar( "votebanSuccessratio", "0.7", _, ULib.ACCESS_ADMIN ) end -- The ratio needed for a voteban to succeed
if SERVER then ulx.convar( "votebanMinvotes", "3", _, ULib.ACCESS_ADMIN ) end -- Minimum votes needed for voteban

-- Our regular votemap command
local votemap = ulx.command( CATEGORY_NAME, "ulx votemap", ulx.votemap, "!votemap" )
votemap:addParam{ type=ULib.cmds.StringArg, completes=ulx.votemaps, hint="map", ULib.cmds.takeRestOfLine, ULib.cmds.optional }
votemap:defaultAccess( ULib.ACCESS_ALL )
votemap:help( "Vote for a map, no args lists available maps." )

-- Our veto command
local veto = ulx.command( CATEGORY_NAME, "ulx veto", ulx.votemapVeto, "!veto" )
veto:defaultAccess( ULib.ACCESS_ADMIN )
veto:help( "Veto a successful votemap." )
