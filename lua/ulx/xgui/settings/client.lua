--Client settings module for ULX GUI -- by Stickly Man!
--A settings module for modifing XGUI-based settings, and allows for modules to add clientside setting here.

local client = xlib.makepanel{ parent=xgui.null }

client.panel = xlib.makepanel{ x=160, y=5, w=425, h=322, parent=client }

client.catList = xlib.makelistview{ x=5, y=5, w=150, h=302, parent=client }
client.catList:AddColumn( "Clientside Settings" )
client.catList.Columns[1].DoClick = function() end
client.catList.OnRowSelected = function( self, LineID, Line )
	local nPanel = xgui.modules.submodule[Line:GetValue(2)].panel
	if nPanel ~= client.curPanel then
		nPanel:SetZPos( 0 )
		xlib.addToAnimQueue( "pnlSlide", { panel=nPanel, startx=-435, starty=0, endx=0, endy=0, setvisible=true } )
		if client.curPanel then
			client.curPanel:SetZPos( -1 )
			xlib.addToAnimQueue( client.curPanel.SetVisible, client.curPanel, false )
		end
		xlib.animQueue_start()
		client.curPanel = nPanel
	else
		xlib.addToAnimQueue( "pnlSlide", { panel=nPanel, startx=0, starty=0, endx=-435, endy=0, setvisible=false } )
		self:ClearSelection()
		client.curPanel = nil
		xlib.animQueue_start()
	end
	if nPanel.onOpen then nPanel.onOpen() end --If the panel has it, call a function when it's opened
end

xlib.makebutton{ x=5, y=307, w=150, label="Save Clientside Settings", parent=client }.DoClick=function()
	xgui.saveClientSettings()
end

function xgui.openClientModule( name )
	name = string.lower( name )
	for i = 1, #xgui.modules.submodule do
		local module = xgui.modules.submodule[i]
		if module.mtype == "client" and string.lower(module.name) == name then
			if module.panel ~= client.curPanel then
				client.catList:ClearSelection()
				for i=1, #client.catList.Lines do
					local line = client.catList.Lines[i]
					if string.lower(line:GetColumnText(1)) == name then
						client.catList:SelectItem( line )
						break
					end
				end
			end
			break
		end
	end
end

--Process modular settings
function client.processModules()
	client.catList:Clear()
	for i, module in ipairs( xgui.modules.submodule ) do
		if module.mtype == "client" and ( not module.access or LocalPlayer():query( module.access ) ) then
			local x,y = module.panel:GetSize()
			if x == y and y == 0 then module.panel:SetSize( 425, 327 ) end
			module.panel:SetParent( client.panel )
			local line = client.catList:AddLine( module.name, i )
			if ( module.panel == client.curPanel ) then
				client.curPanel = nil
				client.catList:SelectItem( line )
			else
				module.panel:SetVisible( false )
			end
		end
	end
	client.catList:SortByColumn( 1, false )
end
client.processModules()

xgui.hookEvent( "onProcessModules", nil, client.processModules, "xguiProcessModules" )
xgui.addSettingModule( "Client", client, "icon16/layout_content.png" )


--------------------General Clientside Module--------------------
local genpnl = xlib.makepanel{ parent=xgui.null }

genpnl.pickupplayers = xlib.makecheckbox{ x=10, y=10, w=150, label="Enable picking up players with physgun (for yourself)", convar="cl_pickupplayers", parent=genpnl }
function genpnl.processModules()
	genpnl.pickupplayers:SetDisabled( not LocalPlayer():query( "ulx physgunplayer" ) )
end

xgui.hookEvent( "onProcessModules", nil, genpnl.processModules, "clientGeneralProcessModules" )
xgui.addSubModule( "General Settings", genpnl, nil, "client" )

--------------------XGUI Clientside Module--------------------
local xguipnl = xlib.makepanel{ parent=xgui.null }
xlib.makebutton{ x=10, y=10, w=150, label="Refresh XGUI Modules", parent=xguipnl }.DoClick=function()
	xgui.processModules()
end
local databutton = xlib.makebutton{ x=10, y=30, w=150, label="Refresh Server Data", parent=xguipnl }
databutton.DoClick=function( self )
	if xgui.offlineMode then
		self:SetDisabled( true )
		RunConsoleCommand( "_xgui", "getInstalled" )
		timer.Simple( 10, function() self:SetDisabled( false ) end )
	else
		if xgui.isInstalled then  --We can't be in offline mode to do this
			self:SetDisabled( true )
			RunConsoleCommand( "xgui", "refreshdata" )
			timer.Simple( 10, function() self:SetDisabled( false ) end )
		end
	end
end
xlib.makelabel{ x=10, y=55, label="Animation transition time:", parent=xguipnl }
xlib.makeslider{ x=10, y=70, w=150, label="<--->", max=2, value=xgui.settings.animTime, decimal=2, parent=xguipnl }.OnValueChanged = function( self, val )
	local testval = math.Clamp( tonumber( val ), 0, 2 )
	if testval ~= tonumber( val ) then self:SetValue( testval ) end
	xgui.settings.animTime = tonumber( val )
end
xlib.makecheckbox{ x=10, y=97, w=150, label="Show Startup Messages", value=xgui.settings.showLoadMsgs, parent=xguipnl }.OnChange = function( self, bVal )
	xgui.settings.showLoadMsgs = bVal
end
xlib.makelabel{ x=10, y=120, label="Infobar color:", parent=xguipnl }

xlib.makecolorpicker{ x=10, y=135, color=xgui.settings.infoColor, addalpha=true, alphamodetwo=true, parent=xguipnl }.OnChangeImmediate = function( self, color )
	xgui.settings.infoColor = color
end

----------------
--SKIN MANAGER--
----------------
xlib.makelabel{ x=10, y=273, label="Derma Theme:", parent=xguipnl }
xguipnl.skinselect = xlib.makecombobox{ x=10, y=290, w=150, parent=xguipnl }
if not derma.SkinList[xgui.settings.skin] then
	xgui.settings.skin = "Default"
end
xguipnl.skinselect:SetText( derma.SkinList[xgui.settings.skin].PrintName )
xgui.base.refreshSkin = true
xguipnl.skinselect.OnSelect = function( self, index, value, data )
	xgui.settings.skin = data
	xgui.base:SetSkin( data )
end
for skin, skindata in pairs( derma.SkinList ) do
	xguipnl.skinselect:AddChoice( skindata.PrintName, skin )
end

----------------
--TAB ORDERING--
----------------
xguipnl.mainorder = xlib.makelistview{ x=175, y=10, w=115, h=110, parent=xguipnl }
xguipnl.mainorder:AddColumn( "Main Modules" )
xguipnl.mainorder.OnRowSelected = function( self, LineID, Line )
	xguipnl.upbtnM:SetDisabled( LineID <= 1 )
	xguipnl.downbtnM:SetDisabled( LineID >= #xgui.settings.moduleOrder )
end
xguipnl.updateMainOrder = function()
	local selected = xguipnl.mainorder:GetSelectedLine() and xguipnl.mainorder:GetSelected()[1]:GetColumnText(1)
	xguipnl.mainorder:Clear()
	for i, v in ipairs( xgui.settings.moduleOrder ) do
		local found = false
		for _, tab in pairs( xgui.modules.tab ) do
			if tab.name == v then
				found = true
				break
			end
		end
		if found then
			local l = xguipnl.mainorder:AddLine( v )
			if v == selected then xguipnl.mainorder:SelectItem( l ) end
		else
			table.remove( xgui.settings.moduleOrder, i )
		end
	end
end
xgui.hookEvent( "onProcessModules", nil, xguipnl.updateMainOrder, "clientXGUIUpdateTabOrder" )
xguipnl.upbtnM = xlib.makebutton{ x=250, y=120, w=20, icon="icon16/bullet_arrow_up.png", centericon=true, disabled=true, parent=xguipnl }
xguipnl.upbtnM.DoClick = function( self )
	self:SetDisabled( true )
	local i = xguipnl.mainorder:GetSelectedLine()
	table.insert( xgui.settings.moduleOrder, i-1, xgui.settings.moduleOrder[i] )
	table.remove( xgui.settings.moduleOrder, i+1 )
	xgui.processModules()
end
xguipnl.downbtnM = xlib.makebutton{ x=270, y=120, w=20, icon="icon16/bullet_arrow_down.png", centericon=true, disabled=true, parent=xguipnl }
xguipnl.downbtnM.DoClick = function( self )
	self:SetDisabled( true )
	local i = xguipnl.mainorder:GetSelectedLine()
	table.insert( xgui.settings.moduleOrder, i+2, xgui.settings.moduleOrder[i] )
	table.remove( xgui.settings.moduleOrder, i )
	xgui.processModules()
end


xguipnl.settingorder = xlib.makelistview{ x=300, y=10, w=115, h=110, parent=xguipnl }
xguipnl.settingorder:AddColumn( "Setting Modules" )
xguipnl.settingorder.OnRowSelected = function( self, LineID, Line )
	xguipnl.upbtnS:SetDisabled( LineID <= 1 )
	xguipnl.downbtnS:SetDisabled( LineID >= #xgui.settings.settingOrder )
end
xguipnl.updateSettingOrder = function()
	local selected = xguipnl.settingorder:GetSelectedLine() and xguipnl.settingorder:GetSelected()[1]:GetColumnText(1)
	xguipnl.settingorder:Clear()
	for i, v in ipairs( xgui.settings.settingOrder ) do
		local found = false
		for _, tab in pairs( xgui.modules.setting ) do
			if tab.name == v then
				found = true
				break
			end
		end
		if found then
			local l = xguipnl.settingorder:AddLine( v )
			if v == selected then xguipnl.settingorder:SelectItem( l ) end
		else
			table.remove( xgui.settings.settingOrder, i )
		end
	end
end
xgui.hookEvent( "onProcessModules", nil, xguipnl.updateSettingOrder, "clientXGUIUpdateSettingOrder" )
xguipnl.upbtnS = xlib.makebutton{ x=395, y=120, w=20, icon="icon16/bullet_arrow_up.png", centericon=true, disabled=true, parent=xguipnl }
xguipnl.upbtnS.DoClick = function( self )
	self:SetDisabled( true )
	local i = xguipnl.settingorder:GetSelectedLine()
	table.insert( xgui.settings.settingOrder, i-1, xgui.settings.settingOrder[i] )
	table.remove( xgui.settings.settingOrder, i+1 )
	xgui.processModules()
end
xguipnl.downbtnS = xlib.makebutton{ x=375, y=120, w=20, icon="icon16/bullet_arrow_down.png", centericon=true, disabled=true, parent=xguipnl }
xguipnl.downbtnS.DoClick = function( self )
	self:SetDisabled( true )
	local i = xguipnl.settingorder:GetSelectedLine()
	table.insert( xgui.settings.settingOrder, i+2, xgui.settings.settingOrder[i] )
	table.remove( xgui.settings.settingOrder, i )
	xgui.processModules()
end

--------------------
--XGUI POSITIONING--
--------------------
xlib.makelabel{ x=175, y=145, label="XGUI Positioning:", parent=xguipnl }
local pos = tonumber( xgui.settings.xguipos.pos )
xguipnl.b7 = xlib.makebutton{ x=175, y=160, w=20, disabled=pos==7, parent=xguipnl }
xguipnl.b7.DoClick = function( self ) xguipnl.updatePos( 7 ) end
xguipnl.b8 = xlib.makebutton{ x=195, y=160, w=20, icon="icon16/arrow_up.png", centericon=true, disabled=pos==8, parent=xguipnl }
xguipnl.b8.DoClick = function( self ) xguipnl.updatePos( 8 ) end
xguipnl.b9 = xlib.makebutton{ x=215, y=160, w=20, disabled=pos==9, parent=xguipnl }
xguipnl.b9.DoClick = function( self ) xguipnl.updatePos( 9 ) end
xguipnl.b4 = xlib.makebutton{ x=175, y=180, w=20, icon="icon16/arrow_left.png", centericon=true, disabled=pos==4, parent=xguipnl }
xguipnl.b4.DoClick = function( self ) xguipnl.updatePos( 4 ) end
xguipnl.b5 = xlib.makebutton{ x=195, y=180, w=20, icon="icon16/bullet_green.png", centericon=true, disabled=pos==5, parent=xguipnl }
xguipnl.b5.DoClick = function( self ) xguipnl.updatePos( 5 ) end
xguipnl.b6 = xlib.makebutton{ x=215, y=180, w=20, icon="icon16/arrow_right.png", centericon=true, disabled=pos==6, parent=xguipnl }
xguipnl.b6.DoClick = function( self ) xguipnl.updatePos( 6 ) end
xguipnl.b1 = xlib.makebutton{ x=175, y=200, w=20, disabled=pos==1, parent=xguipnl }
xguipnl.b1.DoClick = function( self ) xguipnl.updatePos( 1 ) end
xguipnl.b2 = xlib.makebutton{ x=195, y=200, w=20, icon="icon16/arrow_down.png", centericon=true, disabled=pos==2, parent=xguipnl }
xguipnl.b2.DoClick = function( self ) xguipnl.updatePos( 2 ) end
xguipnl.b3 = xlib.makebutton{ x=215, y=200, w=20, disabled=pos==3, parent=xguipnl }
xguipnl.b3.DoClick = function( self ) xguipnl.updatePos( 3 ) end

function xguipnl.updatePos( position, xoffset, yoffset, ignoreanim )
	position = position or 5
	xoffset = xoffset or tonumber( xgui.settings.xguipos.xoff )
	yoffset = yoffset or tonumber( xgui.settings.xguipos.yoff )
	xgui.settings.xguipos = { pos=position, xoff=xoffset, yoff=yoffset }
	xgui.SetPos( position, xoffset, yoffset, ignoreanim )
	xguipnl.b1:SetDisabled( position==1 )
	xguipnl.b2:SetDisabled( position==2 )
	xguipnl.b3:SetDisabled( position==3 )
	xguipnl.b4:SetDisabled( position==4 )
	xguipnl.b5:SetDisabled( position==5 )
	xguipnl.b6:SetDisabled( position==6 )
	xguipnl.b7:SetDisabled( position==7 )
	xguipnl.b8:SetDisabled( position==8 )
	xguipnl.b9:SetDisabled( position==9 )
end

xguipnl.xwang = xlib.makenumberwang{ x=245, y=167, w=50, min=-1000, max=1000, value=xgui.settings.xguipos.xoff, decimal=0, parent=xguipnl }
xguipnl.xwang.OnValueChanged = function( self, val )
	xguipnl.updatePos( xgui.settings.xguipos.pos, tonumber( val ), xgui.settings.xguipos.yoffset, true )
end
xguipnl.xwang.OnEnter = function( self )
	local val = tonumber( self:GetValue() )
	if not val then val = 0 end
	xguipnl.updatePos( xgui.settings.xguipos.pos, tonumber( val ), xgui.settings.xguipos.yoffset )
end
xguipnl.xwang.OnLoseFocus = function( self )
	hook.Call( "OnTextEntryLoseFocus", nil, self )
	self:OnEnter()
end
xlib.makelabel{ x=300, y=169, label="X Offset", parent=xguipnl }

xguipnl.ywang = xlib.makenumberwang{ x=245, y=193, w=50, min=-1000, max=1000, value=xgui.settings.xguipos.yoff, decimal=0, parent=xguipnl }
xguipnl.ywang.OnValueChanged = function( self, val )
	xguipnl.updatePos( xgui.settings.xguipos.pos, xgui.settings.xguipos.xoffset, tonumber( val ), true )
end
xguipnl.ywang.OnEnter = function( self )
	local val = tonumber( self:GetValue() )
	if not val then val = 0 end
	xguipnl.updatePos( xgui.settings.xguipos.pos, xgui.settings.xguipos.xoffset, tonumber( val ) )
end
xguipnl.ywang.OnLoseFocus = function( self )
	hook.Call( "OnTextEntryLoseFocus", nil, self )
	self:OnEnter()
end
xlib.makelabel{ x=300, y=195, label="Y Offset", parent=xguipnl }

-------------------------
--OPEN/CLOSE ANIMATIONS--
-------------------------
xlib.makelabel{ x=175, y=229, label="XGUI Animations:", parent=xguipnl }
xlib.makelabel{ x=175, y=247, label="On Open:", parent=xguipnl }
xguipnl.inAnim = xlib.makecombobox{ x=225, y=245, w=150, choices={ "Fade In", "Slide From Top", "Slide From Left", "Slide From Bottom", "Slide From Right" }, parent=xguipnl }
xguipnl.inAnim:ChooseOptionID( tonumber( xgui.settings.animIntype ) )
function xguipnl.inAnim:OnSelect( index, value, data )
	xgui.settings.animIntype = index
end
xlib.makelabel{ x=175, y=272, label="On Close:", parent=xguipnl }
xguipnl.outAnim = xlib.makecombobox{ x=225, y=270, w=150, choices={ "Fade Out", "Slide To Top", "Slide To Left", "Slide To Bottom", "Slide To Right" }, parent=xguipnl }
xguipnl.outAnim:ChooseOptionID( tonumber( xgui.settings.animOuttype ) )
function xguipnl.outAnim:OnSelect( index, value, data )
	xgui.settings.animOuttype = index
end

xgui.addSubModule( "XGUI Settings", xguipnl, nil, "client" )