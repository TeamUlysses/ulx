--[[
Uppl by Megiddo (Team Ulysses)
Version 1.0
]]--

-- Set this to 1 to affect admins and superadmins
local AffectAdmins = CreateConVar( "uppl_affectadmins", "1" )
local Disabled = CreateConVar( "uppl_disabled", "0" )

---------------------------------------
-- Don't change anything below here! --
---------------------------------------

--[[
Now we're going to change the magnetize behavior to our needs.
We're hacking it so that it will keep old values from the ent's table.
]]--

local function OnDuplicated( ply, ent, data )
	Uppl.RecordProp( ply, ent:GetModel(), ent )
end
duplicator.RegisterEntityModifier( "uppl", OnDuplicated )

local orig = construct.Magnet -- Original function
function construct.Magnet( ply, ... )
	local ent = orig( ply, ... )

	Uppl.RecordProp( ply, ent:GetModel(), ent )
	duplicator.StoreEntityModifier( ent, "uppl", {} ) -- So we'll get a callback when duplicated

	return ent
end

-----------------------------------
-- Now to the meat of our script --
-----------------------------------

if CLIENT then return end -- Just in case

local construct = construct
local Msg = Msg
local hook = hook
local ULib = ULib
local concommand = concommand
local file = file
local tonumber = tonumber
local table = table
local error = error

-- Only ULib function used. Make a dumbified version if they don't have ULib
if not ULib or not ULib.tsay then
	ULib = ULib or {}
	function ULib.tsay( ply, msg )
		ply:PrintMessage( 3, msg )
	end
end

module( "Uppl" )

LimitedModels = {}
ModelCounts = {} -- Player model counts indexed by uniqueid

function LimitModel( model, number )
	model = StandardizeModel( model )
	LimitedModels[ model ] = number
end

function StandardizeModel( model )
	model = model:lower()
	model = model:gsub( "\\", "/" )
	model = model:gsub( "/+", "/" ) -- Multiple dashes
	return model
end

function CheckModelCount( uniqueid, mdl )
	if uniqueid == nil or mdl == nil then return end -- Give up

	mdl = StandardizeModel( mdl )

	if not LimitedModels[ mdl ] then return nil, nil end

	local curcount = ModelCounts[ uniqueid ][ mdl ] -- Grab variable
	if not curcount then -- Initialize
		ModelCounts[ uniqueid ][ mdl ] = 0
		curcount = 0
	end

	return curcount, LimitedModels[ mdl ]
end

local function CheckModelSpawn( ply, mdl )
	if Disabled:GetBool() then return end -- Disabled
	if not AffectAdmins:GetBool() and (ply:IsAdmin() or ply:IsSuperAdmin()) then return end

	mdl = StandardizeModel( mdl )

	local curcount
	local max
	curcount, max = CheckModelCount( ply:UniqueID(), mdl )

	if not curcount or not max then return end -- Not restricted

	if curcount >= max then
		ULib.tsay( ply, "You have reached the limit for this prop (" .. LimitedModels[ mdl ] .. ")" )
		return false
	end
end
hook.Add( "PlayerSpawnProp", "UpplCheckModel", CheckModelSpawn )

function RecordProp( ply, mdl, ent )
	if ent.UpplOwner then return end -- Already recorded

	mdl = StandardizeModel( mdl )
	local uniqueid = ply:UniqueID()
	local curcount, max = CheckModelCount( uniqueid, mdl )

	if not curcount or not max then return end -- Not restricted

	ModelCounts[ uniqueid ][ mdl ] = curcount + 1
	ent.UpplOwner = uniqueid
end
hook.Add( "PlayerSpawnedProp", "UpplRecordProps", RecordProp )

local function RemoveProp( ent )
	if ent.UpplOwner then
		local mdl = StandardizeModel( ent:GetModel() )
		local uniqueid = ent.UpplOwner
		local curcount = ModelCounts[ uniqueid ][ mdl ]

		if curcount > 0 then -- Even though this should never happen, this assures we're not subtracting more than we had.
			ModelCounts[ uniqueid ][ mdl ] = curcount - 1
		end
	end
end
hook.Add( "EntityRemoved", "UppleRemoveProp", RemoveProp )

local function PlayerInitialSpawn( ply )
	ModelCounts[ ply:UniqueID() ] = ModelCounts[ ply:UniqueID() ] or {}
end
hook.Add( "PlayerInitialSpawn", "UpplePlayerInitialSpawn", PlayerInitialSpawn )

local function cc_upplAdd( ply, command, argv )
	if ply:IsValid() and not (ply:IsAdmin() or ply:IsSuperAdmin()) then
		ULib.tsay( ply, "You are not an admin!" )
		return
	end

	local err -- Check for errors
	if #argv < 2 then
		err = "You need at least two arguments for this command."
	elseif not file.Exists( argv[ 1 ], "GAME" ) then
		err = "That model (" .. argv[ 1 ] .. ") does not exist."
	elseif not tonumber( argv[ 2 ] ) or tonumber( argv[ 2 ] ) < 0 then
		err = "Invalid number for model " .. argv[ 1 ] .. " " .. argv[ 2 ]
	end

	if err then
		if ply:IsValid() then
			ULib.tsay( ply, err )
		else
			Msg( err .. "\n" )
		end
		return
	end

	-- Now we should be error free!
	LimitModel( argv[ 1 ], tonumber( argv[ 2 ] ) )
end
concommand.Add( "uppl_add", cc_upplAdd )
