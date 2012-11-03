--[[
	Title: Common Prop Protection Interface
	
	CPPI is a common prop protection interface. See http://forums.facepunchstudios.com/showthread.php?t=488410 for the specifications of CPPI
]]

module( "CPPI", package.seeall )

CPPI_NOTIMPLEMENTED = -2
CPPI_DEFER = UPS.OWNERID_DEFER

function GetName()
	return "Ulysses Prop Share (UPS)"
end

function GetVersion()
	return "0.9"
end

function GetInterfaceVersion()
	return 1.1
end

function GetNameFromUID( uid )
	UPS.nameFromID( uid )
end

local Player = FindMetaTable( "Player" )
if not Player then return end

function Player:CPPIGetFriends()
	return self:UPSGetFriends()
end


local Entity = FindMetaTable( "Entity" )
if not Entity then return end

function Entity:CPPIGetOwner()	
	return self:UPSGetOwnerEnt(), self:UPSGetOwner()
end

if SERVER then
	function Entity:CPPISetOwner( ply )
		if not ply or not ply:IsValid() or not ply:IsPlayer() then return false end -- Malformed arg!
		
		self:UPSSetOwnerEnt( ply )
		return true
	end

	function Entity:CPPISetOwnerUID( uid )
		if not uid then return false end -- Malformed arg!
		
		local ply = player.GetByUniqueID( tostring( uid ) )
		if not ply then return false end -- No player found, must be active in the server.
		
		self:UPSSetOwnerEnt( ply )
		return true
	end

	function Entity:CPPICanTool( ply, toolmode )
		if not ply or not ply:IsValid() or not ply:IsPlayer() or not toolmode then return false end -- Malformed args!
		
		if UPS.canTool( ply, {Entity=self}, toolmode, true ) == false then -- Force no hack detections
			return false
		else
			return true
		end
	end

	function Entity:CPPICanPhysgun( ply )
		if not ply or not ply:IsValid() or not ply:IsPlayer() then return false end -- Malformed args!
		
		if UPS.queryAll( ply, self, UPS.ACTID_PHYSGUN, { QUERY_NOSOUND } ) == false then
			return false
		else
			return true
		end
	end

	function Entity:CPPICanPickup( ply )
		if not ply or not ply:IsValid() or not ply:IsPlayer() then return false end -- Malformed args!
		
		if not UPS.query( ply, self, UPS.ACTID_PHYSGUN, { QUERY_NOSOUND } ) == false then
			return false
		else
			return true
		end
	end

	function Entity:CPPICanPunt( ply )
		return self:CPPICanPickup( ply ) -- For UPS, we want this behavior the same (at least for now)
	end
end -- End if SERVER

local function init() -- Init on gamemode initialize

	function GAMEMODE:CPPIAssignOwnership( ply, ent )
	end

	local function callAssignOwnership( ply, ent )
		return gamemode.Call( "CPPIAssignOwnership", ply, ent )
	end
	hook.Add( "UPSAssignOwnership", "CPPIAssignOwnership", callAssignOwnership )

	function GAMEMODE:CPPIFriendsChanged( ply, ent )
	end

	local function callFriendsChanged( ply, newfriends )
		return gamemode.Call( "CPPIFriendsChanged", ply, newfriends )
	end
	hook.Add( "UPSFriendsChanged", "CPPIFriendsChanged", callFriendsChanged )

end -- End init()
hook.Add( "Initialize", "CPPIInitGM", init )