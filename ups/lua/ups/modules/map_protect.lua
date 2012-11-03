module( "UPS", package.seeall )

local disableAccess = "ups disableplayers"
ULib.ucl.registerAccess( disableAccess, UPS_ADMIN, "Gives the ability to disable portions of UPS or disable UPS for players", "UPS" )

local cWorldProtection = replicatedWritableSavedCvar( "ups_worldprotection", "ups_cl_worldprotection", "1", false, false, disableAccess )

-- Things that are allowed on any map ent
mapProtectionAllow = {
	ACTID_USE,
	ACTID_ENTERVEHICLE,
}

local takeOwnerless = "take"
local allIdsAndTake = table.Copy( accessIds ) -- accessIds is defined in sh_defines.lua
table.insert( allIdsAndTake, takeOwnerless )

initialMapProtectionInfo = {
	['^func_breakable$']               = { ACTID_DAMAGE, },
	['^func_breakable_surf$']          = { ACTID_DAMAGE, },
	['^func_physbox$']                 = { ACTID_DAMAGE, ACTID_FREEZE, ACTID_PHYSGUN, ACTID_TOOL, ACTID_UNFREEZE, },
	['^prop_physics']                  = { ACTID_DAMAGE, ACTID_FREEZE, ACTID_PHYSGUN, ACTID_TOOL, ACTID_UNFREEZE, },
	['^prop_ragdoll$']                 = { ACTID_DAMAGE, ACTID_FREEZE, ACTID_PHYSGUN, ACTID_TOOL, ACTID_UNFREEZE, },
	['^prop_vehicle']                  = { ACTID_DAMAGE, ACTID_FREEZE, ACTID_PHYSGUN, ACTID_TOOL, ACTID_UNFREEZE, },
	['^item_ammo_']                    = { ACTID_FREEZE, ACTID_PHYSGUN, ACTID_UNFREEZE, },
	['^item_battery$']                 = { ACTID_FREEZE, ACTID_PHYSGUN, ACTID_UNFREEZE, },
	['^item_box_buckshot$']            = { ACTID_FREEZE, ACTID_PHYSGUN, ACTID_UNFREEZE, },
	['^item_healthkit$']               = { ACTID_FREEZE, ACTID_PHYSGUN, ACTID_UNFREEZE, },
	['^item_healthvial$']              = { ACTID_FREEZE, ACTID_PHYSGUN, ACTID_UNFREEZE, },
	['^item_item_crate$']              = { ACTID_FREEZE, ACTID_PHYSGUN, ACTID_UNFREEZE, },
	['^item_rpg_round$']               = { ACTID_FREEZE, ACTID_PHYSGUN, ACTID_UNFREEZE, },
}

extendedMapProtectionInfo = {
	['^func_breakable$']               = allIdsAndTake,
	['^func_physbox$']                 = allIdsAndTake,
	['^prop_physics']                  = allIdsAndTake,
	['^prop_ragdoll$']                 = allIdsAndTake,
	['^prop_vehicle']                  = allIdsAndTake,
	['^item_ammo_']                    = allIdsAndTake,
	['^item_battery$']                 = allIdsAndTake,
	['^item_box_buckshot$']            = allIdsAndTake,
	['^item_healthkit$']               = allIdsAndTake,
	['^item_healthvial$']              = allIdsAndTake,
	['^item_item_crate$']              = allIdsAndTake,
	['^item_rpg_round$']               = allIdsAndTake,
}


--[[
	Function: mapProtectionQuery

	This is a prequery (see <query>) hook in order to protect map entities.

	Parameters:

		ply - The player entity requesting access.
		ent - The entity the player wants access to.
		actionid - What action they're trying to perform on the object. (IE, freeze, move, use)
		flags - A table of special instructions for this query. (IE, reassign ownership, no deny sound, etc)
]]
function mapProtectionQuery( ply, ent, actionid, flags )
	-- NOTE: We're overriding some garry stuff here if physgun limited is on.
	-- Should we fix this? See: /garrysmod/gamemodes/sandbox/gamemode/shared.lua line 188
	if table.HasValue( ignoreList, ent:GetClass() ) then return true end

	if ent:UPSGetOwner() == OWNERID_MAP then
		if not cWorldProtection:GetBool() then -- If map protection isn't enabled, allow anything
			return true
		end

		-- Allow these on any map ent
		if table.HasValue( mapProtectionAllow, actionid ) then
			return true
		end

		local class = ent:GetClass()
		local initInfo = findRegexKeyInTable( initialMapProtectionInfo, class )
		if ent.UPSInitialMapEnt and initInfo and table.HasValue( initInfo, actionid ) then
			if table.HasValue( initInfo, takeOwnerless ) then
				ent:UPSSetOwnerEnt( ply )
				playTakeOwnershipSound( ply )
			end
			return true
		end

		local extendedInfo = findRegexKeyInTable( extendedMapProtectionInfo, class )
		if not ent.UPSInitialMapEnt and extendedInfo and table.HasValue( extendedInfo, actionid ) then
			if table.HasValue( extendedInfo, takeOwnerless ) then
				ent:UPSSetOwnerEnt( ply )
				playTakeOwnershipSound( ply )
			end
			return true
		end

		return false
	end
end
hook.Add( "UPSPreQuery", "UPSMapProtection", mapProtectionQuery )

function gatherInitialEnts()
	local mapEnts = ents.FindByClass( "*" )
	for _, ent in ipairs( mapEnts ) do
		ent.UPSInitialMapEnt = true
	end
end
hook.Add( "InitPostEntity", "t", gatherInitialEnts ) -- Execute after ents are created
