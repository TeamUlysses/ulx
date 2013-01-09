--[[
	Title: Messages

	Handles messaging like logging, debug, etc.
]]


--[[
	Function: tsay

	Prints a message in talk say as well as in the user's consoles.

	Parameters:

		ply - The player to print to, set to nil to send to everyone. (Ignores this param if called on client)
		msg - The message to print.
		wait - *(Optional, defaults to false)* Wait one frame before posting. (Useful to use from things like chat hooks)
		wasValid - *(INTERNAL USE ONLY)* This is flagged on waiting if the player *was* valid.

	Revisions:

		v2.10 - Initial
]]
function ULib.tsay( ply, msg, wait, wasValid )
	ULib.checkArg( 1, "ULib.tsay", {"nil","Player","Entity"}, ply )
	ULib.checkArg( 2, "ULib.tsay", "string", msg )
	ULib.checkArg( 3, "ULib.tsay", {"nil","boolean"}, wait )

	if wait then ULib.namedQueueFunctionCall( "ULibChats", ULib.tsay, ply, msg, false, ply and ply:IsValid() ) return end -- Call next frame

	if SERVER and ply and not ply:IsValid() then -- Server console
		if wasValid then -- This means we had a valid player that left, so do nothing
			return
		end
		Msg( msg .. "\n" )
		return
	end

	if CLIENT then
		LocalPlayer():ChatPrint( msg )
		return
	end

	if ply then
		ply:ChatPrint( msg )
	else
		local players = player.GetAll()
		for _, player in ipairs( players ) do
			player:ChatPrint( msg )
		end
	end
end

local serverConsole = {} -- Used in the function below to identify the server console (internal use)

local function tsayColorCallback( ply, ... )
	if CLIENT then
		chat.AddText( ... )
		return
	end

	if ply and ply ~= serverConsole and not ply:IsValid() then return end -- Player must have left the server

	local args = { ... }

	if ply == serverConsole then
		for i=2, #args, 2 do
			Msg( args[ i ] )
		end
		Msg( "\n" );
		return
	end

	local current_chunk = { size = 0 }
	local chunks = { current_chunk }
	local max_chunk_size = 240
	while #args > 0 do
		local arg = table.remove( args, 1 )
		local typ = type( arg )
		local arg_size = typ == "table" and 4 or #arg + 2 -- Include null in strings, bool in both
		if typ == "string" and current_chunk.size + arg_size > max_chunk_size then -- Split a large string up into multiple messages
			local substr = arg:sub( 1, math.max( 1, max_chunk_size - current_chunk.size - 2 ) )
			if #substr > 0 then
				table.insert( current_chunk, substr )
			end
			table.insert( args, 1, arg:sub( #substr + 1) )

			current_chunk = { size = 0 }
			table.insert( chunks, current_chunk )
		else
			if current_chunk.size + arg_size > max_chunk_size then
				current_chunk = { size = 0 }
				table.insert( chunks, current_chunk )
			end
			current_chunk.size = current_chunk.size + arg_size
			table.insert( current_chunk, arg )
		end
	end

	for chunk_num=1, #chunks do
		local chunk = chunks[ chunk_num ]
		umsg.Start( "tsayc", ply )
			umsg.Bool( chunk_num == #chunks )
			umsg.Char( #chunk )
			for i=1, #chunk do
				local arg = chunk[ i ]
				if type( arg ) == "string" then
					umsg.Bool( true )
					umsg.String( arg )
				else
					umsg.Bool( false )
					umsg.Char( arg.r - 128 )
					umsg.Char( arg.g - 128 )
					umsg.Char( arg.b - 128 )
				end
			end
		umsg.End()
	end
end

if CLIENT then
local accumulator = {}

local function tsayColorHook( um )
	local last = um:ReadBool()
	local argn = um:ReadChar()
	for i=1, argn do
		if um:ReadBool() then
			table.insert( accumulator, um:ReadString() )
		else
			table.insert( accumulator, Color( um:ReadChar() + 128, um:ReadChar() + 128, um:ReadChar() + 128) )
		end
	end

	if last then
		chat.AddText( unpack( accumulator ) )
		accumulator = {}
	end
end
usermessage.Hook( "tsayc", tsayColorHook )
end


--[[
	Function: tsayColor

	Prints a tsay message in color!

	Parameters:

		ply - The player to print to, set to nil to send to everyone. (Ignores this param if called on client)
		wait - *(Optional, defaults to false)* Wait one frame before posting. (Useful to use from things like chat hooks)
		... - color arg and text arg ad infinitum, color needs to come before the text it's coloring.

	Revisions:

		v2.40 - Initial.
]]
function ULib.tsayColor( ply, wait, ... )
	if SERVER and ply and not ply:IsValid() then ply = serverConsole end -- Mark as server

	if wait then ULib.namedQueueFunctionCall( "ULibChats", tsayColorCallback, ply, ... ) return end -- Call next frame
	tsayColorCallback( ply, ... )
end


--[[
	Function: tsayError

	Just like tsay, but prints the string in red

	Parameters:

		ply - The player to print to, set to nil to send to everyone. (Ignores this param if called on client)
		msg - The message to print.
		wait - *(Optional, defaults to false)* Wait one frame before posting. (Useful to use from things like chat hooks)

	Revisions:

		v2.40 - Initial.
]]
function ULib.tsayError( ply, msg, wait )
	return ULib.tsayColor( ply, wait, Color( 255, 140, 39 ), msg )
end


--[[
	Function: csay

	Prints a message in center of the screen as well as in the user's consoles.

	Parameters:

		ply - The player to print to, set to nil to send to everyone. (Ignores this param if called on client)
		msg - The message to print.
		color - *(Optional)* The amount of red to use for the text.
		duration - *(Optional)* The amount of time to show the text.
		fade - *(Optional, defaults to 0.5)* The length of fade time

	Revisions:

		v2.10 - Added fade parameter. Fixed it sending the message multiple times.
		v2.40 - Changed to use clientRPC.
]]
function ULib.csay( ply, msg, color, duration, fade )
	if CLIENT then
		ULib.csayDraw( msg, color, duration )
		Msg( msg .. "\n" )
		return
	end

	ULib.clientRPC( ply, "ULib.csayDraw", msg, color, duration, fade )
	ULib.console( ply, msg )
end


--[[
	Function: console

	Prints a message in the user's consoles.

	Parameters:

		ply - The player to print to, set to nil to send to everyone. (Ignores this param if called on client)
		msg - The message to print.
]]
function ULib.console( ply, msg )
	if CLIENT or (ply and not ply:IsValid()) then
		Msg( msg .. "\n" )
		return
	end

	if ply then
		ply:PrintMessage( HUD_PRINTCONSOLE, msg .. "\n" )
	else
		local players = player.GetAll()
		for _, player in ipairs( players ) do
			player:PrintMessage( HUD_PRINTCONSOLE, msg .. "\n" )
		end
	end
end


--[[
	Function: error

	Gives an error to console.

	Parameters:

		s - The string to use as the error message
]]
function ULib.error( s )
	if CLIENT then
		Msg( "[LC ULIB ERROR] " .. s .. "\n" )
	else
		Msg( "[LS ULIB ERROR] " .. s .. "\n" )
	end
end


--[[
	Function: debugFunctionCall

	Prints a function call, very useful for debugging.

	Parameters:

		name - The name of the function called.
		... - all arguments to the function.

	Revisions:

		v2.40 - Now uses print instead of Msg, since Msg seems to have a low max length.
			Changed how the variable length params work so you can pass nil followed by more params
]]
function ULib.debugFunctionCall( name, ... )
	local args = { ... }

	print( "Function '" .. name .. "' called. Parameters:" )
	for i=1, #args do
		local value = ULib.serialize( args[ i ] )
		print( "[PARAMETER " .. i .. "]: Type=" .. type( args[ i ] ) .. "\tValue=(" .. value .. ")" )
	end
end