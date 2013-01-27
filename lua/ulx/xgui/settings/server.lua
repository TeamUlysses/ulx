--Server settings module for ULX GUI -- by Stickly Man!
--A settings module for modifying server and ULX based settings. Also has the base code for loading the server settings modules.

local server = xlib.makepanel{ parent=xgui.null }

--------------------------GMOD Settings--------------------------
xlib.makecheckbox{ x=10, y=10, label="Enable Voice Chat", repconvar="rep_sv_voiceenable", parent=server }
xlib.makelabel{ x=10, y=33, label="Alltalk setting:", parent=server }
xlib.makecombobox{ x=10, y=50, w=120, repconvar="rep_sv_alltalk", isNumberConvar=true, choices={ "Team near you", "Team only", "Everyone near you", "Everyone" }, parent=server }
xlib.makecheckbox{ x=10, y=75, label="Disable AI", repconvar="rep_ai_disabled", parent=server }
xlib.makecheckbox{ x=10, y=95, label="AI Ignore Players", repconvar="rep_ai_ignoreplayers", parent=server }
local offset = 0
if game.SinglePlayer() then
	offset = 20
	xlib.makecheckbox{ x=10, y=115, label="Keep AI Ragdolls", repconvar="rep_ai_keepragdolls", parent=server }
end
xlib.makelabel{ x=10, y=120+offset, label="sv_gravity", parent=server }
xlib.makeslider{ x=10, y=135+offset, label="<--->", w=125, min=-1000, max=1000, repconvar="rep_sv_gravity", parent=server }
xlib.makelabel{ x=10, y=165+offset, label="phys_timescale", parent=server }
xlib.makeslider{ x=10, y=180+offset, label="<--->", w=125, min=0, max=4, decimal=2, repconvar="rep_phys_timescale", parent=server }

------------------------ULX Category Menu------------------------
server.mask = xlib.makepanel{ x=295, y=5, w=290, h=322, parent=server }
server.panel = xlib.makepanel{ x=5, w=285, h=322, parent=server.mask }

server.catList = xlib.makelistview{ x=145, y=5, w=150, h=322, parent=server }
server.catList:AddColumn( "Server Setting Modules" )
server.catList.Columns[1].DoClick = function() end
server.catList.OnRowSelected = function( self, LineID, Line )
	local nPanel = xgui.modules.submodule[Line:GetValue(2)].panel
	if nPanel ~= server.curPanel then
		if server.curPanel then
			local temppanel = server.curPanel
			--Close before opening new one
			xlib.addToAnimQueue( "pnlSlide", { panel=server.panel, startx=5, starty=0, endx=-285, endy=0, setvisible=false } )
			xlib.addToAnimQueue( function()	temppanel:SetVisible( false ) end )
		end
		--Open
		server.curPanel = nPanel
		xlib.addToAnimQueue( function() nPanel:SetVisible( true ) end )
		if nPanel.onOpen then xlib.addToAnimQueue( nPanel.onOpen ) end --If the panel has it, call a function when it's opened
		xlib.addToAnimQueue( "pnlSlide", { panel=server.panel, startx=-285, starty=0, endx=5, endy=0, setvisible=true } )
	else
		--Close
		server.curPanel = nil
		self:ClearSelection()
		xlib.addToAnimQueue( "pnlSlide", { panel=server.panel, startx=5, starty=0, endx=-285, endy=0, setvisible=false } )
		xlib.addToAnimQueue( function() nPanel:SetVisible( false ) end )
	end
	xlib.animQueue_start()
end

--Process modular settings
function server.processModules()
	server.catList:Clear()
	for i, module in ipairs( xgui.modules.submodule ) do
		if module.mtype == "server" and ( not module.access or LocalPlayer():query( module.access ) ) then
			local w,h = module.panel:GetSize()
			if w == h and h == 0 then module.panel:SetSize( 275, 322 ) end
			
			if module.panel.scroll then --For DListLayouts
				module.panel.scroll.panel = module.panel
				module.panel = module.panel.scroll
			end
			module.panel:SetParent( server.panel )
			
			local line = server.catList:AddLine( module.name, i )
			if ( module.panel == server.curPanel ) then
				server.curPanel = nil
				server.catList:SelectItem( line )
			else
				module.panel:SetVisible( false )
			end
		end
	end
	server.catList:SortByColumn( 1, false )
end
server.processModules()

xgui.hookEvent( "onProcessModules", nil, server.processModules )
xgui.addSettingModule( "Server", server, "icon16/server.png", "xgui_svsettings" )


---------------------------
--Server Settings Modules--
---------------------------
--These are submodules that load into the server settings module above.

-------------------------Admin Votemaps--------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="Admin Votemap Settings" } )
plist:Add( xlib.makelabel{ label="Ratio of votes needed to accept a mapchange" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=1, decimal=2, repconvar="ulx_votemap2Successratio" } )
plist:Add( xlib.makelabel{ label="Ratio of votes needed to accept a mapchange" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=10, repconvar="ulx_votemap2Minvotes" } )
xgui.addSubModule( "ULX Admin Votemaps", plist, nil, "server" )

-----------------------------Adverts-----------------------------
xgui.prepareDataType( "adverts" )
local adverts = xlib.makepanel{ parent=xgui.null }
adverts.tree = xlib.maketree{ w=120, h=296, parent=adverts }
adverts.tree.DoClick = function( self, node )
	adverts.removebutton:SetDisabled( false )
	adverts.updatebutton:SetDisabled( not node.data )
	adverts.nodeup:SetDisabled( not node.data or type( node.group ) == "number" )
	adverts.nodedown:SetDisabled( not node.data or not type( node.group ) == "number" or adverts.isBottomNode( node ) )
	adverts.group:SetText( type(node.group) ~= "number" and node.group or "<No Group>" )
	if node.data then
		adverts.message:SetText( node.data.message )
		adverts.time:SetValue( node.data.rpt )
		adverts.color:SetColor( node.data.color )
		adverts.csay:SetOpen( node.data.len )
		adverts.csay:InvalidateLayout()
		adverts.display:SetValue( node.data.len or 10 )
	end
end
function adverts.isBottomNode( node )
	local parentnode = node:GetParentNode()
	local parentchildren = parentnode.ChildNodes:GetChildren()
	
	if parentnode:GetParentNode().ChildNodes then --Is node within a subgroup?
		local parentparentchildren = parentnode:GetParentNode().ChildNodes:GetChildren()
		return parentchildren[#parentchildren] == node and parentparentchildren[#parentparentchildren] == parentnode
	else
		return not adverts.hasGroups or parentchildren[#parentchildren] == node
	end
end
--0 middle, 1 bottom, 2 top, 3 top and bottom
function adverts.getNodePos( node )
	if type( node.group ) == "number" then return 1 end
	local parentchildren = node:GetParentNode().ChildNodes:GetChildren()
	local output = 0
	if parentchildren[#parentchildren] == node then output = 1 end
	if parentchildren[1] == node then output = output + 2 end
	return output
end
adverts.tree.DoRightClick = function( self, node )
	self:SetSelectedItem( node )
	local menu = DermaMenu()
	if not node.data then
		menu:AddOption( "Rename Group...", function() adverts.RenameAdvert( node:GetValue() ) end )
	end
	menu:AddOption( "Delete", function() adverts.removeAdvert( node ) end )
	menu:Open()
end
adverts.seloffset = 0
adverts.message = xlib.maketextbox{ x=125, w=150, h=20, text="Enter a message...", parent=adverts, selectall=true }
xlib.makelabel{ x=125, y=25, label="Time until advert repeats:", parent=adverts }
adverts.time = xlib.makeslider{ x=125, y=40, w=150, label="<--->", value=60, min=1, max=1000, tooltip="Time in seconds till the advert is shown/repeated.", parent=adverts }
adverts.group = xlib.makecombobox{ x=125, y=65, w=150, enableinput=true, parent=adverts, tooltip="Select or create a new advert group." }
adverts.color = xlib.makecolorpicker{ x=135, y=90, parent=adverts }
local panel = xlib.makelistlayout{ w=150, h=45, spacing=4, parent=xgui.null }
panel:Add( xlib.makelabel{ label="Display Time (seconds)" } )
adverts.display = xlib.makeslider{ label="<--->", min=1, max=60, value=10, tooltip="The time in seconds the CSay advert is displayed" }
panel:Add( adverts.display )
adverts.csay = xlib.makecat{ x=125, y=230, w=150, label="Display in center", checkbox=true, contents=panel, parent=adverts, expanded=false }
xlib.makebutton{ x=200, y=302, w=75, label="Create", parent=adverts }.DoClick = function()
	local col = adverts.color:GetColor()
	local rpt = tonumber( adverts.time:GetValue() )
	RunConsoleCommand( "xgui", "addAdvert", adverts.message:GetValue(), ( rpt < 0.1 ) and 0.1 or rpt, adverts.group:GetValue(), col.r, col.g, col.b, adverts.csay:GetExpanded() and adverts.display:GetValue() or nil)
end
adverts.removebutton = xlib.makebutton{ y=302, w=75, label="Remove", disabled=true, parent=adverts }
adverts.removebutton.DoClick = function( node )
	adverts.removeAdvert( adverts.tree:GetSelectedItem() )
end
adverts.updatebutton = xlib.makebutton{ x=125, y=302, w=75, label="Update", parent=adverts, disabled=true }
adverts.updatebutton.DoClick = function( node )
	local node = adverts.tree:GetSelectedItem()
	local col = adverts.color:GetColor()
	if ((( type( node.group ) == "number" ) and "<No Group>" or node.group ) == adverts.group:GetValue() ) then
		RunConsoleCommand( "xgui", "updateAdvert", type( node.group ), node.group, node.number, adverts.message:GetValue(), ( adverts.time:GetValue() < 0.1 ) and 0.1 or adverts.time:GetValue(), col.r, col.g, col.b, adverts.csay:GetExpanded() and adverts.display:GetValue() or nil )
	else
		RunConsoleCommand( "xgui", "removeAdvert", node.group, node.number, type( node.group ), "hold" )
		RunConsoleCommand( "xgui", "addAdvert", adverts.message:GetValue(), ( adverts.time:GetValue() < 0.1 ) and 0.1 or adverts.time:GetValue(), adverts.group:GetValue(), col.r, col.g, col.b, adverts.csay:GetExpanded() and adverts.display:GetValue() or nil)
		adverts.selnewgroup = adverts.group:GetValue()
		if xgui.data.adverts[adverts.group:GetValue()] then
			adverts.seloffset = #xgui.data.adverts[adverts.group:GetValue()]+1
		else
			adverts.seloffset = 1
		end
	end
end
adverts.nodeup = xlib.makebutton{ x=80, y=302, w=20, icon="icon16/bullet_arrow_up.png", centericon=true, parent=adverts, disabled=true }
adverts.nodeup.DoClick = function()
	adverts.nodedown:SetDisabled( true )
	adverts.nodeup:SetDisabled( true )
	local node = adverts.tree:GetSelectedItem()
	local state = adverts.getNodePos( node )
	if state <= 1 then
		RunConsoleCommand( "xgui", "moveAdvert", type( node.group ), node.group, node.number, node.number-1 )
		adverts.seloffset = adverts.seloffset - 1
	else
		local parentnode = node:GetParentNode()
		local parentparentchildren = parentnode:GetParentNode().ChildNodes:GetChildren()
		local newgroup = "<No Group>"
		for i,v in ipairs( parentparentchildren ) do
			if v == parentnode then 
				if parentparentchildren[i-1] and type( parentparentchildren[i-1].group ) ~= "number" then
					newgroup = parentparentchildren[i-1].group
					adverts.selnewgroup = newgroup
					adverts.seloffset = #xgui.data.adverts[newgroup]+1
				end
				break
			end
		end
		RunConsoleCommand( "xgui", "removeAdvert", node.group, node.number, type( node.group ), "hold" )
		RunConsoleCommand( "xgui", "addAdvert", node.data.message, node.data.rpt, newgroup, node.data.color.r, node.data.color.g, node.data.color.b, node.data.len)
		if newgroup == "<No Group>" then
			adverts.selnewgroup = #xgui.data.adverts+1
			adverts.seloffset = 1
		end
	end
end
adverts.nodedown = xlib.makebutton{ x=100, y=302, w=20, icon="icon16/bullet_arrow_down.png", centericon=true, parent=adverts, disabled=true }
adverts.nodedown.DoClick = function()
	adverts.nodedown:SetDisabled( true )
	adverts.nodeup:SetDisabled( true )
	local node = adverts.tree:GetSelectedItem()
	local state = adverts.getNodePos( node )
	if state == 1 or state == 3 then
		local parentnode = type( node.group ) == "string" and node:GetParentNode() or node
		local parentchildren = parentnode:GetParentNode().ChildNodes:GetChildren()
		local newgroup = "<No Group>"
		for index,v in ipairs( parentchildren ) do
			if v == parentnode then
				local temp = 1
				while( type( parentchildren[index+temp].group ) == "number" ) do
					temp = temp + 1
				end
				if type( parentchildren[index+temp].group ) ~= "number" then
					newgroup = parentchildren[index+temp].group
					adverts.selnewgroup = newgroup
					adverts.seloffset = 1
				end
				break
			end
		end
		RunConsoleCommand( "xgui", "removeAdvert", node.group, node.number, type( node.group ), "hold" )
		RunConsoleCommand( "xgui", "addAdvert", node.data.message, node.data.rpt, newgroup, node.data.color.r, node.data.color.g, node.data.color.b, node.data.len or "", "hold" )
		RunConsoleCommand( "xgui", "moveAdvert", type( newgroup ), newgroup, #xgui.data.adverts[newgroup]+1, 1 )
	else
		RunConsoleCommand( "xgui", "moveAdvert", type( node.group ), node.group, node.number, node.number+1 )
		adverts.seloffset = adverts.seloffset + 1
	end
end
function adverts.removeAdvert( node )
	if node then
		Derma_Query( "Are you sure you want to delete this " .. ( node.data and "advert?" or "advert group?" ), "XGUI WARNING", 
		"Delete", function() 
			if node.data then --Remove a single advert
				RunConsoleCommand( "xgui", "removeAdvert", node.group, node.number, type( node.group ) )
			else --Remove an advert group
				RunConsoleCommand( "xgui", "removeAdvertGroup", node.group, type( node.group ) )
			end
			adverts.tree:SetSelectedItem( nil )
		end, "Cancel", function() end )
	end
end
function adverts.RenameAdvert( old )
	advertRename = xlib.makeframe{ label="Set Name of Advert Group - " .. old, w=400, h=80, showclose=true, skin=xgui.settings.skin }
	advertRename.text = xlib.maketextbox{ x=10, y=30, w=380, h=20, text=old, parent=advertRename }
	advertRename.text.OnEnter = function( self )
		RunConsoleCommand( "xgui", "renameAdvertGroup", old, self:GetValue() )
		advertRename:Remove()
	end
	xlib.makebutton{ x=175, y=55, w=50, label="OK", parent=advertRename }.DoClick = function()
		advertRename.text:OnEnter()
	end
end
function adverts.updateAdverts()
	adverts.updatebutton:SetDisabled( true )
	adverts.nodeup:SetDisabled( true )
	adverts.nodedown:SetDisabled( true )
	adverts.removebutton:SetDisabled( true )
	--Store the currently selected node, if any
	local lastNode = adverts.tree:GetSelectedItem()
	if adverts.selnewgroup then 
		lastNode.group = adverts.selnewgroup
		lastNode.number = adverts.seloffset
		adverts.selnewgroup = nil
		adverts.seloffset = 0
	end
	--Check for any previously expanded group nodes
	local groupStates = {}
	if adverts.tree.RootNode.ChildNodes then
		for _, node in ipairs( adverts.tree.RootNode.ChildNodes:GetChildren() ) do
			if node.m_bExpanded then
				groupStates[node:GetText()] = true
			end
		end
	end
	adverts.hasGroups = false
	adverts.tree:Clear()
	adverts.group:Clear()
	adverts.group:AddChoice( "<No Group>" )
	adverts.group:ChooseOptionID( 1 )
	
	local sortGroups = {}
	local sortSingle = {}
	for group, advertgroup in pairs( xgui.data.adverts ) do
		if type( group ) == "string" then --Check if it's a group or a single advert
			table.insert( sortGroups, group )
		else
			table.insert( sortSingle, { group=group, message=advertgroup[1].message } )
		end
	end
	table.sort( sortSingle, function(a,b) return string.lower( a.message ) < string.lower( b.message ) end )
	table.sort( sortGroups, function(a,b) return string.lower( a ) < string.lower( b ) end )
	for _, advert in ipairs( sortSingle ) do
		adverts.createNode( adverts.tree, xgui.data.adverts[advert.group][1], advert.group, 1, xgui.data.adverts[advert.group][1].message, lastNode )
	end
	for _, group in ipairs( sortGroups ) do
		advertgroup = xgui.data.adverts[group]
		adverts.hasGroups = true
		local foldernode = adverts.tree:AddNode( group, "icon16/folder.png" )
		adverts.group:AddChoice( group )
		foldernode.group = group
		--Check if folder was previously selected
		if lastNode and not lastNode.data and lastNode:GetValue() == group then
			adverts.tree:SetSelectedItem( foldernode )
			adverts.removebutton:SetDisabled( false )
		end
		for advert, data in ipairs( advertgroup ) do
			adverts.createNode( foldernode, data, group, advert, data.message, lastNode )
		end
		--Expand folder if it was expanded previously
		if groupStates[group] then foldernode:SetExpanded( true, true ) end
	end
	
	adverts.tree:InvalidateLayout()
	local node = adverts.tree:GetSelectedItem()
	if node then
		if adverts.seloffset ~= 0 then
			for i,v in ipairs( node:GetParentNode().ChildNodes:GetChildren() ) do
				if v == node then
					node = node:GetParentNode().ChildNodes:GetChildren()[i+adverts.seloffset]
					adverts.tree:SetSelectedItem( node )
					break
				end
			end
			adverts.seloffset = 0
		end
		if adverts.isBottomNode( node ) then adverts.nodedown:SetDisabled( true ) end
		adverts.nodeup:SetDisabled( type( node.group ) == "number" )
	end
end
function adverts.createNode( parent, data, group, number, message, lastNode )
	local node = parent:AddNode( message, data.len and "icon16/style.png" or "icon16/text_smallcaps.png" )
	node.data = data
	node.group = group
	node.number = number
	node:SetTooltip( xlib.wordWrap( message, 250, "Default" ) )
	if lastNode and lastNode.data then
		--Check if node was previously selected
		if lastNode.group == group and lastNode.number == number then
			adverts.tree:SetSelectedItem( node )
			adverts.group:SetText( type(node.group) ~= "number" and node.group or "<No Group>" )
			adverts.updatebutton:SetDisabled( false )
			adverts.nodeup:SetDisabled( false )
			adverts.nodedown:SetDisabled( false )
			adverts.removebutton:SetDisabled( false )
		end
	end
end
function adverts.onOpen()
	ULib.queueFunctionCall( adverts.tree.InvalidateLayout, adverts.tree )
end
xgui.hookEvent( "adverts", "process", adverts.updateAdverts )
xgui.addSubModule( "ULX Adverts", adverts, nil, "server" )

------------------------------Echo-------------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="Command/Event echo settings" } )
plist:Add( xlib.makecheckbox{ label="Echo players vote choices", repconvar="ulx_voteEcho" } )
plist:Add( xlib.makecombobox{ repconvar="ulx_logEcho", isNumberConvar=true, choices={ "Do not echo admin commands", "Echo admin commands anonymously", "Echo commands and identify admin" } } )
plist:Add( xlib.makecombobox{ repconvar="ulx_logSpawnsEcho", isNumberConvar=true, choices={ "Do not echo spawns", "Echo spawns to admins only", "Echo spawns to everyone" } } )
plist:Add( xlib.makecheckbox{ label="Enable colored event echoes", repconvar="ulx_logEchoColors" } )

plist:Add( xlib.makelabel{ label="Default text color" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorDefault", noalphamodetwo=true } )
plist:Add( xlib.makelabel{ label="Color for console" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorConsole", noalphamodetwo=true } )
plist:Add( xlib.makelabel{ label="Color for self" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorSelf", noalphamodetwo=true } )
plist:Add( xlib.makelabel{ label="Color for everyone" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorEveryone", noalphamodetwo=true } )
plist:Add( xlib.makecheckbox{ label="Show team colors for players", repconvar="ulx_logEchoColorPlayerAsGroup" } )
plist:Add( xlib.makelabel{ label="Color for players (when above is disabled)" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorPlayer", noalphamodetwo=true } )
plist:Add( xlib.makelabel{ label="Color for everything else" } )
plist:Add( xlib.makecolorpicker{ repconvar="ulx_logEchoColorMisc", noalphamodetwo=true } )
xgui.addSubModule( "ULX Command/Event Echoes", plist, nil, "server" )

------------------------General Settings-------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="General ULX Settings" } )
plist:Add( xlib.makeslider{ label="Chat spam time", min=0, max=5, decimal=1, repconvar="ulx_chattime" } )
plist:Add( xlib.makelabel{ label="\nMOTD Settings" } )
--Very custom convar handling for ulx_showMotd
plist.motdEnabled = xlib.makecheckbox{ label="Show MOTD when players join" }
function plist.motdEnabled:Toggle() self.Button:DoClick() end
plist.motdEnabled.Button.DoClick = function( self )
	self:Toggle()
	local bVal = self:GetChecked()
	if bVal == true then
		if plist.motdURLEnabled:GetChecked() then
			RunConsoleCommand( "ulx_showMotd", plist.motdURLText:GetValue() )
		else
			RunConsoleCommand( "ulx_showMotd", "1" )
		end
	else
		RunConsoleCommand( "ulx_showMotd", "0" )
	end
end
plist.motdURLEnabled = xlib.makecheckbox{ label="Get MOTD from URL instead of motd.txt:" }

function plist.motdURLEnabled:Toggle() self.Button:DoClick() end
plist.motdURLEnabled.Button.DoClick = function( self )
	self:Toggle()
	local bVal = self:GetChecked()
	if bVal == true then
		if plist.motdURLText:GetValue() ~= "" then
			RunConsoleCommand( "ulx_showMotd", plist.motdURLText:GetValue() )
		end
		plist.motdURLText:SetDisabled( false )
	else
		RunConsoleCommand( "ulx_showMotd", "1" )
		plist.motdURLText:SetDisabled( true )
	end
end
plist.motdURLText = xlib.maketextbox{ selectall=true }
function plist.motdURLText:UpdateConvarValue()
	if plist.motdURLText:GetValue() ~= "" then
		RunConsoleCommand( "ulx_showMotd", self:GetValue() )
	end
end
function plist.motdURLText:OnEnter() self:UpdateConvarValue() end
function plist.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
	if cl_cvar == "ulx_showmotd" then
		if tonumber( new_val ) == nil then --MOTD is enabled and set to a URL 
			plist.motdEnabled:SetValue( 1 )
			plist.motdURLEnabled:SetValue( 1 )
			plist.motdURLEnabled:SetDisabled( false )
			plist.motdURLText:SetValue( new_val )
			plist.motdURLText:SetDisabled( false )
		else
			plist.motdEnabled:SetValue( new_val )
			if new_val == "1" then
				plist.motdURLEnabled:SetValue( 0 )
				plist.motdURLEnabled:SetDisabled( false )
				plist.motdURLText:SetDisabled( true )
			elseif new_val == "0" then
				plist.motdURLEnabled:SetDisabled( true )
				plist.motdURLText:SetDisabled( true )
			end
		end
	end
end
hook.Add( "ULibReplicatedCvarChanged", "XGUI_ulx_showMotd", plist.ConVarUpdated )

plist:Add( plist.motdEnabled )
plist:Add( plist.motdURLEnabled )
plist:Add( plist.motdURLText )
plist:Add( xlib.makelabel{ label="\nWelcome Message" } )
plist:Add( xlib.maketextbox{ repconvar="ulx_welcomemessage", selectall=true } )
plist:Add( xlib.makelabel{ label="Allowed variables: %curmap%, %host%" } )
plist:Add( xlib.makelabel{ label="\nAuto Name-Changing Kicker" } )
plist:Add( xlib.makelabel{ label="Number of name changes till kicked (0 disables)" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=10, decimal=0, repconvar="ulx_kickAfterNameChanges" } )
plist:Add( xlib.makeslider{ label="Cooldown time (seconds)", min=0, max=600, decimal=0, repconvar="ulx_kickAfterNameChangesCooldown" } )
plist:Add( xlib.makecheckbox{ label="Warn players how many name-changes remain", repconvar="ulx_kickAfterNameChangesWarning" } )

xlib.checkRepCvarCreated( "ulx_showMotd" )
plist.ConVarUpdated( nil, "ulx_showMotd", nil, nil, GetConVar( "ulx_showMotd" ):GetString() )

xgui.addSubModule( "ULX General Settings", plist, nil, "server" )

------------------------------Gimps------------------------------
xgui.prepareDataType( "gimps" )
local gimps = xlib.makepanel{ parent=xgui.null }
gimps.textbox = xlib.maketextbox{ w=225, h=20, parent=gimps, selectall=true }
gimps.textbox.OnEnter = function( self )
	if self:GetValue() then
		RunConsoleCommand( "xgui", "addGimp", self:GetValue() )
		self:SetText( "" )
	end
end
gimps.textbox.OnGetFocus = function( self )
	gimps.button:SetText( "Add" )
	self:SelectAllText()
	xgui.anchor:SetKeyboardInputEnabled( true )
end
gimps.button = xlib.makebutton{ x=225, w=50, label="Add", parent=gimps }
gimps.button.DoClick = function( self )
	if self:GetValue() == "Add" then
		gimps.textbox:OnEnter()
	elseif gimps.list:GetSelectedLine() then
		RunConsoleCommand( "xgui", "removeGimp", gimps.list:GetSelected()[1]:GetColumnText(1) )
	end
end
gimps.list = xlib.makelistview{ y=20, w=275, h=302, multiselect=false, headerheight=0, parent=gimps }
gimps.list:AddColumn( "Gimp Sayings" )
gimps.list.OnRowSelected = function( self, LineID, Line )
	gimps.button:SetText( "Remove" )
end
gimps.updateGimps = function()
	gimps.list:Clear()
	for k, v in pairs( xgui.data.gimps ) do
		gimps.list:AddLine( v )
	end
end
xgui.hookEvent( "gimps", "process", gimps.updateGimps )
xgui.addSubModule( "ULX Gimps", gimps, nil, "server" )

------------------------Kick/Ban Reasons-------------------------
xgui.prepareDataType( "banreasons", ulx.common_kick_reasons )
local panel = xlib.makepanel{ parent=xgui.null }
panel.textbox = xlib.maketextbox{ w=225, h=20, parent=panel, selectall=true }
panel.textbox.OnEnter = function( self )
	if self:GetValue() then
		RunConsoleCommand( "xgui", "addBanReason", self:GetValue() )
		self:SetText( "" )
	end
end
panel.textbox.OnGetFocus = function( self )
	panel.button:SetText( "Add" )
	self:SelectAllText()
	xgui.anchor:SetKeyboardInputEnabled( true )
end
panel.button = xlib.makebutton{ x=225, w=50, label="Add", parent=panel }
panel.button.DoClick = function( self )
	if self:GetValue() == "Add" then
		panel.textbox:OnEnter()
	elseif panel.list:GetSelectedLine() then
		RunConsoleCommand( "xgui", "removeBanReason", panel.list:GetSelected()[1]:GetColumnText(1) )
	end
end
panel.list = xlib.makelistview{ y=20, w=275, h=302, multiselect=false, headerheight=0, parent=panel }
panel.list:AddColumn( "Kick/Ban Reasons" )
panel.list.OnRowSelected = function()
	panel.button:SetText( "Remove" )
end
panel.updateBanReasons = function()
	panel.list:Clear()
	for k, v in pairs( ulx.common_kick_reasons ) do
		panel.list:AddLine( v )
	end
end
xgui.hookEvent( "banreasons", "process", panel.updateBanReasons )
xgui.addSubModule( "ULX Kick/Ban Reasons", panel, "xgui_managebans", "server" )

--------------------------Log Settings---------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="Logging Settings" } )
plist:Add( xlib.makecheckbox{ label="Enable Logging to Files", repconvar="ulx_logFile" } )
plist:Add( xlib.makecheckbox{ label="Log Chat", repconvar="ulx_logChat" } )
plist:Add( xlib.makecheckbox{ label="Log Player Events (Connects, Deaths, etc.)", repconvar="ulx_logEvents" } )
plist:Add( xlib.makecheckbox{ label="Log Spawns (Props, Effects, Ragdolls, etc.)", repconvar="ulx_logSpawns" } )
plist:Add( xlib.makelabel{ label="Save log files to this directory:" } )
local logdirbutton = xlib.makebutton{}
xlib.checkRepCvarCreated( "ulx_logdir" )
logdirbutton:SetText( "data/" .. GetConVar( "ulx_logDir" ):GetString() )

function logdirbutton.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
	if cl_cvar == "ulx_logdir" then
		logdirbutton:SetText( "data/" .. new_val )
	end
end
hook.Add( "ULibReplicatedCvarChanged", "XGUI_ulx_logDir", logdirbutton.ConVarUpdated )
plist:Add( logdirbutton )
xgui.addSubModule( "ULX Logs", plist, nil, "server" )

-----------------------Player Votemap List-----------------------
xgui.prepareDataType( "votemaps", ulx.votemaps )
local panel = xlib.makepanel{ w=285, h=322, parent=xgui.null }
xlib.makelabel{ label="Allowed Votemaps", x=5, y=3, parent=panel }
xlib.makelabel{ label="Excluded Votemaps", x=150, y=3, parent=panel }
panel.votemaps = xlib.makelistview{ y=20, w=135, h=262, multiselect=true, headerheight=0, parent=panel }
panel.votemaps:AddColumn( "" )
panel.votemaps.OnRowSelected = function( self, LineID, Line )
	panel.add:SetDisabled( true )
	panel.remove:SetDisabled( false )
	panel.remainingmaps:ClearSelection()
end
panel.remainingmaps = xlib.makelistview{ x=140, y=20, w=135, h=262, multiselect=true, headerheight=0, parent=panel }
panel.remainingmaps:AddColumn( "" )
panel.remainingmaps.OnRowSelected = function( self, LineID, Line )
	panel.add:SetDisabled( false )
	panel.remove:SetDisabled( true )
	panel.votemaps:ClearSelection()
end
panel.remove = xlib.makebutton{ y=282, w=135, label="Remove -->", disabled=true, parent=panel }
panel.remove.DoClick = function()
	panel.remove:SetDisabled( true )
	local temp = {}
	for _, v in ipairs( panel.votemaps:GetSelected() ) do
		table.insert( temp, v:GetColumnText(1) )
	end
	RunConsoleCommand( "xgui", "removeVotemaps", unpack( temp ) )
end
panel.add = xlib.makebutton{ x=140, y=282, w=135, label="<-- Add", disabled=true, parent=panel }
panel.add.DoClick = function()
	panel.add:SetDisabled( true )
	local temp = {}
	for _, v in ipairs( panel.remainingmaps:GetSelected() ) do
		table.insert( temp, v:GetColumnText(1) )
	end
	RunConsoleCommand( "xgui", "addVotemaps", unpack( temp ) )
end
panel.votemapmode = xlib.makecombobox{ y=302, w=275, repconvar="ulx_votemapMapmode", isNumberConvar=true, numOffset=0, choices={ "Include new maps by default", "Exclude new maps by default" }, parent=panel }
panel.updateList = function()
	if #ulx.maps ~= 0 then
		panel.votemaps:Clear()
		panel.remainingmaps:Clear()
		panel.add:SetDisabled( true )
		panel.remove:SetDisabled( true )
		for _, v in ipairs( ulx.maps ) do
			if table.HasValue( ulx.votemaps, v ) then
				panel.votemaps:AddLine( v )
			else
				panel.remainingmaps:AddLine( v )
			end
		end
	end
end
xgui.hookEvent( "votemaps", "process", panel.updateList )
xgui.addSubModule( "ULX Player Votemap List", panel, nil, "server" )

---------------------Player Votemap Settings---------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="Player Votemap Settings" } )
plist:Add( xlib.makecheckbox{ label="Enable Player Votemaps", repconvar="ulx_votemapEnabled" } )
plist:Add( xlib.makelabel{ label="Time (min) before a user can vote for a map" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=300, repconvar="ulx_votemapMintime" } )
plist:Add( xlib.makelabel{ label="Time (min) until a user can change their vote" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=60, decimal=1, repconvar="ulx_votemapWaittime" } )
plist:Add( xlib.makelabel{ label="Ratio of votes needed to accept mapchange" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=1, decimal=2, repconvar="ulx_votemapSuccessratio" } )
plist:Add( xlib.makelabel{ label="Minimum votes for a successful mapchange" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=10, repconvar="ulx_votemapMinvotes" } )
plist:Add( xlib.makelabel{ label="Time (sec) for an admin to veto a mapchange" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=300, repconvar="ulx_votemapVetotime" } )
xgui.addSubModule( "ULX Player Votemap Settings", plist, nil, "server" )

-------------------------Reserved Slots--------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="Reserved Slots Settings" } )
plist:Add( xlib.makecombobox{ repconvar="ulx_rslotsMode", isNumberConvar=true, choices={ "0 - Reserved slots disabled", "1 - Admins fill slots", "2 - Admins don't fill slots", "3 - Admins kick newest player" } } )
plist:Add( xlib.makeslider{ label="Number of Reserved Slots", min=0, max=game.MaxPlayers(), repconvar="ulx_rslots" } )
plist:Add( xlib.makecheckbox{ label="Reserved Slots Visible", repconvar="ulx_rslotsVisible" } )
plist:Add( xlib.makelabel{ w=265, wordwrap=true, label="Reserved slots mode info:\n1 - Set a certain number of slots reserved for admins-- As admins join, they will fill up these slots.\n2 - Same as #1, but admins will not fill the slots-- they'll be freed when players leave.\n3 - Always keep 1 slot open for admins, and, if full, kick the user with the shortest connection time when an admin joins, thus keeping 1 slot open.\n\nReserved Slots Visible:\nWhen enabled, if there are no regular player slots available in your server, it will appear that the server is full. The major downside to this is that admins can't connect to the server using the 'find server' dialog. Instead, they have to go to console and use the command 'connect <ip>'" } )
xgui.addSubModule( "ULX Reserved Slots", plist, nil, "server" )

------------------------Votekick/Voteban-------------------------
local plist = xlib.makelistlayout{ w=275, h=322, parent=xgui.null }
plist:Add( xlib.makelabel{ label="Votekick Settings" } )
plist:Add( xlib.makelabel{ label="Ratio of votes needed to accept votekick" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=1, decimal=2, repconvar="ulx_votekickSuccessratio" } )
plist:Add( xlib.makelabel{ label="Minimum votes required for a successful votekick" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=10, repconvar="ulx_votekickMinvotes" } )
plist:Add( xlib.makelabel{ label="\nVoteban Settings" } )
plist:Add( xlib.makelabel{ label="Ratio of votes needed to accept voteban" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=1, decimal=2, repconvar="ulx_votebanSuccessratio" } )
plist:Add( xlib.makelabel{ label="Minimum votes required for a successful voteban" } )
plist:Add( xlib.makeslider{ label="<--->", min=0, max=10, repconvar="ulx_votebanMinvotes" } )
xgui.addSubModule( "ULX Votekick/Voteban", plist, nil, "server" )