local meta = FindMetaTable( "Player" )

ULib.spawnWhitelist = -- Tool white list for tools that don't spawn things
{
	"colour",
	"material",
	"paint",
	"ballsocket",
	"ballsocket_adv",
	"weld",
	"keepupright",
	"nocollide",
	"eyeposer",
	"faceposer",
	"statue",
	"weld_ez",
	"axis",
}

-- Return if there's nothing to add on to
if not meta then return end

function meta:DisallowNoclip( bool )
	self.NoNoclip = bool
end

function meta:DisallowSpawning( bool )
	self.NoSpawning = bool
end

function meta:DisallowVehicles( bool )
	self.NoVehicles = bool
end

local function tool( ply, tr, toolmode )
	if ply.NoSpawning then
		if not table.HasValue( ULib.spawnWhitelist, toolmode ) then
			return false
		end
	end
end
hook.Add( "CanTool", "ULibPlayerToolCheck", tool, -10 )

local function noclip( ply )
	if ply.NoNoclip then return false end
end
hook.Add( "PlayerNoClip", "ULibNoclipCheck", noclip, -10 )

local function spawnblock( ply )
	if ply.NoSpawning then return false end
end
hook.Add( "PlayerSpawnObject", "ULibSpawnBlock", spawnblock )
hook.Add( "PlayerSpawnEffect", "ULibSpawnBlock", spawnblock )
hook.Add( "PlayerSpawnProp", "ULibSpawnBlock", spawnblock )
hook.Add( "PlayerSpawnNPC", "ULibSpawnBlock", spawnblock )
hook.Add( "PlayerSpawnVehicle", "ULibSpawnBlock", spawnblock )
hook.Add( "PlayerSpawnRagdoll", "ULibSpawnBlock", spawnblock )
hook.Add( "PlayerSpawnSENT", "ULibSpawnBlock", spawnblock )
hook.Add( "PlayerGiveSWEP", "ULibSpawnBlock", spawnblock )

local function vehicleblock( ply, ent )
	if ply.NoVehicles then
		return false
	end
end
hook.Add( "CanPlayerEnterVehicle", "ULibVehicleBlock", vehicleblock, -10 )
hook.Add( "CanDrive", "ULibVehicleDriveBlock", vehicleblock, -10 )
