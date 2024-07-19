--sv_bans -- by Stickly Man!
--Server-side code related to the bans menu.

local bans={}
function bans.init()
	ULib.ucl.registerAccess( "xgui_managebans", "superadmin", "Allows addition, removal, and viewing of bans in XGUI.", "XGUI" )

	xgui.addDataType( "bans", function() return { count=table.Count( ULib.bans ) } end, "xgui_managebans", 30, 20 )

	--Chat commands
	local function xgui_banWindowChat( ply, func, args, doFreeze )
		if doFreeze ~= true then doFreeze = false end
		if args[1] and args[1] ~= "" then
			local target = ULib.getUser( args[1] )
			if target then
				ULib.clientRPC( ply, "xgui.ShowBanWindow", target, target:SteamID(), doFreeze )
			end
		else
			ULib.clientRPC( ply, "xgui.ShowBanWindow" )
		end
	end
	ULib.addSayCommand( "!xban", xgui_banWindowChat, "ulx ban" )

	local function xgui_banWindowChatFreeze( ply, func, args )
		xgui_banWindowChat( ply, func, args, true )
	end
	ULib.addSayCommand( "!fban", xgui_banWindowChatFreeze, "ulx ban" )

	--XGUI commands
	function bans.updateBan( ply, args )
		local access, accessTag = ULib.ucl.query( ply, "ulx ban" )
		if not access then
			ULib.tsayError( ply, "Error editing ban: You must have access to ulx ban, " .. ply:Nick() .. "!", true )
			return
		end

		local steamID = args[1] or ""
		local bantime = tonumber( args[2] )
		local reason = args[3]
		local name = args[4]

		-- Check steamid
		if not ULib.isValidSteamID(steamID) then
			ULib.tsayError( ply, "Invalid steamid", true )
			return
		end

		-- Check restrictions
		local cmd = ULib.cmds.translatedCmds[ "ulx ban" ]
		local accessPieces = {}
		if accessTag then
			accessPieces = ULib.splitArgs( accessTag, "<", ">" )
		end

		-- Ban length
		local argInfo = cmd.args[3]
		local success, err = argInfo.type:parseAndValidate( ply, bantime, argInfo, accessPieces[2] )
		if not success then
			ULib.tsayError( ply, "Error editing ban: " .. err, true )
			return
		end

		-- Reason
		local argInfo = cmd.args[4]
		local success, err = argInfo.type:parseAndValidate( ply, reason, argInfo, accessPieces[3] )
		if not success then
			ULib.tsayError( ply, "Error editing ban: You did not specify a valid reason, " .. ply:Nick() .. "!", true )
			return
		end


		if not ULib.bans[steamID] then
			ULib.addBan( steamID, bantime, reason, name, ply )
			return
		end

		if name == "" then
			name = nil
			ULib.bans[steamID].name = nil
		end

		if bantime ~= 0 then
			if (ULib.bans[steamID].time + bantime*60) <= os.time() then --New ban time makes the ban expired
				ULib.unban( steamID, ply )
				return
			end
			bantime = bantime - (os.time() - ULib.bans[steamID].time)/60
		end
		ULib.addBan( steamID, bantime, reason, name, ply )
	end
	xgui.addCmd( "updateBan", bans.updateBan )

	--Misc functions
	function bans.processBans()
		bans.clearSortCache()
		xgui.sendDataTable( {}, "bans" )	--Only sends the ban count, and triggers the client to clear their cache.
	end

	function bans.clearSortCache()
		xgui.bansbyid = {}
		xgui.bansbyname = {}
		xgui.bansbyadmin = {}
		xgui.bansbyreason = {}
		xgui.bansbydate = {}
		xgui.bansbyunban = {}
		xgui.bansbybanlength = {}
	end

	local sortTypeTable = {
		[1] = function()
			-- Bans by Name
			if next( xgui.bansbyname ) == nil then
				for k, v in pairs( ULib.bans ) do
					table.insert( xgui.bansbyname, { k, v.name and string.upper( v.name ) or nil } )
				end
				table.sort( xgui.bansbyname, function( a, b ) return (a[2] or "\255" .. a[1]) < (b[2] or "\255" .. b[1]) end )
			end
			return xgui.bansbyname

		end,
		[2] = function()
			-- Bans by SteamID
			if next( xgui.bansbyid ) == nil then
				for k, v in pairs( ULib.bans ) do
					table.insert( xgui.bansbyid, { k } )
				end
				table.sort( xgui.bansbyid, function( a, b ) return a[1] < b[1] end )
			end
			return xgui.bansbyid

		end,
		[3] = function()
			-- Bans by Admin
			if next( xgui.bansbyadmin ) == nil then
				for k, v in pairs( ULib.bans ) do
					table.insert( xgui.bansbyadmin, { k, v.admin or "" } )
				end
				table.sort( xgui.bansbyadmin, function( a, b ) return a[2] < b[2] end )
			end
			return xgui.bansbyadmin

		end,
		[4] = function()
			-- Bans by Reason
			if next( xgui.bansbyreason ) == nil then
				for k, v in pairs( ULib.bans ) do
					table.insert( xgui.bansbyreason, { k, v.reason or "" } )
				end
				table.sort( xgui.bansbyreason, function( a, b ) return a[2] < b[2] end )
			end
			return xgui.bansbyreason

		end,
		[5] = function()
			-- Bans by Unban Date
			if next( xgui.bansbyunban ) == nil then
				for k, v in pairs( ULib.bans ) do
					table.insert( xgui.bansbyunban, { k, tonumber(v.unban) or 0 } )
				end
				table.sort( xgui.bansbyunban, function( a, b ) return a[2] < b[2] end )
			end
			return xgui.bansbyunban

		end,
		[6] = function()
			-- Bans by Ban Length
			if next( xgui.bansbybanlength ) == nil then
				for k, v in pairs( ULib.bans ) do
					table.insert( xgui.bansbybanlength, { k, (tonumber(v.unban) ~= 0) and (v.unban - v.time) or nil } )
				end
				table.sort( xgui.bansbybanlength, function( a, b ) return (a[2] or math.huge) < (b[2] or math.huge) end )
			end
			return xgui.bansbybanlength

		end,
		[7] = function()
			-- Bans by Ban Date
			if next( xgui.bansbydate ) == nil then
				for k, v in pairs( ULib.bans ) do
					table.insert( xgui.bansbydate, { k, v.time or 0 } )
				end
				table.sort( xgui.bansbydate, function( a, b ) return tonumber( a[2] ) > tonumber( b[2] ) end )
			end
			return xgui.bansbydate
		end,
	}
	function bans.getSortTable( sortType )
		-- Retrieve the sorted table of bans. If type hasn't been sorted, then sort and cache.
		local value = sortTypeTable[sortType] and sortTypeTable[sortType]() or sortTypeTable[7]()
		return value
	end

	function bans.sendBansToUser( ply, args )
		if not ply then return end

		if not ULib.ucl.query( ply, "xgui_managebans" ) then return end

		--local perfTimer = os.clock() --Debug

		-- Default params
		sortType = tonumber( args[1] ) or 0
		filterString = (args[2] ~= "" and args[2] ~= nil) and string.lower( args[2] ) or nil
		filterPermaBan = args[3] and tonumber( args[3] ) or 0
		filterIncomplete = args[4] and tonumber( args[4] ) or 0
		page = tonumber( args[5] ) or 1
		ascending = tonumber( args[6] ) == 1 or false

		-- Get cached sort table to use to reference the real data.
		sortTable = bans.getSortTable( sortType )

		local bansToSend = {}

		-- Handle ascending or descending
		local startValue = ascending and #sortTable or 1
		local endValue = ascending and 1 or #sortTable
		local firstEntry = (page - 1) * 17
		local currentEntry = 0

		local noFilter = ( filterPermaBan == 0 and filterIncomplete == 0 and filterString == nil )

		for i = startValue, endValue, ascending and -1 or 1 do
			local steamID = sortTable[i][1]
			local bandata = ULib.bans[steamID]

			-- Handle filters. This is confusing, but essentially 0 means skip check, 1 means restrict if condition IS true, 2+ means restrict if condition IS NOT true.
			if not ( filterPermaBan > 0 and ( ( tonumber( bandata.unban ) == 0 ) == ( filterPermaBan == 1 ) ) ) then
				if not ( filterIncomplete > 0 and ( ( bandata.time == nil ) == ( filterIncomplete == 1 ) ) ) then

					-- Handle string filter
					if not ( filterString and
						not ( steamID and string.find( string.lower( steamID ), filterString ) or
							bandata.name and string.find( string.lower( bandata.name ), filterString ) or
							bandata.reason and string.find( string.lower( bandata.reason ), filterString ) or
							bandata.admin and string.find( string.lower( bandata.admin ), filterString ) or
							bandata.modified_admin and string.find( string.lower( bandata.modified_admin ), filterString ) )) then

						--We found a valid one! .. Now for the pagination.
						if #bansToSend < 17 and currentEntry >= firstEntry then
							table.insert( bansToSend, bandata )
							bansToSend[#bansToSend].steamID = steamID
							if noFilter and #bansToSend >= 17 then break end	-- If there is a filter, then don't stop the loop so we can get a "result" count.
						end
						currentEntry = currentEntry + 1
					end
				end
			end
		end
		if not noFilter then bansToSend.count = currentEntry end

		--print( "XGUI: Ban request took " .. os.clock() - perfTimer ) --Debug

		-- Send bans to client via custom handling.
		xgui.sendDataEvent( ply, 7, "bans", bansToSend )
	end
	xgui.addCmd( "getbans", bans.sendBansToUser )

	--Hijack the addBan function to update XGUI's ban info.
	local banfunc = ULib.addBan
	ULib.addBan = function( steamid, time, reason, name, admin )
		banfunc( steamid, time, reason, name, admin )
		bans.processBans()
		bans.unbanTimer()
	end

	--Hijack the unBan function to update XGUI's ban info.
	local unbanfunc = ULib.unban
	ULib.unban = function( steamid, admin )
		unbanfunc( steamid, admin )
		bans.processBans()
		if timer.Exists( "xgui_unban" .. steamid ) then
			timer.Remove( "xgui_unban" .. steamid )
		end
	end

	--Create timers that will automatically perform an unban when a users ban runs out. Polls hourly.
	function bans.unbanTimer()
		timer.Create( "xgui_unbanTimer", 3600, 0, bans.unbanTimer )
		for ID, data in pairs( ULib.bans ) do
			if tonumber( data.unban ) ~= 0 then
				if tonumber( data.unban ) - os.time() <= 3600 then
					timer.Remove( "xgui_unban" .. ID )
					timer.Create( "xgui_unban" .. ID, tonumber( data.unban ) - os.time(), 1, function() ULib.unban( ID ) end )
				end
			end
		end
	end

	ulx.addToHelpManually( "Menus", "xgui fban", "<player> - Opens the add ban window, freezes the specified player, and fills out the Name/SteamID automatically. (say: !fban)" )
	ulx.addToHelpManually( "Menus", "xgui xban", "<player> - Opens the add ban window and fills out Name/SteamID automatically if a player was specified. (say: !xban)" )
end

function bans.postinit()
	bans.processBans()
	bans.unbanTimer()
end

xgui.addSVModule( "bans", bans.init, bans.postinit )
