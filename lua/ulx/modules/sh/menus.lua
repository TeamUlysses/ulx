local CATEGORY_NAME = "Menus"

if ULib.fileExists( "lua/ulx/modules/cl/motdmenu.lua" ) or ulx.motdmenu_exists then
	local function sendMotd( ply, showMotd )
		if ply.ulxHasMotd then return end -- This player already has the motd data
		if showMotd == "1" then -- Assume it's a file
			if not ULib.fileExists( GetConVarString( "ulx_motdfile" ) ) then return end -- Invalid
			local f = ULib.fileRead( GetConVarString( "ulx_motdfile" ) )

			ULib.clientRPC( ply, "ulx.rcvMotd", showMotd, f )

		elseif showMotd == "2" then
			ULib.clientRPC( ply, "ulx.rcvMotd", showMotd, ulx.motdSettings )

		else -- Assume URL
			ULib.clientRPC( ply, "ulx.rcvMotd", showMotd, GetConVarString( "ulx_motdurl" ) )
		end
		ply.ulxHasMotd = true
	end

	local function showMotd( ply )
		local showMotd = GetConVarString( "ulx_showMotd" )
		if showMotd == "0" then return end
		if not ply:IsValid() then return end -- They left, doh!

		sendMotd( ply, showMotd )
		ULib.clientRPC( ply, "ulx.showMotdMenu", ply:SteamID() ) -- Passing it because they may get it before LocalPlayer() is valid
	end
	hook.Add( "PlayerInitialSpawn", "showMotd", showMotd )

	function ulx.motdUpdated()
		for i=1, #player.GetAll() do
			player.GetAll()[i].ulxHasMotd = false
		end
	end

	local function conVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
		if string.lower( cl_cvar ) == "ulx_showmotd" or string.lower( cl_cvar ) == "ulx_motdfile" or string.lower( cl_cvar ) == "ulx_motdurl" then
			ulx.motdUpdated()
		end
	end
	hook.Add( "ULibReplicatedCvarChanged", "ulx.clearMotdCache", conVarUpdated )

	function ulx.motd( calling_ply )
		if not calling_ply:IsValid() then
			Msg( "You can't see the motd from the console.\n" )
			return
		end

		if GetConVarString( "ulx_showMotd" ) == "0" then
			ULib.tsay( calling_ply, "The MOTD has been disabled on this server." )
			return
		end

		if GetConVarString( "ulx_showMotd" ) == "1" and not ULib.fileExists( GetConVarString( "ulx_motdfile" ) ) then
			ULib.tsay( calling_ply, "The MOTD file could not be found." )
			return
		end

		showMotd( calling_ply )
	end
	local motdmenu = ulx.command( CATEGORY_NAME, "ulx motd", ulx.motd, "!motd" )
	motdmenu:defaultAccess( ULib.ACCESS_ALL )
	motdmenu:help( "Show the message of the day." )

	if SERVER then
		ulx.convar( "showMotd", "2", " <0/1/2/3> - MOTD mode. 0 is off.", ULib.ACCESS_ADMIN )
		ulx.convar( "motdfile", "ulx_motd.txt", "MOTD filepath from gmod root to use if ulx showMotd is 1.", ULib.ACCESS_ADMIN )
		ulx.convar( "motdurl", "ulyssesmod.net", "MOTD URL to use if ulx showMotd is 3.", ULib.ACCESS_ADMIN )

		function ulx.populateMotdData()
			if ulx.motdSettings == nil or ulx.motdSettings.info == nil then return end

			ulx.motdSettings.admins = {}

			local getAddonInfo = false

			-- Gather addon/admin information to display
			for i=1, #ulx.motdSettings.info do
				local sectionInfo = ulx.motdSettings.info[i]
				if sectionInfo.type == "mods" and not ulx.motdSettings.addons then
					getAddonInfo = true
				elseif sectionInfo.type == "admins" then
					for a=1, #sectionInfo.contents do
						ulx.motdSettings.admins[sectionInfo.contents[a]] = true
					end
				end
			end

			if getAddonInfo then
				ulx.motdSettings.addons = {}
				local addons = engine.GetAddons()
				for i=1, #addons do
					local addon = addons[i]
					if addon.mounted then
						table.insert( ulx.motdSettings.addons, { title=addon.title, workshop_id=addon.file:gsub("%D", "") } )
					end
				end

				local _, possibleaddons = file.Find( "addons/*", "GAME" )
				for _, addon in ipairs( possibleaddons ) do
					if ULib.fileExists( "addons/" .. addon .. "/addon.txt" ) then
						local t = ULib.parseKeyValues( ULib.stripComments( ULib.fileRead( "addons/" .. addon .. "/addon.txt" ), "//" ) )
						if t and t.AddonInfo then
							local name = t.AddonInfo.name or addon
							table.insert( ulx.motdSettings.addons, { title=name, author=t.AddonInfo.author_name } )
						end
					end
				end

				table.sort( ulx.motdSettings.addons, function(a,b) return string.lower(a.title) < string.lower(b.title) end )
			end

			for group, _ in pairs( ulx.motdSettings.admins ) do
				ulx.motdSettings.admins[group] = {}
				for steamID, data in pairs( ULib.ucl.users ) do
					if data.group == group and data.name then
						table.insert( ulx.motdSettings.admins[group], data.name )
					end
				end
			end
		end
		hook.Add( ULib.HOOK_UCLCHANGED, "ulx.updateMotd.adminsChanged", ulx.populateMotdData )
	end

end
