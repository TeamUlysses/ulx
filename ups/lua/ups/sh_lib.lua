--[[
	Title: Shared library
	
	Even more library stuff that executes on both server and client.
]]

module( "UPS", package.seeall )

-- This block intializes our <accessIds> with ULib.
if SERVER then
	for _, id in ipairs( accessIds ) do
		ULib.ucl.registerAccess( "ups_" .. id, UPS_ADMIN, "Gives access to " .. id .. "-related things", "UPS" )
	end
end

--[[
	Variable: playerTable

	Stores player names indexed by uid.
]]
playerTable = {}

--[[
	Function: nameFromID

	Gets the last known player name for a user uid. The unique id is based off GMod's ply:UniqueID().
	This is similar to GMod's player.GetByUniqueID() except it keeps the names even after dicsconnect.

	Parameters:

		uid - A number or string representing the user's uid. This value gets automatically converted to a number.
		
	Returns:
	
		The string of the player's last known name if found, otherwise nil.
]]
function nameFromID( uid )
	return playerTable[ tonumber( uid ) ]
end


--[[
	Function: nameToID

	*DO NOT CALL DIRECTLY, UPS HANDLES THIS FUNCTION*
	Sets the name for use with <nameFromID>.

	Parameters:

		uid - A number or string representing the user's uid. This value gets automatically converted to a number.
		name - The name to assign to the id.
]]
function nameToID( uid, name )
	playerTable[ tonumber( uid ) ] = name
end


local entitymeta = FindMetaTable( "Entity" )
--[[
	Function: ENTITY:UPSGetOwner

	Gets the unique id of the owner of this prop. Can return one of the 
	OWNERID_* variables (see definitions and explanations in defines)
	
	Returns:
	
		The short id.
]]	
function entitymeta:UPSGetOwner()
	if CLIENT and not self.UOwn then
		requestOwner( self )
		return OWNERID_DEFER
	end
	return self.UOwn or OWNERID_MAP
end


--[[
	Function: ENTITY:UPSGetOwnerEnt

	Gets the player entity of the owner of this prop or nil if it has no owner or the owner is disconnected.
	
	Returns:
	
		The short id.
]]		
function entitymeta:UPSGetOwnerEnt()
	local uid = self:UPSGetOwner()
	if not uid then return end
	
	if CLIENT and uid == OWNERID_DEFER then return uid end
	
	local name = UPS.nameFromID( uid )
	if not name then return end
	
	return ULib.getUser( name )
end


--[[
	Function: ENTITY:UPSSetOwnerEnt

	Sets the current entity owner to the player specified.
	
	Parameters:
	
		ply - The valid player object to own this entity.
]]		
function entitymeta:UPSSetOwnerEnt( ply )
	if self:UPSGetOwner() == tonumber( ply:UniqueID() ) then return end -- No need, already set
	gamemode.Call( "UPSAssignOwnership", ply, self )
end

	
--[[
	Function: ENTITY:UPSClearOwner

	Clears the owner of this entity and puts it "up for grabs".
]]		
function entitymeta:UPSClearOwner()
	if self:UPSGetOwner() == OWNERID_UPFORGRABS then return end -- No need, already up for grabs
	gamemode.Call( "UPSAssignOwnership", nil, self )
end	


	
local function init()
--[[
	Function: GAMEMODE:UPSAssignOwnership

	This hook allows you to override an ownership change or simply catalog it.
]]		
	function GAMEMODE:UPSAssignOwnership( ply, ent )
		if not ent then return end -- Just in case.
		
		local id
		if not ply or not ply:IsValid() then
			id = OWNERID_UPFORGRABS
		else
			id = tonumber( ply:UniqueID() )
		end
		
		ent.UOwn = id
	end
end
hook.Add( "Initialize", "UPSInitializeAssignOwnership", init )	


--[[
	Function: deleteAll

	This function removes all of a player's worldly possessions. Handle with care!
	Note that this function is shared but it automatically invokes the client side part when called from the server.

	Parameters:

		uid - The uid of the owner who is about to lose everything they own.
		isLeaving - A boolean stating whether or not the player is disconnecting. If true, this function clears their data out completely.
]]
function deleteAll( uid, isLeaving )
	uid = tonumber( uid )
	local name = nameFromID( uid )
	if not name or (SERVER and not ownership[ uid ]) then return end -- Invalid
	
	if SERVER then
		for ent, _ in pairs( ownership[ uid ] ) do
			if ent:IsValid() then
				ent:Remove()
			end
		end
	end

	if isLeaving then
		if SERVER then
			ownership[ uid ] = nil	
		end
		playerTable[ uid ] = nil
	elseif SERVER then
		ownership[ uid ] = {}
	end
	
	if SERVER then
		umsg.Start( "ups_removeid" )
			umsg.String( tostring( uid ) )
			umsg.Bool( isLeaving )
		umsg.End()
	end
end

function upsError( str )
	Msg( "[UPS ERROR] " .. str .. "   Please report this error to ulyssesmod.net with information on how you got it.\n" )
end  

function findRegexKeyInTable( t, desiredKey )
	for k, v in pairs( t ) do
		if desiredKey:find( k ) then
			return v
		end
	end
	return nil
end

