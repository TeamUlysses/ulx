module( "UPS", package.seeall )
-- This holds all the "essential" or base client menu stuff.

local function buildMenu( panel )
	panel:AddControl( "Checkbox", { 
			Label = "Play sound on deny",
			Command = cPlayDenySound:GetName(),
		} )
	panel:AddControl( "TextBox", { 
			Label = "Sound to play on deny",
			Command = cDenySound:GetName(),
			WaitForEnter = "1",
		} )
	
	panel:AddControl( "Label", { Text = "" } ) -- Spacing
end
UPS.addToMenu( UPS.ID_MCLIENT, buildMenu ) 
