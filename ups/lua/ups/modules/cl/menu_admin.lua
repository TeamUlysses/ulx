module( "UPS", package.seeall )
-- This holds all the "essential" or base admin menu stuff.

local function buildMenu( panel )

	panel:AddControl( "Label", { Text = "" } ) -- Spacing

	panel:AddControl( "Label", { Text = "Time until props are put up for grabs after player leaves:" } )
	panel:AddControl( "Slider",  {
			Label	= "Set to -1 to disable",
			Type	= "Integer",
			Min		= -1,
			Max		= 1200,
			Command = "ups_cl_cleartime",
		} )

	panel:AddControl( "Label", { Text = "" } ) -- Spacing

	panel:AddControl( "Label", { Text = "Time until deletion after player leaves:" } )
	panel:AddControl( "Slider",  {
			Label	= "Set to -1 to disable",
			Type	= "Integer",
			Min		= -1,
			Max		= 1200,
			Command = "ups_cl_deletetime",
		} )
	panel:AddControl( "Checkbox", { Label = "Delete admin props on leave", Command = "ups_cl_deleteadmin" } )
	panel:AddControl( "Checkbox", { Label = "Admins affected by restrictions", Command = "ups_cl_affectadmins" } )
	panel:AddControl( "Checkbox", { Label = "Enable world protection", Command = "ups_cl_worldprotection" } )

	panel:AddControl( "Label", { Text = "" } ) -- Spacing

	panel:AddControl( "Label", { Text = "Delete all of a player's props:" } )
	for uid, nick in pairs( playerTable ) do
		panel:AddControl( "Button", { Text = nick, Command = "ups_remove " .. uid } )
	end
end
UPS.addToMenu( UPS.ID_MADMIN, buildMenu )
