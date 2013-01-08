--[[
	Title: Shared definitions

	This file defines some common needed values.
]]

module( "UPS", package.seeall )

--[[
	Variable: UPS_ADMIN

	What group to give access to everything by default.
]]
UPS_ADMIN = "admin"


--[[
	Variable: delWhitelist

	White list for objects that can't be deleted.

	Are you a STOOL author who's angry that your tool isn't on this list?
	Just add this to your code:
	> if UPS then table.insert( UPS.delWhiteList, "my_stool" ) end
]]
delWhitelist =
{
	"colour",
	"material",
	"paint",
	"hoverball",
	"emitter",
	"elastic",
	"hydraulic",
	"muscle",
	"nail",
	"ballsocket",
	"ballsocket_adv",
	"pulley",
	"rope",
	"slider",
	"weld",
	"winch",
	"balloon",
	"button",
	"duplicator",
	"dynamite",
	"keepupright",
	"lamp",
	"nocollide",
	"thruster",
	"turret",
	"wheel",
	"eyeposer",
	"faceposer",
	"statue",
	"weld_ez",
	"axis",
	
	-- Properties
	"gravity",
	"collision",
	--"keepupright", -- Already above
	"persist",
}

--[[
	Variable: moveWhitelist

	White list for objects that can't be moved.

	Are you a STOOL author who's angry that your tool isn't on this list?
	Just add this to your code:
	> if UPS then table.insert( UPS.moveWhiteList, "my_stool" ) end
]]
moveWhitelist =
{
	"colour",
	"material",
	"paint",
	"duplicator",
	"eyeposer",
	"faceposer",
	"remover",
	
	-- Properties
	--"remover", -- Already above
	"persist",
}


--[[
	Variable: ignoreList

	List of ents to just completely remove from all UPS considerations.
]]
ignoreList =
{
	"player",            -- Not our territory to mess with.
	"worldspawn",        -- The world. Leave it be.
	"gmod_anchor",       -- Used for sliders connected to the world. Could be used for other stuff too, should be safe to ignore.
	"npc_grenade_frag",  -- Grenades, no reason we should muck around with these.
	"prop_combine_ball", -- Energy balls, ditto as above.
	"npc_satchel",       -- Ditto.
}

ACTID_DAMAGE       = "damage"
ACTID_ENTERVEHICLE = "vehicle"
ACTID_FREEZE       = "freeze"
ACTID_PHYSGUN      = "physgun"
ACTID_REMOVE       = "remove"
ACTID_TOOL         = "tool" -- This is used for "non-dangerous" or third-party tools that have declared themselves safe
ACTID_UNFREEZE     = "unfreeze"
ACTID_USE          = "use"

--[[
	Variable: accessIds

	Our access ids, used for our limit UCL checks.
]]
accessIds = {
	ACTID_DAMAGE,
	ACTID_ENTERVEHICLE,
	ACTID_FREEZE,
	ACTID_PHYSGUN,
	ACTID_REMOVE,
	ACTID_TOOL,
	ACTID_UNFREEZE,
	ACTID_USE,
}

QUERY_NOSOUND = 1 -- No sound if query fails
QUERY_TAKEOWNERLESS = 2 -- Reassign ownership on prop if unowned


--[[
	Variable: ID_MCLIENT

	Used to identify client menu objects in the spawn menu.
]]
ID_MCLIENT = 1

--[[
	Variable: ID_MADMIN

	Used to identify admin menu objects in the spawn menu.
]]
ID_MADMIN = 2

FRIENDFILE = "ups/friends.txt"
DISABLEDFILE = "ups/disabledplayers.txt"
CONFIGFILE = "ups/config.txt"

-- Ensure it's created
file.CreateDir( "ups" )

--[[
	Variable: OWNERID_DEFER

	This value is returned from functions when we don't know the value requested yet
]]
OWNERID_DEFER = -3

OWNERID_MAP = -1
OWNERID_UPFORGRABS = 0
