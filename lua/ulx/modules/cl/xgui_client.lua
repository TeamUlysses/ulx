--XGUI: A GUI for ULX -- by Stickly Man!
xgui = xgui or {}

--Make a spot for modules to store data and hooks
xgui.data = xgui.data or {}
xgui.hook = xgui.hook or { onProcessModules={}, onOpen={}, onClose={} }
--Call this function in your client-side module code to ensure the data types have been instantiated on the client.
function xgui.prepareDataType( dtype, location )
	if not xgui.data[dtype] then
		xgui.data[dtype] = location or {}
		xgui.hook[dtype] = { clear={}, process={}, done={}, add={}, update={}, remove={}, data={} }
	end
end

--Set up various hooks modules can "hook" into.
function xgui.hookEvent( dtype, event, func, name )
	if not xgui.hook[dtype] or ( event and not xgui.hook[dtype][event] ) then
		Msg( "XGUI: Attempted to add to invalid type or event to a hook! (" .. dtype .. ", " .. ( event or "nil" ) .. ")\n" )
	else
		if not name then name = "FixMe" .. math.floor(math.random()*10000) end -- Backwards compatibility for older XGUI modules
		if not event then
			xgui.hook[dtype][name] = func
		else
			xgui.hook[dtype][event][name] = func
		end
	end
end

--Set up tables and functions for creating and storing modules
xgui.modules = xgui.modules or {}

xgui.modules.tab = xgui.modules.tab or {}
function xgui.addModule( name, panel, icon, access, tooltip )
	local refreshModules = false
	for i = #xgui.modules.tab, 1, -1 do
		if xgui.modules.tab[i].name == name then
			xgui.modules.tab[i].panel:Remove()
			xgui.modules.tab[i].tabpanel:Remove()
			xgui.modules.tab[i].xbutton:Remove()
			table.remove(xgui.modules.tab, i)
			refreshModules = true
		end
	end
	table.insert( xgui.modules.tab, { name=name, panel=panel, icon=icon, access=access, tooltip=tooltip } )
	if refreshModules then xgui.processModules() end
end

xgui.modules.setting = xgui.modules.setting or {}
function xgui.addSettingModule( name, panel, icon, access, tooltip )
	local refreshModules = false
	for i = #xgui.modules.setting, 1, -1 do
		if xgui.modules.setting[i].name == name then
			xgui.modules.setting[i].panel:Remove()
			xgui.modules.setting[i].tabpanel:Remove()
			table.remove(xgui.modules.setting, i)
			refreshModules = true
		end
	end
	table.insert( xgui.modules.setting, { name=name, panel=panel, icon=icon, access=access, tooltip=tooltip } )
	if refreshModules then xgui.processModules() end
end

xgui.modules.submodule = xgui.modules.submodule or {}
function xgui.addSubModule( name, panel, access, mtype )
	local refreshModules = false
	for i = #xgui.modules.submodule, 1, -1 do
		if xgui.modules.submodule[i].name == name then
			xgui.modules.submodule[i].panel:Remove()
			table.remove(xgui.modules.submodule, i)
			refreshModules = true
		end
	end
	table.insert( xgui.modules.submodule, { name=name, panel=panel, access=access, mtype=mtype } )
	if refreshModules then xgui.processModules() end
end
--Set up a spot to store entries for autocomplete.
xgui.tabcompletes = xgui.tabcompletes or {}
xgui.ulxmenucompletes = xgui.ulxmenucompletes or {}


--Set up XGUI clientside settings, load settings from file if it exists
xgui.settings = xgui.settings or {}
if ULib.fileExists( "data/ulx/xgui_settings.txt" ) then
	local input = ULib.fileRead( "data/ulx/xgui_settings.txt" )
	input = input:match( "^.-\n(.*)$" )
	xgui.settings = ULib.parseKeyValues( input )
end
--Set default settings if they didn't get loaded
if not xgui.settings.moduleOrder then xgui.settings.moduleOrder = { "Cmds", "Groups", "Maps", "Settings", "Bans" } end
if not xgui.settings.settingOrder then xgui.settings.settingOrder = { "Sandbox", "Server", "Client" } end
if not xgui.settings.animTime then xgui.settings.animTime = 0.22 else xgui.settings.animTime = tonumber( xgui.settings.animTime ) end
if not xgui.settings.infoColor then
	--Default color
	xgui.settings.infoColor = Color( 100, 255, 255, 128 )
else
	--Ensure that the color contains numbers, not strings
	xgui.settings.infoColor = Color(xgui.settings.infoColor.r, xgui.settings.infoColor.g, xgui.settings.infoColor.b, xgui.settings.infoColor.a)
end
if not xgui.settings.showLoadMsgs then xgui.settings.showLoadMsgs = true else xgui.settings.showLoadMsgs = ULib.toBool( xgui.settings.showLoadMsgs ) end
if not xgui.settings.skin then xgui.settings.skin = "Default" end
if not xgui.settings.xguipos then xgui.settings.xguipos = { pos=5, xoff=0, yoff=0 } end
if not xgui.settings.animIntype then xgui.settings.animIntype = 1 end
if not xgui.settings.animOuttype then xgui.settings.animOuttype = 1 end


function xgui.init( ply )
	xgui.load_helpers()

	--Initiate the base window (see xgui_helpers.lua for code)
	xgui.makeXGUIbase{}

	--Create the bottom infobar
	xgui.infobar = xlib.makepanel{ x=10, y=399, w=580, h=20, parent=xgui.anchor }
	xgui.infobar:NoClipping( true )
	xgui.infobar.Paint = function( self, w, h )
		draw.RoundedBoxEx( 4, 0, 1, 580, 20, xgui.settings.infoColor, false, false, true, true )
	end
	local infoLabel = string.format( "\nULX Admin Mod :: XGUI - Team Ulysses |  ULX %s  |  ULib %s", ULib.pluginVersionStr("ULX"), ULib.pluginVersionStr("ULib") )
	xlib.makelabel{ x=5, y=-10, label=infoLabel, parent=xgui.infobar }:NoClipping( true )
	xgui.thetime = xlib.makelabel{ x=515, y=-10, label="", parent=xgui.infobar }
	xgui.thetime:NoClipping( true )
	xgui.thetime.check = function()
		xgui.thetime:SetText( os.date( "\n%I:%M:%S %p" ) )
		xgui.thetime:SizeToContents()
		timer.Simple( 1, xgui.thetime.check )
	end
	xgui.thetime.check()

	--Create an offscreen place to parent modules that the player can't access
	xgui.null = xlib.makepanel{ x=-10, y=-10, w=0, h=0 }
	xgui.null:SetVisible( false )

	--Load modules
	local sm = xgui.settings.showLoadMsgs
	if sm then
		Msg( "\n///////////////////////////////////////\n" )
		Msg( "//  ULX GUI -- Made by Stickly Man!  //\n" )
		Msg( "///////////////////////////////////////\n" )
		Msg( "// Loading GUI Modules...            //\n" )
	end
	for _, file in ipairs( file.Find( "ulx/xgui/*.lua", "LUA" ) ) do
		include( "ulx/xgui/" .. file )
		if sm then Msg( "//   " .. file .. string.rep( " ", 32 - file:len() ) .. "//\n" ) end
	end
	if sm then Msg( "// Loading Setting Modules...        //\n" ) end
	for _, file in ipairs( file.Find( "ulx/xgui/settings/*.lua", "LUA" ) ) do
		include( "ulx/xgui/settings/" .. file )
		if sm then Msg( "//   " .. file .. string.rep( " ", 32 - file:len() ) .. "//\n" ) end
	end
	if sm then Msg( "// Loading Gamemode Module(s)...     //\n" ) end
	if ULib.isSandbox() and GAMEMODE.FolderName ~= "sandbox" then -- If the gamemode sandbox-derived (but not sandbox, that will get added later), then add the sandbox Module
		include( "ulx/xgui/gamemodes/sandbox.lua" )
		if sm then Msg( "//   sandbox.lua                     //\n" ) end
	end
	for _, file in ipairs( file.Find( "ulx/xgui/gamemodes/*.lua", "LUA" ) ) do
		if string.lower( file ) == string.lower( GAMEMODE.FolderName .. ".lua" ) then
			include( "ulx/xgui/gamemodes/" .. file )
			if sm then Msg( "//   " .. file .. string.rep( " ", 32 - file:len() ) .. "//\n" ) end
			break
		end
		if sm then Msg( "//   No module found!                //\n" ) end
	end
	if sm then Msg( "// Modules Loaded!                   //\n" ) end
	if sm then Msg( "///////////////////////////////////////\n\n" ) end

	--Find any existing modules that aren't listed in the requested order.
	local function checkModulesOrder( moduleTable, sortTable )
		for _, m in ipairs( moduleTable ) do
			local notlisted = true
			for _, existing in ipairs( sortTable ) do
				if m.name == existing then
					notlisted = false
					break
				end
			end
			if notlisted then
				table.insert( sortTable, m.name )
			end
		end
	end
	checkModulesOrder( xgui.modules.tab, xgui.settings.moduleOrder )
	checkModulesOrder( xgui.modules.setting, xgui.settings.settingOrder )

	--Check if the server has XGUI installed
	RunConsoleCommand( "_xgui", "getInstalled" )

	xgui.initialized = true

	xgui.processModules()
end
hook.Add( ULib.HOOK_LOCALPLAYERREADY, "InitXGUI", xgui.init, HOOK_MONITOR_LOW )

function xgui.saveClientSettings()
	if not ULib.fileIsDir( "data/ulx" ) then
		ULib.fileCreateDir( "data/ulx" )
	end
	local output = "// This file stores clientside settings for XGUI.\n"
	output = output .. ULib.makeKeyValues( xgui.settings )
	ULib.fileWrite( "data/ulx/xgui_settings.txt", output )
end

function xgui.checkModuleExists( modulename, moduletable )
	for k, v in ipairs( moduletable ) do
		if v.name == modulename then
			return k
		end
	end
	return false
end

function xgui.processModules()
	local activetab = nil
	if xgui.base:GetActiveTab() then
		activetab = xgui.base:GetActiveTab():GetValue()
	end

	local activesettingstab = nil
	if xgui.settings_tabs:GetActiveTab() then
		activesettingstab = xgui.settings_tabs:GetActiveTab():GetValue()
	end

	xgui.base:Clear() --We need to remove any existing tabs in the GUI
	xgui.tabcompletes = {}
	xgui.ulxmenucompletes = {}
	for _, modname in ipairs( xgui.settings.moduleOrder ) do
		local module = xgui.checkModuleExists( modname, xgui.modules.tab )
		if module then
			module = xgui.modules.tab[module]
			if module.xbutton == nil then
				module.xbutton = xlib.makebutton{ x=555, y=-5, w=32, h=32, btype="close", parent=module.panel }
				module.xbutton.DoClick = function()
					xgui.hide()
				end
			end
			if LocalPlayer():query( module.access ) then
				xgui.base:AddSheet( module.name, module.panel, module.icon, false, false, module.tooltip )
				module.tabpanel = xgui.base.Items[#xgui.base.Items].Tab
				table.insert( xgui.tabcompletes, "xgui show " .. modname )
				table.insert( xgui.ulxmenucompletes, "ulx menu " .. modname )
			else
				module.tabpanel = nil
				module.panel:SetParent( xgui.null )
			end
		end
	end

	xgui.settings_tabs:Clear() --Clear out settings tabs for reprocessing
	for _, modname in ipairs( xgui.settings.settingOrder ) do
		local module = xgui.checkModuleExists( modname, xgui.modules.setting )
		if module then
			module = xgui.modules.setting[module]
			if LocalPlayer():query( module.access ) then
				xgui.settings_tabs:AddSheet( module.name, module.panel, module.icon, false, false, module.tooltip )
				module.tabpanel = xgui.settings_tabs.Items[#xgui.settings_tabs.Items].Tab
				table.insert( xgui.tabcompletes, "xgui show " .. modname )
				table.insert( xgui.ulxmenucompletes, "ulx menu " .. modname )
			else
				module.tabpanel = nil
				module.panel:SetParent( xgui.null )
			end
		end
	end

	--Call any functions that requested to be called when permissions change
	xgui.callUpdate( "onProcessModules" )
	table.sort( xgui.tabcompletes )
	table.sort( xgui.ulxmenucompletes )

	local hasFound = false
	if activetab then
		for _, v in pairs( xgui.base.Items ) do
			if v.Tab:GetValue() == activetab then
				xgui.base:SetActiveTab( v.Tab, true )
				hasFound = true
				break
			end
		end
		if not hasFound then
			xgui.base.m_pActiveTab = "none"
			xgui.base:SetActiveTab( xgui.base.Items[1].Tab, true )
		end
	end

	hasFound = false
	if activesettingstab then
		for _, v in pairs( xgui.settings_tabs.Items ) do
			if v.Tab:GetValue() == activesettingstab then
				xgui.settings_tabs:SetActiveTab( v.Tab, true )
				hasFound = true
				break
			end
		end
		if not hasFound then
			xgui.settings_tabs.m_pActiveTab = "none"
			xgui.settings_tabs:SetActiveTab( xgui.settings_tabs.Items[1].Tab, true )
		end
	end
end

function xgui.checkNotInstalled( tabname )
	if xgui.notInstalledWarning then return end

	gui.EnableScreenClicker( true )
	RestoreCursorPosition()
	xgui.notInstalledWarning = xlib.makeframe{ label="XGUI Warning!", w=375, h=110, nopopup=true, showclose=false, skin=xgui.settings.skin }
	xlib.makelabel{ x=10, y=30, wordwrap=true, w=365, label="XGUI has not initialized properly with the server. This could be caused by a heavy server load after a mapchange, a major error during XGUI server startup, or XGUI not being installed.", parent=xgui.notInstalledWarning }

	xlib.makebutton{ x=37, y=83, w=80, label="Offline Mode", parent=xgui.notInstalledWarning }.DoClick = function()
		xgui.notInstalledWarning:Remove()
		xgui.notInstalledWarning = nil
		offlineWarning = xlib.makeframe{ label="XGUI Warning!", w=375, h=110, nopopup=true, showclose=false, skin=xgui.settings.skin }
		xlib.makelabel{ x=10, y=30, wordwrap=true, w=365, label="XGUI will run locally in offline mode. Some features will not work, and information will be missing. You can attempt to reconnect to the server using the 'Refresh Server Data' button in the XGUI client menu.", parent=offlineWarning }
		xlib.makebutton{ x=77, y=83, w=80, label="OK", parent=offlineWarning }.DoClick = function()
			offlineWarning:Remove()
			xgui.offlineMode = true
			xgui.show( tabname )
		end
		xlib.makebutton{ x=217, y=83, w=80, label="Cancel", parent=offlineWarning }.DoClick = function()
			offlineWarning:Remove()
			RememberCursorPosition()
			gui.EnableScreenClicker( false )
		end
	end

	xlib.makebutton{ x=257, y=83, w=80, label="Close", parent=xgui.notInstalledWarning }.DoClick = function()
		xgui.notInstalledWarning:Remove()
		xgui.notInstalledWarning = nil
		RememberCursorPosition()
		gui.EnableScreenClicker( false )
	end

	xlib.makebutton{ x=147, y=83, w=80, label="Try Again", parent=xgui.notInstalledWarning }.DoClick = function()
		xgui.notInstalledWarning:Remove()
		xgui.notInstalledWarning = nil
		RememberCursorPosition()
		gui.EnableScreenClicker( false )
		local reattempt = xlib.makeframe{ label="XGUI: Attempting reconnection...", w=200, h=20, nopopup=true, showclose=false, skin=xgui.settings.skin }
		timer.Simple( 1, function()
			RunConsoleCommand( "_xgui", "getInstalled" )
			reattempt:Remove()
			timer.Simple( 0.5, function() xgui.show( tabname ) end )
		end )
	end
end

function xgui.show( tabname )
	if not xgui.anchor then return end
	if not xgui.initialized then return end

	--Check if XGUI is not installed, display the warning if hasn't been shown yet.
	if not xgui.isInstalled and not xgui.offlineMode then
		xgui.checkNotInstalled( tabname )
		return
	end

	if not game.SinglePlayer() and not ULib.ucl.authed[LocalPlayer():UniqueID()] then
		local unauthedWarning = xlib.makeframe{ label="XGUI Error!", w=250, h=90, showclose=true, skin=xgui.settings.skin }
		xlib.makelabel{ label="Your ULX player has not been Authed!", x=10, y=30, parent=unauthedWarning }
		xlib.makelabel{ label="Please wait a couple seconds and try again.", x=10, y=45, parent=unauthedWarning }
		xlib.makebutton{ x=50, y=63, w=60, label="Try Again", parent=unauthedWarning }.DoClick = function()
			unauthedWarning:Remove()
			xgui.show( tabname )
		end
		xlib.makebutton{ x=140, y=63, w=60, label="Close", parent=unauthedWarning }.DoClick = function()
			unauthedWarning:Remove()
		end
		return
	end

	if xgui.base.refreshSkin then
		xgui.base:SetSkin( xgui.settings.skin )
		xgui.base.refreshSkin = nil
	end

	--In case the string name had spaces, it sent the whole argument table. Convert it to a string here!
	if type( tabname ) == "table" then
		tabname = table.concat( tabname, " " )
	end
	--Sets the active tab to tabname if it was specified
	if tabname and tabname ~= "" then
		local found, settingsTab
		for _, v in ipairs( xgui.modules.tab ) do
			if string.lower( v.name ) == "settings" then settingsTab = v.tabpanel end
			if string.lower( v.name ) == string.lower( tabname ) and v.panel:GetParent() ~= xgui.null then
				xgui.base:SetActiveTab( v.tabpanel )
				if xgui.anchor:IsVisible() then return end
				found = true
				break
			end
		end
		if not found then
			for _, v in ipairs( xgui.modules.setting ) do
				if string.lower( v.name ) == string.lower( tabname ) and v.panel:GetParent() ~= xgui.null then
					xgui.base:SetActiveTab( settingsTab )
					xgui.settings_tabs:SetActiveTab( v.tabpanel )
					if xgui.anchor:IsVisible() then return end
					found = true
					break
				end
			end
		end
		if not found then return end --If invalid input was taken, then do nothing.
	end

	xgui.base.animOpen()
	gui.EnableScreenClicker( true )
	RestoreCursorPosition()
	xgui.anchor:SetMouseInputEnabled( true )

	--Calls the functions requesting to hook when XGUI is opened
	xgui.callUpdate( "onOpen" )
end

function xgui.hide()
	if not xgui.anchor then return end
	if not xgui.anchor:IsVisible() then return end
	RememberCursorPosition()
	gui.EnableScreenClicker( false )
	xgui.anchor:SetMouseInputEnabled( false )
	xgui.base.animClose()
	CloseDermaMenus()

	--Calls the functions requesting to hook when XGUI is closed
	xgui.callUpdate( "onClose" )
end

function xgui.toggle( tabname )
	if xgui.anchor and ( not xgui.anchor:IsVisible() or ( tabname and #tabname ~= 0 ) ) then
		xgui.show( tabname )
	else
		xgui.hide()
	end
end

--New XGUI Data stuff
function xgui.expectChunks( numofchunks )
	if xgui.isInstalled then
		xgui.expectingdata = true
		xgui.chunkbox.max = numofchunks
		xgui.chunkbox.value = 0
		xgui.chunkbox:SetFraction( 0 )
		xgui.chunkbox.Label:SetText( "Getting data: Waiting for server..." )
		xgui.chunkbox:SetVisible( true )
		xgui.chunkbox:SetSkin( xgui.settings.skin )
		xgui.flushQueue( "chunkbox" ) --Remove the queue entry that would hide the chunkbox
	end
end

function xgui.getChunk( flag, datatype, data )
	if xgui.expectingdata then
		--print( datatype, flag ) --Debug
		xgui.chunkbox:Progress( datatype )
		if flag == -1 then return --Ignore these chunks
		elseif flag == 0 then --Data should be purged
			if xgui.data[datatype] then
				table.Empty( xgui.data[datatype] )
			end
			xgui.flushQueue( datatype )
			xgui.callUpdate( datatype, "clear" )
		elseif flag == 1 then
			if not xgui.mergeData then --A full data table is coming in
				if not data then data = {} end --Failsafe for no table being sent
				xgui.flushQueue( datatype )
				table.Empty( xgui.data[datatype] )
				table.Merge( xgui.data[datatype], data )
				xgui.callUpdate( datatype, "clear" )
				xgui.callUpdate( datatype, "process", data )
				xgui.callUpdate( datatype, "done" )
			else --A chunk of data is coming in
				table.Merge( xgui.data[datatype], data )
				xgui.callUpdate( datatype, "process", data )
			end
		elseif flag == 2 or flag == 3 then --Add/Update a portion of data
			table.Merge( xgui.data[datatype], data )
			xgui.callUpdate( datatype, flag == 2 and "add" or "update", data )
		elseif flag == 4 then --Remove a key from the table
			xgui.removeDataEntry( xgui.data[datatype], data ) --Needs to be called recursively!
			xgui.callUpdate( datatype, "remove", data )
		elseif flag == 5 then --Begin a set of chunks (Clear the old data, then flag to merge incoming data)
			table.Empty( xgui.data[datatype] )
			xgui.mergeData = true
			xgui.flushQueue( datatype )
			xgui.callUpdate( datatype, "clear" )
		elseif flag == 6 then --End a set of chunks (Clear the merge flag)
			xgui.mergeData = nil
			xgui.callUpdate( datatype, "done" )
		elseif flag == 7 then --Pass the data directly to the module to be handled.
			xgui.callUpdate( datatype, "data", data )
		end
	end
end

function xgui.removeDataEntry( data, entry )
	for k, v in pairs( entry ) do
		if type( v ) == "table" then
			xgui.removeDataEntry( data[k], v )
		else
			if type(v) == "number" then
				table.remove( data, v )
			else
				data[v] = nil
			end
		end
	end
end

function xgui.callUpdate( dtype, event, data )
	--Run any functions that request to be called when "curtable" is updated
	if not xgui.hook[dtype] or ( event and not xgui.hook[dtype][event] ) then
		Msg( "XGUI: Attempted to call non-existent type or event to a hook! (" .. dtype .. ", " .. ( event or "nil" ) .. ")\n" )
	else
		if not event then
			for name, func in pairs( xgui.hook[dtype] ) do func( data ) end
		else
			for name, func in pairs( xgui.hook[dtype][event] ) do func( data ) end
		end
	end
end

--If the player's group is changed, reprocess the XGUI modules for permissions, and request for extra data if needed
function xgui.PermissionsChanged( ply )
	if ply == LocalPlayer() and xgui.isInstalled then
		xgui.processModules()
		local types = {}
		for dtype, data in pairs( xgui.data ) do
			if table.Count( data ) > 0 then table.insert( types, dtype ) end
		end
		RunConsoleCommand( "xgui", "refreshdata", unpack( types ) )
	end
end
hook.Add( "UCLAuthed", "XGUI_PermissionsChanged", xgui.PermissionsChanged )

function xgui.getInstalled()
	if not xgui.isInstalled then
		if xgui.notInstalledWarning then
			xgui.notInstalledWarning:Remove()
			xgui.notInstalledWarning = nil
		end
		xgui.isInstalled = true
		xgui.offlineMode = false
		RunConsoleCommand( "xgui", "getdata" )
	end
end

function xgui.cmd_base( ply, func, args )
	if not args[ 1 ] then
		xgui.toggle()
	elseif xgui.isInstalled then --First check that it's installed
		RunConsoleCommand( "_xgui", unpack( args ) )
	end
end

function xgui.tab_completes()
	return xgui.tabcompletes
end

function xgui.ulxmenu_tab_completes()
	return xgui.ulxmenucompletes
end

ULib.cmds.addCommandClient( "xgui", xgui.cmd_base )
ULib.cmds.addCommandClient( "xgui show", function( ply, cmd, args ) xgui.show( args ) end, xgui.tab_completes )
ULib.cmds.addCommandClient( "xgui hide", xgui.hide )
ULib.cmds.addCommandClient( "xgui toggle", function() xgui.toggle() end )

--local ulxmenu = ulx.command( CATEGORY_NAME, "ulx menu", ulx.menu, "!menu" )
ULib.cmds.addCommandClient( "ulx menu", function( ply, cmd, args ) xgui.toggle( args ) end, xgui.ulxmenu_tab_completes )
