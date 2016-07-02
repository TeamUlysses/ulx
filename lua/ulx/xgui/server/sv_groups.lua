--sv_groups -- by Stickly Man!
--Server-side code related to the groups menu.

local groups = {}
function groups.init()
	ULib.ucl.registerAccess( "xgui_managegroups", "superadmin", "Allows managing of groups, users, and access strings via the groups tab in XGUI.", "XGUI" )

	xgui.addDataType( "playermodels", player_manager.AllValidModels, "xgui_managegroups", 0, 10 )
	xgui.addDataType( "teams", function() return xgui.teams end, "xgui_managegroups", 0, -20 )
	xgui.addDataType( "accesses", function() return xgui.accesses end, "xgui_managegroups", 0, 5 )
	xgui.addDataType( "users", 	function()
									local temp = groups.garryUsers
									table.Merge( temp, ULib.ucl.users )
									return temp
								end, "xgui_managegroups", 20, -10 )

	function groups.setInheritance( ply, args )
		if ULib.ucl.query( ply, "ulx addgroup" ) then
			--Check for cycles
			local group = ULib.ucl.groupInheritsFrom( args[2] )
			while group do
				if group == args[1] or args[1] == args[2] then
					ULib.clientRPC( ply, "Derma_Message", "Cannot set inheritance! You cannot inherit from something you're inheriting to!", "XGUI NOTICE" )
					return
				end
				group = ULib.ucl.groupInheritsFrom( group )
			end
			ULib.ucl.setGroupInheritance( args[1], args[2] )
		end
	end
	xgui.addCmd( "setinheritance", groups.setInheritance )

	function xgui.playerExistsByID( id )
		for k, v in pairs( player.GetAll() ) do
			if v:SteamID() == id or v:UniqueID() == id or ULib.splitPort( v:IPAddress() ) == id then
				return v
			end
		end
		return false
	end

	--Override adduser to (re)send the new user info to the players.
	local tempfuncadd = ULib.ucl.addUser
	ULib.ucl.addUser = function( id, allows, denies, group )
		local affectedply = xgui.playerExistsByID( id )
		if affectedply then groups.resetAllPlayerValues( affectedply ) end
		tempfuncadd( id, allows, denies, group )
		local temp = {}
		temp[id] = ULib.ucl.users[id]
		xgui.updateData( {}, "users", temp )
	end

	--Override removeuser to resend the users table to the players.
	local tempfuncremove = ULib.ucl.removeUser
	ULib.ucl.removeUser = function( id )
		xgui.removeData( {}, "users", { id } )
		local affectedply = xgui.playerExistsByID( id )
		if affectedply then groups.resetAllPlayerValues( affectedply ) end
		tempfuncremove( id )
	end

	---------------------------
	--UTeam Integration Stuff--
	---------------------------
	function groups.createTeam( ply, args )
		if ULib.ucl.query( ply, "xgui_managegroups" ) then
			--Check and make sure the team doesn't exist first
			local exists = false
			for i, v in ipairs( xgui.teams ) do
				if v.name == args[1] then
					exists = true
				end
			end
			if not exists then
				local team = {}
				team.name = args[1]
				team.color = Color( args[2], args[3], args[4], 255 )
				team.order = #xgui.teams+1
				team.groups = {}
				table.insert( xgui.teams, team )
				groups.refreshTeams()
			end
		end
	end
	xgui.addCmd( "createTeam", groups.createTeam )

	function groups.removeTeam( ply, args )
		if ULib.ucl.query( ply, "xgui_managegroups" ) then
			for i, v in ipairs( xgui.teams ) do
				if v.name == args[1] then
					for _,group in ipairs( v.groups ) do --Unassign groups in team being deleted
						groups.doChangeGroupTeam( group, "" )
					end
					table.remove( xgui.teams, i )
					groups.setTeamsOrder()
					groups.refreshTeams()
					break
				end
			end
		end
	end
	xgui.addCmd( "removeTeam", groups.removeTeam )

	function groups.changeGroupTeam( ply, args, norefresh )
		if ULib.ucl.query( ply, "xgui_managegroups" ) then
			groups.doChangeGroupTeam( args[1], args[2], norefresh )
		end
	end
	xgui.addCmd( "changeGroupTeam", groups.changeGroupTeam )

	function groups.doChangeGroupTeam( group, newteam, norefresh )
		local resettable = {}
		for _,teamdata in ipairs( xgui.teams ) do
			for i,groupname in ipairs( teamdata.groups ) do
				if group == groupname then --Found the previous team the group belonged to, remove it now!
					table.remove( teamdata.groups, i )
					--Grab old modifier info while we're here
					for modifier, _ in pairs( teamdata ) do
						if modifier ~= "order" and modifier ~= "index" and modifier ~= "groups" and modifier ~= "name" and modifier ~= "color" then
							table.insert( resettable, modifier )
						end
					end
					break
				end
			end
			if teamdata.name == newteam then --If the team requested was found, then add it to the new team.
				table.insert( teamdata.groups, group )
			end
		end
		--Reset modifiers for affected players, then let UTeam set the new modifiers
		groups.resetTeamValue( group, resettable, newteam=="" ) --Let the function know if the new team is unassigned
		if not norefresh then groups.refreshTeams() end
	end

	--UTeam Parameters: If values are a table, then it specifies default, min, then max. Otherwise it just specifies a min.
	--Note that the min/max values here are ABSOLUTE values, meaning values outside of this range will probably cause undesirable results.
	xgui.teamDefaults = {
		armor = { 0, 0, 255 },
		--crouchedWalkSpeed = 0.6, --Pointless setting?
		deaths = { 0, -2048, 2047 },
		duckSpeed = 0.3,
		frags = { 0, -2048, 2047 },
		gravity = 1,
		health = { 100, 1, 2.14748e+009 },
		jumpPower = 200,
		maxHealth = 100,
		--maxSpeed = 250, --Pointless setting?
		model = "scientist",
		runSpeed = { 500, 1, nil },
		stepSize = { 18, 0, 512 },
		unDuckSpeed = 0.2,
		walkSpeed = { 250, 1, nil } }

	function groups.updateTeamValue( ply, args )
		if ULib.ucl.query( ply, "xgui_managegroups" ) then
			local modifier = args[2]
			local value = tonumber( args[3] ) or args[3] --If args[3] is a number, set value as a number.
			for k, v in ipairs( xgui.teams ) do
				if v.name == args[1] then
					if modifier == "color" then
						v.color = { r=tonumber(args[3]), g=tonumber(args[4]), b=tonumber(args[5]), a=255 }
					else
						if value ~= "" then
							--Check for out-of-bound values!
							local def = xgui.teamDefaults[modifier]
							if type(def) == "table" then
								if def[2] and value < def[2] then value = def[2] end
								if def[3] and value > def[3] then value = def[3] end
							end
							v[modifier] = value
						else
							v[modifier] = nil
							--Set the players back to the original value
							for _, group in ipairs( v.groups ) do
								groups.resetTeamValue( group, { args[2] } )
							end
						end
					end
					--Check for order updates, only refresh the teams when args[4] flag is set to prevent multiple data sendings
					if v[modifier] ~= "order" or args[4] == "true" then
						groups.refreshTeams()
					end
					break
				end
			end
		end
	end
	xgui.addCmd( "updateTeamValue", groups.updateTeamValue )

	function groups.refreshTeams()
		if not ulx.uteamEnabled() then return	end --Do not perform any of the following code if UTeam is disabled.

		ulx.teams = table.Copy( xgui.teams )
		ulx.saveTeams() --Let ULX reprocess the teams (Empty/new teams would be lost here)
		ulx.refreshTeams()
		table.sort( xgui.teams, function(a, b) return a.order < b.order end ) --Sort table by order.

		xgui.sendDataTable( {}, "teams" )
		hook.Call( ULib.HOOK_UCLCHANGED )

		--Save any teams that don't have a group assigned to it to a special file. (They'll be removed on changelevel if we don't)
		local emptyteams = {}
		for _, teamdata in ipairs( xgui.teams ) do
			if #teamdata.groups == 0 then
				table.insert( emptyteams, teamdata )
			end
		end
		if #emptyteams > 0 then
			local output = "//This file stores teams that do not have any groups assigned to it (Since ULX would discard them). Do not edit this file!\n"
			output = output .. ULib.makeKeyValues( emptyteams )
			ULib.fileWrite( "data/ulx/empty_teams.txt", output )
		else
			if ULib.fileExists( "data/ulx/empty_teams.txt" ) then
				ULib.fileDelete( "data/ulx/empty_teams.txt" )
			end
		end
	end

	function groups.resetPlayerValue( ply, values )
		for _, modifier in ipairs( values ) do
			--Code from UTeam
			local defaultvalue = xgui.teamDefaults[modifier]
			if type( defaultvalue ) == "table" then defaultvalue = xgui.teamDefaults[modifier][1] end
			ply[ "Set" .. modifier:sub( 1, 1 ):upper() .. modifier:sub( 2 ) ]( ply, defaultvalue )
		end
	end

	--This function will locate all players affected by team modifier(s) being unset (or team being changed)
	--and will reset any related modifiers to their defaults.
	function groups.resetTeamValue( group, values, teamIsUnassigned )
		for _, ply in ipairs( player.GetAll() ) do
			if ply:GetUserGroup() == group then
				groups.resetPlayerValue( ply, values )
				if teamIsUnassigned then ply:SetTeam(1001) end --Force the player to the unassigned team
			end
		end
	end

	--Remove all UTeam values from a player (used when they change teams)
	function groups.resetAllPlayerValues( ply )
		for _, team in ipairs( ulx.teams ) do				--Loop through each team
			if team.groups == nil then break end
			for _, group in ipairs( team.groups ) do		--Loop through each group per team
				if group == ply:GetUserGroup() then			--Have we found our team associated with this players group?
					local resettable = {}
					for modifier, _ in pairs( team ) do 	--Good! Now go reset the UTeam params based on the current team.
						if modifier ~= "order" and modifier ~= "index" and modifier ~= "groups" and modifier ~= "name" and modifier ~= "color" then
							table.insert( resettable, modifier )
						end
					end
					groups.resetPlayerValue( ply, resettable )
					break
				end
			end
		end
	end

	--Check and make sure the teams have a specified order
	function groups.setTeamsOrder()
		for i, v in ipairs( xgui.teams ) do
			v.order = i --Assign based on their index, which should be in order set by the file
		end
	end

	--Hijack the renameGroup and removeGroup ULib functions to properly update team information when these are called.
	local tempfunc = ULib.ucl.renameGroup
	ULib.ucl.renameGroup = function( orig, new )
		for _, teamdata in ipairs( xgui.teams ) do
			for i, groupname in ipairs( teamdata.groups ) do
				if groupname == orig then
					teamdata.groups[i] = new
				end
				break
			end
		end
		tempfunc( orig, new )
		groups.refreshTeams()
	end

	local otherfunc = ULib.ucl.removeGroup
	ULib.ucl.removeGroup = function( name )
		groups.doChangeGroupTeam( name, "", true )
		otherfunc( name )
		groups.refreshTeams()
		xgui.sendDataTable( {}, "users" ) --Resend user information in case users were bumped to another group.
	end
end

function groups.postinit()
	--Get user information from Garry's users.txt
	groups.garryUsers = {}
	if ULib.fileExists( "settings/users.txt" ) then
		local t = ULib.parseKeyValues( ULib.stripComments( ULib.fileRead( "settings/users.txt", true ), "//" ) ) or {}
		for group, users in pairs ( t ) do
			for user, steamID in pairs( users ) do
				groups.garryUsers[steamID] = { name=user, group=group }
			end
		end
	end

	--Combine access data into one table.
	xgui.accesses = {}
	for k, v in pairs( ULib.ucl.accessStrings ) do
		xgui.accesses[k] = {}
		xgui.accesses[k].hStr = v
	end
	for k, v in pairs( ULib.ucl.accessCategories ) do
		xgui.accesses[k].cat = v
	end

	---------------------------
	--UTeam Integration Stuff--
	---------------------------
	--Duplicate ULX's UTeam table (required for how Megiddo stores team data within the groups data)
	xgui.teams = table.Copy( ulx.teams )

	--Load empty teams saved by XGUI (if any)
	if ULib.fileExists( "data/ulx/empty_teams.txt" ) then
		local input = ULib.fileRead( "data/ulx/empty_teams.txt" )
		input = input:match( "^.-\n(.*)$" )
		local emptyteams = ULib.parseKeyValues( input )
		for _, teamdata in ipairs( emptyteams ) do
			for k,v in pairs( teamdata ) do
				teamdata[k] = tonumber( teamdata[k] ) or teamdata[k] --Ensure any number values are read as numbers and not strings
			end
			table.insert( xgui.teams, teamdata.order, teamdata )
		end
	end

	groups.setTeamsOrder()

	--Uteam doesn't load the shortname for playermodels, so to make it easier for the GUI, check for model paths and see if we can use a shortname instead.
	for _, v in ipairs( xgui.teams ) do
		if v.model then
			for shortname,modelpath in pairs( player_manager.AllValidModels() ) do
				if v.model == modelpath then v.model = shortname break end
			end
		end
	end

end
xgui.addSVModule( "groups", groups.init, groups.postinit )
