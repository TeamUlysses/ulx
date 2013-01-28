--sv_bans -- by Stickly Man!
--Server-side code related to the bans menu.

local bans={}
function bans.init()
	ULib.ucl.registerAccess( "xgui_managebans", "superadmin", "Allows addition, removal, and viewing of bans in XGUI.", "XGUI" )
	
	xgui.addDataType( "bans", function() return xgui.ulxbans end, "xgui_managebans", 30, 20 )
	xgui.addDataType( "sbans", function() return xgui.sourcebans end, "xgui_managebans", 60, 20 )
	
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
	ULib.addSayCommand(	"!xban", xgui_banWindowChat, "ulx ban" )

	local function xgui_banWindowChatFreeze( ply, func, args )
		xgui_banWindowChat( ply, func, args, true )
	end
	ULib.addSayCommand(	"!fban", xgui_banWindowChatFreeze, "ulx ban" )
	
	--XGUI commands
	function bans.updateBan( ply, args )
		if ULib.ucl.query( ply, "ulx ban" ) or ULib.ucl.query( ply, "ulx banid" ) then
			local steamID = args[1]
			local bantime = tonumber( args[2] )
			
			if not ULib.bans[steamID] then 
				ULib.addBan( steamID, bantime, args[3], args[4], ply )
				return
			end
			local reason = args[3]
			local name = args[4]
			if name == "" then 
				name = nil
				ULib.bans[steamID].name = nil
			end
			
			if not ULib.bans[steamID].time then --Is an sban conversion
				ULib.bans[ steamID ] = nil
				ULib.addBan( steamID, bantime, reason, name, ply )
				xgui.removeData( {}, "sbans", { steamID } )
				return
			end
			if bantime ~= 0 then
				if (ULib.bans[steamID].time + bantime*60) <= os.time() then --New ban time makes the ban expired
					ULib.unban( steamID )
					return
				end
				bantime = bantime - (os.time() - ULib.bans[steamID].time)/60
			end
			ULib.addBan( steamID, bantime, reason, name, ply )
		end
	end
	xgui.addCmd( "updateBan", bans.updateBan )
	
	--Misc functions
	function bans.splitbans()
		xgui.sourcebans = {}
		xgui.ulxbans = {}
		for k, v in pairs( ULib.bans ) do
			if v.time == nil then
				xgui.sourcebans[k] = v
			else
				xgui.ulxbans[k] = v
			end
		end
	end
	
	--Hijack the addBan function to send new ban information to players.
	local banfunc = ULib.addBan
	ULib.addBan = function( steamid, time, reason, name, admin )
		banfunc( steamid, time, reason, name, admin )
		bans.splitbans()
		bans.unbanTimer()
		local t = {}
		t[steamid] = ULib.bans[steamid]
		xgui.addData( {}, "bans", t )
	end
	
	--Hijack the unBan function to update player ban info
	local unbanfunc = ULib.unban
	ULib.unban = function( steamid, admin )
		unbanfunc( steamid, admin )
		bans.splitbans()
		if timer.Exists( "xgui_unban" .. steamid ) then
			timer.Destroy( "xgui_unban" .. steamid )
		end
		xgui.removeData( {}, "bans", { steamid } )
	end
	
	--Create timers that will automatically refresh clent's banlists when a users ban runs out. Polls hourly.
	function bans.unbanTimer()
		timer.Create( "xgui_unbanTimer", 3600, 0, bans.unbanTimer )
		for ID, data in pairs( xgui.ulxbans ) do
			if tonumber( data.unban ) ~= 0 then
				if tonumber( data.unban ) - os.time() <= 3600 then
					timer.Destroy( "xgui_unban" .. ID )
					timer.Create( "xgui_unban" .. ID, tonumber( data.unban ) - os.time(), 1, function() ULib.unban( ID ) end )
				end
			end
		end
	end
	
	ulx.addToHelpManually( "Menus", "xgui fban", "<player> - Opens the add ban window, freezes the specified player, and fills out the Name/SteamID automatically. (say: !fban)" )
	ulx.addToHelpManually( "Menus", "xgui xban", "<player> - Opens the add ban window and fills out Name/SteamID automatically if a player was specified. (say: !xban)" )
end

function bans.postinit()
	bans.splitbans()
	bans.unbanTimer()
end

xgui.addSVModule( "bans", bans.init, bans.postinit )