--Groups/Players module V2 for ULX GUI -- by Stickly Man!
--Manages groups and players within groups, teams, and permissions/restrictions

xgui.prepareDataType( "groups" )
xgui.prepareDataType( "users" )
xgui.prepareDataType( "teams" )
xgui.prepareDataType( "accesses" )
xgui.prepareDataType( "playermodels" )

local groups = xlib.makepanel{ parent=xgui.null }
groups.list = xlib.makecombobox{ x=5, y=5, w=175, parent=groups }
function groups.list:populate()
	local prev_sel = self:GetValue()
	if prev_sel == "" then prev_sel = "Select a group..." end
	self:Clear()
	for _, v in ipairs( xgui.data.groups ) do
		self:AddChoice( v )
	end
	self:AddChoice( "--*" )
	self:AddChoice( "Manage Groups..." )
	self:SetText( groups.lastOpenGroup or prev_sel )
	if groups.lastOpenGroup then
		if not ULib.ucl.groups[groups.lastOpenGroup] then --Group no longer exists
			groups.pnlG1:Close()
			xlib.animQueue_start()
			self.openFlag = nil
			groups.lastOpenGroup = nil
			self:SetText( "Select a group..." )
		end
	end
end
groups.list.OnSelect = function( self, index, value, data )
	if value ~= "Manage Groups..." then
		if value ~= groups.lastOpenGroup then
			groups.lastOpenGroup = value
			groups.pnlG1:Open( value )
			xlib.animQueue_start()
		end
	else
		groups.lastOpenGroup = nil
		groups.pnlG2:Open()
		xlib.animQueue_start()
	end
end
groups.lastOpenGroup = nil

groups.clippanela = xlib.makepanel{ x=5, y=30, w=580, h=335, parent=groups }
groups.clippanela.Paint = function( self, w, h ) end
groups.clippanelb = xlib.makepanel{ x=175, y=30, w=410, h=335, visible=false, parent=groups }
groups.clippanelb.Paint = function( self, w, h ) end
groups.clippanelc = xlib.makepanel{ x=380, y=30, w=210, h=335, visible=false, parent=groups }
groups.clippanelc.Paint = function( self, w, h ) end

-----------------------------------
------Groups Panel 1 (Users, Teams)
-----------------------------------
groups.pnlG1 = xlib.makepanel{ w=170, h=335, parent=groups.clippanela }
groups.pnlG1:SetVisible( false )
function groups.pnlG1:Open( group )
	if self:IsVisible() then --Is open, lets close it first.
		self:Close()
	elseif groups.pnlG2:IsVisible() then
		groups.pnlG2:Close()
	end
	self:openAnim( group )
	if self.openFlag then
		self.openFlag:Open()
		self.openFlag = nil
	end
end
function groups.pnlG1:Close()
	if groups.pnlG3:IsVisible() then
		groups.pnlG3:Close()
		self.openFlag = groups.pnlG3
	end
	if groups.pnlG4:IsVisible() then
		groups.pnlG4:Close()
		self.openFlag = groups.pnlG4
	end
	self:closeAnim()
end
xlib.makelabel{ x=5, y=5, label="Users in group:", parent=groups.pnlG1 }
groups.players = xlib.makelistview{ x=5, y=20, w=160, h=190, parent=groups.pnlG1 }
groups.players:AddColumn( "Name" )
groups.players.OnRowSelected = function( self, LineID, Line )
	groups.cplayer:SetDisabled( false )
end
groups.aplayer = xlib.makebutton{ x=5, y=210, w=80, label="Add...", parent=groups.pnlG1 }
groups.aplayer.DoClick = function()
	local menu = DermaMenu()
	menu:SetSkin(xgui.settings.skin)
	for k, v in ipairs( player.GetAll() ) do
		if v:GetUserGroup() ~= groups.list:GetValue() then
			menu:AddOption( v:Nick() .. "  |  " .. v:GetUserGroup(), function() groups.changeUserGroup( v:SteamID(), groups.list:GetValue() ) end )
		end
	end
	menu:AddSpacer()
	for ID, v in pairs( xgui.data.users ) do
		if v.group ~= groups.list:GetValue() and not groups.isOnline( ID ) then
			menu:AddOption( ( v.name or ID ) .. "  |  " .. ( v.group or "<none?>" ), function() groups.changeUserGroup( ID, groups.list:GetValue() ) end )
		end
	end
	menu:AddSpacer()
	menu:AddOption( "Add by SteamID...", function() groups.addBySteamID( groups.list:GetValue() ) end )
	menu:Open()
end
groups.cplayer = xlib.makebutton{ x=85, y=210, w=80, label="Change...", disabled=true, parent=groups.pnlG1 }
groups.cplayer.DoClick = function()
	if groups.players:GetSelectedLine() then
		local ID = groups.players:GetSelected()[1]:GetColumnText(2)
		local menu = DermaMenu()
		menu:SetSkin(xgui.settings.skin)
		for _, v in pairs( xgui.data.groups ) do
			if v ~= "user" and v ~= groups.list:GetValue() then
				menu:AddOption( v, function() groups.changeUserGroup( ID, v ) end )
			end
		end
		menu:AddSpacer()
		menu:AddOption( "Remove User", function() groups.changeUserGroup( ID, "user" ) end )
		menu:Open()
	end
end
xlib.makelabel{ x=5, y=240, label="Team:", parent=groups.pnlG1}
groups.teams = xlib.makecombobox{ x=5, y=255, w=160, disabled=not ulx.uteamEnabled(), parent=groups.pnlG1 }
groups.teams.OnSelect = function( self, index, value, data )
	if value == "<None>" then value = "" end
	RunConsoleCommand( "xgui", "changeGroupTeam", groups.list:GetValue(), value )
end
groups.teambutton = xlib.makebutton{ x=5, y=275, w=160, label="Manage Teams >>", disabled=not ulx.uteamEnabled(), parent=groups.pnlG1 }
groups.teambutton.DoClick = function( self )
	if not groups.pnlG3:IsVisible() then
		self:SetText( "Manage Teams <<" )
		groups.pnlG3:Open()
	else
		self:SetText( "Manage Teams >>" )
		groups.pnlG3:Close()
	end
	xlib.animQueue_start()
end
groups.accessbutton = xlib.makebutton{ x=5, y=305, w=160, label="Manage Permissions >>", parent=groups.pnlG1 }
groups.accessbutton.DoClick = function( self )
	if not groups.pnlG4:IsVisible() then
		self:SetText( "Manage Permissions <<" )
		groups.pnlG4:Open()
	else
		self:SetText( "Manage Permissions >>" )
		groups.pnlG4:Close()
	end
	xlib.animQueue_start()
end

function groups.addBySteamID( group )
	local frame = xlib.makeframe{ label="Add ID to group " .. group, w=190, h=60, skin=xgui.settings.skin }
	xlib.maketextbox{ x=5, y=30, w=180, parent=frame, selectall=true, text="Enter STEAMID..." }.OnEnter = function( self )
		if ULib.isValidSteamID( self:GetValue() ) then
			RunConsoleCommand( "ulx", "adduserid", self:GetValue(), group )
			frame:Remove()
		else
			Derma_Message( "Invalid SteamID!", "XGUI NOTICE" )
		end
	end
end

function groups.changeUserGroup( ID, group )
	if ID == "NULL" then
		-- Is bot, most likely.
		ID = "BOT"
	end

	if group == "user" then
		RunConsoleCommand( "ulx", "removeuserid", ID )
	else
		RunConsoleCommand( "ulx", "adduserid", ID, group )
	end
end

function groups.isOnline( steamID )
	for _, v in ipairs( player.GetAll() ) do
		if v:SteamID() == steamID then
			return true
		end
	end
	return false
end

---------------------------------------
------Groups Panel 2 (Group Management)
---------------------------------------
groups.pnlG2 = xlib.makepanel{ w=350, h=200, parent=groups.clippanela }
groups.pnlG2:SetVisible( false )
function groups.pnlG2:Open()
	if not self:IsVisible() then
		if groups.pnlG1:IsVisible() then
			groups.pnlG1:Close()
		end
		self:openAnim()
	end
end
function groups.pnlG2:Close()
	self:closeAnim()
end
groups.glist = xlib.makelistview{ x=5, y=5, h=170, w=130, headerheight=0, parent=groups.pnlG2 }
groups.glist:AddColumn( "Groups" )
groups.glist.populate = function( self )
	local previous_group = nil
	local prev_inherit = groups.ginherit:GetValue()
	if groups.glist:GetSelectedLine() then previous_group = groups.glist:GetSelected()[1]:GetColumnText(1) end
	self:Clear()
	groups.ginherit:Clear()
	groups.ginherit:SetText( prev_inherit )
	for _, v in ipairs( xgui.data.groups ) do
		local l = self:AddLine( v )
		groups.ginherit:AddChoice( v )
		if v == previous_group then
			previous_group = true
			self:SelectItem( l )
		end
	end
	if previous_group and previous_group ~= true then --Old group not found, reset the values
		groups.gname:SetText( "new_group" )
		groups.ginherit:SetText( "user" )
		groups.gcantarget:SetText( "" )
		groups.glist:ClearSelection()
		groups.gdelete:SetDisabled( true )
		groups.gupdate:SetDisabled( true )
		groups.newgroup:SetDisabled( false )
		groups.gname:SetDisabled( false )
		groups.ginherit:SetDisabled( false )
	end
end
groups.glist.OnRowSelected = function( self, LineID, Line )
	local group = Line:GetColumnText(1)
	groups.gname:SetText( group )
	groups.ginherit:SetText( ULib.ucl.groups[group].inherit_from or "user" )
	groups.gcantarget:SetText( ULib.ucl.groups[group].can_target or "*" )
	groups.gupdate:SetDisabled( false )

	local isGroupUser = ( group == "user" )
	groups.gdelete:SetDisabled( isGroupUser )
	groups.ginherit:SetDisabled( isGroupUser )
	groups.newgroup:SetDisabled( isGroupUser )
	groups.gname:SetDisabled( isGroupUser )
end
groups.newgroup = xlib.makebutton{ x=245, y=175, w=100, label="Create New...", parent=groups.pnlG2 }
groups.newgroup.DoClick = function()
	if not ULib.ucl.groups[groups.gname:GetValue()] then
		RunConsoleCommand( "ulx", "addgroup", groups.gname:GetValue(), groups.ginherit:GetValue() )
		if groups.gcantarget:GetValue() ~= "" and groups.gcantarget:GetValue() ~= "*" then
			ULib.queueFunctionCall( RunConsoleCommand, "ulx", "setgroupcantarget", groups.gname:GetValue(), groups.gcantarget:GetValue() )
		end
	else
		Derma_Message( "A group with that name already exists!", "XGUI NOTICE" );
	end
end
xlib.makelabel{ x=145, y=8, label="Name:", parent=groups.pnlG2 }
xlib.makelabel{ x=145, y=33, label="Inherits from:", parent=groups.pnlG2 }
xlib.makelabel{ x=145, y=58, label="Can Target:", parent=groups.pnlG2 }
groups.gname = xlib.maketextbox{ x=180, y=5, w=165, text="new_group", selectall=true, parent=groups.pnlG2 }
groups.ginherit = xlib.makecombobox{ x=215, y=30, w=130, text="user", parent=groups.pnlG2 }
groups.gcantarget = xlib.maketextbox{ x=205, y=55, w=140, text="", selectall=true, parent=groups.pnlG2 }
groups.gupdate = xlib.makebutton{ x=140, y=175, w=100, disabled=true, label="Update", parent=groups.pnlG2 }
groups.gupdate.DoClick = function( self )
	local groupname = groups.glist:GetSelected()[1]:GetColumnText(1)
	local oldinheritance = ULib.ucl.groups[groupname].inherit_from
	local newinheritance = groups.ginherit:GetValue()
	local cantarget = ULib.ucl.groups[groupname].can_target

	if newinheritance == "user" then newinheritance = nil end
	if not cantarget then cantarget = "*" end

	if groups.gname:GetValue() ~= groupname then
		if groupname == "superadmin" or groupname == "admin" then
			Derma_Query( "Renaming the " .. groupname .. " group is generally a bad idea, and it could break some plugins. Are you sure?", "XGUI WARNING",
				"Rename to " .. groups.gname:GetValue(), function()
					RunConsoleCommand( "ulx", "renamegroup", groupname, groups.gname:GetValue() )
					groupname = groups.gname:GetValue() end,
				"Cancel", function() end )
		else
			if not ULib.ucl.groups[groups.gname:GetValue()] then
				RunConsoleCommand( "ulx", "renamegroup", groupname, groups.gname:GetValue() )
				groupname = groups.gname:GetValue()
			else
				Derma_Message( "A group with that name already exists!", "XGUI NOTICE" );
			end
		end
	end

	if newinheritance ~= oldinheritance then
		ULib.queueFunctionCall( RunConsoleCommand, "xgui", "setinheritance", groupname, newinheritance or ULib.ACCESS_ALL )
	end

	if cantarget ~= groups.gcantarget:GetValue() then
		ULib.queueFunctionCall( RunConsoleCommand, "ulx", "setgroupcantarget", groupname, groups.gcantarget:GetValue() )
	end
end
groups.gdelete = xlib.makebutton{ x=5, y=175, w=130, label="Delete", disabled=true, parent=groups.pnlG2 }
groups.gdelete.DoClick = function()
	local group = groups.gname:GetValue()
	if group == "superadmin" or group == "admin" then
		Derma_Query( "Removing the " .. group .. " group is generally a bad idea, and it could break some plugins. Are you sure?", "XGUI WARNING",
			"Remove", function()
				RunConsoleCommand( "ulx", "removegroup", group ) end,
			"Cancel", function() end )
	else
		Derma_Query( "Are you sure you would like to remove the \"" .. group .. "\" group?", "XGUI WARNING",
			"Remove", function()
				RunConsoleCommand( "ulx", "removegroup", group ) end,
			"Cancel", function() end )
	end
end

---------------------------------------
------Groups Panel 3 (Teams Management)
---------------------------------------
groups.pnlG3 = xlib.makepanel{ y=130, w=405, h=205, parent=groups.clippanelb }
groups.pnlG3:SetVisible( false )
function groups.pnlG3:Open()
	if groups.pnlG4:IsVisible() then
		groups.accessbutton:SetText( "Manage Permissions >>" )
		groups.pnlG4:Close()
	end
	self:openAnim()
end
function groups.pnlG3:Close()
	self:closeAnim()
end
groups.teamlist = xlib.makelistview{ x=5, y=5, w=100, h=155, headerheight=0, parent=groups.pnlG3 }
groups.teamlist:AddColumn( "Teams" )
groups.teamlist.OnRowSelected = function( self, LineID, Line )
	local team = Line:GetColumnText(1)
	groups.teamdelete:SetDisabled( false )
	groups.upbtn:SetDisabled( LineID == 1 )
	groups.downbtn:SetDisabled( LineID == #self.Lines )
	groups.teammodadd:SetDisabled( false )

	local lastmod = groups.teammodifiers:GetSelectedLine() and groups.teammodifiers:GetSelected()[1]:GetColumnText(1)
	groups.teammodifiers:Clear()
	for _, chteam in pairs( xgui.data.teams ) do
		if chteam.name == team then
			for k, v in pairs( chteam ) do
				if k ~= "index" and k ~= "order" and k ~= "groups" then
					local value = v
					if k == "color" then
						value = v.r .. " " .. v.g .. " " .. v.b
					end
					local l = groups.teammodifiers:AddLine( k, value, type( value ) )
					if k == lastmod then
						groups.teammodifiers:SelectItem( l )
						lastmod = true
					end
				end
			end
			break
		end
	end
	groups.teammodifiers:SortByColumn( 1, false )
	if not groups.teammodifiers:GetSelectedLine() then
		groups.teammodspace:Clear()
	end
end

local function checkNewTeamExists( name, number )
	for _, v in ipairs( xgui.data.teams ) do
		if v.name == name .. number then
			name, number = checkNewTeamExists( name, number == "" and 1 or number+1 )
			break
		end
	end
	return name, number
end

xlib.makebutton{ x=5, y=160, w=80, label="Create New", parent=groups.pnlG3 }.DoClick = function()
	local teamname, number = checkNewTeamExists( "New_Team", "" )
	RunConsoleCommand( "xgui", "createTeam", teamname..number, 255, 255, 255 )
end
groups.teamdelete = xlib.makebutton{ x=5, y=180, w=80, label="Delete", disabled=true, parent=groups.pnlG3 }
groups.teamdelete.DoClick = function()
	local team = groups.teamlist:GetSelected()[1]:GetColumnText(1)
	Derma_Query( "Are you sure you would like to remove the \"" .. team .. "\" team?", "XGUI WARNING",
		"Remove", function() RunConsoleCommand( "xgui", "removeTeam", team ) end,
		"Cancel", function() end )
end
groups.upbtn = xlib.makebutton{ x=85, y=160, w=20, icon="icon16/bullet_arrow_up.png", centericon=true, disabled=true, parent=groups.pnlG3 }
groups.upbtn.DoClick = function( self )
	self:SetDisabled( true )
	local lineID = groups.teamlist:GetSelectedLine()
	RunConsoleCommand( "xgui", "updateTeamValue",  groups.teamlist.Lines[lineID]:GetColumnText(1), "order", lineID-1 )
	RunConsoleCommand( "xgui", "updateTeamValue",  groups.teamlist.Lines[lineID-1]:GetColumnText(1), "order", lineID, "true" )
end
groups.downbtn = xlib.makebutton{ x=85, y=180, w=20, icon="icon16/bullet_arrow_down.png", centericon=true, disabled=true, parent=groups.pnlG3 }
groups.downbtn.DoClick = function( self )
	self:SetDisabled( true )
	local lineID = groups.teamlist:GetSelectedLine()
	RunConsoleCommand( "xgui", "updateTeamValue",  groups.teamlist.Lines[lineID]:GetColumnText(1), "order", lineID+1 )
	RunConsoleCommand( "xgui", "updateTeamValue",  groups.teamlist.Lines[lineID+1]:GetColumnText(1), "order", lineID, "true" )
end
groups.teammodifiers = xlib.makelistview{ x=110, y=5, h=175, w=150, parent=groups.pnlG3 }
groups.teammodifiers:AddColumn( "Modifiers" ).DoClick = function() end
groups.teammodifiers:AddColumn( "Value" ).DoClick = function() end
groups.teammodifiers.OnRowSelected = function( self, LineID, Line )
	groups.teammodremove:SetDisabled( Line:GetColumnText(1) == "name" or Line:GetColumnText(1) == "color" )
	groups.teammodspace:Clear()
	local applybtn = xlib.makebutton{ label="Apply", parent=groups.teammodspace }
	if Line:GetColumnText(3) ~= "number" then
		if Line:GetColumnText(1) == "name" then
			groups.teamctrl = xlib.maketextbox{ selectall=true, text=Line:GetColumnText(2), parent=groups.teammodspace }
			groups.teamctrl.OnEnter = function()
				applybtn.DoClick()
			end
			groups.teammodspace:Add( groups.teamctrl )
		elseif Line:GetColumnText(1) == "color" then
			groups.teamctrl = xlib.makecolorpicker{ parent=groups.teammodspace }
			local tempcolor = string.Explode( " ", Line:GetColumnText(2) )
			groups.teamctrl:SetColor( Color( tempcolor[1], tempcolor[2], tempcolor[3] ) )
			groups.teammodspace:Add( groups.teamctrl )
		elseif Line:GetColumnText(1) == "model" then
			groups.teamctrl = xlib.maketextbox{ selectall=true, text=Line:GetColumnText(2), parent=groups.teammodspace }
			groups.teamctrl.OnEnter = function( self )
				applybtn.DoClick()
				for _, item in ipairs( groups.modelList.Items ) do
					if item.ConVars == self:GetValue() or item.Model == self:GetValue() then
						groups.modelList:SelectPanel( item )
						break
					end
				end
			end
			groups.teammodspace:Add( groups.teamctrl )
			groups.modelList = vgui.Create( "DModelSelect" )
			groups.updateModelPanel()
			for _, item in ipairs( groups.modelList.Items ) do
				if item.ConVars == Line:GetColumnText(2) or item.Model == Line:GetColumnText(2) then
					groups.modelList:SelectPanel( item )
					break
				end
			end
			function groups.modelList:OnActivePanelChanged( pnlOld, pnlNew )
				groups.teamctrl:SetText( pnlNew.ConVars or pnlNew.Model )
				applybtn.DoClick()
			end
			groups.teammodspace:Add( groups.modelList )
		end
	else
		local defvalues = xgui.allowedTeamModifiers[Line:GetColumnText(1)]
		if type( defvalues ) ~= "table" then defvalues = { defvalues } end
		groups.teamctrl = xlib.makeslider{ min=defvalues[2] or 0, max=defvalues[3] or 2000, decimal=defvalues[4], value=tonumber( Line:GetColumnText(2) ), label=Line:GetColumnText(1), parent=groups.teammodspace }
		groups.teamctrl.OnEnter = function( self )
			applybtn.DoClick()
		end
		groups.teammodspace:Add( groups.teamctrl )
	end
	applybtn.DoClick = function()
		if Line:GetColumnText(1) == "color" then
			local col = groups.teamctrl:GetColor()
			RunConsoleCommand( "xgui", "updateTeamValue", groups.teamlist:GetSelected()[1]:GetColumnText(1), Line:GetColumnText(1), col.r, col.g, col.b )
		else
			if Line:GetColumnText(1) == "name" then --Check if a team by this name already exists!
				for _, v in ipairs( xgui.data.teams ) do
					if v.name == groups.teamctrl:GetValue() then return end
				end
			end
			RunConsoleCommand( "xgui", "updateTeamValue", groups.teamlist:GetSelected()[1]:GetColumnText(1), Line:GetColumnText(1), groups.teamctrl:GetValue() )
		end
	end
	if Line:GetColumnText(1) ~= "model" then
		groups.teammodspace:Add( applybtn )
	else
		applybtn:SetSize(0,0)
		groups.teammodspace:Add( applybtn )
	end
end

--Default, Min, Max, Decimals
xgui.allowedTeamModifiers = {
	armor = { 0, 0, 255 },
	--crouchedWalkSpeed = 0.6, --Pointless setting?
	deaths = { 0, -2048, 2047 },
	duckSpeed = { 0.3, 0, 10, 2 },
	frags = { 0, -2048, 2047 },
	gravity = { 1, -10, 10, 2 },
	health = { 100, 1, 2000 },
	jumpPower = 200,
	maxHealth = 100,
	--maxSpeed = 250, --Pointless setting?
	model = "scientist",
	runSpeed = { 500, 1, nil },
	stepSize = { 18, 0, 512, 2 },
	unDuckSpeed = { 0.2, 0, 10, 2 },
	walkSpeed = { 250, 1, nil } }

groups.teammodadd = xlib.makebutton{ x=110, y=180, w=75, label="Add..", disabled=true, parent=groups.pnlG3 }
groups.teammodadd.DoClick = function()
	local selectedItem = groups.teamlist:GetSelected()[1]
	if selectedItem == nil then
		return
	end
	local team = selectedItem:GetColumnText(1)
	local teamdata
	for i, v in pairs( xgui.data.teams ) do
		if v.name == team then teamdata = v end
	end

	local allowedSorted = {}
	for k,_ in pairs(xgui.allowedTeamModifiers) do table.insert(allowedSorted, k) end
	table.sort( allowedSorted, function( a,b ) return string.lower( a ) < string.lower( b ) end )

	local menu = DermaMenu()
	menu:SetSkin(xgui.settings.skin)
	for _, allowedname in pairs( allowedSorted ) do
		local add = true
		for name, data in pairs( teamdata ) do
			if name == allowedname then
				add = false
				break
			end
		end
		if add then
			local def = xgui.allowedTeamModifiers[allowedname]
			if type( def ) == "table" then def = def[1] end
			menu:AddOption( allowedname, function() RunConsoleCommand( "xgui", "updateTeamValue", team, allowedname, def ) end )
		end
	end
	menu:Open()
end
groups.teammodremove = xlib.makebutton{ x=185, y=180, w=75, label="Remove", disabled=true, parent=groups.pnlG3 }
groups.teammodremove.DoClick = function()
	local selectedItem = groups.teamlist:GetSelected()[1]
	if selectedItem == nil then
		return
	end
	local team = selectedItem:GetColumnText(1)
	local modifier = groups.teammodifiers:GetSelected()[1]:GetColumnText(1)
	RunConsoleCommand( "xgui", "updateTeamValue", team, modifier, "" )
end
groups.teammodspace = xlib.makelistlayout{ x=265, y=5, w=135, h=195, padding=1, parent=groups.pnlG3 }

----------------------------------------
------Groups Panel 4 (Access Management)
----------------------------------------
groups.pnlG4 = xlib.makepanel{ y=130, w=200, h=335, parent=groups.clippanelb }
groups.pnlG4:SetVisible( false )
function groups.pnlG4:Open()
	if groups.pnlG3:IsVisible() then
		groups.teambutton:SetText( "Manage Teams >>" )
		groups.pnlG3:Close()
	end
	self:openAnim()
	if groups.selcmd then
		if ULib.cmds.translatedCmds[groups.selcmd] and #ULib.cmds.translatedCmds[groups.selcmd].args > 1 then
			groups.pnlG5:Open( groups.selcmd )
		else
			groups.selcmd = nil
			groups.pnlG5:Close()
		end
	end
end
function groups.pnlG4:Close()
	if groups.pnlG5:IsVisible() then
		groups.pnlG5:Close()
	end
	self:closeAnim()
end
xlib.makelabel{ x=5, y=5, label="Has access to:", parent=groups.pnlG4 }
groups.accesses = xlib.makelistlayout{ x=5, y=20, w=190, h=310, padding=1, spacing=1, parent=groups.pnlG4 }

groups.access_cats = {}
groups.access_lines = {}
function groups.populateAccesses()
	if ULib.ucl.groups[groups.list:GetValue()] then
		local group = groups.list:GetValue()
		for access, line in pairs( groups.access_lines ) do
			--First, check through the group's allows and see if the access exists.
			local foundAccess, fromGroup, restrictionString = groups.groupHasAccess( group, access )
			--If found, then skip inheritance check and move along.
			if foundAccess then
				line.Columns[2]:SetDisabled( false )
			else --Access was not given to the group, check for inherited groups!
				foundAccess, fromGroup, restrictionString = groups.checkInheritedAccess( ULib.ucl.groups[group].inherit_from, access )
				line.Columns[2]:SetDisabled( foundAccess )
			end
			line.Columns[1]:SetColor((foundAccess and (restrictionString ~= "" and restrictionString ~= "*")) and SKIN.text_highlight or SKIN.text_dark )
			line.Columns[1]:SetAlpha( foundAccess and 255 or 128 )
			line.Columns[2]:SetValue( foundAccess )
			line:SetColumnText( 3, restrictionString )
			line:SetColumnText( 4, fromGroup )
			if groups.selcmd == line:GetColumnText(1) then
				if ( groups.access_lines[groups.selcmd].Columns[2].disabled or fromGroup ) or line:GetColumnText(3) ~= restrictionString then
					groups.populateRestrictionArgs( line:GetColumnText(1), restrictionString )
				end
			end
		end
	end
end

function groups.groupHasAccess( group, access )
	for k, v in pairs( ULib.ucl.groups[group].allow ) do
		if v == access then --This means there is no restriction tag
			return true, group, ""
		elseif k == access then
			return true, group, v
		end
	end
	return false, ""
end

function groups.checkInheritedAccess( group, access )
	if ULib.ucl.groups[group] then
		local foundAccess, fromGroup, restrictionString = groups.groupHasAccess( group, access )
		if foundAccess then
			return foundAccess, group, restrictionString
		else
			return groups.checkInheritedAccess( ULib.ucl.groups[group].inherit_from, access )
		end
	else
		return false, "", ""
	end
end

---------------------------------------------
------Groups Panel 5 (Restriction Management)
---------------------------------------------
groups.pnlG5 = xlib.makepanel{ y=130, w=200, h=335, parent=groups.clippanelc }
groups.pnlG5:SetVisible( false )
function groups.pnlG5:Open( cmd, accessStr )
	xlib.addToAnimQueue( groups.populateRestrictionArgs, cmd, accessStr )
	self:openAnim()
end
function groups.pnlG5:Close()
	if self:IsVisible() then
		self:closeAnim()
	end
end
groups.rArgList = xlib.makelistlayout{ x=5, y=20, w=190, h=308, parent=groups.pnlG5 }
xlib.makelabel{ x=5, y=5, label="Restrict command arguments:", parent=groups.pnlG5 }

function groups.populateRestrictionArgs( cmd, accessStr )
	if not accessStr then accessStr = groups.access_lines[cmd]:GetColumnText(3) end

	groups.rArgList:Clear()

	local restrictions = ULib.splitArgs( accessStr, "<", ">" )
	if restrictions[1] == "" then restrictions[1] = nil end

	local argnum = 0
	for i, arg in ipairs( ULib.cmds.translatedCmds[cmd].args ) do
		if not arg.type.invisible then
			argnum = argnum + 1
			if not arg.invisible then
				local hasrestriction = ( restrictions[argnum] ~= nil and restrictions[argnum] ~= "*" )
				local outCat
				---Player(s) Argument---
				if arg.type == ULib.cmds.PlayerArg or arg.type == ULib.cmds.PlayersArg then
					local ignoreCanTarget = ( restrictions[argnum] and string.sub( restrictions[argnum], 1, 1 ) == "$" )
					local outPanel = xlib.makepanel{ h=50 }
					outPanel.type = "ply"
					outPanel.cantarget = xlib.makecheckbox{ x=5, y=5, label="Ignore can_target", value=ignoreCanTarget or 0, parent=outPanel }
					outPanel.txtfield = xlib.maketextbox{ x=5, y=25, w=170, text=ignoreCanTarget and string.sub( restrictions[argnum], 2 ) or restrictions[argnum] or "*", parent=outPanel }
					--Handle change in width due to scrollbar
					local tempfunc = outPanel.PerformLayout
					outPanel.PerformLayout = function( self )
						tempfunc( self )
						outPanel.txtfield:SetWide( self:GetWide()-10 )
					end
					outCat = xlib.makecat{ label="Restrict " .. (arg.hint or "player(s)"), w=180, checkbox=true, expanded=hasrestriction, contents=outPanel, parent=xgui.null }
				---Number Argument---
				elseif arg.type == ULib.cmds.NumArg then
					local outPanel = xlib.makepanel{ h=85 }
					local rmin, rmax
					if hasrestriction and hasrestriction ~= "*" then
						local temp = restrictions[argnum] and string.Split( restrictions[argnum], ":" ) or ""
						rmin = string.sub( temp[1], 1, 1 ) ~= ":" and temp[1]
						rmax = temp[2]
						if rmax == nil then rmax = rmin end
					end
					outPanel.hasmin = xlib.makecheckbox{ x=5, y=8, value=( rmin~=nil ), parent=outPanel }
					outPanel.hasmax = xlib.makecheckbox{ x=5, y=48, value=( rmax~=nil ), parent=outPanel }
					if table.HasValue( arg, ULib.cmds.allowTimeString ) then
						outPanel.type = "time"

						local irmin, vrmin = ULib.cmds.NumArg.getTime( rmin )
						local iargmin, vargmin = ULib.cmds.NumArg.getTime( arg.min )
						local irmax, vrmax = ULib.cmds.NumArg.getTime( rmax )
						local iargmax, vargmax = ULib.cmds.NumArg.getTime( arg.max )

						local curinterval = ( irmin or iargmin or "Permanent" )
						local curval = vrmin or vargmin or 0
						outPanel.min = xlib.makeslider{ x=25, y=25, w=150, label="<--->", min=( vargmin or 0 ), max=( vargmax or 100 ), value=curval, decimal=0, disabled=( curinterval=="Permanent" ), parent=outPanel }
						outPanel.min:SetValue( curval ) --Set the value of the textentry manually to show decimals even though decimal=0.
						outPanel.minterval = xlib.makecombobox{ x=105, y=5, w=50, text=curinterval, choices={ "Permanent", "Minutes", "Hours", "Days", "Weeks", "Years" }, disabled=( rmin==nil ), parent=outPanel }
						outPanel.minterval.OnSelect = function( self, index, value, data )
							outPanel.min:SetDisabled( value == "Permanent" )
						end
						outPanel.hasmin.OnChange = function( self, bVal )
							outPanel.min:SetDisabled( not bVal or outPanel.minterval:GetValue() == "Permanent" )
							outPanel.minterval:SetDisabled( not bVal )
						end

						local curinterval = ( irmax or iargmax or "Permanent" )
						local curval = vrmax or vargmax or 0
						outPanel.max = xlib.makeslider{ x=25, y=65, w=150, label="<--->", min=( vargmin or 0 ), max=( vargmax or 100 ), value=curval, decimal=0, disabled=( curinterval=="Permanent" ), parent=outPanel }
						outPanel.max:SetValue( curval )
						outPanel.maxterval = xlib.makecombobox{ x=105, y=45, w=50, text=curinterval, choices={ "Permanent", "Minutes", "Hours", "Days", "Weeks", "Years" }, disabled=( rmax==nil ), parent=outPanel }
						outPanel.maxterval.OnSelect = function( self, index, value, data )
							outPanel.max:SetDisabled( value == "Permanent" )
						end
						outPanel.hasmax.OnChange = function( self, bVal )
							outPanel.max:SetDisabled( not bVal or outPanel.maxterval:GetValue() == "Permanent" )
							outPanel.maxterval:SetDisabled( not bVal )
						end

						xlib.makelabel{ x=25, y=8, label="Limit Minimum", parent=outPanel }
						xlib.makelabel{ x=25, y=48, label="Limit Maximum", parent=outPanel }

						--Handle change in width due to scrollbar
						local tempfunc = outPanel.PerformLayout
						outPanel.PerformLayout = function( self )
							tempfunc( self )
							local w = self:GetWide() - 10
							outPanel.min:SetWide( w-15 )
							outPanel.max:SetWide( w-15 )
							outPanel.minterval:SetWide( w-95 )
							outPanel.maxterval:SetWide( w-95 )
						end
					else
						outPanel.type = "num"
						outPanel.min = xlib.makeslider{ x=25, y=5, w=150, value=( rmin or arg.min or 0 ), min=( arg.min or 0 ), max=( arg.max or 100 ), label="Min", disabled=( rmin==nil ), parent=outPanel }
						outPanel.max = xlib.makeslider{ x=25, y=30, w=150, value=( rmax or arg.max or 100 ), min=( arg.min or 0 ), max=( arg.max or 100 ), label="Max", disabled=( rmax==nil ), parent=outPanel }
						outPanel.hasmax:SetPos( 5,33 )
						outPanel:SetHeight( 55 )
						outPanel.hasmin.OnChange = function( self, bVal )
							outPanel.min:SetDisabled( not bVal )
						end
						outPanel.hasmax.OnChange = function( self, bVal )
							outPanel.max:SetDisabled( not bVal )
						end

						--Handle change in width due to scrollbar
						local tempfunc = outPanel.PerformLayout
						outPanel.PerformLayout = function( self )
							tempfunc( self )
							local w = self:GetWide() - 10
							outPanel.min:SetWide( w-20 )
							outPanel.max:SetWide( w-20 )
						end
					end

					outCat = xlib.makecat{ label="Restrict " .. ( arg.hint or "number value" ), w=180, checkbox=true, expanded=hasrestriction, contents=outPanel, parent=xgui.null }
				---Bool Argument---
				elseif arg.type == ULib.cmds.BoolArg then
					local outPanel = xlib.makepanel{ h=25 }
					outPanel.type = "bool"
					outPanel.checkbox = xlib.makecheckbox{ x=5, y=5, value=restrictions[argnum] or false, label="Must be: True (1), False (0)", parent=outPanel }
					outCat = xlib.makecat{ label="Restrict " .. ( arg.hint or "bool value" ), w=180, checkbox=true, expanded=hasrestriction, contents=outPanel, parent=xgui.null }
				---String Argument---
				elseif arg.type == ULib.cmds.StringArg then
					local outPanel = xlib.makepanel{ h=200 }
					outPanel.type = "str"
					outPanel.list = xlib.makelistview{ x=5, y=5, w=170, h=150, multiselect=false, parent=outPanel }
					outPanel.list:AddColumn( "Whitelist String Values" )
					outPanel.textbox = xlib.maketextbox{ x=5, y=155, w=170, parent=outPanel, selectall=true }

					local strings = {}
					if restrictions[argnum] then strings = string.Split( restrictions[argnum], "," ) end
					for _, v in ipairs( strings ) do
						outPanel.list:AddLine( v )
					end

					outPanel.textbox.OnEnter = function( self )
						if self:GetValue() ~= "" then
							if not( string.find( self:GetValue(), "<" ) or string.find( self:GetValue(), ">" ) or string.find( self:GetValue(), "," ) ) then
								local found = false
								for _, l in ipairs( outPanel.list.Lines ) do
									if l:GetColumnText(1) == self:GetValue() then
										found = true
									end
								end
								if not found then
									outPanel.list:AddLine( self:GetValue() )
									self:SetText( "" )
								else
									Derma_Message( "This item already exists in the list!", "XGUI NOTICE" )
								end
							else
								Derma_Message( "You cannot use a string that contains the following characters: < > ,", "XGUI NOTICE" )
							end
						end
					end
					outPanel.addButton = xlib.makebutton{ x=5, y=175, w=85, label="Add", parent=outPanel }
					outPanel.addButton.DoClick = function( self )
						outPanel.textbox:OnEnter()
					end
					outPanel.removeButton = xlib.makebutton{ x=90, y=175, w=85, label="Remove", disabled=true, parent=outPanel }
					outPanel.removeButton.DoClick = function( self )
						outPanel.list:RemoveLine( outPanel.list:GetSelectedLine() )
						self:SetDisabled( true )
					end
					outPanel.list.OnRowSelected = function( self, LineID, Line )
						outPanel.removeButton:SetDisabled( false )
					end
					--Handle change in width due to scrollbar
					local tempfunc = outPanel.PerformLayout
					outPanel.PerformLayout = function( self )
						tempfunc( self )
						local w = self:GetWide() - 10
						outPanel.addButton:SetWide( w/2 )
						outPanel.removeButton:SetWide( w/2 )
						outPanel.list:SetWide( w )
						outPanel.textbox:SetWide( w )
						outPanel.removeButton:SetPos( (w/2)+5, 175 )
					end
					outCat = xlib.makecat{ label="Restrict " .. ( arg.hint or "string value" ), w=180, padding=0, checkbox=true, expanded=hasrestriction, contents=outPanel, parent=xgui.null }
				end
				groups.rArgList:Add( outCat )
			end
		end
	end
	groups.applyButton = xlib.makebutton{ h=20, label="Apply restrictions", parent=groups.rArgList }
	groups.applyButton.DoClick = function( self )
		if ( groups.access_lines[cmd].Columns[2].disabled or groups.access_lines[cmd]:GetColumnText(4) == "" ) or outstr ~= accessStr then
			RunConsoleCommand( "ulx", "groupallow", groups.list:GetValue(), cmd, groups.generateAccessString() )
		end
	end
	groups.rArgList:Add( groups.applyButton )

	if not groups.access_lines[cmd].Columns[2]:GetChecked() then
		groups.applyButton:SetText( "Apply access + restrictions" )
	elseif groups.access_lines[cmd].Columns[2].disabled then
		groups.applyInheritedButton = xlib.makebutton{ h=20, parent=groups.rArgList }
		groups.applyInheritedButton.DoClick = function( self )
			RunConsoleCommand( "ulx", "groupallow", groups.access_lines[cmd]:GetColumnText(4), cmd, groups.generateAccessString() )
		end
		groups.applyButton:SetText( "Apply access + restrictions" )
		groups.applyInheritedButton:SetText( "Apply restrictions at \"" .. groups.access_lines[cmd]:GetColumnText(4) .. "\" level" )
		groups.rArgList:Add( groups.applyInheritedButton )
	end
	groups.rArgList:SetSkin( xgui.settings.skin )  -- For some reason, skin doesn't update properly when this panel is recreated
	groups.rArgList:SetSkin( "" )                  -- Set the skin back to "" so that future skin changes in client settings will apply
end

function groups.generateAccessString()
	local outstr = ""
	local outtmp = ""
	for _, panel in ipairs( groups.rArgList:GetChildren() ) do
		local pnl = panel.Contents

		if panel.GetExpanded then --Weed out panels that we're not interested in
			if panel:GetExpanded() then
				if pnl.type == "ply" then
					outstr = outstr .. outtmp .. " " .. ( pnl.cantarget:GetChecked() and "$" or "" ) .. ( pnl.txtfield:GetValue() ~= "" and pnl.txtfield:GetValue() or "*" )
					outtmp = ""
				elseif pnl.type == "num" then
					if pnl.hasmin:GetChecked() or pnl.hasmax:GetChecked() then
						outstr = outstr .. outtmp .. " " .. ( pnl.hasmin:GetChecked() and pnl.min:GetValue() or "" ) .. ( pnl.hasmax:GetChecked() and ":" .. pnl.max:GetValue() or "" )
						outtmp = ""
					else
						outtmp = outtmp .. " *"
					end
				elseif pnl.type == "time" then
					if pnl.hasmin:GetChecked() or pnl.hasmax:GetChecked() then
						if pnl.min:GetValue() == 0 then pnl.minterval:ChooseOptionID(1) end --Set to Permanent when 0 hours/mins/weeks/years is selected
						if pnl.max:GetValue() == 0 then pnl.maxterval:ChooseOptionID(1) end

						local minchr = string.lower( pnl.minterval:GetValue():sub(1,1) )
						if minchr == "m" or minchr == "p" then minchr = "" end

						local maxchr = string.lower( pnl.maxterval:GetValue():sub(1,1) )
						if maxchr == "m" or maxchr == "p" then maxchr = "" end

						outstr = outstr .. outtmp .. " "
						if pnl.hasmin:GetChecked() then
							outstr = outstr .. pnl.min:GetValue() .. minchr
						end
						if pnl.hasmax:GetChecked() and not ( maxchr == minchr and pnl.max:GetValue() == pnl.min:GetValue() ) then
							outstr = outstr .. ":" .. pnl.max:GetValue() .. maxchr
						end
						outtmp = ""
					else
						outtmp = outtmp .. " *"
					end

				elseif pnl.type == "bool" then
					outstr = outstr .. outtmp .. " " .. ( pnl.checkbox:GetChecked() and "1" or "0" )
					outtmp = ""
				elseif pnl.type == "str" then
					if #pnl.list.Lines > 0 then
						local strings = {}
						for _, v in pairs( pnl.list.Lines ) do
							table.insert( strings, v:GetColumnText(1) )
						end
						outstr = outstr .. outtmp .. " <" .. table.concat( strings, "," ) .. ">"
					else
						outtmp = outtmp .. " *"
					end
				end
			else
				outtmp = outtmp .. " *"
			end
		end
	end
	outstr = string.sub( outstr, 2 )
	if outstr == "*" then outstr = "" end
	return outstr
end


--------------------------------
------Data refresh/GUI functions
--------------------------------
function groups.getGroupData( group )
	groups.refreshPlayerList()
	groups.populateAccesses()
	groups.aplayer:SetDisabled( group == "user" )
	groups.teams:SetText( groups.getGroupsTeam( groups.list:GetValue() ) )
end

function groups.clearPlayerList()
	groups.players:Clear()
	xgui.flushQueue( "group_userlist" )
end

function groups.sortPlayerList()
	groups.players:SortByColumn( 1, false )
end

function groups.playerRemoved( IDs )
	for i, ID in ipairs( IDs ) do
		groups.removePlayerLine( ID )
	end
end

function groups.removePlayerLine( ID )
	for lID, line in ipairs( groups.players.Lines ) do
		if line:GetColumnText(2) == ID then
			groups.players:RemoveLine( lID )
			break
		end
	end
end

function groups.playerUpdate( data ) --Call when a user has been moved to a different group
	for ID, pdata in pairs ( data ) do
		groups.removePlayerLine( ID ) --Remove the line, if it exists
	end
	groups.playerListAddChunk( data )
	xgui.queueFunctionCall( groups.sortPlayerList, "group_userlist" )
end

--Process a chunk of users and add them to the player list.
function groups.playerListAddChunk( chunk )
	local group = groups.lastOpenGroup
	if not group then return end

	local lastsel
	if groups.players:GetSelectedLine() then lastsel = groups.players:GetSelected()[1]:GetColumnText(1) end

	local function processline( name, ID, lastsel )
		local l = groups.players:AddLine( name, ID )
		if lastsel and name == lastsel then groups.players:SelectItem( l ) end
	end

	if group ~= "user" then
		for ID, user in pairs( chunk ) do
			if user.group == group then
				if user.name == nil or user.name == "" then user.name = ID end
				xgui.queueFunctionCall( processline, "group_userlist", user.name, ID, lastsel )
			end
		end
	else
		for k, v in ipairs( player.GetAll() ) do
			if v:GetUserGroup() == "user" then
				xgui.queueFunctionCall( processline, "group_userlist", v:Nick(), v:SteamID(), lastsel )
			end
		end
	end
end

--Refresh the entire player list for a group
function groups.refreshPlayerList()

	groups.cplayer:SetDisabled( true )

	groups.clearPlayerList()
	groups.playerListAddChunk( xgui.data.users )
	xgui.queueFunctionCall( groups.sortPlayerList, "group_userlist" )
end

function groups.playerNameChanged( ply, old, new )
	if groups.lastOpenGroup then
		for i, line in ipairs( groups.players.Lines ) do
			if line:GetColumnText(1) == old then
				line:SetColumnText( 1, new )
			end
		end
	end
end

function groups.updateGroups()
	xgui.data.groups = {}
	groups.SortGroups( ULib.ucl.getInheritanceTree() )
	groups.list:populate()
	groups.glist:populate()
end

function groups.SortGroups( t )
	for k, v in pairs( t ) do
		groups.SortGroups( v )
		table.insert( xgui.data.groups, k )
	end
end
groups.updateGroups()

function groups.updateTeams()
	local last_selected = groups.teamlist:GetSelectedLine() and groups.teamlist:GetSelected()[1]:GetColumnText(1)
	groups.teams:Clear()
	groups.teams:AddChoice( "<None>" )
	groups.teams:AddChoice( "--*" )
	groups.teamlist:Clear()
	local updateLine = nil
	for k, v in pairs( xgui.data.teams ) do
		groups.teams:AddChoice( v.name )
		local l = groups.teamlist:AddLine( v.name )
		if v.name == last_selected then
			updateLine = l
		end
	end
	if updateLine then
		groups.teamlist:SelectItem( updateLine )
	else
		groups.teammodifiers:Clear()
		groups.teammodspace:Clear()
		groups.upbtn:SetDisabled( true )
		groups.downbtn:SetDisabled( true )
		groups.teamdelete:SetDisabled( true )
		groups.teammodadd:SetDisabled( true )
		groups.teammodremove:SetDisabled( true )
	end
	groups.teams:SetText( groups.getGroupsTeam( groups.list:GetValue() ) )
end

function groups.getGroupsTeam( check_group )
	--Since ULX doesn't refresh its groups data to clients when team stuff changes, we have to go the long way round to get the info.
	for _, team in ipairs( xgui.data.teams ) do
		for _, group in ipairs( team.groups ) do
			if group == check_group then
				return team.name
			end
		end
	end
	return "<None>"
end
groups.updateTeams()

function groups.updateAccessPanel()
	groups.accesses:Clear()
	groups.access_cats = {}
	groups.access_lines = {}
	groups.access_expandedcat = nil

	local newcategories = {}
	local sortcategories = {}
	local function processAccess( access, data )
		local catname = data.cat or "_Uncategorized"
		if catname == "Command" then
			if ULib.cmds.translatedCmds[access] and ULib.cmds.translatedCmds[access].category then
				catname = "Cmds - " .. ULib.cmds.translatedCmds[access].category
			else
				catname = "_Uncategorized Cmds"
			end
		end
		if not groups.access_cats[catname] then
			--Make a new category
			local list = xlib.makelistview{ headerheight=0, multiselect=false, h=136 }
			list:AddColumn( "Tag" )
			local col = list:AddColumn( "Checkbox" )
			col:SetMaxWidth( 15 )
			col:SetMinWidth( 15 )
			list.OnRowRightClick = function( self, LineID, line )
				groups.showAccessOptions( line )
			end
			list.OnRowSelected = function( self, LineID, Line )
				groups.accessSelected( self, LineID )
				local cmd = Line:GetColumnText(1)
				if ULib.cmds.translatedCmds[cmd] and #ULib.cmds.translatedCmds[cmd].args > 1 then
					if groups.selcmd == cmd then
						self:ClearSelection()
						groups.selcmd = nil
						groups.pnlG5:Close()
						xlib.animQueue_start()
						return
					end
					groups.selcmd = cmd
					if groups.pnlG5:IsVisible() then
						groups.pnlG5:Close()
					end
					groups.pnlG5:Open( cmd, Line:GetColumnText(3) )
					xlib.animQueue_start()
				else
					groups.selcmd = nil
					groups.pnlG5:Close()
					xlib.animQueue_start()
				end
			end
			--Hijack the DataLayout function to manually set the position of the checkboxes
			local tempfunc = list.DataLayout
			list.DataLayout = function( list )
				local rety = tempfunc( list )
				for _, Line in ipairs( list.Lines ) do
					local x,y = Line:GetColumnText(2):GetPos()
					Line.Columns[2]:SetPos( x-2, y+1 )
				end
				return rety
			end
			groups.access_cats[catname] = list
			local cat = xlib.makecat{ label=catname, contents=list, expanded=false, parent=xgui.null }
			newcategories[catname] = cat
			table.insert( sortcategories, catname )
			function cat.Header:OnMousePressed( mcode )
				if ( mcode == MOUSE_LEFT ) then
					self:GetParent():Toggle()
					--Use this to collapse the other categories.
					if groups.access_expandedcat then
						if groups.access_expandedcat ~= self:GetParent() then
							groups.access_expandedcat:Toggle()
						else
							groups.access_expandedcat = nil
							return
						end
					end
					groups.access_expandedcat = self:GetParent()
					return
				end
				return self:GetParent():OnMousePressed( mcode )
			end
		end
		local checkbox = xlib.makecheckbox{}
		checkbox.Button.DoClick = function( self )
			groups.accessChanged( access, not self:GetChecked() )
		end
		local line = groups.access_cats[catname]:AddLine( access, checkbox, "", "" )
		line:SetTooltip( data.hStr )
		groups.access_lines[access] = line
	end

	for access, data in pairs( xgui.data.accesses ) do
		xgui.queueFunctionCall( processAccess, "accesses", access, data )
	end
	--Why queueFunctionCall? Mainly to prevent large lags when performing a bunch of derma AddLine()s at once. queueFunctionCall will spread the load for each line, usually one per frame.
	--This results in the possibility of the end user seeing lines appearing as he's looking at the menus, but I believe that a few seconds of lines appearing is better than 150+ms of freeze time.

	local function finalSort()
		table.sort( sortcategories )
		for _, catname in ipairs( sortcategories ) do
			local cat = newcategories[catname]
			groups.accesses:Add( cat )
			cat.Contents:SortByColumn( 1 )
			cat.Contents:SetHeight( 17*#cat.Contents:GetLines() )
		end
		groups.accesses:InvalidateLayout()
		groups.populateAccesses()
	end
	xgui.queueFunctionCall( finalSort, "accesses" )
end
groups.updateAccessPanel()

function groups.accessChanged( access, newVal, group )
	if not group then group = groups.list:GetValue() end
	if newVal == true then
		RunConsoleCommand( "ulx", "groupallow", group, access )
	else
		--Check to see if they're attempting to remove one of these accesses from themselves:
		if access == "ulx groupallow" or access == "ulx groupdeny" or access == "ulx userallow" or access == "ulx userdeny" or access == "xgui_managegroups" then
			local foundAccess, fromGroup = groups.checkInheritedAccess( LocalPlayer():GetUserGroup(), access )
			if foundAccess and fromGroup == group then
				--Do a check for lower leves to determine whether or not they'll gain access from a lower inheritance level.
				if ULib.ucl.groups[group].inherit_from then
					local foundAccess, fromGroup = groups.checkInheritedAccess( ULib.ucl.groups[group].inherit_from, access )
					if foundAccess then
						RunConsoleCommand( "ulx", "groupdeny", group, access )
						return
					end
				end

				Derma_Query( "WARNING! Removing access to " .. access .. " will revoke YOUR access to features you're currently using.\nYou will most likely not be able to regain access without console intervention.\nAre you sure you wish to proceed?", "XGUI WARNING",
					"Revoke", function() RunConsoleCommand( "ulx", "groupdeny", group, access ) end,
					"Cancel", function() end )
				return
			end
		end
		RunConsoleCommand( "ulx", "groupdeny", group, access )
	end
end

function groups.accessSelected( catlist, LineID )
	for _, cat in pairs( groups.access_cats ) do
		if cat ~= catlist then
			cat:ClearSelection()
		end
	end
end

function groups.showAccessOptions( line )
	local access = line:GetColumnText(1)
	local menu = DermaMenu()
	menu:SetSkin(xgui.settings.skin)
	if line.Columns[2]:GetChecked() then
		if line.Columns[2].disabled then
			menu:AddOption( "Grant access at \"" .. groups.list:GetValue() .. "\" level", function() groups.accessChanged( access, true ) end )

			menu:AddOption( "Revoke access from \"" .. line:GetColumnText(4) .. "\"", function() groups.accessChanged( access, false, line:GetColumnText(4) ) end )
		else
			menu:AddOption( "Revoke access", function() groups.accessChanged( access, false ) end )
		end
	else
		menu:AddOption( "Grant access", function() groups.accessChanged( access, true ) end )
	end
	menu:Open()
end

function groups.updateModelPanel()
	if groups.modelList and groups.modelList:IsValid() then
		groups.modelList:Clear()
		local models = {}
		for k,v in pairs( xgui.data.playermodels ) do models[v] = k end
		groups.modelList:SetModelList( models, nil, false, true )
		groups.modelList:SetHeight( 2.63 )
	end
end

--------------
--ANIMATIONS--
--------------
groups.pnlG1.openAnim = function( self, group )
	xlib.addToAnimQueue( groups.getGroupData, group )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=0, starty=-335, endx=0, endy=0, setvisible=true } )
end
groups.pnlG1.closeAnim = function( self )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=0, starty=0, endx=0, endy=-335, setvisible=false } )
end

groups.pnlG2.openAnim = function( self )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=0, starty=-200, endx=0, endy=0, setvisible=true } )
end
groups.pnlG2.closeAnim = function( self )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=0, starty=0, endx=0, endy=-200, setvisible=false } )
end

groups.pnlG3.openAnim = function( self )
	xlib.addToAnimQueue( groups.clippanelb.SetVisible, groups.clippanelb, true )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=-410, starty=130, endx=5, endy=130, setvisible=true } )
end
groups.pnlG3.closeAnim = function( self )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=5, starty=130, endx=-410, endy=130, setvisible=false } )
	xlib.addToAnimQueue( groups.clippanelb.SetVisible, groups.clippanelb, false )
end

groups.pnlG4.openAnim = function( self )
	xlib.addToAnimQueue( groups.clippanelb.SetVisible, groups.clippanelb, true )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=-210, starty=0, endx=5, endy=0, setvisible=true } )
end
groups.pnlG4.closeAnim = function( self )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=5, starty=0, endx=-210, endy=0, setvisible=false } )
	xlib.addToAnimQueue( groups.clippanelb.SetVisible, groups.clippanelb, false )
end

groups.pnlG5.openAnim = function( self )
	xlib.addToAnimQueue( groups.clippanelc.SetVisible, groups.clippanelc, true )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=-210, starty=0, endx=5, endy=0, setvisible=true } )
end
groups.pnlG5.closeAnim = function( self )
	xlib.addToAnimQueue( "pnlSlide", { panel=self, startx=5, starty=0, endx=-210, endy=0, setvisible=false } )
	xlib.addToAnimQueue( groups.clippanelc.SetVisible, groups.clippanelc, false )
end
--------------

function groups.UCLChanged()
	groups.populateAccesses()
	groups.updateGroups()
end

hook.Add( "UCLChanged", "xgui_RefreshGroups", groups.UCLChanged )
hook.Add( "ULibPlayerNameChanged", "xgui_plyUpdateGroups", groups.playerNameChanged )
xgui.hookEvent( "users", "clear",  groups.clearPlayerList, "groupsPlayerClear" )
xgui.hookEvent( "users", "process", groups.playerListAddChunk, "groupsPlayerChunk" )
xgui.hookEvent( "users", "done", groups.sortPlayerList, "groupsPlayerSort" )
xgui.hookEvent( "users", "update", groups.playerUpdate, "groupsPlayerUpdate" )
xgui.hookEvent( "users", "remove", groups.playerRemoved, "groupsPlayerRemoved" )
xgui.hookEvent( "teams", "process", groups.updateTeams, "groupsUpdateTeams" )
xgui.hookEvent( "accesses", "process", groups.updateAccessPanel, "groupsUpdateAccesses" )
xgui.hookEvent( "playermodels", "process", groups.updateModelPanel, "groupsUpdateModels" )
xgui.addModule( "Groups", groups, "icon16/group_gear.png", "xgui_managegroups" )
