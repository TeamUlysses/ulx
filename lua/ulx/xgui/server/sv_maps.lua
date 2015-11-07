--sv_maps -- by Stickly Man!
--Server-side code related to the maps menu.

local function init()
	ULib.replicatedWritableCvar( "nextlevel", "rep_nextlevel", GetConVarString( "sbox_godmode" ), false, false, "ulx map" )

	local function getVetoState( ply, args )
		if ULib.ucl.query( ply, "ulx veto" ) then
			ULib.clientRPC( ply, "xgui.updateVetoButton", ulx.timedVeto )
		end
	end
	xgui.addCmd( "getVetoState", getVetoState )

	local function updateVetoState()
		for _, v in ipairs( player.GetAll() ) do
			getVetoState( v )
		end
	end
	hook.Add( "ULXVetoChanged", "XGUI_ServerCatchVeto", updateVetoState )
end
xgui.addSVModule( "maps", init )