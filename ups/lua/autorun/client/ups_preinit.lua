-- We have to load this before ULib
if not file.Exists( "lua_temp/ups/cl_init.lua", true ) then return end -- If this file doesn't exist then the server isn't running UPS.

local function empty( panel ) -- For the callback
end

local function firstMessage( panel )
	panel:AddControl( "Label", { Text = "UPS is not loaded on this server." } ) -- Default text.
end

local function popToolMenu()
	spawnmenu.AddToolMenuOption( "Utilities", "UPS Controls", "UPSAdmin", "Admin", "", "", empty )
	firstMessage( GetControlPanel( "UPSAdmin" ) )
	
	if file.Exists( "lua_temp/ups/modules/cl/menu_disable.lua", true ) then
		spawnmenu.AddToolMenuOption( "Utilities", "UPS Controls", "UPSDisable", "Admin Disables", "", "", empty )
		firstMessage( GetControlPanel( "UPSDisable" ) )
	end		
	
	spawnmenu.AddToolMenuOption( "Utilities", "UPS Controls", "UPSClient", "Client", "", "", empty )	
	firstMessage( GetControlPanel( "UPSClient" ) )
	
	if file.Exists( "lua_temp/ups/modules/cl/friends.lua", true ) then
		spawnmenu.AddToolMenuOption( "Utilities", "UPS Controls", "UPSFriends", "Friends", "", "", empty )
		firstMessage( GetControlPanel( "UPSFriends" ) )
	end		
	
	if file.Exists( "lua_temp/ups/modules/cl/hud.lua", true ) then
		spawnmenu.AddToolMenuOption( "Utilities", "UPS Controls", "UPSHUD", "HUD", "", "", empty, { SwitchConVar = "ups_hudenable" } )
		firstMessage( GetControlPanel( "UPSHUD" ) )
	end
end
hook.Add( "PopulateToolMenu", "UPSMenuPopulateTools", popToolMenu )