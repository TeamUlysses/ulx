--[[
	Title: Player

	Holds some helpful player functions.
]]

--[[
	Table: slapSounds

	These are the sounds used for slaps.
]]
local slapSounds = {
	"physics/body/body_medium_impact_hard1.wav",
	"physics/body/body_medium_impact_hard2.wav",
	"physics/body/body_medium_impact_hard3.wav",
	"physics/body/body_medium_impact_hard5.wav",
	"physics/body/body_medium_impact_hard6.wav",
	"physics/body/body_medium_impact_soft5.wav",
	"physics/body/body_medium_impact_soft6.wav",
	"physics/body/body_medium_impact_soft7.wav",
}


--[[
	Function: slap

	Slaps an entity, can be a user or any entity.

	Parameters:

		ent - The target ent.
		damage - *(Optional, defaults to 0)* The amount of damage to inflict on the entity.
		power - *(Optional, defaults to 30)* The power of the slap.
		nosound - *(Optional, defaults to false)* If true, no sound will be played.
]]
function ULib.slap( ent, damage, power, nosound )
	if ent:GetMoveType() == MOVETYPE_OBSERVER then return end -- Nothing we can do.

	damage = damage or 0
	power = power or 500

	if ent:IsPlayer() then
		if not ent:Alive() then
			return -- Nothing we can do.
		end

		if ent:InVehicle() then
			ent:ExitVehicle()
		end

		if ent:GetMoveType() == MOVETYPE_NOCLIP then
			ent:SetMoveType( MOVETYPE_WALK )
		end
	end

	if not nosound then -- Play a slap sound
		local sound_num = math.random( #slapSounds ) -- Choose at random
		ent:EmitSound( slapSounds[ sound_num ] )
	end

	local direction = Vector( math.random( 20 )-10, math.random( 20 )-10, math.random( 20 )-5 ) -- Make it random, slightly biased to go up.
	ULib.applyAccel( ent, power, direction )

	local angle_punch_pitch = math.Rand( -20, 20 )
	local angle_punch_yaw = math.sqrt( 20*20 - angle_punch_pitch * angle_punch_pitch )
	if math.random( 0, 1 ) == 1 then
		angle_punch_yaw = angle_punch_yaw * -1
	end
	ent:ViewPunch( Angle( angle_punch_pitch, angle_punch_yaw, 0 ) )

	local newHp = ent:Health() - damage
	if newHp <= 0 then
		if ent:IsPlayer() then
			ent:Kill()
		else
			ent:Fire( "break", 1, 0 )
		end
		return
	end
	ent:SetHealth( newHp )
end

--[[
	Function: kick

	Kicks a user.

	Parameters:

		ply - The player to kick.
		reason - *(Optional)* The reason to give for kicking.
]]
function ULib.kick( ply, reason, calling_ply )
	if reason and calling_ply ~= nil then
		local nick = calling_ply:IsValid() and string.format( "%s(%s)", calling_ply:Nick(), calling_ply:SteamID() ) or "Console"
		ply:Kick( string.format( "Kicked by %s (%s)", nick, reason or "[ULX] Kicked from server" ) )
	else
		ply:Kick( reason or "[ULX] Kicked from server" )
	end
end


--[[
	Function: ban

	Bans a user.

	Parameters:

		ply - The player to ban.
		time - *(Optional)* The time in minutes to ban the person for, leave nil or 0 for permaban.
		reason - *(Optional)* The reason for banning
		admin - *(Optional)* Admin player enacting ban

	Revisions:

		v2.10 - Added support for custom ban list
]]
function ULib.ban( ply, time, reason, admin )
	if not time or type( time ) ~= "number" then
		time = 0
	end

	ULib.addBan( ply:SteamID(), time, reason, ply:Name(), admin )

	-- Load our currently banned users so we don't overwrite them
	if ULib.fileExists( "cfg/banned_user.cfg" ) then
		ULib.execFile( "cfg/banned_user.cfg" )
	end
end


--[[
	Function: kickban

	Kicks and bans a user.

	Parameters:

		ply - The player to ban.
		time - *(Optional)* The time in minutes to ban the person for, leave nil or 0 for permaban.
		reason - *(Optional)* The reason for banning
		admin - *(Optional)* Admin player enacting ban

	Revisions:

		v2.10 - Added support for custom ban list
]]
function ULib.kickban( ply, time, reason, admin )
	if not time or type( time ) ~= "number" then
		time = 0
	end

	ULib.addBan( ply:SteamID(), time, reason, ply:Name(), admin )

	-- Load our currently banned users so we don't overwrite them
	if ULib.fileExists( "cfg/banned_user.cfg" ) then
		ULib.execFile( "cfg/banned_user.cfg" )
	end
end

--[[
	Function: addBan

	Helper function to store additional data about bans.

	Parameters:

		steamid - Banned player's steamid
		time - Length of ban
		reason - *(Optional)* Reason for banning
		name - *(Optional)* Name of player banned
		admin - *(Optional)* Admin player enacting the ban

	Revisions:

		2.10 - Initial
		2.40 - If the steamid is connected, kicks them with the reason given
]]
function ULib.addBan( steamid, time, reason, name, admin )
	local strTime = time ~= 0 and string.format( "for %s minute(s)", time ) or "permanently"
	local showReason = string.format( "Banned %s: %s", strTime, reason )

	local players = player.GetAll()
	for i=1, #players do
		if players[ i ]:SteamID() == steamid then
			ULib.kick( players[ i ], showReason, admin )
		end
	end

	-- This redundant kick code is to ensure they're kicked -- even if they're joining
	game.ConsoleCommand( string.format( "kickid %s %s\n", steamid, showReason or "" ) )
	game.ConsoleCommand( string.format( "banid %f %s kick\n", time, steamid ) )
	game.ConsoleCommand( "writeid\n" )

	local admin_name
	if admin then
		admin_name = "(Console)"
		if admin:IsValid() then
			admin_name = string.format( "%s(%s)", admin:Name(), admin:SteamID() )
		end
	end

	local t = {}
	if ULib.bans[ steamid ] then
		t = ULib.bans[ steamid ]
		t.modified_admin = admin_name
		t.modified_time = os.time()
	else
		t.admin = admin_name
	end
	t.time = t.time or os.time()
	if time > 0 then
		t.unban = ( ( time * 60 ) + os.time() )
	else
		t.unban = 0
	end
	if reason then
		t.reason = reason
	end
	if name then
		t.name = name
	end
	ULib.bans[ steamid ] = t
	ULib.fileWrite( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) )
end

--[[
	Function: unban

	Unbans the given steamid.

	Parameters:

		steamid - The steamid to unban.

	Revisions:

		v2.10 - Initial
]]
function ULib.unban( steamid )

	--Default banlist
	if ULib.fileExists( "cfg/banned_user.cfg" ) then
		ULib.execFile( "cfg/banned_user.cfg" )
	end
	ULib.queueFunctionCall( game.ConsoleCommand, "removeid " .. steamid .. ";writeid\n" ) -- Execute after done loading bans

	--ULib banlist
	ULib.bans[ steamid ] = nil
	ULib.fileWrite( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) )
end

local function doInvis()
	local players = player.GetAll()
	local remove = true
	for _, player in ipairs( players ) do
		local t = player:GetTable()
		if t.invis then
			remove = false
			if player:Alive() and player:GetActiveWeapon():IsValid() then
				if player:GetActiveWeapon() ~= t.invis.wep then
					timer.Simple( 0.05, function () ULib.invisible( player, true, t.invis.vis ) end )
					t.invis.wep = player:GetActiveWeapon()
				end
			end
		end
	end

	if remove then
		hook.Remove( "Think", "InvisThink" )
	end
end

--[[
	Function: invisible

	Makes a user invisible

	Parameters:

		ply - The player to affect.
		bool - Whether they're invisible or not
		visibility - *(Optional, defaults to 0)* A number from 0 to 255 for their visibility.

	Revisions:

		v2.40 - Removes shadow when invisible
]]
function ULib.invisible( ply, bool, visibility )
	if not ply:IsValid() then return end -- This is called on a timer so we need to verify they're still connected

	if bool then
		visibility = visibility or 0
		ply:DrawShadow( false )
		ply:SetMaterial( "models/effects/vol_light001" )
		ply:SetRenderMode( RENDERMODE_TRANSALPHA )
		ply:Fire( "alpha", visibility, 0 )
		ply:GetTable().invis = { vis=visibility, wep=ply:GetActiveWeapon() }

		if IsValid( ply:GetActiveWeapon() ) then
			ply:GetActiveWeapon():SetRenderMode( RENDERMODE_TRANSALPHA )
			ply:GetActiveWeapon():Fire( "alpha", visibility, 0 )
			ply:GetActiveWeapon():SetMaterial( "models/effects/vol_light001" )
			if ply:GetActiveWeapon():GetClass() == "gmod_tool" then
				ply:DrawWorldModel( false ) -- tool gun has problems
			else
				ply:DrawWorldModel( true )
			end
		end

		hook.Add( "Think", "InvisThink", doInvis )
	else
		ply:DrawShadow( true )
		ply:SetMaterial( "" )
		ply:SetRenderMode( RENDERMODE_NORMAL )
		ply:Fire( "alpha", 255, 0 )
		local activeWeapon = ply:GetActiveWeapon()
		if IsValid( activeWeapon ) then
			activeWeapon:SetRenderMode( RENDERMODE_NORMAL )
			activeWeapon:Fire( "alpha", 255, 0 )
			activeWeapon:SetMaterial( "" )
		end
		ply:GetTable().invis = nil
	end
end


--[[
	Function: refreshBans

	Refreshes the ULib bans.
]]
function ULib.refreshBans()
	local err
	if not ULib.fileExists( ULib.BANS_FILE ) then
		ULib.bans = {}
	else
		ULib.bans, err = ULib.parseKeyValues( ULib.fileRead( ULib.BANS_FILE ) )
	end

	if err then
		Msg( "Bans file was not formatted correctly. Attempting to fix and backing up original\n" )
		if err then
			Msg( "Error while reading bans file was: " .. err .. "\n" )
		end
		Msg( "Original file was backed up to " .. ULib.backupFile( ULib.BANS_FILE ) .. "\n" )
		ULib.bans = {}
	end

	local default_bans = ""
	if ULib.fileExists( "cfg/banned_user.cfg" ) then
		ULib.execFile( "cfg/banned_user.cfg" )
		ULib.queueFunctionCall( game.ConsoleCommand, "writeid\n" )
		default_bans = ULib.fileRead( "cfg/banned_user.cfg" )
	end

	--default_bans = ULib.makePatternSafe( default_bans )
	default_bans = string.gsub( default_bans, "banid %d+ ", "" )
	default_bans = string.Explode( "\n", default_bans:gsub( "\r", "" ) )
	local ban_set = {}
	for _, v in pairs( default_bans ) do
		if v ~= "" then
			ban_set[ v ] = true
			if not ULib.bans[ v ] then
				ULib.bans[ v ] = { unban = 0 }
			end
		end
	end

	for k, v in pairs( ULib.bans ) do
		if type( v ) == "table" and type( k ) == "string" then
			local time = ( v.unban - os.time() ) / 60
			if time > 0 then
				game.ConsoleCommand( string.format( "banid %f %s\n", time, k ) )
			elseif math.floor( v.unban ) == 0 then -- We floor it because GM10 has floating point errors that might make it be 0.1e-20 or something dumb.
				if not ban_set[ k ] then
					ULib.bans[ k ] = nil
				end
			else
				ULib.bans[ k ] = nil
			end
		else
			Msg( "Warning: Bad ban data is being ignored, key = " .. tostring( k ) .. "\n" )
			ULib.bans[ k ] = nil
		end
	end

	-- We're queueing this because it will split the load out for VERY large ban files
	ULib.queueFunctionCall( function() ULib.fileWrite( ULib.BANS_FILE, ULib.makeKeyValues( ULib.bans ) ) end )
end
ULib.pcallError( ULib.refreshBans )


--[[
	Function: getSpawnInfo

	Grabs and returns player information that can be used to respawn player with same health/armor as before the spawn.

	Parameters:

		ply - The player to grab information for.


	Returns:

		Updates player object to store health and armor. Has no effect unless ULib.Spawn is used later.
]]
function ULib.getSpawnInfo( player )
	local result = {}

	local t = {}
	player.ULibSpawnInfo = t
	t.health = player:Health()
	t.armor = player:Armor()
	if player:GetActiveWeapon():IsValid() then
		t.curweapon = player:GetActiveWeapon():GetClass()
	end

	local weapons = player:GetWeapons()
	local data = {}
	for _, weapon in ipairs( weapons ) do
		printname = weapon:GetClass()
		data[ printname ] = {}
		data[ printname ].clip1 = weapon:Clip1()
		data[ printname ].clip2 = weapon:Clip2()
		data[ printname ].ammo1 = player:GetAmmoCount( weapon:GetPrimaryAmmoType() )
		data[ printname ].ammo2 = player:GetAmmoCount( weapon:GetSecondaryAmmoType() )
	end
	t.data = data
end

-- Helper function for ULib.spawn()
local function doWeapons( player, t )
	if not player:IsValid() then return end -- Drat, missed 'em.

	player:StripAmmo()
	player:StripWeapons()

	for printname, data in pairs( t.data ) do
		player:Give( printname )
		local weapon = player:GetWeapon( printname )
		weapon:SetClip1( data.clip1 )
		weapon:SetClip2( data.clip2 )
		player:SetAmmo( data.ammo1, weapon:GetPrimaryAmmoType() )
		player:SetAmmo( data.ammo2, weapon:GetSecondaryAmmoType() )
	end

	if t.curweapon then
		player:SelectWeapon( t.curweapon )
	end
end


--[[
	Function: spawn

	Enhanced spawn player. Can spawn player and return health/armor to status before the spawn. (Only IF ULib.getSpawnInfo was used previously.)
	Clears previously set values that were stored from ULib.getSpawnInfo.

	Parameters:

		ply - The player to grab information for.
		bool - If true, spawn will set player information to values stored using ULib.SpawnInfo

	Returns:

		Spawns player. Sets health/armor to stored defaults if ULib.getSpawnInfo was used previously. Clears SpawnInfo table afterwards.
]]
function ULib.spawn( player, bool )
	player:Spawn()

	if bool and player.ULibSpawnInfo then
		local t = player.ULibSpawnInfo
		player:SetHealth( t.health )
		player:SetArmor( t.armor )
		timer.Simple( 0.1, function() doWeapons( player, t ) end )
		player.ULibSpawnInfo = nil
	end
end
