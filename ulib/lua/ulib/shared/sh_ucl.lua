--[[
	Title: Shared UCL

	Shared UCL stuff.
]]

--[[
	Table: ucl

	Holds all of the ucl variables and functions
]]
ULib.ucl = {}
local ucl = ULib.ucl -- Make it easier for us to refer to

-- Setup!
ucl.groups = {} -- Stores allows, inheritance, and custom addon info keyed by group name
ucl.users = {} -- Stores allows, denies, group, and last seen name keyed by user id (steamid, ip, whatever)
ucl.authed = {} -- alias to ucl.users subtable for player if they have an entry, otherwise a "guest" entry. Keyed by uniqueid.
-- End setup

--[[
	Function: ucl.query

	This function is used to see if a user has access to a command.

	Parameters:

		ply - The player to check access for
		access - The access string to check for. (IE "ulx slap", doesn't have to be a command though). If nil is passed in, this always
			returns true.
		hide - *(Optional, defaults to false)* Normally, a listen host is automatically given access to everything.
			Set this to true if you want to treat the listen host as a normal user. (Will be denied commands that no one has access to)

	Returns:

		A bool signifying whether or not they have access.

	Revisions:
		v2.40 - Rewrite.
]]
function ucl.query( ply, access, hide )
	if SERVER and (not ply:IsValid() or (not hide and ply:IsListenServerHost())) then return true end -- Grant full access to server host.
	if access == nil then return true end
	-- if ply:IsBot() then return false end -- Bots have no access!

	access = access:lower()

	local unique_id = ply:UniqueID()
	if CLIENT and game.SinglePlayer() then
		unique_id = "1" -- Fix garry's bug
	end

	if not ucl.authed[ unique_id ] then return error( "[ULIB] Unauthed player" ) end -- Sanity check
	local playerInfo = ucl.authed[ unique_id ]

	-- First check the player's info
	if table.HasValue( playerInfo.deny, access ) then return false end -- Deny overrides all else
	if table.HasValue( playerInfo.allow, access ) then return true end
	if playerInfo.allow[ access ] then return true, playerInfo.allow[ access ] end -- Access tag

	-- Now move onto groups and group inheritance
	local group = ply:GetUserGroup()
	while group do -- While group is not nil
		local groupInfo = ucl.groups[ group ]
		if not groupInfo then return error( "[ULib] Player " .. ply:Nick() .. " has an invalid group (" .. group .. "), aborting. Please be careful when modifying the ULib files!" ) end
		if table.HasValue( groupInfo.allow, access ) then return true end
		if groupInfo.allow[ access ] then return true, groupInfo.allow[ access ] end

		group = ucl.groupInheritsFrom( group )
	end

	-- No specific instruction, assume they don't have access.
	return false
end


--[[
	Function: ucl.groupInheritsFrom

	This function is used to see if a specified group is inheriting from another

	Parameters:

		group - The group to check inheritance on. Must be a valid group.

	Returns:

		The group this group is inheriting from or nil (everything implicity inherits from "user", "user" inherits from nil).

	Revisions:

		v2.40 - Initial.
]]
function ucl.groupInheritsFrom( group )
	if not ucl.groups[ group ] then return false end

	if group == ULib.ACCESS_ALL then -- Force this to inherit from nil
		return nil
	elseif not ucl.groups[ group ].inherit_from or ucl.groups[ group ].inherit_from == "" then
		return ULib.ACCESS_ALL
	else
		return ucl.groups[ group ].inherit_from
	end
end


--[[
	Function: ucl.getInheritanceTree

	This function returns a tree-like structure representing the group inheritance architecture.

	Returns:

		The inheritance tree.

	Example return:

		:PrintTable( ULib.ucl.getInheritanceTree() )
		:user:
		:	trusted:
		:		members:
		:	thedumbones:
		:	admin:
		:		superadmin:
		:		serverowner:
		:		clanowner:
		:	respected:

	Revisions:

		v2.40 - Initial
]]
function ucl.getInheritanceTree()
	local inherits = { [ULib.ACCESS_ALL]={} }
	local find = { [ULib.ACCESS_ALL]=inherits[ULib.ACCESS_ALL] }
	for group, _ in pairs( ucl.groups ) do
		if group ~= ULib.ACCESS_ALL then
			local inherits_from = ucl.groupInheritsFrom( group )
			if not inherits_from then inherits_from = ULib.ACCESS_ALL end

			find[ inherits_from ] = find[ inherits_from ] or {} -- Use index if it exists, otherwise create one for this group
			find[ group ] = find[ group ] or {} -- If someone's created our index, use it. Otherwise, create one.
			find[ inherits_from ][ group ] = find[ group ]
		end
	end

	return inherits
end


--[[
	Function: ucl.getGroupCanTarget

	Gets what a group is allowed to target in the UCL.

	Parameters:

		group - A string of the group name. (IE: superadmin)

	Returns:

		The string of who they're allowed to target (IE: !%admin) or nil if there's no restriction.

	Revisions:

		v2.40 - Initial.
]]
function ucl.getGroupCanTarget( group )
	ULib.checkArg( 1, "ULib.ucl.getGroupCanTarget", "string", group )
	if not ucl.groups[ group ] then return error( "Group does not exist (" .. group .. ")", 2 ) end

	return ucl.groups[ group ].can_target
end

-- Client init stuff
if CLIENT then
	function ucl.initClientUCL( authed, groups )
		ucl.authed = authed
		ucl.groups = groups
	end
end

------------------
--//Meta hooks//--
------------------
local meta = FindMetaTable( "Player" )
if not meta then return end


--[[
	Function: Player:query

	This is an alias of ULib.ucl.query()
]]
function meta:query( access, hide )
	return ULib.ucl.query( self, access, hide )
end


local origIsAdmin = meta.IsAdmin
--[[
	Function: Player:IsAdmin

	Overwrite garry's IsAdmin function to check for membership in admin group. This is so if group "serverowner"
	inherits from superadmin, this function will still return true when checking on a member belonging to the
	"serverowner" group.

	Returns:

		True is the user belongs in the admin group directly or indirectly, false otherwise.

	Revisions:

		v2.40 - Rewrite.
]]
function meta:IsAdmin()
	if ucl.groups[ ULib.ACCESS_ADMIN ] then
		return self:CheckGroup( ULib.ACCESS_ADMIN )
	else -- Group doesn't exist, fall back on garry's method
		origIsAdmin( self )
	end
end


local origIsSuperAdmin = meta.IsSuperAdmin
--[[
	Function: Player:IsSuperAdmin

	Overwrite garry's IsSuperAdmin function to check for membership in admin group. This is so if group "serverowner"
	inherits from superadmin, this function will still return true when checking on a member belonging to the
	"serverowner" group.

	Returns:

		True is the user belongs in the superadmin group directly or indirectly, false otherwise.

	Revisions:

		v2.40 - Rewrite.
]]
function meta:IsSuperAdmin()
	if ucl.groups[ ULib.ACCESS_SUPERADMIN ] then
		return self:CheckGroup( ULib.ACCESS_SUPERADMIN )
	else -- Group doesn't exist, fall back on garry's method
		origIsSuperAdmin( self )
	end
end


--[[
	Function: Player:GetUserGroup

	This should have been included with garrysmod by default, so ULib is creating it for us.

	Returns:

		The group the player belongs to.

	Revisions:

		v2.40 - Initial.
]]
function meta:GetUserGroup()
	if not self:IsValid() then return "" end -- Not a valid player

	local uid = self:UniqueID()
	if CLIENT and game.SinglePlayer() then
		uid = "1" -- Fix garry's bug
	end
	if not ucl.authed[ uid ] then return "" end
	return ucl.authed[ uid ].group or "user"
end


--[[
	Function: Player:CheckGroup

	This function is similar to IsUserGroup(), but this one checks the UCL group chain as well.
	For example, if a user is in group "owner" which inherits from "superadmin", this function
	will return true if you check the user against "superadmin", where IsUserGroup() wouldn't.

	Parameters:

		group - The group you want to check a player's membership in.

	Returns:

		A boolean stating whether they have membership in the group or not.

	Revisions:

		v2.40 - Initial.
]]
function meta:CheckGroup( group_check )
	if not ucl.groups[ group_check ] then return false end
	local group = self:GetUserGroup()
	while group do
		if group == group_check then return true end
		group = ucl.groupInheritsFrom( group )
	end

	return false
end
