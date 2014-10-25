--[[
	Title: UCL

	ULib's Access Control List
]]

local ucl = ULib.ucl -- Make it easier for us to refer to

local accessStrings = ULib.parseKeyValues( ULib.fileRead( ULib.UCL_REGISTERED ) or "" ) or {}
local accessCategories = {}
ULib.ucl.accessStrings = accessStrings
ULib.ucl.accessCategories = accessCategories

-- Helper function to save access string registration to misc_registered.txt
local function saveAccessStringRegistration()
	ULib.fileWrite( ULib.UCL_REGISTERED, ULib.makeKeyValues( accessStrings ) )
end

-- Save what we've got with ucl.groups so far!
function ucl.saveGroups()
	for _, groupInfo in pairs( ucl.groups ) do
		table.sort( groupInfo.allow )
	end

	ULib.fileWrite( ULib.UCL_GROUPS, ULib.makeKeyValues( ucl.groups ) )
end

function ucl.saveUsers()
	for _, userInfo in pairs( ucl.users ) do
		table.sort( userInfo.allow )
		table.sort( userInfo.deny )
	end

	ULib.fileWrite( ULib.UCL_USERS, ULib.makeKeyValues( ucl.users ) )
end

local function reloadGroups()
	local needsBackup = false
	local err
	ucl.groups, err = ULib.parseKeyValues( ULib.removeCommentHeader( ULib.fileRead( ULib.UCL_GROUPS ), "/" ) )

	if not ucl.groups or not ucl.groups[ ULib.ACCESS_ALL ] then
		needsBackup = true
		-- Totally messed up! Clear it.
		local f = "addons/ulib/" .. ULib.UCL_GROUPS
		if not ULib.fileExists( f ) then
			Msg( "ULIB PANIC: groups.txt is corrupted and I can't find the default groups.txt file!!\n" )
		else
			local err2
			ucl.groups, err2 = ULib.parseKeyValues( ULib.removeCommentHeader( ULib.fileRead( f ), "/" ) )
			if not ucl.groups or not ucl.groups[ ULib.ACCESS_ALL ] then
				Msg( "ULIB PANIC: default groups.txt is corrupt!\n" )
				err = err2
			end
		end
		if ULib.fileExists( ULib.UCL_REGISTERED ) then
			ULib.fileDelete( ULib.UCL_REGISTERED ) -- Since we're regnerating we'll need to remove this
		end
		accessStrings = {}

	else
		-- Check to make sure it passes a basic validity test
		ucl.groups[ ULib.ACCESS_ALL ].inherit_from = nil -- Ensure this is the case
		for groupName, groupInfo in pairs( ucl.groups ) do
			if type( groupName ) ~= "string" then
				needsBackup = true
				ucl.groups[ groupName ] = nil
			else

				if type( groupInfo ) ~= "table" then
					needsBackup = true
					groupInfo = {}
					ucl.groups[ groupName ] = groupInfo
				end

				if type( groupInfo.allow ) ~= "table" then
					needsBackup = true
					groupInfo.allow = {}
				end

				local inherit_from = groupInfo.inherit_from
				if inherit_from and inherit_from ~= "" and not ucl.groups[ groupInfo.inherit_from ] then
					needsBackup = true
					groupInfo.inherit_from = nil
				end

				-- Check for cycles
				local group = ucl.groupInheritsFrom( groupName )
				while group do
					if group == groupName then
						needsBackup = true
						groupInfo.inherit_from = nil
					end
					group = ucl.groupInheritsFrom( group )
				end

				if groupName ~= ULib.ACCESS_ALL and not groupInfo.inherit_from or groupInfo.inherit_from == "" then
					groupInfo.inherit_from = ULib.ACCESS_ALL -- Clean :)
				end

				-- Lower case'ify
				for k, v in pairs( groupInfo.allow ) do
					if type( k ) == "string" and k:lower() ~= k then
						groupInfo.allow[ k:lower() ] = v
						groupInfo.allow[ k ] = nil
					else
						groupInfo.allow[ k ] = v
					end
				end
			end
		end
	end

	if needsBackup then
		Msg( "Groups file was not formatted correctly. Attempting to fix and backing up original\n" )
		if err then
			Msg( "Error while reading groups file was: " .. err .. "\n" )
		end
		Msg( "Original file was backed up to " .. ULib.backupFile( ULib.UCL_GROUPS ) .. "\n" )
		ucl.saveGroups()
	end
end
reloadGroups()

local function reloadUsers()
	local needsBackup = false
	local err
	ucl.users, err = ULib.parseKeyValues( ULib.removeCommentHeader( ULib.fileRead( ULib.UCL_USERS ), "/" ) )

	-- Check to make sure it passes a basic validity test
	if not ucl.users then
		needsBackup = true
		-- Totally messed up! Clear it.
		local f = "addons/ulib/" .. ULib.UCL_USERS
		if not ULib.fileExists( f ) then
			Msg( "ULIB PANIC: users.txt is corrupted and I can't find the default users.txt file!!\n" )
		else
			local err2
			ucl.users, err2 = ULib.parseKeyValues( ULib.removeCommentHeader( ULib.fileRead( f ), "/" ) )
			if not ucl.users then
				Msg( "ULIB PANIC: default users.txt is corrupt!\n" )
				err = err2
			end
		end
		if ULib.fileExists( ULib.UCL_REGISTERED ) then
			ULib.fileDelete( ULib.UCL_REGISTERED ) -- Since we're regnerating we'll need to remove this
		end
		accessStrings = {}

	else
		for id, userInfo in pairs( ucl.users ) do
			if type( id ) ~= "string" then
				needsBackup = true
				ucl.users[ id ] = nil
			else

				if type( userInfo ) ~= "table" then
					needsBackup = true
					userInfo = {}
					ucl.users[ id ] = userInfo
				end

				if type( userInfo.allow ) ~= "table" then
					needsBackup = true
					userInfo.allow = {}
				end

				if type( userInfo.deny ) ~= "table" then
					needsBackup = true
					userInfo.deny = {}
				end

				if userInfo.group and type( userInfo.group ) ~= "string" then
					needsBackup = true
					userInfo.group = nil
				end

				if userInfo.name and type( userInfo.name ) ~= "string" then
					needsBackup = true
					userInfo.name = nil
				end

				if userInfo.group == "" then userInfo.group = nil end -- Clean :)

				-- Lower case'ify
				for k, v in pairs( userInfo.allow ) do
					if type( k ) == "string" and k:lower() ~= k then
						userInfo.allow[ k:lower() ] = v
						userInfo.allow[ k ] = nil
					else
						userInfo.allow[ k ] = v
					end
				end

				for k, v in ipairs( userInfo.deny ) do
					if type( k ) == "string" and type( v ) == "string" then -- This isn't allowed here
						table.insert( userInfo.deny, k )
						userInfo.deny[ k ] = nil
					else
						userInfo.deny[ k ] = v
					end
				end
			end
		end
	end

	if needsBackup then
		Msg( "Users file was not formatted correctly. Attempting to fix and backing up original\n" )
		if err then
			Msg( "Error while reading groups file was: " .. err .. "\n" )
		end
		Msg( "Original file was backed up to " .. ULib.backupFile( ULib.UCL_USERS ) .. "\n" )
		ucl.saveUsers()
	end
end
reloadUsers()


--[[
	Function: ucl.addGroup

	Adds a new group to the UCL. Automatically saves.

	Parameters:

		name - A string of the group name. (IE: superadmin)
		allows - *(Optional, defaults to empty table)* The allowed access for the group.
		inherit_from - *(Optional)* A string of a valid group to inherit from

	Revisions:

		v2.10 - acl is now an options parameter, added inherit_from.
		v2.40 - Rewrite, changed parameter list around.
]]
function ucl.addGroup( name, allows, inherit_from )
	ULib.checkArg( 1, "ULib.ucl.addGroup", "string", name )
	ULib.checkArg( 2, "ULib.ucl.addGroup", {"nil","table"}, allows )
	ULib.checkArg( 3, "ULib.ucl.addGroup", {"nil","string"}, inherit_from )
	allows = allows or {}
	inherit_from = inherit_from or "user"

	if ucl.groups[ name ] then return error( "Group already exists, cannot add again (" .. name .. ")", 2 ) end
	if inherit_from then
		if inherit_from == name then return error( "Group cannot inherit from itself", 2 ) end
		if not ucl.groups[ inherit_from ] then return error( "Invalid group for inheritance (" .. tostring( inherit_from ) .. ")", 2 ) end
	end

	-- Lower case'ify
	for k, v in ipairs( allows ) do allows[ k ] = v:lower() end

	ucl.groups[ name ] = { allow=allows, inherit_from=inherit_from }
	ucl.saveGroups()

	hook.Call( ULib.HOOK_UCLCHANGED )
end


--[[
	Function: ucl.groupAllow

	Adds or removes an access tag in the allows for a group. Automatically reprobes, automatically saves.

	Parameters:

		name - A string of the group name. (IE: superadmin)
		access - The string of the access or a table of accesses to add or remove. Access tags can be specified in values in the table for allows.
		revoke - *(Optional, defaults to false)* A boolean of whether access should be granted or revoked.

	Returns:

		A boolean stating whether you changed anything or not.

	Revisions:

		v2.40 - Initial.
]]
function ucl.groupAllow( name, access, revoke )
	ULib.checkArg( 1, "ULib.ucl.groupAllow", "string", name )
	ULib.checkArg( 2, "ULib.ucl.groupAllow", {"string","table"}, access )
	ULib.checkArg( 3, "ULib.ucl.groupAllow", {"nil","boolean"}, revoke )

	if type( access ) == "string" then access = { access } end
	if not ucl.groups[ name ] then return error( "Group does not exist for changing access (" .. name .. ")", 2 ) end

	local allow = ucl.groups[ name ].allow

	local changed = false
	for k, v in pairs( access ) do
		local access = v:lower()
		local accesstag
		if type( k ) == "string" then
			accesstag = v
			access = k:lower()
		end

		if not revoke and (allow[ access ] ~= accesstag or (not accesstag and not ULib.findInTable( allow, access ))) then
			changed = true
			if not accesstag then
				table.insert( allow, access )
				allow[ access ] = nil -- Ensure no access tag
			else
				allow[ access ] = accesstag
				if ULib.findInTable( allow, access ) then -- Ensure removal of non-access tag version
					table.remove( allow, ULib.findInTable( allow, access ) )
				end
			end
		elseif revoke and (allow[ access ] or ULib.findInTable( allow, access )) then
			changed = true

			allow[ access ] = nil -- Remove any accessTags
			if ULib.findInTable( allow, access ) then
				table.remove( allow, ULib.findInTable( allow, access ) )
			end
		end
	end

	if changed then
		for id, userInfo in pairs( ucl.authed ) do
			local ply = ULib.getPlyByID( id )
			if ply and ply:CheckGroup( name ) then
				ULib.queueFunctionCall( hook.Call, ULib.HOOK_UCLAUTH, _, ply ) -- Inform the masses
			end
		end

		ucl.saveGroups()

		hook.Call( ULib.HOOK_UCLCHANGED )
	end

	return changed
end


--[[
	Function: ucl.renameGroup

	Renames a group in the UCL. Automatically moves current members, automatically renames inheritances, automatically saves.

	Parameters:

		orig - A string of the original group name. (IE: superadmin)
		new - A string of the new group name. (IE: owner)

	Revisions:

		v2.40 - Initial.
]]
function ucl.renameGroup( orig, new )
	ULib.checkArg( 1, "ULib.ucl.renameGroup", "string", orig )
	ULib.checkArg( 2, "ULib.ucl.renameGroup", "string", new )

	if orig == ULib.ACCESS_ALL then return error( "This group (" .. orig .. ") cannot be renamed!", 2 ) end
	if not ucl.groups[ orig ] then return error( "Group does not exist for renaming (" .. orig .. ")", 2 ) end
	if ucl.groups[ new ] then return error( "Group already exists, cannot rename (" .. new .. ")", 2 ) end

	for id, userInfo in pairs( ucl.users ) do
		if userInfo.group == orig then
			userInfo.group = new
		end
	end

	for id, userInfo in pairs( ucl.authed ) do
		local ply = ULib.getPlyByID( id )
		if ply and ply:CheckGroup( orig ) then
			if ply:GetUserGroup() == orig then
				ULib.queueFunctionCall( ply.SetUserGroup, ply, new ) -- Queued so group will be removed
			else
				ULib.queueFunctionCall( hook.Call, ULib.HOOK_UCLAUTH, _, ply ) -- Inform the masses
			end
		end
	end

	ucl.groups[ new ] = ucl.groups[ orig ] -- Copy!
	ucl.groups[ orig ] = nil

	for _, groupInfo in pairs( ucl.groups ) do
		if groupInfo.inherit_from == orig then
			groupInfo.inherit_from = new
		end
	end

	ucl.saveUsers()
	ucl.saveGroups()

	hook.Call( ULib.HOOK_UCLCHANGED )
end


--[[
	Function: ucl.setGroupInheritance

	Sets a group's inheritance in the UCL. Automatically reprobes current members, automatically saves.

	Parameters:

		group - A string of the group name. (IE: superadmin)
		inherit_from - Either a string of the new inheritance group name or nil to remove inheritance. (IE: admin)

	Revisions:

		v2.40 - Initial.
]]
function ucl.setGroupInheritance( group, inherit_from )
	ULib.checkArg( 1, "ULib.ucl.renameGroup", "string", group )
	ULib.checkArg( 2, "ULib.ucl.renameGroup", {"nil","string"}, inherit_from )
	if inherit_from then
		if inherit_from == ULib.ACCESS_ALL then inherit_from = nil end -- Implicitly inherited
	end

	if group == ULib.ACCESS_ALL then return error( "This group (" .. group .. ") cannot have it's inheritance changed!", 2 ) end
	if not ucl.groups[ group ] then return error( "Group does not exist (" .. group .. ")", 2 ) end
	if inherit_from and not ucl.groups[ inherit_from ] then return error( "Group for inheritance does not exist (" .. inherit_from .. ")", 2 ) end

	-- Check for cycles
	local old_inherit = ucl.groups[ group ].inherit_from
	ucl.groups[ group ].inherit_from = inherit_from -- Temporary!
	local groupCheck = ucl.groupInheritsFrom( group )
	while groupCheck do
		if groupCheck == group then -- Got back to ourselves. This is bad.
			ucl.groups[ group ].inherit_from = old_inherit -- Set it back
			error( "Changing group \"" .. group .. "\" inheritance to \"" .. inherit_from .. "\" would cause cyclical inheritance. Aborting.", 2 )
		end
		groupCheck = ucl.groupInheritsFrom( groupCheck )
	end
	ucl.groups[ group ].inherit_from = old_inherit -- Set it back

	if old_inherit == inherit_from then return end -- Nothing to change

	for id, userInfo in pairs( ucl.authed ) do
		local ply = ULib.getPlyByID( id )
		if ply and ply:CheckGroup( group ) then
			ULib.queueFunctionCall( hook.Call, ULib.HOOK_UCLAUTH, _, ply ) -- Queued so group will be changed
		end
	end

	ucl.groups[ group ].inherit_from = inherit_from

	ucl.saveGroups()

	hook.Call( ULib.HOOK_UCLCHANGED )
end


--[[
	Function: ucl.setGroupCanTarget

	Sets what a group is allowed to target in the UCL. Automatically saves.

	Parameters:

		group - A string of the group name. (IE: superadmin)
		can_target - Either a string of who the group is allowed to target (IE: !%admin) or nil to clear the restriction.

	Revisions:

		v2.40 - Initial.
]]
function ucl.setGroupCanTarget( group, can_target )
	ULib.checkArg( 1, "ULib.ucl.setGroupCanTarget", "string", group )
	ULib.checkArg( 2, "ULib.ucl.setGroupCanTarget", {"nil","string"}, can_target )
	if not ucl.groups[ group ] then return error( "Group does not exist (" .. group .. ")", 2 ) end

	if ucl.groups[ group ].can_target == can_target then return end -- Nothing to change

	ucl.groups[ group ].can_target = can_target

	ucl.saveGroups()

	hook.Call( ULib.HOOK_UCLCHANGED )
end


--[[
	Function: ucl.removeGroup

	Removes a group from the UCL. Automatically removes this group from members in it, automatically patches inheritances, automatically saves.

	Parameters:

		name - A string of the group name. (IE: superadmin)

	Revisions:

		v2.10 - Initial.
		v2.40 - Rewrite, removed write parameter.
]]
function ucl.removeGroup( name )
	ULib.checkArg( 1, "ULib.ucl.removeGroup", "string", name )

	if name == ULib.ACCESS_ALL then return error( "This group (" .. name .. ") cannot be removed!", 2 ) end
	if not ucl.groups[ name ] then return error( "Group does not exist for removing (" .. name .. ")", 2 ) end

	local inherits_from = ucl.groupInheritsFrom( name )
	if inherits_from == ULib.ACCESS_ALL then inherits_from = nil end -- Easier

	for id, userInfo in pairs( ucl.users ) do
		if userInfo.group == name then
			userInfo.group = inherits_from
		end
	end

	for id, userInfo in pairs( ucl.authed ) do
		local ply = ULib.getPlyByID( id )
		if ply and ply:CheckGroup( name ) then
			if ply:GetUserGroup() == name then
				ULib.queueFunctionCall( ply.SetUserGroup, ply, inherits_from or ULib.ACCESS_ALL ) -- Queued so group will be removed
			else
				ULib.queueFunctionCall( hook.Call, ULib.HOOK_UCLAUTH, _, ply ) -- Inform the masses
			end
		end
	end

	ucl.groups[ name ] = nil
	for _, groupInfo in pairs( ucl.groups ) do
		if groupInfo.inherit_from == name then
			groupInfo.inherit_from = inherits_from
		end
	end

	ucl.saveUsers()
	ucl.saveGroups()

	hook.Call( ULib.HOOK_UCLCHANGED )
end

--[[
	Function: ucl.getUserRegisteredID

	Returns the SteamID, IP, or UniqueID of a player if they're registered under any of those IDs under ucl.users. Checks in order. Returns nil if not registered.

	Parameters:

		ply - The player object you wish to check.

	Revisions:

		2.41 - Initial.
]]

function ucl.getUserRegisteredID( ply )
	local id = ply:SteamID()
	local uid = ply:UniqueID()
	local ip = ULib.splitPort( ply:IPAddress() )
	local checkIndexes = { id, ip, uid }
	for _, index in ipairs( checkIndexes ) do
		if ULib.ucl.users[ index ] then
			return id
		end
	end
end

--[[
	Function: ucl.addUser

	Adds a user to the UCL. Automatically probes for the user, automatically saves.

	Parameters:

		id - The SteamID, IP, or UniqueID of the user you wish to add.
		allows - *(Optional, defaults to empty table)* The list of access you wish to give this user.
		denies - *(Optional, defaults to empty table)* The list of access you wish to explicitly deny this user.
		group - *(Optional)* The sting of the group this user should belong to. Must be a valid group.

	Revisions:

		2.10 - No longer makes a group if it doesn't exist.
		2.40 - Rewrite, changed the arguments all around.
]]
function ucl.addUser( id, allows, denies, group )
	ULib.checkArg( 1, "ULib.ucl.addUser", "string", id )
	ULib.checkArg( 2, "ULib.ucl.addUser", {"nil","table"}, allows )
	ULib.checkArg( 3, "ULib.ucl.addUser", {"nil","table"}, denies )
	ULib.checkArg( 4, "ULib.ucl.addUser", {"nil","string"}, group )

	id = id:upper() -- In case of steamid, needs to be upper case
	allows = allows or {}
	denies = denies or {}
	if allows == ULib.DEFAULT_GRANT_ACCESS.allow then allows = table.Copy( allows ) end -- Otherwise we'd be changing all guest access
	if denies == ULib.DEFAULT_GRANT_ACCESS.deny then denies = table.Copy( denies ) end -- Otherwise we'd be changing all guest access
	if group and not ucl.groups[ group ] then return error( "Group does not exist for adding user to (" .. group .. ")", 2 ) end

	-- Lower case'ify
	for k, v in ipairs( allows ) do allows[ k ] = v end
	for k, v in ipairs( denies ) do denies[ k ] = v end

	local name
	if ucl.users[ id ] and ucl.users[ id ].name then name = ucl.users[ id ].name end -- Preserve name
	ucl.users[ id ] = { allow=allows, deny=denies, group=group, name=name }

	ucl.saveUsers()

	local ply = ULib.getPlyByID( id )
	if ply then
		ucl.probe( ply )
	else -- Otherwise this gets called twice
		hook.Call( ULib.HOOK_UCLCHANGED )
	end
end


--[[
	Function: ucl.userAllow

	Adds or removes an access tag in the allows or denies for a user. Automatically reprobes, automatically saves.

	Parameters:

		id - The SteamID, IP, or UniqueID of the user to change. Must be a valid, existing ID, or an ID of a connected player.
		access - The string of the access or a table of accesses to add or remove. Access tags can be specified in values in the table for allows.
		revoke - *(Optional, defaults to false)* A boolean of whether the access tag should be added or removed
			from the allow or deny list. If true, it's removed.
		deny - *(Optional, defaults to false)* If true, the access is added or removed from the deny list,
			if false it's added or removed from the allow list.

	Returns:

		A boolean stating whether you changed anything or not.

	Revisions:

		v2.40 - Initial.
		v2.50 - Relaxed restrictions on id parameter.
		v2.51 - Fixed this function not working on disconnected players.
]]
function ucl.userAllow( id, access, revoke, deny )
	ULib.checkArg( 1, "ULib.ucl.userAllow", "string", id )
	ULib.checkArg( 2, "ULib.ucl.userAllow", {"string","table"}, access )
	ULib.checkArg( 3, "ULib.ucl.userAllow", {"nil","boolean"}, revoke )
	ULib.checkArg( 4, "ULib.ucl.userAllow", {"nil","boolean"}, deny )

	id = id:upper() -- In case of steamid, needs to be upper case
	if type( access ) == "string" then access = { access } end

	local uid = id
	if not ucl.authed[ uid ] then -- Check to see if it's a steamid or IP
		local ply = ULib.getPlyByID( id )
		if ply and ply:IsValid() then
			uid = ply:UniqueID()
		end
	end

	local userInfo = ucl.users[ id ] or ucl.authed[ uid ] -- Check both tables
	if not userInfo then return error( "User id does not exist for changing access (" .. id .. ")", 2 ) end

	-- If they're connected but don't exist in the ULib user database, add them.
	-- This can be the case if they're only using the default garrysmod file to pull in users.
	if userInfo.guest then
		local allows = {}
		local denies = {}
		if not revoke and not deny then allows = access
		elseif not revoke and deny then denies = access end

		ucl.addUser( id, allows, denies )
		return true -- And we're done
	end

	local accessTable = userInfo.allow
	local otherTable = userInfo.deny
	if deny then
		accessTable = userInfo.deny
		otherTable = userInfo.allow
	end

	local changed = false
	for k, v in pairs( access ) do
		local access = v:lower()
		local accesstag
		if type( k ) == "string" then
			access = k:lower()
			if not revoke and not deny then -- Not valid to have accessTags unless this is the case
				accesstag = v
			end
		end

		if not revoke and (accessTable[ access ] ~= accesstag or (not accesstag and not ULib.findInTable( accessTable, access ))) then
			changed = true
			if not accesstag then
				table.insert( accessTable, access )
				accessTable[ access ] = nil -- Ensure no access tag
			else
				accessTable[ access ] = accesstag
				if ULib.findInTable( accessTable, access ) then -- Ensure removal of non-access tag version
					table.remove( accessTable, ULib.findInTable( accessTable, access ) )
				end
			end

			-- If it's on the other table, remove
			if deny then
				otherTable[ access ] = nil -- Remove any accessTags
			end
			if ULib.findInTable( otherTable, access ) then
				table.remove( otherTable, ULib.findInTable( otherTable, access ) )
			end

		elseif revoke and (accessTable[ access ] or ULib.findInTable( accessTable, access )) then
			changed = true

			if not deny then
				accessTable[ access ] = nil -- Remove any accessTags
			end
			if ULib.findInTable( accessTable, access ) then
				table.remove( accessTable, ULib.findInTable( accessTable, access ) )
			end
		end
	end

	if changed then
		local ply = ULib.getPlyByID( id )
		if ply then
			ULib.queueFunctionCall( hook.Call, ULib.HOOK_UCLAUTH, _, ply ) -- Inform the masses
		end

		ucl.saveUsers()

		hook.Call( ULib.HOOK_UCLCHANGED )
	end

	return changed
end


--[[
	Function: ucl.removeUser

	Removes a user from the UCL. Automatically probes for the user, automatically saves.

	Parameters:

		id - The SteamID, IP, or UniqueID of the user you wish to remove. Must be a valid, existing ID.
			The unique id of a connected user is always valid.

	Revisions:

		v2.40 - Rewrite, removed the write argument.
]]
function ucl.removeUser( id )
	ULib.checkArg( 1, "ULib.ucl.addUser", "string", id )
	id = id:upper() -- In case of steamid, needs to be upper case

	local userInfo = ucl.users[ id ] or ucl.authed[ id ] -- Check both tables
	if not userInfo then return error( "User id does not exist for removing (" .. id .. ")", 2 ) end

	local changed = false

	if ucl.authed[ id ] and not ucl.users[ id ] then -- Different ids between offline and authed
		local ply = ULib.getPlyByID( id )
		if not ply then return error( "SANITY CHECK FAILED!" ) end -- Should never be invalid

		local ip = ULib.splitPort( ply:IPAddress() )
		local checkIndexes = { ply:UniqueID(), ip, ply:SteamID() }

		for _, index in ipairs( checkIndexes ) do
			if ucl.users[ index ] then
				changed = true
				ucl.users[ index ] = nil
				break -- Only match the first one
			end
		end
	else
		changed = true
		ucl.users[ id ] = nil
	end

	if changed then -- If the user is only added to the default garry file, then nothing changed
		ucl.saveUsers()
	end

	local ply = ULib.getPlyByID( id )
	if ply then
		ply:SetUserGroup( ULib.ACCESS_ALL, true )
		ucl.probe( ply ) -- Reprobe
	else -- Otherwise this is called twice
		hook.Call( ULib.HOOK_UCLCHANGED )
	end
end


--[[
	Function: ucl.registerAccess

	Inform UCL about the existence of a particular access string, optionally make it have a certain default access,
	optionally give a help message along with it. The use of this function is optional, it is not required in order
	to query an access string, but it's use is highly recommended.

	Parameters:

		access - The access string (IE, "ulx slap" or "ups deletionAccess").
		groups - *(Optional, defaults to no access)* Either a string of a group or a table of groups to give the default access to.
		comment - *(Optional)* A brief description of what this access string is granting access to.
		category - *(Optional)* Category  for the access string (IE, "Command", "CVAR", "Limits")

	Revisions:

		v2.40 - Rewrite.
]]
function ucl.registerAccess( access, groups, comment, category )
	ULib.checkArg( 1, "ULib.ucl.registerAccess", "string", access )
	ULib.checkArg( 2, "ULib.ucl.registerAccess", {"nil","string","table"}, groups )
	ULib.checkArg( 3, "ULib.ucl.registerAccess", {"nil","string"}, comment )
	ULib.checkArg( 4, "ULib.ucl.registerAccess", {"nil","string"}, category )

	access = access:lower()
	comment = comment or ""
	if groups == nil then groups = {} end
	if type( groups ) == "string" then
		groups = { groups }
	end

	accessCategories[ access ] = category
	if accessStrings[ access ] ~= comment then -- Only if not already registered or if the comment has changed
		accessStrings[ access ] = comment

		-- Create a named timer so no matter how many times this function is called in a frame, it's only saved once.
		timer.Create( "ULibSaveAccessStrings", 1, 1, saveAccessStringRegistration ) -- 1 sec delay, 1 rep

		-- Double check to make sure this isn't already registered with some group somewhere before re-adding it
		for _, groupInfo in pairs( ucl.groups ) do
			if table.HasValue( groupInfo.allow, access ) then return end -- Found, don't add again
		end

		for _, group in ipairs( groups ) do
			-- Create group if it doesn't exist
			if not ucl.groups[ group ] then ucl.addGroup( group ) end

			table.insert( ucl.groups[ group ].allow, access )
		end

		timer.Create( "ULibSaveGroups", 1, 1, ucl.saveGroups ) -- 1 sec delay, 1 rep
	end
end


--[[
	Function: ucl.probe

	Probes the user to assign access appropriately.
	*DO NOT CALL THIS DIRECTLY, UCL HANDLES IT.*

	Parameters:

		ply - The player object to probe.

	Revisions:

		v2.40 - Rewrite.
]]
function ucl.probe( ply )
	local ip = ULib.splitPort( ply:IPAddress() )
	local uid = ply:UniqueID()
	local checkIndexes = { uid, ip, ply:SteamID() }

	local match = false
	for _, index in ipairs( checkIndexes ) do
		if ucl.users[ index ] then
			ucl.authed[ uid ] = ucl.users[ index ] -- Setup an ALIAS

			-- If they have a group, set it
			local group = ucl.authed[ uid ].group
			if group and group ~= "" then
				ply:SetUserGroup( group, true )
			end

			-- Update their name
			ucl.authed[ uid ].name = ply:Nick()
			ucl.saveUsers()

			match = true
			break
		end
	end

	if not match then
		ucl.authed[ ply:UniqueID() ] = ULib.DEFAULT_GRANT_ACCESS
		if ply.tmp_group then
			ply:SetUserGroup( ply.tmp_group, true ) -- Make sure they keep the group
			ply.tmp_group = nil
		end
	end

	hook.Call( ULib.HOOK_UCLCHANGED )
	hook.Call( ULib.HOOK_UCLAUTH, _, ply )
end
hook.Add( "PlayerAuthed", "ULibAuth", ucl.probe, -4 ) -- Run slightly after garry-auth


local function botCheck( ply )
	if ply:IsBot() and not ucl.authed[ ply:UniqueID() ] then
		ply:SetUserGroup( ULib.ACCESS_ALL, true ) -- Give it a group!
		ucl.probe( ply )
	end
end
hook.Add( "PlayerInitialSpawn", "ULibSendAuthToClients", botCheck, -20 )

local function sendAuthToClients( ply )
	ULib.clientRPC( _, "authPlayerIfReady", ply, ply:UserID() ) -- Call on client
end
hook.Add( ULib.HOOK_UCLAUTH, "ULibSendAuthToClients", sendAuthToClients, 20 )

local function sendUCLDataToClient( ply )
	ULib.clientRPC( ply, "ULib.ucl.initClientUCL", ucl.authed, ucl.groups ) -- Send all UCL data (minus offline users) to all loaded users
	ULib.clientRPC( ply, "hook.Call", ULib.HOOK_UCLCHANGED ) -- Call hook on client
	ULib.clientRPC( ply, "authPlayerIfReady", ply, ply:UserID() ) -- Call on client
end
hook.Add( ULib.HOOK_LOCALPLAYERREADY, "ULibSendUCLDataToClient", sendUCLDataToClient, -20 )

local function playerDisconnected( ply )
	local uid = ply:UniqueID()
	ULib.queueFunctionCall( function()
		ucl.authed[ uid ] = nil
		hook.Call( ULib.HOOK_UCLCHANGED )
	end )
end
hook.Add( "PlayerDisconnected", "ULibUCLDisconnect", playerDisconnected, 20 ) -- Last thing we want to do

local function UCLChanged()
	ULib.clientRPC( _, "ULib.ucl.initClientUCL", ucl.authed, ucl.groups ) -- Send all UCL data (minus offline users) to all loaded users
	ULib.clientRPC( _, "hook.Call", ULib.HOOK_UCLCHANGED ) -- Call hook on client
end
hook.Add( ULib.HOOK_UCLCHANGED, "ULibSendUCLToClients", UCLChanged )

--[[
-- The following is useful for debugging since Garry changes client bootstrapping so frequently
hook.Add( ULib.HOOK_UCLCHANGED, "UTEST", function() print( "HERE HERE: UCL Changed" ) end )
hook.Add( "PlayerInitialSpawn", "UTEST", function() print( "HERE HERE: Initial Spawn" ) end )
hook.Add( "PlayerAuthed", "UTEST", function() print( "HERE HERE: Player Authed" ) end )
]]

---------- Modify

-- Move garry's auth function so it gets called sooner
local playerAuth = hook.GetTable().PlayerInitialSpawn.PlayerAuthSpawn
hook.Remove( "PlayerInitialSpawn", "PlayerAuthSpawn" ) -- Remove from original spot
hook.Add( "PlayerAuthed", "GarryAuth", playerAuth, -5 ) -- Put here

local meta = FindMetaTable( "Player" )
if not meta then return end

local oldSetUserGroup = meta.SetUserGroup
function meta:SetUserGroup( group, dontCall )
	if not ucl.groups[ group ] then ULib.ucl.addGroup( group ) end

	local oldGroup = self:GetUserGroup()
	oldSetUserGroup( self, group )

	if ucl.authed[ self:UniqueID() ] then
		if ucl.authed[ self:UniqueID() ] == ULib.DEFAULT_GRANT_ACCESS then
			ucl.authed[ self:UniqueID() ] = table.Copy( ULib.DEFAULT_GRANT_ACCESS )
		end
		ucl.authed[ self:UniqueID() ].group = group
	else
		self.tmp_group = group
	end

	if not dontCall and self:GetUserGroup() ~= oldGroup then -- Changed! Inform the masses of the change
		hook.Call( ULib.HOOK_UCLCHANGED )
		hook.Call( ULib.HOOK_UCLAUTH, _, self )
	end
end
