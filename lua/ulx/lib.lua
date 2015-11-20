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

function ulx.getVersion() -- This exists on the client as well, so feel free to use it!
	local versionStr
	local build = nil
	local usingWorkshop = false

	-- Get workshop information, if available
	local addons = engine.GetAddons()
	for i=1, #addons do
		-- Ideally we'd use the "wsid" from this table
		-- But, as of 19 Nov 2015, that is broken, so we'll work around it
		if addons[i].file:find(tostring(ulx.WORKSHOPID)) then
			usingWorkshop = true
		end
	end

	-- If we have good build data, set it in "build"
	if ULib.fileExists( "ulx.build" ) then
		local buildStr = ULib.fileRead( "ulx.build" )
		local buildNum = tonumber(buildStr)
		-- Make sure the time is something reasonable -- between the year 2014 and 2128
		if buildNum and buildNum > 1400000000 and buildNum < 5000000000 then
			build = buildNum
		end
	end

	if ulx.release then
		versionStr = string.format( "v%.02f", ulx.version )
	elseif usingWorkshop then
		versionStr = string.format( "v%.02fw", ulx.version )
	elseif build then -- It's not release and it's not workshop
		versionStr = string.format( "v%.02fd (%s)", ulx.version, os.date( "%x", build ) )
	else -- Not sure what this version is, but it's not a release
		versionStr = string.format( "v%.02fd", ulx.version )
	end

	return versionStr, ulx.version, build, usingWorkshop
end

ulx.updateAvailable = false
local function ulxUpdateCheck( body, len, headers, httpCode )
	if httpCode ~= 200 then
		return
	end

	local currentBuild = tonumber(body)
	if not currentBuild then return end

	local _, _, myBuild = ulx.getVersion()
	if myBuild < currentBuild then
		ulx.updateAvailable = true
		Msg( "[ULX] There is an update available\n" )
	end
end

local function downloadForUlxUpdateCheck()
	local _, _, myBuild, workshop = ulx.getVersion()
	if not myBuild or workshop then
		return
	end

	if ulx.release then
		http.Fetch( "https://teamulysses.github.io/ulx/ulx.build", ulxUpdateCheck )
	else
		http.Fetch( "https://raw.githubusercontent.com/TeamUlysses/ulx/master/ulx.build", ulxUpdateCheck )
	end
end
hook.Add( "Initialize", "ULXUpdateChecker", downloadForUlxUpdateCheck )

local function advertiseNewVersion( ply )
	if ply:IsAdmin() and ulx.updateAvailable and not ply.UlxUpdateAdvertised then
		ULib.tsay( ply, "[ULX] There is an update available" )
		ply.UlxUpdateAdvertised = true
	end
end
hook.Add( ULib.HOOK_UCLAUTH, "ULXAdvertiseUpdate", advertiseNewVersion )

function ulx.standardizeModel( model ) -- This will convert all model strings to be of the same type, using linux notation and single dashes.
	model = model:lower()
	model = model:gsub( "\\", "/" )
	model = model:gsub( "/+", "/" ) -- Multiple dashes
	return model
end
