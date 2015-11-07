local CATEGORY_NAME = "Menus"

if ULib.fileExists( "lua/ulx/modules/cl/motdmenu.lua" ) or ulx.motdmenu_exists then
	CreateConVar( "motdfile", "ulx_motd.txt" ) -- Garry likes to add and remove this cvar a lot, so it's here just in case he removes it again.
	local function sendMotd( ply, showMotd )
		if showMotd == "1" then -- Assume it's a file
			if ply.ulxHasMotd then return end -- This player already has the motd
			if not ULib.fileExists( GetConVarString( "motdfile" ) ) then return end -- Invalid
			local f = ULib.fileRead( GetConVarString( "motdfile" ) )

			ULib.clientRPC( ply, "ulx.rcvMotd", false, f )

			ply.ulxHasMotd = true

		else -- Assume URL
			ULib.clientRPC( ply, "ulx.rcvMotd", true, showMotd )
			ply.ulxHasMotd = nil
		end
	end

	local function showMotd( ply )
		local showMotd = GetConVarString( "ulx_showMotd" )
		if showMotd == "0" then return end
		if not ply:IsValid() then return end -- They left, doh!

		sendMotd( ply, showMotd )
		ULib.clientRPC( ply, "ulx.showMotdMenu", ply:SteamID() ) -- Passing it because they may get it before LocalPlayer() is valid
	end
	hook.Add( "PlayerInitialSpawn", "showMotd", showMotd )

	function ulx.motd( calling_ply )
		if not calling_ply:IsValid() then
			Msg( "You can't see the motd from the console.\n" )
			return
		end

		if GetConVarString( "ulx_showMotd" ) == "0" then
			ULib.tsay( calling_ply, "The MOTD has been disabled on this server." )
			return
		end

		showMotd( calling_ply )
	end
	local motdmenu = ulx.command( CATEGORY_NAME, "ulx motd", ulx.motd, "!motd" )
	motdmenu:defaultAccess( ULib.ACCESS_ALL )
	motdmenu:help( "Show the message of the day." )
	if SERVER then ulx.convar( "showMotd", "1", " <0/1/(url)> - Shows the motd to clients on startup. Can specify URL here.", ULib.ACCESS_ADMIN ) end
end
