--Bans module for ULX GUI -- by Stickly Man!
--Manages banned users and shows ban details

xgui.prepareDataType( "bans" )

local xbans = xlib.makepanel{ parent=xgui.null }

xbans.banlist = xlib.makelistview{ x=5, y=30, w=572, h=310, multiselect=false, parent=xbans }
	xbans.banlist:AddColumn( "Name/SteamID" )
	xbans.banlist:AddColumn( "Banned By" )
	xbans.banlist:AddColumn( "Unban Date" )
	xbans.banlist:AddColumn( "Reason" )
xbans.banlist.DoDoubleClick = function( self, LineID, line )
	xbans.ShowBanDetailsWindow( xgui.data.bans.cache[LineID] )
end
xbans.banlist.OnRowRightClick = function( self, LineID, line )
	local menu = DermaMenu()
	menu:SetSkin(xgui.settings.skin)
	menu:AddOption( "Details...", function()
		if not line:IsValid() then return end
		xbans.ShowBanDetailsWindow( xgui.data.bans.cache[LineID] )
	end )
	menu:AddOption( "Edit Ban...", function()
		if not line:IsValid() then return end
		xgui.ShowBanWindow( nil, line:GetValue( 5 ), nil, true, xgui.data.bans.cache[LineID] )
	end )
	menu:AddOption( "Remove", function()
		if not line:IsValid() then return end
		xbans.RemoveBan( line:GetValue( 5 ), xgui.data.bans.cache[LineID] )
	end )
	menu:Open()
end
-- Change the column sorting method to hook into our own custom sort stuff.
xbans.banlist.SortByColumn = function( self, ColumnID, Desc )
	local index =	ColumnID == 1 and 2 or	-- Sort by Name
					ColumnID == 2 and 4 or	-- Sort by Admin
					ColumnID == 3 and 6 or	-- Sort by Unban Date
					ColumnID == 4 and 5 or	-- Sort by Reason
									  1		-- Otherwise sort by Date
	xbans.sortbox:ChooseOptionID( index )
end

local searchFilter = ""
xbans.searchbox = xlib.maketextbox{ x=5, y=6, w=175, text="Search...", selectall=true, parent=xbans }
local txtCol = xbans.searchbox:GetTextColor() or Color( 0, 0, 0, 255 )
xbans.searchbox:SetTextColor( Color( txtCol.r, txtCol.g, txtCol.b, 196 ) ) -- Set initial color
xbans.searchbox.OnChange = function( pnl )
	if pnl:GetText() == "" then
		pnl:SetText( "Search..." )
		pnl:SelectAll()
		pnl:SetTextColor( Color( txtCol.r, txtCol.g, txtCol.b, 196 ) )
	else
		pnl:SetTextColor( Color( txtCol.r, txtCol.g, txtCol.b, 255 ) )
	end
end
xbans.searchbox.OnLoseFocus = function( pnl )
	if pnl:GetText() == "Search..." then
		searchFilter = ""
	else
		searchFilter = pnl:GetText()
	end
	xbans.setPage( 1 )
	xbans.retrieveBans()
	hook.Call( "OnTextEntryLoseFocus", nil, pnl )
end

local sortMode = 0
local sortAsc = false
xbans.sortbox = xlib.makecombobox{ x=185, y=6, w=150, text="Sort: Date (Desc.)", choices={ "Date", "Name", "Steam ID", "Admin", "Reason", "Unban Date", "Ban Length" }, parent=xbans }
function xbans.sortbox:OnSelect( i, v )
	if i-1 == sortMode then
		sortAsc = not sortAsc
	else
		sortMode = i-1
		sortAsc = false
	end
	self:SetValue( "Sort: " .. v .. (sortAsc and " (Asc.)" or " (Desc.)") )
	xbans.setPage( 1 )
	xbans.retrieveBans()
end

local hidePerma = 0
xlib.makebutton{ x=355, y=6, w=95, label="Permabans: Show", parent=xbans }.DoClick = function( self )
	hidePerma = hidePerma + 1
	if hidePerma == 1 then
		self:SetText( "Permabans: Hide" )
	elseif hidePerma == 2 then
		self:SetText( "Permabans: Only" )
	elseif hidePerma == 3 then
		hidePerma = 0
		self:SetText( "Permabans: Show" )
	end
	xbans.setPage( 1 )
	xbans.retrieveBans()
end

local hideIncomplete = 0
xlib.makebutton{ x=455, y=6, w=95, label="Incomplete: Show", parent=xbans, tooltip="Filters bans that are loaded by ULib, but do not have any metadata associated with them." }.DoClick = function( self )
	hideIncomplete = hideIncomplete + 1
	if hideIncomplete == 1 then
		self:SetText( "Incomplete: Hide" )
	elseif hideIncomplete == 2 then
		self:SetText( "Incomplete: Only" )
	elseif hideIncomplete == 3 then
		hideIncomplete = 0
		self:SetText( "Incomplete: Show" )
	end
	xbans.setPage( 1 )
	xbans.retrieveBans()
end


local function banUserList( doFreeze )
	local menu = DermaMenu()
	menu:SetSkin(xgui.settings.skin)
	for k, v in ipairs( player.GetAll() ) do
		menu:AddOption( v:Nick(), function()
			if not v:IsValid() then return end
			xgui.ShowBanWindow( v, v:SteamID(), doFreeze )
		end )
	end
	menu:AddSpacer()
	if LocalPlayer():query("ulx banid") then menu:AddOption( "Ban by STEAMID...", function() xgui.ShowBanWindow() end ) end
	menu:Open()
end

xlib.makebutton{ x=5, y=340, w=70, label="Ban...", parent=xbans }.DoClick = function() banUserList( false ) end
xbans.btnFreezeBan = xlib.makebutton{ x=80, y=340, w=95, label="Freeze Ban...", parent=xbans }
xbans.btnFreezeBan.DoClick = function() banUserList( true ) end

xbans.infoLabel = xlib.makelabel{ x=204, y=344, label="Right-click on a ban for more options", parent=xbans }


xbans.resultCount = xlib.makelabel{ y=344, parent=xbans }
function xbans.setResultCount( count )
	local pnl = xbans.resultCount
	pnl:SetText( count .. " results" )
	pnl:SizeToContents()

	local width = pnl:GetWide()
	local x, y = pnl:GetPos()
	pnl:SetPos( 475 - width, y )

	local ix, iy = xbans.infoLabel:GetPos()
	xbans.infoLabel:SetPos( ( 130 - width ) / 2 + 175, y )
end

local numPages = 1
local pageNumber = 1
xbans.pgleft = xlib.makebutton{ x=480, y=340, w=20, icon="icon16/arrow_left.png", centericon=true, disabled=true, parent=xbans }
xbans.pgleft.DoClick = function()
	xbans.setPage( pageNumber - 1 )
	xbans.retrieveBans()
end
xbans.pageSelector = xlib.makecombobox{ x=500, y=340, w=57, text="1", enableinput=true, parent=xbans }
function xbans.pageSelector:OnSelect( index )
	xbans.setPage( index )
	xbans.retrieveBans()
end
function xbans.pageSelector.TextEntry:OnEnter()
	pg = math.Clamp( tonumber( self:GetValue() ) or 1, 1, numPages )
	xbans.setPage( pg )
	xbans.retrieveBans()
end
xbans.pgright = xlib.makebutton{ x=557, y=340, w=20, icon="icon16/arrow_right.png", centericon=true, disabled=true, parent=xbans }
xbans.pgright.DoClick = function()
	xbans.setPage( pageNumber + 1 )
	xbans.retrieveBans()
end

xbans.setPage = function( newPage )
	pageNumber = newPage
	xbans.pgleft:SetDisabled( pageNumber <= 1 )
	xbans.pgright:SetDisabled( pageNumber >= numPages )
	xbans.pageSelector.TextEntry:SetText( pageNumber )
end


function xbans.RemoveBan( ID, bandata )
	local tempstr = "<Unknown>"
	if bandata then tempstr = bandata.name or "<Unknown>" end
	Derma_Query( "Are you sure you would like to unban " .. tempstr .. " - " .. ID .. "?", "XGUI WARNING", 
		"Remove",	function()
						RunConsoleCommand( "ulx", "unban", ID ) 
						xbans.RemoveBanDetailsWindow( ID )
					end,
		"Cancel", 	function() end )
end

xbans.openWindows = {}
function xbans.RemoveBanDetailsWindow( ID )
	if xbans.openWindows[ID] then
		xbans.openWindows[ID]:Remove()
		xbans.openWindows[ID] = nil
	end
end

function xbans.ShowBanDetailsWindow( bandata )
	local wx, wy

	if not bandata then return end

	if xbans.openWindows[bandata.steamID] then
		wx, wy = xbans.openWindows[bandata.steamID]:GetPos()
		xbans.openWindows[bandata.steamID]:Remove()
	end
	xbans.openWindows[bandata.steamID] = xlib.makeframe{ label="Ban Details", x=wx, y=wy, w=285, h=295, skin=xgui.settings.skin }

	local panel = xbans.openWindows[bandata.steamID]
	local name = xlib.makelabel{ x=50, y=30, label="Name:", parent=panel }
	xlib.makelabel{ x=90, y=30, w=190, label=( bandata.name or "<Unknown>" ), parent=panel, tooltip=bandata.name }
	xlib.makelabel{ x=36, y=50, label="SteamID:", parent=panel }
	xlib.makelabel{ x=90, y=50, label=bandata.steamID, parent=panel }
	xlib.makelabel{ x=33, y=70, label="Ban Date:", parent=panel }
	xlib.makelabel{ x=90, y=70, label=bandata.time and ( os.date( "%b %d, %Y - %I:%M:%S %p", tonumber( bandata.time ) ) ) or "<This ban has no metadata>", parent=panel }
	xlib.makelabel{ x=20, y=90, label="Unban Date:", parent=panel }
	xlib.makelabel{ x=90, y=90, label=( tonumber( bandata.unban ) == 0 and "Never" or os.date( "%b %d, %Y - %I:%M:%S %p", math.min(  tonumber( bandata.unban ), 4294967295 ) ) ), parent=panel }
	xlib.makelabel{ x=10, y=110, label="Length of Ban:", parent=panel }
	xlib.makelabel{ x=90, y=110, label=( tonumber( bandata.unban ) == 0 and "Permanent" or xgui.ConvertTime( tonumber( bandata.unban ) - bandata.time ) ), parent=panel }
	xlib.makelabel{ x=33, y=130, label="Time Left:", parent=panel }
	local timeleft = xlib.makelabel{ x=90, y=130, label=( tonumber( bandata.unban ) == 0 and "N/A" or xgui.ConvertTime( tonumber( bandata.unban ) - os.time() ) ), parent=panel }
	xlib.makelabel{ x=26, y=150, label="Banned By:", parent=panel }
	if bandata.admin then xlib.makelabel{ x=90, y=150, label=string.gsub( bandata.admin, "%(STEAM_%w:%w:%w*%)", "" ), parent=panel } end
	if bandata.admin then xlib.makelabel{ x=90, y=165, label=string.match( bandata.admin, "%(STEAM_%w:%w:%w*%)" ), parent=panel } end
	xlib.makelabel{ x=41, y=185, label="Reason:", parent=panel }
	xlib.makelabel{ x=90, y=185, w=190, label=bandata.reason, parent=panel, tooltip=bandata.reason ~= "" and bandata.reason or nil }
	xlib.makelabel{ x=13, y=205, label="Last Updated:", parent=panel }
	xlib.makelabel{ x=90, y=205, label=( ( bandata.modified_time == nil ) and "Never" or os.date( "%b %d, %Y - %I:%M:%S %p", tonumber( bandata.modified_time ) ) ), parent=panel }
	xlib.makelabel{ x=21, y=225, label="Updated by:", parent=panel }
	if bandata.modified_admin then xlib.makelabel{ x=90, y=225, label=string.gsub( bandata.modified_admin, "%(STEAM_%w:%w:%w*%)", "" ), parent=panel } end
	if bandata.modified_admin then xlib.makelabel{ x=90, y=240, label=string.match( bandata.modified_admin, "%(STEAM_%w:%w:%w*%)" ), parent=panel } end

	panel.data = bandata	-- Store data on panel for future reference.
	xlib.makebutton{ x=5, y=265, w=89, label="Edit Ban...", parent=panel }.DoClick = function()
		xgui.ShowBanWindow( nil, panel.data.steamID, nil, true, panel.data )
	end

	xlib.makebutton{ x=99, y=265, w=89, label="Unban", parent=panel }.DoClick = function()
		xbans.RemoveBan( panel.data.steamID, panel.data )
	end

	xlib.makebutton{ x=192, y=265, w=88, label="Close", parent=panel }.DoClick = function()
		xbans.RemoveBanDetailsWindow( panel.data.steamID )
	end

	panel.btnClose.DoClick = function ( button )
		xbans.RemoveBanDetailsWindow( panel.data.steamID )
	end

	if timeleft:GetValue() ~= "N/A" then
		function panel.OnTimer()
			if panel:IsVisible() then
				local bantime = tonumber( panel.data.unban ) - os.time()
				if bantime <= 0 then
					xbans.RemoveBanDetailsWindow( panel.data.steamID )
					return
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

function xgui.ShowBanWindow( ply, ID, doFreeze, isUpdate, bandata )
	if not LocalPlayer():query( "ulx ban" ) and not LocalPlayer():query( "ulx banid" ) then return end

	local xgui_banwindow = xlib.makeframe{ label=( isUpdate and "Edit Ban" or "Ban Player" ), w=285, h=180, skin=xgui.settings.skin }
	xlib.makelabel{ x=37, y=33, label="Name:", parent=xgui_banwindow }
	xlib.makelabel{ x=23, y=58, label="SteamID:", parent=xgui_banwindow }
	xlib.makelabel{ x=28, y=83, label="Reason:", parent=xgui_banwindow }
	xlib.makelabel{ x=10, y=108, label="Ban Length:", parent=xgui_banwindow }
	local reason = xlib.makecombobox{ x=75, y=80, w=200, parent=xgui_banwindow, enableinput=true, selectall=true, choices=ULib.cmds.translatedCmds["ulx ban"].args[4].completes }
	local banpanel = ULib.cmds.NumArg.x_getcontrol( ULib.cmds.translatedCmds["ulx ban"].args[3], 2, xgui_banwindow )
	banpanel.interval:SetParent( xgui_banwindow )
	banpanel.interval:SetPos( 200, 105 )
	banpanel.val:SetParent( xgui_banwindow )
	banpanel.val:SetPos( 75, 125 )
	banpanel.val:SetWidth( 200 )

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
		if bandata then
			name:SetText( bandata.name or "" )
			reason:SetText( bandata.reason or "" )
			if tonumber( bandata.unban ) ~= 0 then
				local btime = ( tonumber( bandata.unban ) - tonumber( bandata.time ) )
				if btime % 31536000 == 0 then
					if #banpanel.interval.Choices >= 6 then
						banpanel.interval:ChooseOptionID(6)
					else
						banpanel.interval:SetText( "Years" )
					end
					btime = btime / 31536000
				elseif btime % 604800 == 0 then
					if #banpanel.interval.Choices >= 5 then
						banpanel.interval:ChooseOptionID(5)
					else
						banpanel.interval:SetText( "Weeks" )
					end
					btime = btime / 604800
				elseif btime % 86400 == 0 then
					if #banpanel.interval.Choices >= 4 then
						banpanel.interval:ChooseOptionID(4)
					else
						banpanel.interval:SetText( "Days" )
					end
					btime = btime / 86400
				elseif btime % 3600 == 0 then
					if #banpanel.interval.Choices >= 3 then
						banpanel.interval:ChooseOptionID(3)
					else
						banpanel.interval:SetText( "Hours" )
					end
					btime = btime / 3600
				else
					btime = btime / 60
					if #banpanel.interval.Choices >= 2 then
						banpanel.interval:ChooseOptionID(2)
					else
						banpanel.interval:SetText( "Minutes" )
					end
				end
				banpanel.val:SetValue( btime )
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
		if isUpdate then
			local function performUpdate(btime)
				RunConsoleCommand( "xgui", "updateBan", steamID:GetValue(), btime, reason:GetValue(), name:GetValue() )
				xgui_banwindow:Remove()
			end
			btime = banpanel:GetMinutes()
			if btime ~= 0 and bandata and btime * 60 + bandata.time < os.time() then
				Derma_Query( "WARNING! The new ban time you have specified will cause this ban to expire.\nThe minimum time required in order to change the ban length successfully is " 
						.. xgui.ConvertTime( os.time() - bandata.time ) .. ".\nAre you sure you wish to continue?", "XGUI WARNING",
					"Expire Ban", function()
						performUpdate(btime)
						xbans.RemoveBanDetailsWindow( bandata.steamID )
					end,
					"Cancel", function() end )
			else
				performUpdate(btime)
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
					RunConsoleCommand( "ulx", "banid", steamID:GetValue(), banpanel:GetValue(), reason:GetValue() )
				else
					RunConsoleCommand( "xgui", "updateBan", steamID:GetValue(), banpanel:GetMinutes(), reason:GetValue(), ( name:GetValue() ~= "" and name:GetValue() or nil ) )
				end
			else
				RunConsoleCommand( "ulx", "ban", "$" .. ULib.getUniqueIDForPlayer( isOnline ), banpanel:GetValue(), reason:GetValue() )
			end
			xgui_banwindow:Remove()
		else
			local ply, message = ULib.getUser( name:GetValue() )
			if ply then
				RunConsoleCommand( "ulx", "ban", "$" .. ULib.getUniqueIDForPlayer( ply ), banpanel:GetValue(), reason:GetValue() )
				xgui_banwindow:Remove()
				return
			end
			Derma_Message( message )
		end
	end

	if ply then name:SetText( ply:Nick() ) end
	if ID then steamID:SetText( ID ) else steamID:SetText( "STEAM_0:" ) end
end

function xgui.ConvertTime( seconds )
	--Convert number of seconds remaining to something more legible (Thanks JamminR!)
	local years = math.floor( seconds / 31536000 )
	seconds = seconds - ( years * 31536000 )
	local weeks = math.floor( seconds / 604800 )
	seconds = seconds - ( weeks * 604800 )
	local days = math.floor( seconds / 86400 )
	seconds = seconds - ( days * 86400 )
	local hours = math.floor( seconds/3600 )
	seconds = seconds - ( hours * 3600 )
	local minutes = math.floor( seconds/60 )
	seconds = seconds - ( minutes * 60 )
	local curtime = ""
	if years ~= 0 then curtime = curtime .. years .. " year" .. ( ( years > 1 ) and "s, " or ", " ) end
	if weeks ~= 0 then curtime = curtime .. weeks .. " week" .. ( ( weeks > 1 ) and "s, " or ", " ) end
	if days ~= 0 then curtime = curtime .. days .. " day" .. ( ( days > 1 ) and "s, " or ", " ) end
	curtime = curtime .. ( ( hours < 10 ) and "0" or "" ) .. hours .. ":"
	curtime = curtime .. ( ( minutes < 10 ) and "0" or "" ) .. minutes .. ":"
	return curtime .. ( ( seconds < 10 and "0" or "" ) .. seconds )
end

---Update stuff
function xbans.bansRefreshed()
	xgui.data.bans.cache = {} -- Clear the bans cache

	-- Retrieve bans if XGUI is open, otherwise it will be loaded later.
	if xgui.anchor:IsVisible() then
		xbans.retrieveBans()
	end
end
xgui.hookEvent( "bans", "process", xbans.bansRefreshed, "bansRefresh" )

function xbans.banPageRecieved( data )
	xgui.data.bans.cache = data
	xbans.clearbans()
	xbans.populateBans()
end
xgui.hookEvent( "bans", "data", xbans.banPageRecieved, "bansGotPage" )

function xbans.checkCache()
	if xgui.data.bans.cache and xgui.data.bans.count ~= 0 and table.Count(xgui.data.bans.cache) == 0 then
		xbans.retrieveBans()
	end
end
xgui.hookEvent( "onOpen", nil, xbans.checkCache, "bansCheckCache" )

function xbans.clearbans()
	xbans.banlist:Clear()
end

function xbans.retrieveBans()
	RunConsoleCommand( "xgui", "getbans",
		sortMode,			-- Sort Type
		searchFilter,		-- Filter String
		hidePerma,			-- Hide permabans?
		hideIncomplete,		-- Hide bans that don't have full ULX metadata?
		pageNumber,			-- Page number
		sortAsc and 1 or 0)	-- Ascending/Descending
end

function xbans.populateBans()
	if xgui.data.bans.cache == nil then return end
	local cache = xgui.data.bans.cache
	local count = cache.count or xgui.data.bans.count
	numPages = math.max( 1, math.ceil( count / 17 ) )

	xbans.setResultCount( count )
	xbans.pageSelector:SetDisabled( numPages == 1 )
	xbans.pageSelector:Clear()
	for i=1, numPages do
		xbans.pageSelector:AddChoice(i)
	end
	xbans.setPage( math.Clamp( pageNumber, 1, numPages ) )

	cache.count = nil

	for _, baninfo in pairs( cache ) do
		xbans.banlist:AddLine( baninfo.name or baninfo.steamID,
					( baninfo.admin ) and string.gsub( baninfo.admin, "%(STEAM_%w:%w:%w*%)", "" ) or "",
					(( tonumber( baninfo.unban ) ~= 0 ) and os.date( "%c", math.min( tonumber( baninfo.unban ), 4294967295 ) )) or "Never",
					baninfo.reason,
					baninfo.steamID,
					tonumber( baninfo.unban ) )
	end
end
xbans.populateBans() --For autorefresh

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

function xbans.UCLChanged()
	xbans.btnFreezeBan:SetDisabled( not LocalPlayer():query("ulx freeze") )
end
hook.Add( "UCLChanged", "xgui_RefreshBansMenu", xbans.UCLChanged )

xgui.addModule( "Bans", xbans, "icon16/exclamation.png", "xgui_managebans" )
