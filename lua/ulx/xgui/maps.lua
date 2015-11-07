--Maps module for ULX GUI -- by Stickly Man!
--Lists maps on server, allows for map voting, changing levels, etc. All players may access this menu.

ulx.votemaps = ulx.votemaps or {}
xgui.prepareDataType( "votemaps", ulx.votemaps )
local maps = xlib.makepanel{ parent=xgui.null }

maps.maplabel = xlib.makelabel{ x=10, y=13, label="Server Votemaps: (Votemaps are highlighted)", parent=maps }
xlib.makelabel{ x=10, y=343, label="Gamemode:", parent=maps }
maps.curmap = xlib.makelabel{ x=187, y=223, w=192, label="No Map Selected", parent=maps }

maps.list = xlib.makelistview{ x=5, y=30, w=175, h=310, multiselect=true, parent=maps, headerheight=0 } --Remember to enable/disable multiselect based on admin status?
maps.list:AddColumn( "Map Name" )
maps.list.OnRowSelected = function( self, LineID, Line )
	if ( ULib.fileExists( "maps/thumb/" .. maps.list:GetSelected()[1]:GetColumnText(1) .. ".png" ) ) then
		maps.disp:SetMaterial( Material( "maps/thumb/" .. maps.list:GetSelected()[1]:GetColumnText(1) .. ".png" ) )
	else
		maps.disp:SetMaterial( Material( "maps/thumb/noicon.png" ) )
	end
	maps.curmap:SetText( Line:GetColumnText(1) )
	maps.updateButtonStates()
end

maps.disp = vgui.Create( "DImage", maps )
maps.disp:SetPos( 185, 30 )
maps.disp:SetMaterial( Material( "maps/thumb/noicon.png" ) )
maps.disp:SetSize( 192, 192 )

maps.gamemode = xlib.makecombobox{ x=70, y=340, w=110, h=20, text="<default>", parent=maps }

maps.vote = xlib.makebutton{ x=185, y=245, w=192, h=20, label="Vote to play this map!", parent=maps }
maps.vote.DoClick = function()
	if maps.curmap:GetValue() ~= "No Map Selected" then
		RunConsoleCommand( "ulx", "votemap", maps.curmap:GetValue() )
	end
end

maps.svote = xlib.makebutton{ x=185, y=270, w=192, h=20, label="Server-wide vote of selected map(s)", parent=maps }
maps.svote.DoClick = function()
	if maps.curmap:GetValue() ~= "No Map Selected" then
		local votemaps = {}
		for k, v in ipairs( maps.list:GetSelected() ) do
			table.insert( votemaps, maps.list:GetSelected()[k]:GetColumnText(1))
		end
		RunConsoleCommand( "ulx", "votemap2", unpack( votemaps ) )
	end
end

maps.changemap = xlib.makebutton{ x=185, y=295, w=192, h=20, disabled=true, label="Force changelevel to this map", parent=maps }
maps.changemap.DoClick = function()
	if maps.curmap:GetValue() ~= "No Map Selected" then
		Derma_Query( "Are you sure you would like to change the level to \"" .. maps.curmap:GetValue() .. "\"?", "XGUI WARNING",
		"Change Level", function()
			RunConsoleCommand( "ulx", "map", maps.curmap:GetValue(), ( maps.gamemode:GetValue() ~= "<default>" ) and maps.gamemode:GetValue() or nil ) end,
		"Cancel", function() end )
	end
end

maps.vetomap = xlib.makebutton{ x=185, y=320, w=192, label="Veto a map vote", parent=maps }
maps.vetomap.DoClick = function()
	RunConsoleCommand( "ulx", "veto" )
end

maps.nextLevelLabel = xlib.makelabel{ x=382, y=13, label="Nextlevel (cvar)", parent=maps }
maps.nextlevel = xlib.makecombobox{ x=382, y=30, w=180, h=20, repconvar="rep_nextlevel", convarblanklabel="<not specified>", parent=maps }

function maps.addMaptoList( mapname, lastselected )
	local line = maps.list:AddLine( mapname )
	if table.HasValue( lastselected, mapname ) then
		maps.list:SelectItem( line )
	end
	line.isNotVotemap = nil
	if not table.HasValue( ulx.votemaps, mapname ) then
		line:SetAlpha( 128 )
		line.isNotVotemap = true
	end
end

function maps.updateVoteMaps()
	local lastselected = {}
	for k, Line in pairs( maps.list.Lines ) do
		if ( Line:IsLineSelected() ) then table.insert( lastselected, Line:GetColumnText(1) ) end
	end

	maps.list:Clear()
	maps.nextlevel:Clear()

	if LocalPlayer():query( "ulx map" ) then --Show all maps for admins who have access to change the level
		maps.maplabel:SetText( "Server Maps (Votemaps are highlighted)" )
		maps.nextlevel:AddChoice( "<not specified>" )
		maps.nextlevel.ConVarUpdated( "nextlevel", "rep_nextlevel", nil, nil, GetConVar( "rep_nextlevel" ):GetString() )
		maps.nextLevelLabel:SetAlpha(255);
		maps.nextlevel:SetDisabled( false )
		for _,v in ipairs( ulx.maps ) do
			maps.addMaptoList( v, lastselected )
			maps.nextlevel:AddChoice( v )
		end
	else
		maps.maplabel:SetText( "Server Votemaps" )
		maps.nextLevelLabel:SetAlpha(0);
		maps.nextlevel:SetDisabled( true )
		maps.nextlevel:SetAlpha(0);
		for _,v in ipairs( ulx.votemaps ) do --Show the list of votemaps for users without access to "ulx map"
			maps.addMaptoList( v, lastselected )
		end
	end
	if not maps.accessVotemap2 then  --Only select the first map if they don't have access to votemap2
		local l = maps.list:GetSelected()[1]
		maps.list:ClearSelection()
		maps.list:SelectItem( l )
	end
	maps.updateButtonStates()

	ULib.cmds.translatedCmds["ulx votemap"].args[2].completes = xgui.data.votemaps --Set concommand completes for the ulx votemap command. (Used by XGUI in the cmds tab)
end

function maps.updateGamemodes()
	local lastselected = maps.gamemode:GetValue()
	maps.gamemode:Clear()
	maps.gamemode:SetText( lastselected )
	maps.gamemode:AddChoice( "<default>" )

	-- Get allowed gamemodes
	local access, tag = LocalPlayer():query( "ulx map" )
	local restrictions = {}
	ULib.cmds.StringArg.processRestrictions( restrictions, ULib.cmds.translatedCmds['ulx map'].args[3], ulx.getTagArgNum( tag, 2 ) )

	for _, v in ipairs( restrictions.restrictedCompletes ) do
		maps.gamemode:AddChoice( v )
	end
end

function maps.updatePermissions()
	maps.vetomap:SetDisabled( true )
	RunConsoleCommand( "xgui", "getVetoState" ) --Get the proper enabled/disabled state of the veto button.
	maps.accessVotemap = ( GetConVarNumber( "ulx_votemapEnabled" ) == 1 )
	maps.accessVotemap2 = LocalPlayer():query( "ulx votemap2" )
	maps.accessMap = LocalPlayer():query( "ulx map" )
	maps.updateGamemodes()
	maps.updateVoteMaps()
	maps.updateButtonStates()
end

function xgui.updateVetoButton( value )
	maps.vetomap:SetDisabled( not value )
end

function maps.updateButtonStates()
	maps.gamemode:SetDisabled( not maps.accessMap )
	maps.list:SetMultiSelect( maps.accessVotemap2 )
	if maps.list:GetSelectedLine() then
		maps.vote:SetDisabled( maps.list:GetSelected()[1].isNotVotemap or not maps.accessVotemap )
		maps.svote:SetDisabled( not maps.accessVotemap2 )
		maps.changemap:SetDisabled( not maps.accessMap )
	else --No lines are selected
		maps.vote:SetDisabled( true )
		maps.svote:SetDisabled( true )
		maps.changemap:SetDisabled( true )
		maps.curmap:SetText( "No Map Selected" )
		maps.disp:SetMaterial( Material( "maps/thumb/noicon.png" ) )
	end
end
maps.updateVoteMaps() -- For autorefresh

--Enable/Disable the votemap button when ulx_votemapEnabled changes
function maps.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
	if cl_cvar == "ulx_votemapenabled" then
		maps.accessVotemap = ( tonumber( new_val ) == 1 )
		maps.updateButtonStates()
	end
end
hook.Add( "ULibReplicatedCvarChanged", "XGUI_mapsUpdateVotemapEnabled", maps.ConVarUpdated )

xgui.hookEvent( "onProcessModules", nil, maps.updatePermissions, "mapsUpdatePermissions" )
xgui.hookEvent( "votemaps", "process", maps.updateVoteMaps, "mapsUpdateVotemaps" )
xgui.addModule( "Maps", maps, "icon16/map.png" )
