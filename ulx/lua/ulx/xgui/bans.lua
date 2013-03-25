--Bans module for ULX GUI -- by Stickly Man!
--Manages banned users and shows ban details

xgui.prepareDataType( "bans" )
xgui.prepareDataType( "sbans" )

local xbans = xlib.makepanel{ parent=xgui.null }
xbans.isPopulating = 0
xbans.showperma = xlib.makecheckbox{ x=445, y=10, value=1, label="Show Permabans", parent=xbans }
function xbans.showperma:OnChange()
	xbans.clearbans()
	xbans.populateBans()
end

xbans.banlist = xlib.makelistview{ x=5, y=30, w=572, h=310, multiselect=false, parent=xbans }
	xbans.banlist:AddColumn( "Name/SteamID" )
	xbans.banlist:AddColumn( "Banned By" )
	xbans.banlist:AddColumn( "Unban Date" )
	xbans.banlist:AddColumn( "Reason" )
xbans.banlist.DoDoubleClick = function()
	xbans.ShowBanDetailsWindow( xbans.banlist:GetLine( xbans.banlist:GetSelectedLine() ):GetValue( 5 ) )
end
xbans.banlist.OnRowRightClick = function( self, LineID, line )
	local menu = DermaMenu()
	menu:AddOption( "Details...", function() xbans.ShowBanDetailsWindow( line:GetValue( 5 ) ) end )
	menu:AddOption( "Edit Ban...", function() xgui.ShowBanWindow( nil, line:GetValue( 5 ), nil, true ) end )
	menu:AddOption( "Remove", function() xbans.RemoveBan( line:GetValue( 5 ) ) end )
	menu:Open()
end

xlib.makelabel{ x=200, y=10, label="Right-click on a ban for more options", parent=xbans }
xbans.freezeban = xlib.makecheckbox{ x=140, y=343, label="Use Freezeban", tooltip="Freezes a player you have selected for banning while editing ban information (!fban in chat)", value=1, parent=xbans }
xlib.makebutton{ x=5, y=340, w=130, label="Add Ban...", parent=xbans }.DoClick = function()
	local menu = DermaMenu()
	for k, v in ipairs( player.GetAll() ) do
		menu:AddOption( v:Nick(), function() xgui.ShowBanWindow( v, v:SteamID(), xbans.freezeban:GetChecked() ) end )
	end
	menu:AddSpacer()
	if LocalPlayer():query("ulx banid") then menu:AddOption( "Ban by STEAMID...", function() xgui.ShowBanWindow() end ) end
	menu:Open()
end
xlib.makebutton{ x=447, y=340, w=130, label="View Source Bans...", parent=xbans }.DoClick = function()
	if xbans.sbanWindow and xbans.sbanWindow:IsVisible() then return end
	xbans.sbanWindow = xlib.makeframe{ w=160, h=400, label="Bans added via banid", skin=xgui.settings.skin }
	xbans.sbanWindow.bans = xlib.makelistview{ x=5, y=50, w=150, h=323, headerheight=0, parent=xbans.sbanWindow }
	xbans.sbanWindow.bans:AddColumn( "" )
	xbans.sbanWindow.bans.OnRowSelected = function( self, LineID, Line )
		xbans.sbanWindow.sbanDelete:SetDisabled( false )
		xbans.sbanWindow.sbanDetails:SetDisabled( false )
	end
	xlib.makelabel{ x=5, y=32, label="100 per page", parent=xbans.sbanWindow }
	xbans.sbanWindow.pgleft = xlib.makebutton{ x=80, y=30, w=20, icon="icon16/arrow_left.png", centericon=true, disabled=true, parent=xbans.sbanWindow }
	xbans.sbanWindow.pgleft.DoClick = function()
		local page = xbans.sbanWindow.sbanPage:GetValue()-1
		xbans.sbanWindow.gotoPage( page )
		xbans.sbanWindow.sbanPage:SetText( page )
	end
	xbans.sbanWindow.pgright = xlib.makebutton{ x=100, y=30, w=20, icon="icon16/arrow_right.png", centericon=true, disabled=true, parent=xbans.sbanWindow }
	xbans.sbanWindow.pgright.DoClick = function()
		local page = xbans.sbanWindow.sbanPage:GetValue()+1
		xbans.sbanWindow.gotoPage( page )
		xbans.sbanWindow.sbanPage:SetText( page )
	end
	xbans.sbanWindow.sbanPage = xlib.makecombobox{x=120, y=30, w=35, text="1", disabled=true, parent=xbans.sbanWindow }
	function xbans.sbanWindow.sbanPage:OnSelect()
		xbans.sbanWindow.gotoPage( tonumber( self:GetValue() ) )
	end
	xbans.sbanWindow.sbanDelete = xlib.makebutton{ x=5, y=373, w=75, label="Delete", disabled=true, parent=xbans.sbanWindow }
	xbans.sbanWindow.sbanDelete.DoClick = function()
		xbans.RemoveBan( xbans.sbanWindow.bans:GetSelected()[1]:GetColumnText(1), true )
	end
	xbans.sbanWindow.sbanDetails = xlib.makebutton{ x=80, y=373, w=75, label="Add Details...", disabled=true, parent=xbans.sbanWindow }
	xbans.sbanWindow.sbanDetails.DoClick = function()
		xgui.ShowBanWindow( nil, xbans.sbanWindow.bans:GetSelected()[1]:GetColumnText(1), nil, true )
	end
	
	function xbans.sbanWindow.gotoPage( pageno )
		xbans.sbanWindow.bans:Clear()
		xbans.sbanWindow.sbanDelete:SetDisabled( true )
		xbans.sbanWindow.sbanDetails:SetDisabled( true )
		for i,ID in ipairs( xbans.sbanWindow.banlist ) do
			if i > ( pageno-1 )*100 and i <= ( pageno )*100 then
				xbans.sbanWindow.bans:AddLine( ID )
			end
		end
		xbans.sbanWindow.sbanPage:SetText( pageno )
		
		if xbans.sbanPages > 2 then
			xbans.sbanWindow.sbanPage:SetDisabled( false )
			xbans.sbanWindow.pgright:SetDisabled( not ( pageno < xbans.sbanPages ) )
			xbans.sbanWindow.pgleft:SetDisabled( not ( pageno > 1 ) )
		else
			xbans.sbanWindow.sbanPage:SetDisabled( true )
			xbans.sbanWindow.pgright:SetDisabled( true )
			xbans.sbanWindow.pgleft:SetDisabled( true )
		end
	end
	
	function xbans.populateSBans( page )
		xbans.sbanWindow.banlist = {}
		for ID,_ in pairs( xgui.data.sbans ) do
			table.insert( xbans.sbanWindow.banlist, ID )
		end
		table.sort( xbans.sbanWindow.banlist )
		xbans.sbanWindow.sbanPage:Clear()
		xbans.sbanPages = 0
		for i=1,#xbans.sbanWindow.banlist,100 do
			xbans.sbanWindow.sbanPage:AddChoice( tostring(math.floor((i+100)/100)) )
			xbans.sbanPages = xbans.sbanPages + 1
		end
		xbans.sbanWindow.gotoPage( page )
	end
	xbans.populateSBans( 1 )
end

function xbans.RemoveBan( ID, noName )
	local tempstr = "<Unknown>"
	if not noName then tempstr = xgui.data.bans[ID].name or "<Unknown>" end
	Derma_Query( "Are you sure you would like to unban " .. tempstr .. " - " .. ID .. "?", "XGUI WARNING", 
		"Remove", function()
			RunConsoleCommand( "ulx", "unban", ID ) end,
		"Cancel", function() end )
end

xbans.openWindows = {}
function xbans.ShowBanDetailsWindow( ID )

	local wx, wy
	if xbans.openWindows[ID] then
		wx, wy = xbans.openWindows[ID]:GetPos()
		xbans.openWindows[ID]:Remove()
	end
	xbans.openWindows[ID] = xlib.makeframe{ label="Ban Details", x=wx, y=wy, w=285, h=295, skin=xgui.settings.skin }
	
	local panel = xbans.openWindows[ID]
	local name = xlib.makelabel{ x=50, y=30, label="Name:", parent=panel }
	xlib.makelabel{ x=90, y=30, w=190, label=( xgui.data.bans[ID].name or "<Unknown>" ), parent=panel, tooltip=xgui.data.bans[ID].name }
	xlib.makelabel{ x=36, y=50, label="SteamID:", parent=panel }
	xlib.makelabel{ x=90, y=50, label=ID, parent=panel }
	xlib.makelabel{ x=33, y=70, label="Ban Date:", parent=panel }
	if xgui.data.bans[ID].time then xlib.makelabel{ x=90, y=70, label=os.date( "%b %d, %Y - %I:%M:%S %p", tonumber( xgui.data.bans[ID].time ) ), parent=panel } end
	xlib.makelabel{ x=20, y=90, label="Unban Date:", parent=panel }
	xlib.makelabel{ x=90, y=90, label=( tonumber( xgui.data.bans[ID].unban ) == 0 and "Never" or os.date( "%b %d, %Y - %I:%M:%S %p", math.min(  tonumber( xgui.data.bans[ID].unban ), 4294967295 ) ) ), parent=panel }
	xlib.makelabel{ x=10, y=110, label="Length of Ban:", parent=panel }
	xlib.makelabel{ x=90, y=110, label=( tonumber( xgui.data.bans[ID].unban ) == 0 and "Permanent" or xgui.ConvertTime( tonumber( xgui.data.bans[ID].unban ) - xgui.data.bans[ID].time ) ), parent=panel }
	xlib.makelabel{ x=33, y=130, label="Time Left:", parent=panel }
	local timeleft = xlib.makelabel{ x=90, y=130, label=( tonumber( xgui.data.bans[ID].unban ) == 0 and "N/A" or xgui.ConvertTime( tonumber( xgui.data.bans[ID].unban ) - os.time() ) ), parent=panel }
	xlib.makelabel{ x=26, y=150, label="Banned By:", parent=panel }
	if xgui.data.bans[ID].admin then xlib.makelabel{ x=90, y=150, label=string.gsub( xgui.data.bans[ID].admin, "%(STEAM_%w:%w:%w*%)", "" ), parent=panel } end
	if xgui.data.bans[ID].admin then xlib.makelabel{ x=90, y=165, label=string.match( xgui.data.bans[ID].admin, "%(STEAM_%w:%w:%w*%)" ), parent=panel } end
	xlib.makelabel{ x=41, y=185, label="Reason:", parent=panel }
	xlib.makelabel{ x=90, y=185, w=190, label=xgui.data.bans[ID].reason, parent=panel, tooltip=xgui.data.bans[ID].reason ~= "" and xgui.data.bans[ID].reason or nil }
	xlib.makelabel{ x=13, y=205, label="Last Updated:", parent=panel }
	xlib.makelabel{ x=90, y=205, label=( ( xgui.data.bans[ID].modified_time == nil ) and "Never" or os.date( "%b %d, %Y - %I:%M:%S %p", tonumber( xgui.data.bans[ID].modified_time ) ) ), parent=panel }
	xlib.makelabel{ x=21, y=225, label="Updated by:", parent=panel }
	if xgui.data.bans[ID].modified_admin then xlib.makelabel{ x=90, y=225, label=string.gsub( xgui.data.bans[ID].modified_admin, "%(STEAM_%w:%w:%w*%)", "" ), parent=panel } end
	if xgui.data.bans[ID].modified_admin then xlib.makelabel{ x=90, y=240, label=string.match( xgui.data.bans[ID].modified_admin, "%(STEAM_%w:%w:%w*%)" ), parent=panel } end
	
	xlib.makebutton{ x=5, y=265, w=89, label="Edit Ban...", parent=panel }.DoClick = function()
		xgui.ShowBanWindow( nil, ID, nil, true )
	end
	
	xlib.makebutton{ x=99, y=265, w=89, label="Unban", parent=panel }.DoClick = function()
		xbans.RemoveBan( ID )
	end
		
	xlib.makebutton{ x=192, y=265, w=88, label="Close", parent=panel }.DoClick = function()
		xbans.openWindows[ID] = nil
		panel:Remove()
	end
	
	panel.btnClose.DoClick = function ( button )
		xbans.openWindows[ID] = nil
		panel:Remove()
	end
	
	if timeleft:GetValue() ~= "N/A" then
		function panel.OnTimer()
			if panel:IsVisible() then
				if not xgui.data.bans[ID] then
					panel:Remove()
					return
				end
				local bantime = tonumber( xgui.data.bans[ID].unban ) - os.time()
				if bantime <= 0 then
					timeleft:SetText( xgui.ConvertTime( 0 ) .. "      (Waiting for server)" )
				else
					timeleft:SetText( xgui.ConvertTime( bantime ) )
				end
				timeleft:SizeToContents()
				timer.Simple( 1, panel.OnTimer )
			end
		end
		panel.OnTimer()
	end
end

function xgui.ShowBanWindow( ply, ID, doFreeze, isUpdate )
	if LocalPlayer():query( "ulx ban" ) or LocalPlayer():query( "ulx banid" ) then
		local xgui_banwindow = xlib.makeframe{ label=( isUpdate and "Edit Ban" or "Ban Player" ), w=285, h=180, skin=xgui.settings.skin }
		xlib.makelabel{ x=37, y=33, label="Name:", parent=xgui_banwindow }
		xlib.makelabel{ x=23, y=58, label="SteamID:", parent=xgui_banwindow }
		xlib.makelabel{ x=28, y=83, label="Reason:", parent=xgui_banwindow }
		xlib.makelabel{ x=10, y=108, label="Ban Length:", parent=xgui_banwindow }
		local reason = xlib.makecombobox{ x=75, y=80, w=200, parent=xgui_banwindow, enableinput=true, selectall=true, choices=ULib.cmds.translatedCmds["ulx ban"].args[4].completes }
		local bantime = xlib.makeslider{ x=150, y=105, w=125, value=0, min=0, max=360, decimal=0, disabled=true, parent=xgui_banwindow }
		local interval = xlib.makecombobox{ x=75, y=105, w=75, text="Permanent", choices={ "Permanent", "Minutes", "Hours", "Days", "Weeks", "Years" }, parent=xgui_banwindow }
		interval.OnSelect = function( self, index, value, data )
			bantime:SetDisabled( value == "Permanent" )
		end
		local name
		if not isUpdate then
			name = xlib.makecombobox{ x=75, y=30, w=200, parent=xgui_banwindow, enableinput=true, selectall=true }
			for k,v in pairs( player.GetAll() ) do
				name:AddChoice( v:Nick(), v:SteamID() )
			end
			name.OnSelect = function( self, index, value, data )
				self.steamIDbox:SetText( data )
			end
		else
			name = xlib.maketextbox{ x=75, y=30, w=200, parent=xgui_banwindow, selectall=true }
			if xgui.data.bans[ID] then
				name:SetText( xgui.data.bans[ID].name or "" )
				reason:SetText( xgui.data.bans[ID].reason or "" )
				if tonumber( xgui.data.bans[ID].unban ) ~= 0 then
					local btime = ( tonumber( xgui.data.bans[ID].unban ) - tonumber( xgui.data.bans[ID].time ) )
					if btime % 31536000 == 0 then
						interval:SetText( "Years" )
						btime = btime / 31536000
					elseif btime % 86400 == 0 then
						interval:SetText( "Days" )
						btime = btime / 86400
					elseif btime % 3600 == 0 then
						interval:SetText( "Hours" )
						btime = btime / 3600
					else
						btime = btime / 60
						interval:SetText( "Minutes" )
					end
					bantime:SetDisabled( false )
					bantime:SetValue( btime )
				end
			end
		end
		
		local steamID = xlib.maketextbox{ x=75, y=55, w=200, selectall=true, disabled=( isUpdate or not LocalPlayer():query( "ulx banid" ) ), parent=xgui_banwindow }
		name.steamIDbox = steamID --Make a reference to the steamID textbox so it can change the value easily without needing a global variable

		if doFreeze and ply then
			if LocalPlayer():query( "ulx freeze" ) then
				RunConsoleCommand( "ulx", "freeze", "$" .. ULib.getUniqueIDForPlayer( ply ) )
				steamID:SetDisabled( true )
				name:SetDisabled( true )
				xgui_banwindow:ShowCloseButton( false )
			else
				doFreeze = false
			end
		end
		xlib.makebutton{ x=165, y=150, w=75, label="Cancel", parent=xgui_banwindow }.DoClick = function()
			if doFreeze and ply and ply:IsValid() then
				RunConsoleCommand( "ulx", "unfreeze", "$" .. ULib.getUniqueIDForPlayer( ply ) )
			end
			xgui_banwindow:Remove()
		end
		xlib.makebutton{ x=45, y=150, w=75, label=( isUpdate and "Update" or "Ban!" ), parent=xgui_banwindow }.DoClick = function()
			local calctime = bantime:GetValue()
			if interval:GetValue() == "Permanent" then calctime = calctime*0
			elseif interval:GetValue() == "Hours" then calctime = calctime*60
			elseif interval:GetValue() == "Days" then calctime = calctime*1440
			elseif interval:GetValue() == "Years" then calctime = calctime*525600 end
			
			if isUpdate then
				local function performUpdate()
					RunConsoleCommand( "xgui", "updateBan", steamID:GetValue(), calctime, reason:GetValue(), name:GetValue() )
					xgui_banwindow:Remove()
				end
				if calctime ~= 0 and xgui.data.bans[steamID:GetValue()] and calctime*60 + xgui.data.bans[steamID:GetValue()].time < os.time() then
					Derma_Query( "WARNING! The new ban time you have specified will cause this ban to expire.\nThe minimum time required in order to change the ban length successfully is " 
							.. xgui.ConvertTime( os.time() - xgui.data.bans[steamID:GetValue()].time ) .. ".\nAre you sure you wish to continue?", "XGUI WARNING",
						"Expire Ban", function()
							performUpdate()
						end,
						"Cancel", function() end )
				else
					performUpdate()
				end
				return
			end
			
			if ULib.isValidSteamID( steamID:GetValue() ) then
				local isOnline = false
				for k, v in ipairs( player.GetAll() ) do
					if v:SteamID() == steamID:GetValue() then
						isOnline = v
						break
					end
				end
				if not isOnline then
					if name:GetValue() == "" then
						RunConsoleCommand( "ulx", "banid", steamID:GetValue(), calctime, reason:GetValue() )
					else
						RunConsoleCommand( "xgui", "updateBan", steamID:GetValue(), calctime, reason:GetValue(), ( name:GetValue() ~= "" and name:GetValue() or nil ) )
					end
				else
					RunConsoleCommand( "ulx", "ban", "$" .. ULib.getUniqueIDForPlayer( isOnline ), calctime, reason:GetValue() )
				end
				xgui_banwindow:Remove()
			else
				local ply = ULib.getUser( name:GetValue() )
				if ply then
					RunConsoleCommand( "ulx", "ban", "$" .. ULib.getUniqueIDForPlayer( ply ), calctime, reason:GetValue() )
					xgui_banwindow:Remove()
					return
				end
				Derma_Message( "Invalid SteamID, player name, or multiple player targets found!" )		
			end
		end
		
		if ply then name:SetText( ply:Nick() ) end
		if ID then steamID:SetText( ID ) else steamID:SetText( "STEAM_0:" ) end
	end
end

--If the user requests to sort by unban date, tell the listview to sort by column 6 (unban date in seconds) for better sort accuracy
xbans.banlist.Columns[3].DoClick = function( self )
	self:GetParent():SortByColumn( 6, self:GetDescending() )
	self:SetDescending( not self:GetDescending() )
end

function xgui.ConvertTime( seconds )
	--Convert number of seconds remaining to something more legible (Thanks JamminR!)
	local years = math.floor( seconds / 31536000 )
	seconds = seconds - ( years * 31536000 )
	local days = math.floor( seconds / 86400 )
	seconds = seconds - ( days * 86400 )
	local hours = math.floor( seconds/3600 )
	seconds = seconds - ( hours * 3600 )
	local minutes = math.floor( seconds/60 )
	seconds = seconds - ( minutes * 60 )
	local curtime = ""
	if years ~= 0 then curtime = curtime .. years .. " year" .. ( ( years > 1 ) and "s, " or ", " ) end
	if days ~= 0 then curtime = curtime .. days .. " day" .. ( ( days > 1 ) and "s, " or ", " ) end
	curtime = curtime .. ( ( hours < 10 ) and "0" or "" ) .. hours .. ":"
	curtime = curtime .. ( ( minutes < 10 ) and "0" or "" ) .. minutes .. ":"
	return curtime .. ( ( seconds < 10 and "0" or "" ) .. seconds )
end


---Update stuff
function xbans.clearbans()
	xbans.banlist:Clear()
end

function xbans.populateBans( chunk )
	if not chunk then chunk = xgui.data.bans end
	xbans.showperma:SetDisabled( true )
	xbans.isPopulating = xbans.isPopulating + 1
	for steamID, baninfo in pairs( chunk ) do
		if not ( xbans.showperma:GetChecked() == false and tonumber( baninfo.unban ) == 0 ) then
			xgui.queueFunctionCall( xbans.addbanline, "bans", baninfo, steamID ) --Queue this via xgui.queueFunctionCall to prevent lag
		end
	end
	xgui.queueFunctionCall( function() xbans.isPopulating = xbans.isPopulating - 1 
										if xbans.isPopulating == 0 then xbans.showperma:SetDisabled( false ) end end, nil )
end

function xbans.addbanline( baninfo, steamID )
	xbans.banlist:AddLine(	baninfo.name or steamID,
								( baninfo.admin ) and string.gsub( baninfo.admin, "%(STEAM_%w:%w:%w*%)", "" ) or "",
								(( tonumber( baninfo.unban ) ~= 0 ) and os.date( "%c", math.min( tonumber( baninfo.unban ), 4294967295 ) )) or "Never",
								baninfo.reason,
								steamID,
								tonumber( baninfo.unban ) )
end

function xbans.banRemoved( banids )
	for _,ID in ipairs( banids ) do
		if xbans.openWindows[ID] then
			xbans.openWindows[ID]:Remove()
			xbans.openWindows[ID] = nil
		end
		for i, v in ipairs( xbans.banlist.Lines ) do
			if v.Columns[5]:GetValue() == ID then
				xbans.banlist:RemoveLine(i)
				break
			end
		end
		if xgui.data.sbans[ID] then
			xgui.data.sbans[ID] = nil
			if xbans.sbanWindow and xbans.sbanWindow:IsVisible() then
				xbans.populateSBans( tonumber( xbans.sbanWindow.sbanPage:GetValue() ) )
			end
		end
	end
end

function xbans.banUpdated( bantable )
	for SteamID, data in pairs( bantable ) do
		local found = false
		for i, v in ipairs( xbans.banlist.Lines ) do
			if v.Columns[5]:GetValue() == SteamID then
				found = true
				v:SetColumnText( 1, data.name or SteamID )
				v:SetColumnText( 2, data.admin and string.gsub( data.admin, "%(STEAM_%w:%w:%w*%)", "" ) or "" )
				v:SetColumnText( 3, (( tonumber( data.unban ) ~= 0 ) and os.date( "%c", math.min( tonumber( data.unban ), 4294967295 ) )) or "Never" )
				v:SetColumnText( 4, data.reason )
				v:SetColumnText( 5, SteamID )
				v:SetColumnText( 6, tonumber( data.unban ) )
				break
			end				
		end
		if not found then
			local t = {}
			t[SteamID] = data
			xbans.populateBans( t )
		end
		if xbans.openWindows[SteamID] then xbans.ShowBanDetailsWindow( SteamID ) end
	end
end

function xbans.updateSBans( chunk )
	if xbans.sbanWindow and xbans.sbanWindow:IsVisible() then
		xbans.populateSBans( tonumber( xbans.sbanWindow.sbanPage:GetValue() ) )
	end
end

function xbans.xban( ply, cmd, args, dofreeze )
	if args[1] and args[1] ~= "" then
		local target = ULib.getUser( args[1] )
		if target then
			xgui.ShowBanWindow( target, target:SteamID(), dofreeze )
		end
	else
		xgui.ShowBanWindow()
	end
end
ULib.cmds.addCommandClient( "xgui xban", xbans.xban )

function xbans.fban( ply, cmd, args )
	xbans.xban( ply, cmd, args, true )
end
ULib.cmds.addCommandClient( "xgui fban", xbans.fban )

xgui.hookEvent( "bans", "process", xbans.populateBans )
xgui.hookEvent( "bans", "clear", xbans.clearbans )
xgui.hookEvent( "bans", "add", xbans.banUpdated )
xgui.hookEvent( "bans", "remove", xbans.banRemoved )
xgui.hookEvent( "sbans", "process", xbans.updateSBans )
xgui.hookEvent( "sbans", "remove", xbans.updateSBans )
xgui.addModule( "Bans", xbans, "icon16/exclamation.png", "xgui_managebans" )
