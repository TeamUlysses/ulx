local meta = FindMetaTable( "Entity" )

-- Return if there's nothing to add on to
if not meta then return end


-- Are you a STOOL author who's angry that your tool isn't on this list?
-- Just add this to your code:
-- if ULib then table.insert( ULib.delWhiteList, "my_stool" ) end
ULib.delWhitelist = -- White list for objects that can't be deleted
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

-- Are you a STOOL author who's angry that your tool isn't on this list?
-- Just add this to your code:
-- if ULib then table.insert( ULib.moveWhiteList, "my_stool" ) end
ULib.moveWhitelist = -- White list for objects that can't be moved
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

function meta:DisallowMoving( bool )
	self.NoMoving = bool
end

function meta:DisallowDeleting( bool, callback, no_replication )
	self.NoDeleting = bool
	self.NoDeletingCallback = callback
	self.NoReplication = no_replication
end

local function tool( ply, tr, toolmode, second )
	-- In the case of the nail gun, let's check the entity they're nailing TO first.
	if toolmode == "nail" and not second then
		local tr2 = {}
		tr2.start = tr.HitPos
		tr2.endpos = tr.HitPos + ply:GetAimVector() * 16
		tr2.filter = { ply, tr.Entity }
		local trace = util.TraceLine( tr2 )

		if trace.Entity and trace.Entity:IsValid() and not trace.Entity:IsPlayer() then
			local ret = tool( ply, trace, toolmode, true )
			if ret ~= nil then
				return ret
			end
		end
	end

	-- In the case of the remover, we have to make sure they're not trying to right click remove one of no delete ents
	if toolmode == "remover" and ply:KeyDown( IN_ATTACK2 ) and not ply:KeyDownLast( IN_ATTACK2 ) then
		local ConstrainedEntities = constraint.GetAllConstrainedEntities( tr.Entity )
		if ConstrainedEntities then -- If we have anything to worry about
			-- Loop through all the entities in the system
			for _, ent in pairs( ConstrainedEntities ) do
				if ent.NoDeleting then
					ULib.tsay( ply, "You cannot use a right click delete on this ent because it is constrained to a non-deleteable entity." )
					return false
				end
			end
		end
	end

	if tr.Entity.NoMoving then
		if not table.HasValue( ULib.moveWhitelist, toolmode ) then
			return false
		end
	end

	if tr.Entity.NoDeleting then
		if not table.HasValue( ULib.delWhitelist, toolmode ) then
			return false
		end
	end
end
hook.Add( "CanTool", "ULibEntToolCheck", tool, -10 )

local function property( ply, propertymode, ent )
	if ent.NoMoving then
		if not table.HasValue( ULib.moveWhitelist, toolmode ) then
			return false
		end
	end
	
	if ent.NoDeleting then
		if not table.HasValue( ULib.delWhitelist, toolmode ) then
			return false
		end
	end
end
hook.Add( "CanProperty", "ULibEntPropertyCheck", property, -19 )

local function physgun( ply, ent )
	if ent.NoMoving then return false end
end
hook.Add( "PhysgunPickup", "ULibEntPhysCheck", physgun, -10 )
hook.Add( "CanPlayerUnfreeze", "ULibEntUnfreezeCheck", physgun, -10 )

local function physgunReload( weapon, ply )
	local trace = util.GetPlayerTrace( ply )
	local tr = util.TraceLine( trace )

	local ent = tr.Entity
	if not ent or not ent:IsValid() or ent:IsWorld() then return end -- Invalid or not interested
	if ent.NoMoving then return false end
end
hook.Add( "OnPhysgunReload", "ULibEntPhysReloadCheck", physgunReload, -10 )

local function damageCheck( ent )
	if ent.NoDeleting then
		-- return false
	end
end
hook.Add( "EntityTakeDamage", "ULibEntDamagedCheck", damageCheck, -20 )

-- This is just in case we have some horribly programmed addon that goes rampant in deleting things
local function removedCheck( ent )
	if ent.NoDeleting and not ent.NoReplication then
		local class = ent:GetClass()
		local pos = ent:GetPos()
		local ang = ent:GetAngles()
		local model = ent:GetModel()
		local frozen = false
		if ent:GetPhysicsObject():IsValid() and not ent:GetPhysicsObject():IsMoveable() then
			frozen = true
		end
		local t = ent:GetTable()

		ULib.queueFunctionCall( function() -- Create it next frame because 1. Old ent won't be in way and 2. We won't overflow the server while shutting down
			local ent2 = ents.Create( class )
			table.Merge( ent2:GetTable(), t )
			ent2:SetModel( model )
			ent2:SetPos( pos )
			ent2:SetAngles( ang )
			ent2:Spawn()
			if frozen then
				ent2:GetPhysicsObject():EnableMotion( false )
			end

			if ent2.NoDeletingCallback then
				ent2.NoDeletingCallback( ent, ent2 )
			end
		end )
	end
end
hook.Add( "EntityRemoved", "ULibEntRemovedCheck", removedCheck, -20 )
