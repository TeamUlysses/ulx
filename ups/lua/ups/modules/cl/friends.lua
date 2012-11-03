module( "UPS", package.seeall )
local cvarprefix = "ups_cl_friend"

function clientChangedFriend( cvar, oldvalue, newvalue )
	local id = cvar:gsub( cvarprefix, "" )
	id = tonumber( id )
	if not id then return end -- Error, ignore
	
	local ent = Entity( id )
	if not ent:IsValid() or not ent:IsPlayer() or ent == LocalPlayer() then return end -- Error, ignore
	
	local isFriend = tonumber( newvalue )
	if not isFriend then return end -- Error, ignore
	
	if isFriend == 0 then
		LocalPlayer():UPSRemoveFriend( ent )
	else
		LocalPlayer():UPSAddFriend( ent )
	end
	RunConsoleCommand( cvarprefix, id, newvalue )
end

-- The following code used to be triggered when the player was ready, but this file isn't even /loaded/ until the player is ready now... so go ahead and do it now.
--local function onLocalPlayerReady()
	for i=1, MaxPlayers() do
		local cvar = cvarprefix .. i
		CreateClientConVar( cvar, "0", false, false )
		RunConsoleCommand( cvar, "0" )
		cvars.AddChangeCallback( cvar, clientChangedFriend )
	end
--end
--hook.Add( ULib.HOOK_LOCALPLAYERREADY, "UPSCreateFriends", onLocalPlayerReady )

local function onEntCreated( ent )
	if ent:IsValid() and ent:IsPlayer() and ent ~= LocalPlayer() then
		local friends = ULib.parseKeyValues( file.Read( FRIENDFILE ) or "" )
		
		if friends[ ent:SteamID() ] then
			RunConsoleCommand( cvarprefix .. ent:EntIndex(), "1" )
		end		
	end
end
hook.Add( "OnEntityCreated", "UPSWatchJoinFriends", onEntCreated, -20 )

-- Get any players that may already exist
do
	local players = player.GetAll()
	for _, ply in ipairs( players ) do
		if ply:IsValid() then
			onEntCreated( ply )
		end
	end
end

local function buildCP( cpanel )
	cpanel:ClearControls()
	cpanel:AddHeader()
	cpanel:AddControl( "Label", { Text = "Friends:" } )
	for i=1, MaxPlayers() do
		local ply = Entity( i )
		if ply:IsValid() and ply ~= LocalPlayer() and ply:IsPlayer() then
			cpanel:AddControl( "Checkbox", { Label = ply:Nick(), Command = cvarprefix .. i } )
		end
	end
end

local function spawnMenuOpen()
	buildCP( GetControlPanel( "UPSFriends" ) )
end
hook.Add( "SpawnMenuOpen", "UPSFriendsSpawnMenuOpen", spawnMenuOpen )