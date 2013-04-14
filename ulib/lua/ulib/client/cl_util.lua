--[[
	Title: Utilities

	Some client-side utilties
]]

local function ULibRPC()
	local fn_string = net.ReadString()
	local args = net.ReadTable()
	local fn = ULib.findVar( fn_string )
	if type( fn ) ~= "function" then return error( "Received bad RPC, invalid function (" .. tostring( fn_string ) .. ")!" ) end

	-- Since the table length operator can't always be trusted if there are holes in it, find the length by ourself
	local max = 0
	for k, v in pairs( args ) do
		local n = tonumber( k )
		if n and n > max then
			max = n
		end
	end

	fn( unpack( args, 1, max ) )
end
net.Receive( "URPC", ULibRPC )

--[[
	Function: umsgRcv

	Receive a umsg sent by ULib.umsgSend

	Parameters:

		um - The user message object

	Returns:

		The variable from the umsg.
]]
function ULib.umsgRcv( um, control )
	local tv = control or um:ReadChar()

	local ret -- Our return value
	if tv == ULib.TYPE_STRING then
		ret = um:ReadString()
	elseif tv == ULib.TYPE_FLOAT then
		ret = um:ReadFloat()
	elseif tv == ULib.TYPE_SHORT then
		ret = um:ReadShort()
	elseif tv == ULib.TYPE_LONG then
		ret = um:ReadLong()
	elseif tv == ULib.TYPE_BOOLEAN then
		ret = um:ReadBool()
	elseif tv == ULib.TYPE_ENTITY then
		ret = um:ReadEntity()
	elseif tv == ULib.TYPE_VECTOR then
		ret = um:ReadVector()
	elseif tv == ULib.TYPE_ANGLE then
		ret = um:ReadAngle()
	elseif tv == ULib.TYPE_CHAR then
		ret = um:ReadChar()
	elseif tv == ULib.TYPE_TABLE_BEGIN then
		ret = {}
		while true do -- Yes an infite loop. We have a break inside.
			local key = ULib.umsgRcv( um )
			if key == nil then break end -- Here's our break
			ret[ key ] = ULib.umsgRcv( um )
		end
	elseif tv == ULib.TYPE_TABLE_END then
		return nil
	elseif tv == ULib.TYPE_NIL then
		return nil
	else
		ULib.error( "Unknown type passed to umsgRcv - " .. tv )
	end

	return ret
end

-- This will play sounds client side
local function rcvSound( um )
	local str = um:ReadString()
	if not ULib.fileExists( "sound/" .. str ) then
		Msg( "[LC ULib ERROR] Received invalid sound\n" )
		return
	end

	if LocalPlayer():IsValid() then
		LocalPlayer():EmitSound( Sound( str ) )
	end
end
usermessage.Hook( "ulib_sound", rcvSound )

local cvarinfo = {} -- Stores the client cvar object indexed by name of the server cvar
local reversecvar = {} -- Stores the name of server cvars indexed by the client cvar

-- When our client side cvar is changed, notify the server to change it's cvar too.
local function clCvarChanged( cl_cvar, oldvalue, newvalue )
	if not reversecvar[ cl_cvar ] then -- Error
		return
	elseif reversecvar[ cl_cvar ].ignore then -- ignore
		reversecvar[ cl_cvar ].ignore = nil
		return
	end

	local sv_cvar = reversecvar[ cl_cvar ].sv_cvar
	RunConsoleCommand( "ulib_update_cvar", sv_cvar, newvalue )
end

-- This is the counterpart to <replicatedWithWritableCvar>. See that function for more info. We also add callbacks from here.
local function readCvar( um )
	local sv_cvar = um:ReadString()
	local cl_cvar = um:ReadString()
	local default_value = um:ReadString()
	local current_value = um:ReadString()

	cvarinfo[ sv_cvar ] = GetConVar( cl_cvar ) or CreateClientConVar( cl_cvar, default_value, false, false ) -- Make sure it's created one way or another (second case is most common)
	reversecvar[ cl_cvar ] = { sv_cvar=sv_cvar }

	ULib.queueFunctionCall( function() -- Queued to ensure we don't overload the client console
		hook.Call( ULib.HOOK_REPCVARCHANGED, _, sv_cvar, cl_cvar, nil, nil, current_value )
		if cvarinfo[ sv_cvar ]:GetString() ~= current_value then
			reversecvar[ cl_cvar ].ignore = true -- Flag so hook doesn't do anything. Flag is removed at hook.
			RunConsoleCommand( cl_cvar, current_value )
		end
	end )

	cvars.AddChangeCallback( cl_cvar, clCvarChanged )
end
usermessage.Hook( "ulib_repWriteCvar", readCvar )

-- This is called when they've attempted to change a cvar they don't have access to.
local function changeCvar( um )
	local ply = um:ReadEntity()
	local cl_cvar = um:ReadString()
	local oldvalue = um:ReadString()
	local newvalue = um:ReadString()
	local changed = oldvalue ~= newvalue

	if not reversecvar[ cl_cvar ] then -- Error!
		return
	end

	local sv_cvar = reversecvar[ cl_cvar ].sv_cvar

	ULib.queueFunctionCall( function() -- Queued so we won't overload the client console and so that changes are always going to be called via the hook AFTER the initial hook is called
		if changed then
			hook.Call( ULib.HOOK_REPCVARCHANGED, _, sv_cvar, cl_cvar, ply, oldvalue, newvalue )
		end

		if GetConVarString( cl_cvar ) ~= newvalue then
			reversecvar[ cl_cvar ].ignore = true -- Flag so hook doesn't do anything. Flag is removed at hook.
			RunConsoleCommand( cl_cvar, newvalue)
		end
	end )
end
usermessage.Hook( "ulib_repChangeCvar", changeCvar )
