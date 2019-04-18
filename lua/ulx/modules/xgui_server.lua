--Server stuff for the GUI for ULX --by Stickly Man!

xgui = xgui or {}
xgui.svmodules = {}
function xgui.addSVModule( name, initFunc, postinitFunc )
	local t = { name=name, init=initFunc, postinit=postinitFunc }
	local key

	for i, svmodule in pairs( xgui.svmodules ) do
		if svmodule.name == name then
			key = i
			break
		end
	end

	if key then -- Autorefreshed
		xgui.svmodules[key] = t

		initFunc()
		if postinitFunc then
			postinitFunc()
		end
	else
		table.insert( xgui.svmodules, t )
	end
end

Msg( "///////////////////////////////\n" )
Msg( "// ULX GUI -- by Stickly Man //\n" )
Msg( "///////////////////////////////\n" )
Msg( "// Adding Main Modules..     //\n" )
for _, file in ipairs( file.Find( "ulx/xgui/*.lua", "LUA" ) ) do
	AddCSLuaFile( "ulx/xgui/" .. file )
	Msg( "//  " .. file .. string.rep( " ", 25 - file:len() ) .. "//\n" )
end
Msg( "// Adding Setting Modules..  //\n" )
for _, file in ipairs( file.Find( "ulx/xgui/settings/*.lua", "LUA" ) ) do
	AddCSLuaFile( "ulx/xgui/settings/" .. file )
	Msg( "//  " .. file .. string.rep( " ", 25 - file:len() ) .. "//\n" )
end
Msg( "// Adding Gamemode Modules.. //\n" )
for _, file in ipairs( file.Find( "ulx/xgui/gamemodes/*.lua", "LUA" ) ) do
	AddCSLuaFile( "ulx/xgui/gamemodes/" .. file )
	Msg( "//  " .. file .. string.rep( " ", 25 - file:len() ) .. "//\n" )
end
Msg( "// Loading Server Modules..  //\n" )
for _, file in ipairs( file.Find( "ulx/xgui/server/*.lua", "LUA" ) ) do
	include( "ulx/xgui/server/" .. file )
	Msg( "//  " .. file .. string.rep( " ", 25 - file:len() ) .. "//\n" )
end
Msg( "// XGUI modules added!       //\n" )
Msg( "///////////////////////////////\n" )

function xgui.init()
	local function xgui_chatCommand( ply, func, args )
		if ply:IsValid() then
			ULib.clientRPC( ply, "xgui.toggle", args )
		end
	end
	ULib.addSayCommand( "!xgui", xgui_chatCommand )
	ULib.addSayCommand( "!menu", xgui_chatCommand )

	--XGUI command stuff
	xgui.cmds = {}
	function xgui.addCmd( name, func )
		xgui.cmds[name] = func
	end
	function xgui.cmd( ply, cmd, args )
		-- print("xgui.cmd:", args[1], table.concat( args, " ", 2 ))
		local name=args[1]
		table.remove( args, 1 )
		if xgui.cmds[name] then
			xgui.cmds[name]( ply, args )
		else
			ULib.tsay( ply, "XGUI: Command " .. ( name or "<none>" ) .. " not recognized!" )
		end
	end
	concommand.Add( "_xgui", xgui.cmd )

	ULib.cmds.addCommand( "ulx menu", function( ply, cmd, args )
		if ply and ply:IsValid() then
			ULib.clientRPC( ply, "xgui.toggle", args )
		end
	end, xgui.ulxmenu_tab_completes )


	-----------------
	--XGUI data stuff
	-----------------
	xgui.dataTypes = {}
	xgui.activeUsers = {}  --Set up a table to list users who are actively transferring data
	xgui.readyPlayers = {} --Set up a table to store users who are ready to receive data.
	function xgui.addDataType( name, retrievalFunc, access, maxChunkSize, priority )
		xgui.dataTypes[name] = { getData=retrievalFunc, access=access, maxchunk=maxChunkSize }
		-- For autorefresh- ensure priorities for a datatype are never added more than once
		for i=#xgui.dataTypes, 1, -1 do
			if xgui.dataTypes[i].name == name then
				table.remove( xgui.dataTypes, i )
			end
		end
		table.insert( xgui.dataTypes, { name=name, priority=priority or 0 } )
		table.sort( xgui.dataTypes, function(a,b) return a.priority < b.priority end )
	end

	function xgui.getdata( ply, args )
		xgui.sendDataTable( ply, args )
	end
	xgui.addCmd( "getdata", xgui.getdata )

	--Let the server know when players are/aren't ready to receive data.
	function xgui.getInstalled( ply )
		ULib.clientRPC( ply, "xgui.getInstalled" )
		xgui.readyPlayers[ply:UniqueID()] = 1
	end
	xgui.addCmd( "getInstalled", xgui.getInstalled )

	function xgui.onDisconnect( ply )
		xgui.activeUsers[ply:UniqueID()] = nil
		xgui.readyPlayers[ply:UniqueID()] = nil
	end
	hook.Add( "PlayerDisconnected", "xgui_ply_disconnect", xgui.onDisconnect )

	function xgui.refreshdata( ply, existingDatas )
		local t = {}
		if #existingDatas ~= 0 then
			for _, data in ipairs( xgui.dataTypes ) do
				--Only refresh data that the user says they don't have, and refresh datatypes they do not have access to
				if not table.HasValue( existingDatas, data.name ) or not ULib.ucl.query( ply, xgui.dataTypes[data.name].access ) then
					table.insert( t, data.name )
				end
			end
			if #t == 0 then return end --If no updates were needed, then just end the function
		end
		xgui.sendDataTable( ply, t )
	end
	xgui.addCmd( "refreshdata", xgui.refreshdata )

	local function plyToTable( plys ) --If plys is empty, then return the full playerlist.
		if type( plys ) == "Player" then
			plys = { plys }
		elseif #plys == 0 then
			for _, v in pairs( player.GetAll() ) do
				table.insert( plys, v )
			end
		end
		return plys
	end

	--Send an entire table of data to the client(s)
	function xgui.sendDataTable( plys, datatypes, forceSend )
		if type( datatypes ) ~= "table" then
			datatypes = { datatypes }
		elseif #datatypes == 0 then
			for _, k in ipairs( xgui.dataTypes ) do
				table.insert( datatypes, k.name )
			end
		end

		plys = plyToTable( plys )

		for k, ply in pairs( plys ) do
			if not xgui.readyPlayers[ply:UniqueID()] then return end --Ignore requests to players who are not ready, they'll get the data as soon as they can.

			-- print("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv")
			-- print("sendDataTable attempt. Will defer?", xgui.activeUsers[ply:UniqueID()] and not forceSend)
			-- PrintTable(datatypes)
			-- print(debug.traceback())
			-- print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")

			if xgui.activeUsers[ply:UniqueID()] and not forceSend then --If data is currently being sent to the client
				for _, dtype in ipairs( datatypes ) do
					local exists = false
					for _,existingArg in ipairs(xgui.activeUsers[ply:UniqueID()].tables) do
						if dtype == existingArg then exists=true break end
					end
					if not exists then table.insert( xgui.activeUsers[ply:UniqueID()].tables, dtype ) end
					--Clear any events relating to this data type, since those changes will be reflected whenever the new table is sent.
					for i=#xgui.activeUsers[ply:UniqueID()].events,1,-1 do
						if xgui.activeUsers[ply:UniqueID()].events[i][2] == dtype then
							table.remove( xgui.activeUsers[ply:UniqueID()].events, i )
						end
					end
				end
				return
			end

			local chunks = {}
			for _, dtype in ipairs( datatypes ) do
				if xgui.dataTypes[dtype] then
					local data = xgui.dataTypes[dtype]
					if ULib.ucl.query( ply, data.access ) then
						local t = data.getData()
						local size = data.maxchunk or 0 --Split the table into "chunks" of per-datatype specified size to even out data flow. 0 to disable
						if t and table.Count( t ) > size and size ~= 0 then
							table.insert( chunks, { 5, dtype } ) --Signify beginning of split chunks
							local c = 1
							local part = {}
							for key, data in pairs( t ) do
								part[key] = data
								c = c + 1
								if c > size then
									table.insert( chunks, { 1, dtype, part } )
									part = {}
									c = 1
								end
							end
							table.insert( chunks, { 1, dtype, part } )
							table.insert( chunks, { 6, dtype } ) --Signify end of split chunks
						else
							table.insert( chunks, { 1, dtype, data.getData() } )
						end
					else
						table.insert( chunks, { 0, dtype } )
					end
				end
			end

			if #chunks ~= 0 then
				xgui.sendChunks( ply, chunks )
			else
				xgui.chunksFinished( ply )
			end
		end
	end

	--Send a portion of table data to the client(s). The table "data" gets table.Merge'd with the existing table on the client.
	function xgui.addData( plys, dtype, data )
		xgui.sendDataEvent( plys, 2, dtype, data )
	end

	--(Same as add, you can call them differently in your code if you need to be able to determine if one is added vs. updated)
	function xgui.updateData( plys, dtype, data )
		xgui.sendDataEvent( plys, 3, dtype, data )
	end

	--Removes a single key from the table -- The table "data" should be structured that it contains the set of tables to a single key which will be removed. (i.e. data = {base={subtable1="key"}} )
	--It can also remove multiple values. Here are a few examples:
		--xgui.removeData( {}, "adverts", {[2]={[1]={"rpt"} } } )  --This would remove the repeat time of the first advert in the second advert group.
		--xgui.removeData( {}, "votemaps", {3, 3, 3, 3} ) --This will remove votemaps numbered 3-6 in xgui.data.votemaps. (It uses table.remove, but you can alternatively do {6,5,4,3} to produce the same effect)
	function xgui.removeData( plys, dtype, data )
		xgui.sendDataEvent( plys, 4, dtype, data )
	end

	function xgui.sendDataEvent( plys, evtype, dtype, entry )
		plys = plyToTable( plys )
		for k, ply in pairs( plys ) do

			-- print("vvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvvv")
			-- print("sendDataEvent attempt. Will defer?", xgui.activeUsers[ply:UniqueID()])
			-- print(evtype, dtype, entry)
			-- print(debug.traceback())
			-- print("^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^")

			if xgui.activeUsers[ply:UniqueID()] then
				table.insert( xgui.activeUsers[ply:UniqueID()].events, { evtype, dtype, entry } )
				return
			end

			local chunks = {}
			table.insert( chunks, { evtype, dtype, entry } )
			xgui.sendChunks( ply, chunks )
		end
	end

	function xgui.sendChunks( ply, chunks )
		ULib.clientRPC( ply, "xgui.expectChunks", #chunks )
		if not xgui.activeUsers[ply:UniqueID()] then xgui.activeUsers[ply:UniqueID()] = { tables={}, events={} } end
		for _, chunk in ipairs( chunks ) do
			ULib.queueFunctionCall( ULib.clientRPC, ply, "xgui.getChunk", chunk[1], chunk[2], chunk[3] )
		end
	end

	function xgui.chunksFinished( ply )
		if xgui.activeUsers[ply:UniqueID()] then
			if #xgui.activeUsers[ply:UniqueID()].tables > 0 then --Data tables have been requested while the player was transferring data
				xgui.sendDataTable( ply, xgui.activeUsers[ply:UniqueID()].tables, true )
				xgui.activeUsers[ply:UniqueID()].tables = {}
			elseif #xgui.activeUsers[ply:UniqueID()].events > 0 then --No data tables are needed, and events have occurred while the player was transferring data
				local chunks = {}
				for _,v in ipairs( xgui.activeUsers[ply:UniqueID()].events ) do
					table.insert( chunks, v )
				end
				xgui.sendChunks( ply, chunks )
				xgui.activeUsers[ply:UniqueID()].events = {}
			else --Client is up-to-date!
				xgui.activeUsers[ply:UniqueID()] = nil
			end
		end
	end
	xgui.addCmd( "dataComplete", xgui.chunksFinished )

	------------
	--Misc Stuff
	------------
	function xgui.getCommentHeader( data, comment_char )
		comment_char = comment_char or ";"
		local lines = ULib.explode( "\n", data )
		local end_comment_line = 0
		for _, line in ipairs( lines ) do
			local trimmed = line:Trim()
			if trimmed == "" or trimmed:sub( 1, 1 ) == comment_char then
				end_comment_line = end_comment_line + 1
			else
				break
			end
		end

		local comment = table.concat( lines, "\n", 1, end_comment_line )
		if comment ~= "" then comment = comment .. "\n" end
		return comment
	end

	--Initialize the server modules!
	for _, v in ipairs( xgui.svmodules ) do	v.init() end

	ulx.addToHelpManually( "Menus", "xgui", "<show, hide, toggle> - Opens and/or closes XGUI. (say: !xgui, !menu) (alias: ulx menu)" )
end

--Init the code when the server is ready
hook.Add( "Initialize", "XGUI_InitServer", xgui.init, HOOK_HIGH )

--Call the modules postinit function when ULX is done loading. Should be called well after the Initialize hook.
function xgui.postInit()
	for _, v in ipairs( xgui.svmodules ) do if v.postinit then v.postinit() end end

	--Fix any users who requested data before the server was ready
	for _, ply in pairs( player.GetAll() ) do
		for UID, data in pairs( xgui.activeUsers ) do
			if ply:UniqueID() == UID then
				ULib.clientRPC( ply, "xgui.getChunk", -1, "Initializing..." )
			end
		end
	end
end
hook.Add( ulx.HOOK_ULXDONELOADING, "XGUI_PostInitServer", xgui.postInit, HOOK_MONITOR_LOW )
