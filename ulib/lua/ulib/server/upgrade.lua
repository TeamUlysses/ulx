--[[
	Title: Upgrade

	This is the file where we'll dump any upgrade scripts.
]]

local old_version = file.Read( ULib.VERSION_FILE )
old_version = tonumber( old_version ) or 2.3 -- Assume 2.3 if the file is bad/doesn't exist, that's just before we started this file

local function upgrade()

local data = ULib.parseKeyValues( ULib.removeCommentHeader( file.Read( ULib.UCL_GROUPS ), "/" ) )

if old_version == 2.3 and data and data.none then -- Use two checks since we didn't used to keep track of versions
	Msg( "\n\n!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" )
	Msg( "! Currently upgrading ULib on your server !\n" )
	Msg( "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" )

	Msg( "upgrading groups...\n" )
	Msg( "old file backed up to " .. ULib.backupFile( ULib.UCL_GROUPS ) .. "\n" )
	-- Bring groups.txt up to date. We need to drop denies, drop the 'none' group, and change the inheritance var
	local groups = data
	groups.none = nil -- Goodbye!
	for group, groupData in pairs( groups ) do
		groupData.deny = nil
		if type( groupData.inherit_from ) == "table" and groupData.inherit_from[ 1 ] then -- Just grab the first one
			groupData.inherit_from = groupData.inherit_from[ 1 ]
		end
	end
	file.Write( ULib.UCL_GROUPS, ULib.makeKeyValues( groups ) )

	Msg( "upgrading users...\n" )
	Msg( "old file backed up to " .. ULib.backupFile( ULib.UCL_USERS ) .. "\n" )
	-- Bring users.txt up to date. We need to change the group var, move id/key, drop type/password/pass_req
	local users = ULib.parseKeyValues( ULib.removeCommentHeader( file.Read( ULib.UCL_USERS ), "/" ) )
	local new_users = {}
	for user, userData in pairs( users ) do
		local id = userData.id
		new_users[ id ] = {}
		new_users[ id ].deny = userData.deny or {}
		new_users[ id ].allow = userData.allow or {}
		if type( userData.groups ) == "table" and userData.groups[ 1 ] then -- Just grab the first one
			new_users[ id ].group = userData.groups[ 1 ]
		end
		new_users[ id ].name = user
	end
	file.Write( ULib.UCL_USERS, ULib.makeKeyValues( new_users ) )

	if file.Exists( ULib.UCL_REGISTERED ) then
		Msg( "removing misc_registered.lua...\n" )
		file.Delete( ULib.UCL_REGISTERED )
	end

	Msg( "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n" )
	Msg( "! ULib upgraded                           !\n" )
	Msg( "!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!!\n\n\n" )
end

end

b, rA = pcall( upgrade )

if not b then
	ErrorNoHalt( "ERROR: ULib upgrade Failed: " .. tostring( rA ) .. "\n" )
end

file.Write( ULib.VERSION_FILE, ULib.VERSION )