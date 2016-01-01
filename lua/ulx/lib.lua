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
hook.Add( "PlayerDeath", "ULXCheckDeath", checkDeath, HOOK_HIGH ) -- Hook it first because we're blocking their death.

local function checkSuicide( ply )
	if ply.ulxNoDie then
		return false
	end
end
hook.Add( "CanPlayerSuicide", "ULXCheckSuicide", checkSuicide, HOOK_HIGH )


local function advertiseNewVersions( ply )
	if ply:IsAdmin() and not ply.ULX_UpdatesAdvertised then
		local updatesFor = {}
		for name, plugin in pairs (ULib.plugins) do
			myBuild = tonumber( plugin.BuildNumLocal )
			curBuild = tonumber( plugin.BuildNumRemote )
			if myBuild and curBuild and myBuild < curBuild then
				table.insert( updatesFor, name )
			end
		end
		if #updatesFor > 0 then
			ULib.tsay( ply, "[ULX] Updates available for " .. string.Implode( ", ", updatesFor ) )
		end
		ply.ULX_UpdatesAdvertised = true
	end
end
hook.Add( ULib.HOOK_UCLAUTH, "ULXAdvertiseUpdates", advertiseNewVersions )


function ulx.standardizeModel( model ) -- This will convert all model strings to be of the same type, using linux notation and single dashes.
	model = model:lower()
	model = model:gsub( "\\", "/" )
	model = model:gsub( "/+", "/" ) -- Multiple dashes
	return model
end
