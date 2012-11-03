--[[
	Title: Client library
	
	Even more library stuff that executes on the client.
]]

module( "UPS", package.seeall )

local function readName( um )	
	local id = um:ReadString()
	local name = um:ReadString()
	
	nameToID( id, name )
end
usermessage.Hook( "ups_readnames", readName )

local function denysound( um )	
	LocalPlayer():EmitSound( Sound( cDenySound:GetString() ) )
end
usermessage.Hook( "ups_denysound", denysound )

-- We can't stick this in our main menu module in the event they remove/replace the module.
adminMenuContents = {}
clientMenuContents = {}

--[[
	Function: addToMenu

	Adds to the client or admin menu

	Parameters:

		menuid - The ID for the menu to add to, see <ID_MCLIENT> and <ID_MADMIN>.
		callback  - The function to callback to add content to the menu. This callback will receive an argument of the menu to add to.
]]
function addToMenu( menuid, callback )
	if type( callback ) ~= "function" then
		ErrorNoHalt( "Bad callback passed to UPS.addToMenu" )
		return
	end
	
	if menuid == ID_MCLIENT then
		table.insert( clientMenuContents, callback )
	elseif menuid == ID_MADMIN then
		table.insert( adminMenuContents, callback )
	else
		ErrorNoHalt( "Bad id passed to UPS.addToMenu" )
	end
end

local function spawnMenuOpen()
	local admin = GetControlPanel( "UPSAdmin" )
	admin:ClearControls()
	admin:AddHeader()
	for _, callback in ipairs( adminMenuContents ) do
		-- Call hook function
		b, retval = pcall( callback, admin )

		if not b then
				ErrorNoHalt( tostring( retval ) )
		end
	end
	
	local client = GetControlPanel( "UPSClient" )
	client:ClearControls()
	client:AddHeader()
	for _, callback in ipairs( clientMenuContents ) do
		-- Call hook function
		b, retval = pcall( callback, client )

		if not b then
			ErrorNoHalt( tostring( retval ) )
		end
	end
end
hook.Add( "SpawnMenuOpen", "UPSMenuSpawnMenuOpen", spawnMenuOpen )

local function removeId( um )	
	local uid = um:ReadString()
	local bool = um:ReadBool()
	
	deleteAll( uid, bool )
end
usermessage.Hook( "ups_removeid", removeId )

function requestOwner( ent )
	RunConsoleCommand( "ups_requestowner", ent:EntIndex() )
end

function getOwner( um )
	local entid = um:ReadShort()
	local ent = Entity( entid )
	if not ent or not ent:IsValid() then return end -- Not valid
	
	local ownerid = tonumber( um:ReadString() )
	ent.UOwn = ownerid
end
usermessage.Hook( "ups_ownerinfo", getOwner )

--Some client cvars
cDenySound = CreateClientConVar( "ups_cl_denysound", "player/suit_denydevice.WAV", true, false )
cPlayDenySound = CreateClientConVar( "ups_cl_playdenysound", "1", true, true )
