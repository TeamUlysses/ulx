ulx.common_kick_reasons = ulx.common_kick_reasons or {}
function ulx.populateKickReasons( reasons )
	table.Empty( ulx.common_kick_reasons )
	table.Merge( ulx.common_kick_reasons, reasons )
end

ulx.maps = ulx.maps or {}
function ulx.populateClMaps( maps )
	table.Empty( ulx.maps )
	table.Merge( ulx.maps, maps )
end

ulx.gamemodes = ulx.gamemodes or {}
function ulx.populateClGamemodes( gamemodes )
	table.Empty( ulx.gamemodes )
	table.Merge( ulx.gamemodes, gamemodes )
end

ulx.votemaps = ulx.votemaps or {}
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

-- Any language stuff for ULX should go here...

language.Add( "Undone_ulx_ent", "Undone ulx ent command" )
