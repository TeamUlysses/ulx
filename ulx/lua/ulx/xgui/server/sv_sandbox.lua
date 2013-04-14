--sv_sandbox -- by Stickly Man!
--Server-side code related to the sandbox menu.

local function init()
	if ULib.isSandbox() then --Only execute the following code if it's a sandbox gamemode
		xgui.addDataType( "sboxlimits", function() return xgui.sboxLimits end, "xgui_gmsettings", 0, -20 )

		ULib.replicatedWritableCvar( "physgun_limited", "rep_physgun_limited", GetConVarNumber( "physgun_limited" ), false, false, "xgui_gmsettings" )
		ULib.replicatedWritableCvar( "sbox_noclip", "rep_sbox_noclip", GetConVarNumber( "sbox_noclip" ), false, false, "xgui_gmsettings" )
		ULib.replicatedWritableCvar( "sbox_godmode", "rep_sbox_godmode", GetConVarNumber( "sbox_godmode" ), false, false, "xgui_gmsettings" )
		ULib.replicatedWritableCvar( "sbox_plpldamage", "rep_sbox_plpldamage", GetConVarNumber( "sbox_plpldamage" ), false, false, "xgui_gmsettings" )
		ULib.replicatedWritableCvar( "sbox_weapons", "rep_sbox_weapons", GetConVarNumber( "sbox_weapons" ), false, false, "xgui_gmsettings" )

		--Process the list of known Sandbox Cvar Limits and check if they exist
		xgui.sboxLimits = {}
		if ULib.isSandbox() then
			local curgroup
			local f = ULib.fileRead( "data/ulx/sbox_limits.txt", "GAME" )
			if f == nil then Msg( "XGUI ERROR: Sandbox Cvar limits file was needed but could not be found!\n" ) return end
			local lines = string.Explode( "\n", f )
			for i,v in ipairs( lines ) do
				if v:sub( 1,1 ) ~= ";" then
					if v:sub( 1,1 ) == "|" then
						curgroup = table.insert( xgui.sboxLimits, {} )
						xgui.sboxLimits[curgroup].title = v:sub( 2 )
					else
						local data = string.Explode( " ", v ) --Split Convar name from max limit
						if ConVarExists( data[1] ) then
							--We need to create a replicated cvar so the clients can manipulate/view them:
							ULib.replicatedWritableCvar( data[1], "rep_" .. data[1], GetConVarNumber( data[1] ), false, false, "xgui_gmsettings" )
							--Add to the list of cvars to send to the client
							table.insert( xgui.sboxLimits[curgroup], v )
						end
					end
				end
			end
		end
	end
end
xgui.addSVModule( "sandbox", init )
