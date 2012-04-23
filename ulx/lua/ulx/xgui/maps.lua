--Maps module for ULX GUI -- by Stickly Man!
--Lists maps on server, allows for map voting, changing levels, etc. All players may access this menu.

ulx.votemaps = {}
xgui.prepareDataType( "votemaps", ulx.votemaps )
local maps = xlib.makepanel{ parent=xgui.null }

maps.maplabel = xlib.makelabel{ x=10, y=13, label="Server Votemaps: (Votemaps are highlighted)", parent=maps, textcolor=color_black }
xlib.makelabel{ x=10, y=348, label="Gamemode:", parent=maps, textcolor=color_black }
maps.curmap = xlib.makelabel{ x=187, y=223, w=192, label="No Map Selected", parent=maps, textcolor=color_black }

maps.list = xlib.makelistview{ x=5, y=30, w=175, h=315, multiselect=true, parent=maps, headerheight=0 } --Remember to enable/disable multiselect based on admin status?
maps.list:AddColumn( "Map Name" )
maps.list.OnRowSelected = function( self, LineID, Line )
	if ( file.Exists( "materials/maps/" .. maps.list:GetSelected()[1]:GetColumnText(1) .. ".vmt", true ) ) then 
		maps.disp:SetImage( "maps/" .. maps.list:GetSelected()[1]:GetColumnText(1) )
	else 
		maps.disp:SetImage( "maps/noicon.vmt" )
	end
	maps.curmap:SetText( Line:GetColumnText(1) )
	maps.updateButtonStates()
end
maps.list.Think = function()
	if maps.list.checkVotemaps then
		for _,line in ipairs( maps.list.Lines ) do
			if line.isNotVotemap then
				timer.Simple( 0.01, function() line.Columns[1]:SetTextColor( Color( 255,255,255,90 ) ) end ) --Srsly, wtf derma? This doesn't show properly unless it's called on a think AND delayed?
			end
		end
		maps.list.checkVotemaps = nil
	end
end

maps.disp = vgui.Create( "DImage", maps )
maps.disp:SetPos( 185, 30 )
maps.disp:SetImage( "maps/noicon.vmt" )
maps.disp:SetSize( 192, 192 )

maps.gamemode = xlib.makemultichoice{ x=70, y=345, w=110, h=20, text="<default>", parent=maps }

maps.vote = xlib.makebutton{ x=185, y=245, w=192, h=20, label="Vote to play this map!", parent=maps }
maps.vote.DoClick = function()
	if maps.curmap:GetValue() ~= "No Map Selected" then
		RunConsoleCommand( "ulx", "votemap", maps.curmap:GetValue() )
	end
end

maps.svote = xlib.makebutton{ x=185, y=270, w=192, h=20, label="Server-wide vote of selected map(s)", parent=maps }
maps.svote.DoClick = function()
	if maps.curmap:GetValue() ~= "No Map Selected" then
		local xgui_temp = {}
		for k, v in ipairs( maps.list:GetSelected() ) do
			table.insert( xgui_temp, maps.list:GetSelected()[k]:GetColumnText(1))
		end
		RunConsoleCommand( "ulx", "votemap2", unpack( xgui_temp ) )
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

function maps.addMaptoList( mapname, lastselected )
	local line = maps.list:AddLine( mapname )
	if table.HasValue( lastselected, mapname ) then
		maps.list:SelectItem( line )
	end
	line.isNotVotemap = nil
	if not table.HasValue( ulx.votemaps, mapname ) then
		line.isNotVotemap = true
	end
end

function maps.updateVoteMaps()
	local lastselected = {}
	for k, Line in pairs( maps.list.Lines ) do
		if ( Line:GetSelected() ) then table.insert( lastselected, Line:GetColumnText(1) ) end
	end
	
	maps.list:Clear()
	xgui.flushQueue( "votemaps" )
	
	if LocalPlayer():query( "ulx map" ) then --Show all maps for admins who have access to change the level
		maps.maplabel:SetText( "Server Maps (Votemaps are highlighted)" )
		for _,v in ipairs( ulx.maps ) do
			xgui.queueFunctionCall( maps.addMaptoList, "votemaps", v, lastselected )
		end
		xgui.queueFunctionCall( function() maps.list.checkVotemaps = true end, "votemaps" ) --This will grey out votemaps as soon as maps.list Think function is called.
	else
		maps.maplabel:SetText( "Server Votemaps" )
		for _,v in ipairs( ulx.votemaps ) do --Show the list of votemaps for users without access to "ulx map"
			xgui.queueFunctionCall( maps.addMaptoList, "votemaps", v, lastselected )
		end
	end
	if not maps.accessVotemap2 then  --Only select the first map if they don't have access to votemap2
		xgui.queueFunctionCall( function()  local l = maps.list:GetSelected()[1]
											maps.list:ClearSelection()
											maps.list:SelectItem( l ) end, "votemaps" )
	end
	maps.updateButtonStates()
end

function maps.updateGamemodes()
	local lastselected = maps.gamemode:GetValue()
	maps.gamemode:Clear()
	maps.gamemode:SetText( lastselected )
	maps.gamemode:AddChoice( "<default>" )
	for _, v in ipairs( ulx.gamemodes ) do
		maps.gamemode:AddChoice( v )
	end
end

function maps.updatePermissions()
	maps.vetomap:SetDisabled( true )
	RunConsoleCommand( "xgui", "getVetoState" ) --Get the proper enabled/disabled state of the veto button.
	maps.accessVotemap = ( GetConVarNumber( "ulx_votemapEnabled" ) == 1 ) and true or false
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
		maps.disp:SetImage( "maps/noicon.vmt" )
	end
end

--Enable/Disable the votemap button when ulx_votemapEnabled changes
function maps.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
	if cl_cvar == "ulx_cl_votemapenabled" then
		if tonumber( new_val ) == 1 then
			maps.accessVotemap = true
		else
			maps.accessVotemap = false
		end
		maps.updateButtonStates()
	end
end
hook.Add( "ULibReplicatedCvarChanged", "XGUI_mapsUpdateVotemapEnabled", maps.ConVarUpdated )

xgui.hookEvent( "onProcessModules", nil, maps.updatePermissions )
xgui.hookEvent( "votemaps", "process", maps.updateVoteMaps )
xgui.addModule( "Maps", maps, "gui/silkicons/world" )