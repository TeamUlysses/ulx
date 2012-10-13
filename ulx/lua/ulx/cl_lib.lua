ulx.common_kick_reasons = {}
function ulx.populateKickReasons( reasons )
	table.Empty( ulx.common_kick_reasons )
	table.Merge( ulx.common_kick_reasons, reasons )
end

ulx.maps = {}
function ulx.populateClMaps( maps )
	table.Empty( ulx.maps )
	table.Merge( ulx.maps, maps )
end

ulx.gamemodes = {}
function ulx.populateClGamemodes( gamemodes )
	table.Empty( ulx.gamemodes )
	table.Merge( ulx.gamemodes, gamemodes )
end

ulx.votemaps = {}
function ulx.populateClVotemaps( votemaps )
	table.Empty( ulx.votemaps )
	table.Merge( ulx.votemaps, votemaps )
end

function ulx.soundComplete( ply, args )
	local targs = string.Trim( args )
	local soundList = {}

	local relpath = targs:GetPathFromFilename()
	local sounds = file.Find( "sound/" .. relpath .. "*", "GAME" )
	for _, sound in ipairs( sounds ) do
		if targs:len() == 0 or (relpath .. sound):sub( 1, targs:len() ) == targs then
			table.insert( soundList, relpath .. sound )
		end
	end

	return soundList
end

function ulx.blindUser( bool, amt )
	if bool then
		local function blind()
			draw.RoundedBox( 0, 0, 0, ScrW(), ScrH(), Color( 255, 255, 255, amt ) )
		end
		hook.Add( "HUDPaint", "ulx_blind", blind )
	else
		hook.Remove( "HUDPaint", "ulx_blind" )
	end
end

local function rcvBlind( um )
	local bool = um:ReadBool()
	local amt = um:ReadShort()
	ulx.blindUser( bool, amt )
end
usermessage.Hook( "ulx_blind", rcvBlind )

function ulx.gagUser( user_to_gag, should_gag )
	if should_gag then
		if user_to_gag.ulx_was_gagged == nil then user_to_gag.ulx_was_gagged = user_to_gag:IsMuted() end
		if user_to_gag:IsMuted() then return end
		user_to_gag:SetMuted( true )
	else
		local was_gagged = user_to_gag.ulx_was_gagged
		user_to_gag.ulx_was_gagged = nil
		if not user_to_gag:IsMuted() or was_gagged then return end
		user_to_gag:SetMuted( true ) -- Toggle
	end
end

local function rcvGag( um )
	local user_to_gag = um:ReadEntity()
	local gagged = um:ReadBool()
	ulx.gagUser( user_to_gag, gagged )
end
usermessage.Hook( "ulx_gag", rcvGag )

local curVote

local function optionsDraw()
	if not curVote then return end

	local title = curVote.title
	local options = curVote.options
	local endtime = curVote.endtime

	if CurTime() > endtime then return end -- Expired

	surface.SetFont( "Default" )
	local w, h = surface.GetTextSize( title )
	w = math.max( 200, w )
	local totalh = h * 12 + 20
	draw.RoundedBox( 8, 10, ScrH()*0.4 - 10, w + 20, totalh, Color( 111, 124, 138, 200 ) )

	optiontxt = ""
	for i=1, 10 do
		if options[ i ] and options[ i ] ~= "" then
			optiontxt = optiontxt .. math.modf( i, 10 ) .. ". " .. options[ i ]
		end
		optiontxt = optiontxt .. "\n"
	end
	draw.DrawText( title .. "\n\n" .. optiontxt, "Default", 20, ScrH()*0.4, Color( 255, 255, 255, 255 ), TEXT_ALIGN_LEFT )
end

local function rcvVote( um )
	local title = um:ReadString()
	local timeout = um:ReadShort()
	local options = ULib.umsgRcv( um )

	local function callback( id )
		if id == 0 then id = 10 end

		if not options[ id ] then
			return -- Returning nil will keep our hook
		end

		RunConsoleCommand( "ulx_vote", id )
		curVote = nil
		return true -- Let it know we're done here
	end
	LocalPlayer():AddPlayerOption( title, timeout, callback, optionsDraw )

	curVote = { title=title, options=options, endtime=CurTime()+timeout }
end
usermessage.Hook( "ulx_vote", rcvVote )

function ulx.getVersion() -- This exists on the server as well, so feel free to use it!
	if ulx.release then
		version = string.format( "%.02f", ulx.version )
	elseif ulx.revision > 0 then -- SVN version?
		version = string.format( "<SVN> revision %i", ulx.revision )
	else
		version = string.format( "<SVN> unknown revision" )
	end

	return version, ulx.version, ulx.revision

end

function ulx.addToMenu( menuid, label, data ) -- TODO, remove
	Msg( "Warning: ulx.addToMenu was called, which is being phased out!\n" )
end

-- Any language stuff for ULX should go here...

language.Add( "Undone_ulx_ent", "Undone ulx ent command" )
