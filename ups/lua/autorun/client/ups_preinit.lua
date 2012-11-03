-- We have to load this before ULib

local function empty( panel ) -- For the callback
end

local function firstMessage( panel )
	panel:AddControl( "Label", { Text = "UPS is not loaded on this server." } ) -- Default text.
end

local function popToolMenu()
	spawnmenu.AddToolMenuOption( "Utilities", "UPS Controls", "UPSAdmin", "Admin", "", "", empty )
	firstMessage( controlpanel.Get( "UPSAdmin" ) )
	
	spawnmenu.AddToolMenuOption( "Utilities", "UPS Controls", "UPSDisable", "Admin Disables", "", "", empty )
	firstMessage( controlpanel.Get( "UPSDisable" ) )
	
	spawnmenu.AddToolMenuOption( "Utilities", "UPS Controls", "UPSClient", "Client", "", "", empty )	
	firstMessage( controlpanel.Get( "UPSClient" ) )
	
	spawnmenu.AddToolMenuOption( "Utilities", "UPS Controls", "UPSFriends", "Friends", "", "", empty )
	firstMessage( controlpanel.Get( "UPSFriends" ) )
	
	spawnmenu.AddToolMenuOption( "Utilities", "UPS Controls", "UPSHUD", "HUD", "", "", empty, { SwitchConVar = "ups_hudenable" } )
	firstMessage( controlpanel.Get( "UPSHUD" ) )
end
hook.Add( "PopulateToolMenu", "UPSMenuPopulateTools", popToolMenu )