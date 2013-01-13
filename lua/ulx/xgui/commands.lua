--Commands module (formerly players module) v2 for ULX GUI -- by Stickly Man!
--Handles all user-executable commands, such as kick, slay, ban, etc.

local cmds = xlib.makepanel{ parent=xgui.null }
cmds.selcmd = nil
cmds.mask = xlib.makepanel{ x=160, y=30, w=425, h=330, parent=cmds }
cmds.argslist = xlib.makelistlayout{ w=165, h=330, parent=cmds.mask }
cmds.argslist.secondaryPos = nil

function cmds.argslist.IsVisible( self )
	return self.scroll:IsVisible( self.scroll )
end
cmds.argslist.scroll:SetVisible( false )

function cmds.argslist:Open( cmd, secondary )
	if secondary then
		if cmds.plist:IsVisible() then
			cmds.plist:Close()
		elseif self:IsVisible() then
			self:Close()
		end
	end
	cmds.argslist:openAnim( cmd, secondary )
end
function cmds.argslist:Close()
	self:closeAnim( self.secondaryPos )
end
cmds.plist = xlib.makelistview{ w=250, h=330, multiselect=true, parent=cmds.mask }
function cmds.plist:Open( arg )
	if cmds.argslist.secondaryPos == true then cmds.argslist:Close()
	elseif self:IsVisible() then self:Close() end
	self:openAnim( arg )
	--Determine if the arguments should be visible after changing (If a valid player will be selected)
	local targets = cmds.calculateValidPlayers( arg )
	local playerWillBeSelected = false
	for _, line in ipairs( cmds.plist:GetSelected() ) do
		if table.HasValue( targets, line.ply ) then
			playerWillBeSelected = true
			break
		end
	end
	if playerWillBeSelected then
		cmds.argslist:Open( ULib.cmds.translatedCmds[arg.cmd], false )
	end
end
function cmds.plist:Close()
	if cmds.argslist:IsVisible() then cmds.argslist:Close() end
	self:closeAnim()
end
cmds.plist.DoDoubleClick = function()
	cmds.runCmd( cmds.selcmd )
end
cmds.plist:SetVisible( false )
cmds.plist:AddColumn( "Name" )
cmds.plist:AddColumn( "Group" )

cmds.cmds = xlib.makelistlayout{ x=5, y=30, w=150, h=330, parent=cmds, padding=1, spacing=1 }
cmds.setselected = function( selcat, LineID )
	if selcat.Lines[LineID]:GetColumnText(2) == cmds.selcmd then 
		selcat:ClearSelection()
		if cmds.plist:IsVisible() then cmds.plist:Close() else cmds.argslist:Close() end
		xlib.animQueue_start()
		cmds.selcmd = nil
		return 
	end
	
	for _, cat in pairs( cmds.cmd_contents ) do
		if cat ~= selcat then
			cat:ClearSelection()
		end
	end
	cmds.selcmd = selcat.Lines[LineID]:GetColumnText(2)
	
	if cmds.permissionChanged then cmds.refreshPlist() return end
	
	if xlib.animRunning then xlib.animQueue_forceStop() end
	
	local cmd = ULib.cmds.translatedCmds[cmds.selcmd]
	if cmd.args[2] and ( cmd.args[2].type == ULib.cmds.PlayersArg or cmd.args[2].type == ULib.cmds.PlayerArg ) then
		cmds.plist:Open( cmd.args[2] )
	else
		cmds.argslist:Open( cmd, true )
	end
	xlib.animQueue_start()
end

function cmds.refreshPlist( arg )
	if not arg then arg = ULib.cmds.translatedCmds[cmds.selcmd].args[2] end
	if not arg or ( arg.type ~= ULib.cmds.PlayersArg and arg.type ~= ULib.cmds.PlayerArg ) then return end
	
	local lastplys = {}
	for k, Line in pairs( cmds.plist.Lines ) do
		if ( Line:IsLineSelected() ) then table.insert( lastplys, Line:GetColumnText(1) ) end
	end
	
	local targets = cmds.calculateValidPlayers( arg )
	
	cmds.plist:Clear()
	cmds.plist:SetMultiSelect( arg.type == ULib.cmds.PlayersArg )
	for _, ply in ipairs( targets ) do
		local line = cmds.plist:AddLine( ply:Nick(), ply:GetUserGroup() )
		line.ply = ply
		line.OnSelect = function()
			if cmds.permissionChanged then return end
			
			if not xlib.animRunning and not cmds.argslist:IsVisible() then
				cmds.argslist:Open( ULib.cmds.translatedCmds[cmds.selcmd], false )
				xlib.animQueue_start( )
			else
				if not cmds.clickedFlag then --Prevent this from happening multiple times.
					cmds.clickedFlag = true
					xlib.addToAnimQueue( function() if not cmds.argslist:IsVisible() then
						cmds.argslist:Open( ULib.cmds.translatedCmds[cmds.selcmd], false ) end 
						cmds.clickedFlag = nil end )
				end
			end
		end
		
		--Select previously selected Lines
		if table.HasValue( lastplys, ply:Nick() ) then
			cmds.plist:SelectItem( line )
		end
	end
	--Select only the first item if multiselect is disabled.
	if not cmds.plist:GetMultiSelect() then
		local firstSelected = cmds.plist:GetSelected()[1]
		cmds.plist:ClearSelection()
		cmds.plist:SelectItem( firstSelected )
	end
	
	if not cmds.plist:GetSelectedLine() then
		if not xlib.animRunning then
			if cmds.argslist:IsVisible() then
				cmds.argslist:Close()
				xlib.animQueue_start()
			end
		else
			if cmds.permissionChanged then
				xlib.addToAnimQueue( function() if cmds.argslist:IsVisible() and cmds.plist:IsVisible() then cmds.argslist:Close() end end )
			end
		end
	end
end

function cmds.calculateValidPlayers( arg )
	if not arg then arg = ULib.cmds.translatedCmds[cmds.selcmd].args[2] end

	local access, tag = LocalPlayer():query( arg.cmd )
	local restrictions = {}
	ULib.cmds.PlayerArg.processRestrictions( restrictions, LocalPlayer(), arg, ulx.getTagArgNum( tag, 1 ) )

	local targets = restrictions.restrictedTargets
	if targets == false then -- No one allowed
		targets = {}
	elseif targets == nil then -- Everyone allowed
		targets = player.GetAll()
	end
	return targets
end

function cmds.buildArgsList( cmd )
	cmds.argslist:Clear()
	local argnum = 0
	local curitem
	if cmd.args[2] then
		expectingplayers = ( cmd.args[2].type == ULib.cmds.PlayersArg ) or ( cmd.args[2].type == ULib.cmds.PlayerArg )
	else
		expectingplayers = false
	end
	for _, arg in ipairs( cmd.args ) do
		if not arg.type.invisible then
			argnum = argnum + 1
			if not ( argnum == 1 and expectingplayers ) then
				if arg.invisible ~= true then
					curitem = arg
					cmds.argslist:Add( arg.type.x_getcontrol( arg, argnum ) )
				end
			end
		end
	end
	if curitem and curitem.repeat_min then --This command repeats!
		local panel = xlib.makepanel{ h=20 }
		panel.numItems = 0
		for i=2,curitem.repeat_min do --Start at 2 because the first one is already there
			cmds.argslist:Add( curitem.type.x_getcontrol( curitem, argnum ) )
			panel.numItems = panel.numItems + 1
		end
		panel.argnum = argnum
		panel.xguiIgnore = true
		panel.arg = curitem
		panel.insertPos = #cmds.argslist:GetChildren() + 1
		panel.button = xlib.makebutton{ label="Add", w=80, parent=panel }
		panel.button.DoClick = function( self )
			local parent = self:GetParent()
			--table.insert( cmds.argslist:GetChildren(), parent.insertPos, parent.arg.type.x_getcontrol( parent.arg, parent.argnum ) )
			--cmds.argslist:GetChildren()[parent.insertPos]:SetParent( cmds.argslist.pnlCanvas )  --TODO: Broken
			--cmds.argslist:GetChildren()[parent.insertPos]:SetParent( parent ) -- does this help?
			cmds.argslist:InvalidateLayout()
			panel.numItems = panel.numItems + 1
			parent.insertPos = parent.insertPos + 1
			if parent.arg.repeat_max and panel.numItems >= parent.arg.repeat_max - 1 then self:SetDisabled( true ) end
			if panel.button2:GetDisabled() then panel.button2:SetDisabled( false ) end
		end
		panel.button2 = xlib.makebutton{ label="Remove", x=80, w=80, disabled=true, parent=panel }
		panel.button2.DoClick = function( self )
			local parent = self:GetParent()
			--cmds.argslist:GetChildren()[parent.insertPos-1]:Remove()   --TODO: Broken
			--table.remove( cmds.argslist:GetChildren(), parent.insertPos - 1 )
			cmds.argslist:InvalidateLayout()
			panel.numItems = panel.numItems - 1
			parent.insertPos = parent.insertPos - 1
			if panel.numItems < parent.arg.repeat_min then self:SetDisabled( true ) end
			if panel.button:GetDisabled() then panel.button:SetDisabled( false ) end
		end
		--panel:SizeToChildren()
		cmds.argslist:Add( panel )
	elseif curitem and curitem.type == ULib.cmds.NumArg then
		cmds.argslist:GetChildren()[#cmds.argslist:GetChildren()].TextArea.OnEnter = function( self )
			cmds.runCmd( cmd.cmd )
		end
	elseif curitem and curitem.type == ULib.cmds.StringArg then
		cmds.argslist:GetChildren()[#cmds.argslist:GetChildren()].OnEnter = function( self )
			cmds.runCmd( cmd.cmd )
		end
	end
	if LocalPlayer():query( cmd.cmd ) then
		local xgui_temp = xlib.makebutton{ label=cmd.cmd }
		xgui_temp.xguiIgnore = true
		xgui_temp.DoClick = function()
			cmds.runCmd( cmd.cmd )
		end
		cmds.argslist:Add( xgui_temp )
	end
	if cmd.opposite and LocalPlayer():query( cmd.opposite ) then
		local xgui_temp = xlib.makebutton{ label=cmd.opposite }
		xgui_temp.DoClick = function()
			cmds.runCmd( cmd.opposite )
		end
		xgui_temp.xguiIgnore = true
		cmds.argslist:Add( xgui_temp )
	end
	if cmd.helpStr then --If the command has a string for help
		local xgui_temp = xlib.makelabel{ w=160, label=cmd.helpStr, wordwrap=true }
		xgui_temp.xguiIgnore = true
		cmds.argslist:Add( xgui_temp )
	end
end

function cmds.runCmd( cmd )
	local cmd = string.Explode( " ", cmd )
	if cmds.plist:IsVisible() then
		local plys = {}
		for _, arg in ipairs( cmds.plist:GetSelected() ) do
			table.insert( plys, arg:GetColumnText(1) )
			table.insert( plys, "," )
		end
		table.remove( plys ) --Removes the final comma
		table.insert( cmd, table.concat( plys ) )
	end
	
	for _, arg in ipairs( cmds.argslist:GetChildren() ) do
		if not arg.xguiIgnore then
			table.insert( cmd, arg:GetValue() )
		end
	end
	RunConsoleCommand( unpack( cmd ) )
end

function cmds.playerNameChanged( ply, old, new )
	for i, line in ipairs( cmds.plist.Lines ) do
		if line:GetColumnText(1) == old then
			line:SetColumnText( 1, new )
		end
	end
end

cmds.refresh = function( permissionChanged )
	local lastcmd = cmds.selcmd
	cmds.cmds:Clear()
	cmds.cmd_contents = {}
	cmds.expandedcat = nil
	cmds.selcmd = nil
	cmds.permissionChanged = true
	
	local newcategories = {}
	local sortcategories = {}
	local matchedCmdFound = false
	for cmd, data in pairs( ULib.cmds.translatedCmds ) do
		local opposite = data.opposite or ""
		if opposite ~= cmd and ( LocalPlayer():query( data.cmd ) or LocalPlayer():query( opposite ) ) then
			local catname = data.category
			if catname == nil or catname == "" then catname = "_Uncategorized" end
			if not cmds.cmd_contents[catname] then
				--Make a new category
				cmds.cmd_contents[catname] = xlib.makelistview{ headerheight=0, multiselect=false, h=136 }
				cmds.cmd_contents[catname].OnRowSelected = function( self, LineID ) cmds.setselected( self, LineID ) end
				cmds.cmd_contents[catname]:AddColumn( "" )
				local cat = xlib.makecat{ label=catname, contents=cmds.cmd_contents[catname], expanded=false, parent=xgui.null }
				function cat.Header:OnMousePressed( mcode )
					if ( mcode == MOUSE_LEFT ) then
						self:GetParent():Toggle()
						if cmds.expandedcat then
							if cmds.expandedcat ~= self:GetParent() then
								cmds.expandedcat:Toggle()
							else
								cmds.expandedcat = nil
								return
							end
						end
						cmds.expandedcat = self:GetParent()
						return 
					end
					return self:GetParent():OnMousePressed( mcode )
				end
				newcategories[catname] = cat
				table.insert( sortcategories, catname )
			end
			local line = cmds.cmd_contents[catname]:AddLine( string.gsub( data.cmd, "ulx ", "" ), data.cmd )
			if data.cmd == lastcmd then
				cmds.cmd_contents[catname]:SelectItem( line )
				cmds.expandedcat = cmds.cmd_contents[catname]:GetParent()
				cmds.expandedcat:SetExpanded( true )
				matchedCmdFound = true
			end
		end
	end
	if not matchedCmdFound then
		if cmds.plist:IsVisible() then
			cmds.plist:Close()
			xlib.animQueue_start()
		elseif cmds.argslist:IsVisible() then
			cmds.argslist:Close()
			xlib.animQueue_start()
		end
	end
	
	table.sort( sortcategories )
	for _, catname in ipairs( sortcategories ) do
		local cat = newcategories[catname]
		cmds.cmds:Add( cat )
		cat.Contents:SortByColumn( 1 )
		cat.Contents:SetHeight( 17*#cat.Contents:GetLines() )
	end
	cmds.permissionChanged = nil
end

--------------
--ANIMATIONS--
--------------
function cmds.plist:openAnim( arg )
	xlib.addToAnimQueue( cmds.refreshPlist, arg )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=-250, starty=0, endx=0, endy=0, setvisible=true } )
end

function cmds.plist:closeAnim()
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=0, starty=0, endx=-250, endy=0, setvisible=false } )
end

function cmds.argslist:openAnim( cmd, secondary )
	xlib.addToAnimQueue( function() cmds.argslist.secondaryPos = secondary end )
	xlib.addToAnimQueue( cmds.buildArgsList, cmd )
	if secondary then
		xlib.addToAnimQueue( "pnlSlide", { panel=self.scroll, startx=-170, starty=0, endx=0, endy=0, setvisible=true } )
	else
		xlib.addToAnimQueue( "pnlSlide", { panel=self.scroll, startx=80, starty=0, endx=255, endy=0, setvisible=true } )	
	end
end

function cmds.argslist:closeAnim( secondary )
	if secondary then
		xlib.addToAnimQueue( "pnlSlide", { panel=self.scroll, startx=0, starty=0, endx=-170, endy=0, setvisible=false } )
	else
		xlib.addToAnimQueue( "pnlSlide", { panel=self.scroll, startx=255, starty=0, endx=80, endy=0, setvisible=false } )
	end
	xlib.addToAnimQueue( function() cmds.argslist.secondaryPos = nil end )
end
--------------

cmds.refresh()
hook.Add( "UCLChanged", "xgui_RefreshPlayerCmds", cmds.refresh )
hook.Add( "ULibPlayerNameChanged", "xgui_plyUpdateCmds", cmds.playerNameChanged )
xgui.addModule( "Cmds", cmds, "icon16/user_gray.png" )