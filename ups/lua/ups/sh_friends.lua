module( "UPS", package.seeall )

if SERVER then
	local function friendChange( ply, command, argv )
		if not argv[ 1 ] or not argv[ 2 ] then return end -- Invalid input
		
		local id = tonumber( argv[ 1 ] )
		local isFriend = tonumber( argv[ 2 ] )
		if not id or not isFriend then return end -- Invalid input
		
		local ent = Entity( id )
		if not ent:IsValid() or not ent:IsPlayer() or ent == ply then return end -- Invalid input
		
		if isFriend == 0 then
			ply:UPSRemoveFriend( ent )
		else
			ply:UPSAddFriend( ent )
		end
	end
	concommand.Add( "ups_cl_friend", friendChange )
end

local playermeta = FindMetaTable( "Player" )

function playermeta:UPSAddFriend( ply )
	self.UPSFriends = self.UPSFriends or {}
	
	if not ULib.findInTable( self.UPSFriends, ply ) and self ~= ply then
		table.insert( self.UPSFriends, ply )
		gamemode.Call( "UPSFriendsChanged", self, self.UPSFriends )
		
		if CLIENT then
			local friends = ULib.parseKeyValues( file.Read( FRIENDFILE, "DATA" ) or "" )
			friends[ ply:SteamID() ] = {} -- TODO: Table is for future use
			file.Write( FRIENDFILE, ULib.makeKeyValues( friends ) )
		end
	end
end

function playermeta:UPSRemoveFriend( ply )
	self.UPSFriends = self.UPSFriends or {}
	
	local index = ULib.findInTable( self.UPSFriends, ply )
	if index then
		table.remove( self.UPSFriends, index )
		gamemode.Call( "UPSFriendsChanged", self, self.UPSFriends )
		
		if CLIENT then
			local friends = ULib.parseKeyValues( file.Read( FRIENDFILE, "DATA" ) or "" )
			friends[ ply:SteamID() ] = nil
			file.Write( FRIENDFILE, ULib.makeKeyValues( friends ) )		
		end
	end
end

function playermeta:UPSGetFriends()
	self.UPSFriends = self.UPSFriends or {}
	return self.UPSFriends
end

local function init() -- Have to call on initialization or we don't override.		
	function GAMEMODE:UPSFriendsChanged( ply, friends )
	end
end -- End init()
hook.Add( "Initialize", "UPSInitializeFriendsHook", init )
if CLIENT then init() end -- Client doesn't get Init hook.