-- Set exclusive command. Commands can check if an exclusive command is set with getExclusive()
-- and process no further. Only "big" things like jail, maul, etc should be checking and setting this.
function ulx.setExclusive( ply, action )
	ply.ULXExclusive = action
end

function ulx.getExclusive( target, ply )
	if not target.ULXExclusive then return end

	if target == ply then
		return "You are " .. target.ULXExclusive .. "!"
	else
		return target:Nick() .. " is " .. target.ULXExclusive .. "!"
	end
end

function ulx.clearExclusive( ply )
	ply.ULXExclusive = nil
end

--- No die. Don't allow the player to die!
function ulx.setNoDie( ply, bool )
	ULib.getSpawnInfo( ply )
	ply.ulxNoDie = bool
end

local function checkDeath( ply, weapon, killer )
	if ply.frozen then
		ULib.queueFunctionCall( function()
			if ply and ply:IsValid() then
				ply:UnLock()
				ply:Lock()
			end
		end )
	end

	if ply.ulxNoDie then
		ply:AddDeaths( -1 ) -- Won't show on scoreboard
		if killer == ply then -- Suicide
			ply:AddFrags( 1 ) -- Won't show on scoreboard
		end

		local pos = ply:GetPos()
		local ang = ply:EyeAngles()
		ULib.queueFunctionCall( function() -- Run next frame
			if not ply:IsValid() then return end -- Gotta make sure it's still valid since this is a timer
			ULib.spawn( ply, true )
			ply:SetPos( pos )
			ply:SetEyeAngles( ang )
		end )
		return true -- Don't register their death on HUD
	end
end
hook.Add( "PlayerDeath", "ULXCheckDeath", checkDeath, -10 ) -- Hook it first because we're blocking their death.

local function checkSuicide( ply )
	if ply.ulxNoDie then
		return false
	end
end
hook.Add( "CanPlayerSuicide", "ULXCheckSuicide", checkSuicide, - 10 )

function ulx.getVersion() -- This exists on the client as well, so feel free to use it!
	local version
	local r = 0

	if ulx.release then
		version = string.format( "%.02f", ulx.version )
	else
		if ULib.fileExists( "addons/ulx/.svn/wc.db" ) then -- SVN's new format
			-- The following code would probably work if garry allowed us to read this file...
			--[[local raw = ULib.fileRead( "addons/ulx/.svn/wc.db" )
			local highest = 0
			for rev in string.gmatch( raw, "/ulx/!svn/ver/%d+/" ) do
				if rev > highest then
					highest = rev
				end
			end
			r = highest]]
		elseif ULib.fileExists( "addons/ulx/lua/ulx/.svn/entries" ) then
			-- Garry broke the following around 05/11/2010, then fixed it again around 11/10/2010!
			local lines = string.Explode( "\n", ULib.fileRead( "lua/ulx/.svn/entries" ) )
			r = tonumber( lines[ 4 ] )
		end

		if r and r > 0 then
			version = string.format( "<SVN> revision %i", r )
		else
			version = string.format( "<SVN> unknown revision" )
		end
	end

	return version, ulx.version, r
end

function ulx.addToMenu( menuid, label, data ) -- TODO: Remove
	Msg( "Warning: ulx.addToMenu was called, which is being phased out!\n" )
end

function ulx.standardizeModel( model ) -- This will convert all model strings to be of the same type, using linux notation and single dashes.
	model = model:lower()
	model = model:gsub( "\\", "/" )
	model = model:gsub( "/+", "/" ) -- Multiple dashes
	return model
end
