-- Originally written by Team Ulysses, http://ulyssesmod.net/
-- Garry-bug workaround by Ryno-SauruS. Thanks a ton!
AddCSLuaFile( "autorun/sh_uclip.lua" )
AddCSLuaFile( "autorun/cl_uclip.lua" )

module( "Uclip", package.seeall )

------------
-- Config --
------------

maxrecurse = 4 -- Max recurses. Recursion is used when we need to test a new velocity.
-- Should rarely recurse more than twice or else objects are probably wedged together.
-- (We have checks for wedged objects too so don't worry about it). 0 = disable (not recommended but shouldn't have any problems)

maxloop = 50 -- Max loops. We need to loop to find objects behind other objects. 0 = infinite (not recommended but shouldn't have any problems)
-- This *could* open an exploit, but users would be hard pressed to use it... so we'll see.

--------------------------------------------------------
-- End config. DO NOT MODIFY ANYTHING BELOW THIS LINE!--
--------------------------------------------------------

-- This checks to see if a certain player should be able to go through everything or not.
local cvar_help = "Lets admins noclip through everything if enabled."
local uclip_ignore_admins = CreateConVar( "uclip_ignore_admins", 1, { FCVAR_REPLICATED, FCVAR_ARCHIVE, FCVAR_NOTIFY }, cvar_help )
function adminCheck( ply )
	if not uclip_ignore_admins:GetBool() then return false end

	if ulx and ply:query( "ulx noclip" ) then
		return true
	elseif ply:IsAdmin() or ply:IsSuperAdmin() then
		return true
	end
	
	return false
end

noProtection = false -- If there's no protection whatsoever, this is flagged.
-- We need this flag because with a protector, we default to _not_ being able to go through things.
-- This flag saves us major memory/bandwidth when there's no protection

function checkOwnership( ply, ent )
	if ent:IsPlayer() or ent:IsNPC() then return true end -- Let players go through other players and npcs (too problematic otherwise)
	if noProtection then return true end -- No protection, they own everything.

	updateOwnership( ply, ent )	-- Make sure server and the client are current.
	return ent.Uclip[ ply ] -- This is flagged by updateOwnership. True if they own it, nil otherwise.
end

-- Check if a player is stuck in an object or in the world.
-- Returns true and ent they're stuck on if they're stuck.
function isStuck( ply, filter )
	local ang = ply:EyeAngles()
	local directions = {
		ang:Right(),
		ang:Right() * -1,
		ang:Forward(),
		ang:Forward() * -1,
		ang:Up(),
		ang:Up() * -1,
	}
	local ents = {}

	local t = {}
	t.start = ply:GetPos()
	t.filter = filter

	-- Check if they're stuck by checking each direction. A minimum number of directions should hit the same object if they're stuck.
	for _, dir in ipairs( directions ) do
		t.endpos = ply:GetPos() + dir
		local tr = util.TraceEntity( t, ply )
		if tr.Entity:IsValid() and tr.HitPos == tr.StartPos then
			ents[ tr.Entity ] = ents[ tr.Entity ] or 0
			ents[ tr.Entity ] = ents[ tr.Entity ] + 1
		end
	end

	for ent, hits in pairs( ents ) do
		if hits >= 4 then
			return true, ent
		end
	end

	return false
end

-- This function allows us to get the player's *attempted* velocity (incase we're overriding their *actual* velocity).
local sv_noclipspeed = GetConVar( "sv_noclipspeed" )
function getNoclipVel( ply )

	local noclipspeed = sv_noclipspeed:GetFloat() * 100

	local forward = ply:KeyDown( IN_FORWARD )
	local back = ply:KeyDown( IN_BACK )
	local left = ply:KeyDown( IN_MOVELEFT )
	local right = ply:KeyDown( IN_MOVERIGHT )
	local jump = ply:KeyDown( IN_JUMP )
	local duck = ply:KeyDown( IN_DUCK )
	local speed = ply:KeyDown( IN_SPEED )

	-- Convert the input to numbers so we can perform arithmetic on them, to make the code smaller and neater.
	local forwardnum = forward and 1 or 0
	local backnum = back and 1 or 0
	local leftnum = left and 1 or 0
	local rightnum = right and 1 or 0
	local jumpnum = jump and 1 or 0
	local ducknum = duck and 1 or 0
	local speednum = speed and 1 or 0

	local vel = Vector( 0, 0, 0 )

	vel = vel + ( ply:EyeAngles():Forward() * ( forwardnum - backnum ) ) -- Forward and back
	vel = vel + ( ply:EyeAngles():Right() * ( rightnum - leftnum ) ) -- Left and right
	vel = vel + ( Vector( 0, 0, 1 ) * jumpnum ) -- Up
	vel = vel:GetNormalized()
	vel = vel * noclipspeed

	if duck then
		vel = vel / 10
	end
	if speed then
		vel = vel * 3
	end

	return vel

end

-- Given a velocity, normalized velocity, and a normal:
-- Calculate the velocity toward the wall and remove it so we can "slide" across the wall.
function calcWallSlide( vel, normal )
	local toWall = normal * -1
	local velToWall = vel:Dot( toWall ) * toWall
	return vel - velToWall
end

local override_velocity -- This will be set as the current desired velocity, so we can later perform the movement manually.

function zeromove()
	override_velocity = Vector( 0, 0, 0 )
end

-- The brain of Uclip, this makes sure they can move where they want to.
function checkVel( ply, move, vel, recurse, hitnorms )

	if vel == Vector( 0, 0, 0 ) then return end -- No velocity, don't bother.

	local ft = FrameTime()

	local veln = vel:GetNormalized()
	hitnorms = hitnorms or {} -- This is used so we won't process the same normal more than once. (IE, we don't get a wedge where we have to process velocity to 0)

	recurse = recurse or 0 -- Keep track of how many recurses
	recurse = recurse + 1
	if recurse > maxrecurse and maxrecurse > 0 then -- Hard break
		zeromove()
		return
	end

	local t = {}
	t.start = ply:GetPos()
	t.endpos = ply:GetPos() + vel * ft + veln -- Add an extra unit in the direction they're headed just to be safe.
	t.filter = { ply }
	local tr = util.TraceEntity( t, ply )
	local loops = 0
	while tr.Hit do -- Recursively check all the hits. This is so we don't miss objects behind another object.
		loops = loops + 1
		if maxloop > 0 and loops > maxloop then
			zeromove()
			return
		end

		if tr.HitWorld or ( tr.Entity:IsValid() and (tr.Entity:GetClass() == "prop_dynamic" or (not checkOwnership( ply, tr.Entity ) and not isStuck( ply, t.filter ))) ) then -- If world or a prop they don't own that they're not stuck inside. Ignore prop_dynamic due to crash.
			local slide = calcWallSlide( vel, tr.HitNormal )
			override_velocity = slide

			if table.HasValue( hitnorms, tr.HitNormal ) then -- We've already processed this normal. We can get this case when the player's noclipping into a wedge.
				zeromove()
				return
			end
			table.insert( hitnorms, tr.HitNormal )

			return checkVel( ply, move, slide, recurse, hitnorms ) -- Return now so this func isn't left on stack
		end

		if tr.Entity and tr.Entity:IsValid() then -- Ent to add!
			table.insert( t.filter, tr.Entity )
		end

		tr = util.TraceEntity( t, ply )
	end
end

local sbox_noclip = GetConVar( "sbox_noclip" )
function move( ply, move )
	if ply:GetMoveType() ~= MOVETYPE_NOCLIP then return end
	if sbox_noclip:GetInt() == 2 then return end -- This allows servers to disable UClip by setting sbox_noclip to 2.
	if adminCheck( ply ) then return end -- They can go through everything..

	local ft = FrameTime()
	local vel = getNoclipVel( ply ) -- How far are they trying to move this frame?

	override_velocity = vel

	checkVel( ply, move, vel )

	if override_velocity ~= Vector( 0, 0, 0 ) then
		move:SetOrigin( move:GetOrigin() + ( override_velocity * ft ) ) -- This actually performs the movement.
	end
	move:SetVelocity( override_velocity ) -- This doesn't actually move the player (thanks to garry), it just allows other code to detect the player's velocity.

	return true -- Completely disable any engine movement, because we're doing it ourselves.

end
hook.Add( "Move", "UclipMove", move, ULib and 15 or nil ) -- If ULib is installed then set a low priority in its hook priority system.
