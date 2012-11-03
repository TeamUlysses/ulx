-- This file takes care of what happens when a player leaves the game (delete props, put them up for grabs)

module( "UPS", package.seeall )

local deletionAccess = "ups miscDeletionAccess"
ULib.ucl.registerAccess( deletionAccess, UPS_ADMIN, "Gives the ability to control when a player's props are deleted", "UPS" )

local cTimeToDelete = replicatedWritableSavedCvar( "ups_deletetime", "ups_cl_deletetime", "300", false, false, deletionAccess )
local cDelAdminProps = replicatedWritableSavedCvar( "ups_deleteadmin", "ups_cl_deleteadmin", "1", false, false, deletionAccess )
local cTimeToClear = replicatedWritableSavedCvar( "ups_cleartime", "ups_cl_cleartime", "240", false, false, deletionAccess )

local function plyCalledRemove( ply, command, argv )
	if not ply:query( deletionAccess ) then
		ULib.tsay( ply, "You do not have access to this command, " .. ply:Nick() .. "." )
		return
	end

	local uid = tonumber( argv[ 1 ] )
	if not uid then return end -- Error, ignore

	local name = nameFromID( uid )
	if not name then return end

	ULib.tsay( _, ply:Nick() .. " removed all of " .. nameFromID( uid ) .. "'s props" )
	local isDisconnected = not player.GetByUniqueID( tostring( uid ) )
	deleteAll( uid, isDisconnected ) -- Only remove info if they're not connected
end
concommand.Add( "ups_remove", plyCalledRemove )

-- Called when it's time to remove this player's props
local function onTimeToDelete( uid )
	local name = nameFromID( uid )
	if not name then return end -- Already removed

	if player.GetByUniqueID( tostring( uid ) ) then -- They're back!
		return
	end

	local txt = "Removing " .. name .. "'s props"
	if isDedicatedServer() then
		Msg( txt .. "\n" )
	end
	ULib.tsay( _, txt )

	deleteAll( uid, true )
end

-- Called when it's time to clear this player's props
local function onTimeToClear( uid )
	local name = nameFromID( uid )
	if not name then return end -- Already removed

	if player.GetByUniqueID( tostring( uid ) ) then -- They're back!
		return
	end

	if not ownership[ uid ] then
		upsError( "Receive an invalid uid in onTimeToClear. Could be a bad UPS addon installed?" )
		return
	end

	local txt = name .. "'s props are now up for grabs."
	if isDedicatedServer() then
		Msg( txt .. "\n" )
	end
	ULib.tsay( _, txt )

	for ent, _ in pairs( ownership[ uid ] ) do
		if ent:IsValid() then
			ent:UPSClearOwner()
		end
	end

	local cleartime = cTimeToClear:GetInt()
	local deletetime = cTimeToDelete:GetInt()

	if deletetime ~= -1 and cleartime < deletetime then
		timer.Simple( deletetime - cleartime, onTimeToDelete, uid )
	end
end

local function onLeave( ply )
	local uid = tonumber( ply:UniqueID() )
	if table.Count( ownership[ uid ] ) < 1 then -- If they have no props just clear them out right now.
		ULib.queueFunctionCall( deleteAll, uid, true ) -- If we don't queue it we run into trouble as the server registers their leaving
	end

	local cleartime = cTimeToClear:GetInt()
	local deletetime = cTimeToDelete:GetInt()

	if cleartime == -1 or (deletetime ~= -1 and cleartime >= deletetime) then
		if deletetime ~= -1 and (not ply:IsAdmin() or cDelAdminProps:GetBool()) then
			timer.Simple( deletetime, onTimeToDelete, uid )
		end
	else
		if not ply:IsAdmin() or cDelAdminProps:GetBool() then
			timer.Simple( cleartime, onTimeToClear, uid )
		end
	end
end
hook.Add( "PlayerDisconnected", "UPSPlayerDisconnected", onLeave, -20 )
