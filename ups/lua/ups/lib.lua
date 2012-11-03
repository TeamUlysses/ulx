--[[
	Title: Library
	
	Server-side library functions for UPS.
]]

module( "UPS", package.seeall )

-- Check name changes and plug it into our player info table
local function nameChange( ply, oldnick, newnick )	
	local id = ply:UniqueID()
	nameToID( id, newnick )
	umsg.Start( "ups_readnames" )
		umsg.String( id )
		umsg.String( newnick )
	umsg.End()	
end
hook.Add( "ULibPlayerNameChanged", "UPSNameChanged", nameChange ) -- TODO, fix

--[[
	Function: playDenySound

	Takes care of playing the "access denied" sound to a client. IE, use this when they try to grab a prop they cannot.

	Parameters:

		ply - A valid player object to the play the sound to
]]
function playDenySound( ply )
	if not ULib.toBool( ply:GetInfo( "ups_cl_playdenysound" ) ) then return end -- They don't want it
	
	ply.UPSLastDenySound = ply.UPSLastDenySound or 0 -- Initialize
	if ply.UPSLastDenySound + 1.4 < CurTime() then -- If it's past threshold time, send them the sound and note the new time
		umsg.Start( "ups_denysound", ply )
		umsg.End()
		ply.UPSLastDenySound = CurTime()
	end
end

ownership = {}
-- This function is called whenever a prop changes ownership
local function collectOwnership( ply, ent )
	local uid
	if ply then
		uid = tonumber( ply:UniqueID() )
	else
		return -- Don't want to mess with this ownership info
	end
	
	-- Let's make sure no other player owned this
	for uid2, owned in pairs( ownership ) do
		if uid ~= uid2 and owned[ ent ] then
			owned[ ent ] = nil
		end
	end
	
	if ply then
		if not ownership[ uid ] then
			upsError( "Ownership table is not setup for a ply in collectOwnership! Could be a bad UPS addon installed or bad initialization?" )
			return
		end	
		ownership[ uid ][ ent ] = true
	end
end
hook.Add( "UPSAssignOwnership", "UPSCollectOwnership", collectOwnership, 20 )

local function onEntRemoved( ent )
	local players = player.GetAll()
	for _, ply in ipairs( players ) do
		if ply:IsValid() then
			local uid = tonumber( ply:UniqueID() )
			if not ownership[ uid ] then
				upsError( "Ownership table is not setup for a ply in onEntRemoved! Could be a bad UPS addon installed or bad initialization?" )
				return
			end			
			ownership[ tonumber( ply:UniqueID() ) ][ ent ] = nil
		end
	end
end
hook.Add( "EntityRemoved", "UPSEntityRemoved", onEntRemoved, -20 )

-- Run this function as soon as possible. AS SOON AS POSSIBLE!
local function onAuthed( ply, steamid )
	local uid = tonumber( ply:UniqueID() )
	ownership[ uid ] = ownership[ uid ] or {} -- Reclaim if available.
end
hook.Add( "PlayerAuthed", "UPSPlayerAuthed", onAuthed, -20 )
hook.Add( "PlayerInitialSpawn", "UPSPlayerInitialSpawnOwnership", onAuthed, -20 )
-- The double hook above won't hurt anything, but it offers us a double check *just in case*, and because bots never auth

local function onLoaded( ply )
	local uid = tonumber( ply:UniqueID() )
	if table.Count( ownership[ uid ] ) > 0 then
		for ent, _ in pairs( ownership[ uid ] ) do
			ent:UPSSetOwnerEnt( ply )
		end
		ULib.tsay( ply, "You have reclaimed some (or all) of your props from your last session." )
	end
end
hook.Add( "UPSPlayerLoaded", "UPSPlayerInitialSpawnInitOwnership", onLoaded, -20 )


local playermeta = FindMetaTable( "Player" )
--[[
	Function: PLAYER:UPSGetOwnedEnts

	Gets a table of entities this player owns. The table is indexed by entity and the value is always true. 
	The table is done this way so you don't have to search the table for an entity.
	
	Returns:
		
		The table.
]]
function playermeta:UPSGetOwnedEnts()
	return ownership[ tonumber( ply:UniqueID() ) ]
end


--[[
	Function: getUIDOwnedEnts

	Gets a table of entities this uid owns. The table is indexed by entity and the value is always true. 
	The table is done this way so you don't have to search the table for an entity.
	
	Returns:
		
		The table or nil if the uid isn't known.
]]
function getUIDOwnedEnts( uid )
	return ownership[ tonumber( uid ) ]
end

function playTakeOwnershipSound( ply )
	-- We're doing this through a timer so that if they take ownership of a whole contrap they'll still only get one sound
	timer.Create( "UPSTakeOwnership" .. ply:EntIndex(), FrameTime(), 1, function()
		if not ply:IsValid() then return end -- They left! 
		umsg.Start( "ulib_sound", ply )
			umsg.String( "ambient/water/drip" .. math.random( 1, 4 ) .. ".wav" )
		umsg.End()
	end )	
end

local function clientRequestOwner( ply, command, argv )
	local entid = argv[ 1 ]
	local ent = Entity( entid )
	if not ent or not ent:IsValid() then return end -- Invalid
	
	umsg.Start( "ups_ownerinfo", ply )
		umsg.Short( entid )
		umsg.String( tostring( ent:UPSGetOwner() ) )
	umsg.End()
end
concommand.Add( "ups_requestowner", clientRequestOwner )

local function updateOwnership( ply, plyWasValid, ent )
	if plyWasValid and (not ply or not ply:IsValid()) then -- Player error
		return
	end
	
	umsg.Start( "ups_ownerinfo" )
		umsg.Short( ent:EntIndex() )
		if not ply or not ply:IsValid() then -- Ownership was cleared
			umsg.String( tostring( OWNERID_UPFORGRABS ) )
		else
			umsg.String( tostring( ply:UniqueID() ) )
		end
	umsg.End()	
end

-- This function is called whenever a prop changes ownership
local function updateOwnershipCallback( ply, ent )
	timer.Simple( 0.15, function() updateOwnership( ply, (ply and ply:IsValid()), ent ) end )
end
hook.Add( "UPSAssignOwnership", "UPSInvalidateOwnership", updateOwnershipCallback, 20 )
