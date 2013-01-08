--[[
	Title: Utilities

	Some utility functions. Unlike the functions in misc.lua, this file only holds HL2 specific functions.
]]


--[[
	Function: execFile

	Executes a file on the console. Use this instead of the "exec" command when the config lies outside the cfg folder.

	Parameters:

		f - The file, relative to the data folder.
		option - An optional string stating where to pull the file from.

	Revisions:

		v2.40 - No longer strips comments, removed ability to execute on players.
		v2.50 - Added option to conform to Garry's API changes.
]]
function ULib.execFile( f, option )
	if not file.Exists( f, option ) then
		ULib.error( "Called execFile with invalid file! " .. f )
		return
	end

	ULib.execString( file.Read( f, option ) )
end


--[[
	Function: execString

	Just like <execFile>, except acts on newline-delimited strings.

	Parameters:

		f - The string.
		ply - The player to execute on. Leave nil to execute on server. (Ignores this param on client)

	Revisions:

		v2.40 - Initial.
]]
function ULib.execString( f, ply )
	local lines = string.Explode( "\n", f )

	local buffer = ""
	local buffer_lines = 0
	local exec = "exec "
	for _, line in ipairs( lines ) do
		line = string.Trim( line )
		if line:lower():sub( 1, exec:len() ) == exec then
			local dummy, dummy, cfg = line:lower():find( "^exec%s+([%w%.]+)%s*/?/?.*$")
			if not cfg:find( ".cfg", 1, true ) then cfg = cfg .. ".cfg" end -- Add it if it's not there
			ULib.execFile( "../cfg/" .. cfg, ply )
		elseif line ~= "" then
			buffer = buffer .. line .. "\n"
			buffer_lines = buffer_lines + 1

			if buffer_lines >= 10 then
				ULib.queueFunctionCall( ULib.consoleCommand, buffer )
				buffer_lines = 0
				buffer = ""
			end
		end
	end

	if buffer_lines > 0 then
		ULib.queueFunctionCall( ULib.consoleCommand, buffer )
	end
end


--[[
	Function: serialize

	Serializes a variable. It basically converts a variable into a runnable code string. It works correctly with inline tables.

	Parameters:

		v - The variable you wish to serialize

	Returns:

		The string of the serialized variable

	Revisions:

		v2.40 - Can now serialize entities and players
]]
function ULib.serialize( v )
	local t = type( v )
	local str
	if t == "string" then
		str = string.format( "%q", v )
	elseif t == "boolean" or t == "number" then
		str = tostring( v )
	elseif t == "table" then
		str = table.ToString( v )
	elseif t == "Vector" then
		str = "Vector(" .. v.x .. "," .. v.y .. "," .. v.z .. ")"
	elseif t == "Angle" then
		str = "Angle(" .. v.pitch .. "," .. v.yaw .. "," .. v.roll .. ")"
	elseif t == "Player" then
		str = tostring( v )
	elseif t == "Entity" then
		str = tostring( v )
	elseif t == "nil" then
		str = "nil"
	else
		ULib.error( "Passed an invalid parameter to serialize! (type: " .. t .. ")" )
		return
	end
	return str
end


--[[
	Function: isSandbox

	Returns true if the current gamemode is sandbox or is derived from sandbox.
]]
function ULib.isSandbox()
	return GAMEMODE.IsSandboxDerived
end


--[[
	Function: filesInDir

	Returns files in directory.

	Parameters:

		dir - The dir to look for files in.
		recurse - *(Optional, defaults to false)* If true, searches directories recursively.
		root - *INTERNAL USE ONLY* This helps with recursive functions.

	Revisions:

		v2.10 - Initial (But dragged over from GM9 archive).
		v2.40 - Fixed (was completely broken).
		v2.50 - Now assumes paths relative to base folder.
]]
function ULib.filesInDir( dir, recurse, root )
	if not file.IsDir( dir, "GAME" ) then
		return nil
	end

	local files = {}
	local relDir
	if root then
		relDir = dir:gsub( root .. "[\\/]", "" )
	end
	root = root or dir

	local result = file.Find( dir .. "/*", "GAME" )

	for i=1, #result do
		if file.IsDir( dir .. "/" .. result[ i ], "GAME" ) and recurse then
			files = table.Add( files, ULib.filesInDir( dir .. "/" .. result[ i ], recurse, root ) )
		else
			if not relDir then
				table.insert( files, result[ i ] )
			else
				table.insert( files, relDir .. "/" .. result[ i ] )
			end
		end
	end

	return files
end


-- Helper function for <queueFunctionCall()>
local stacks = {}
local function onThink()
	local remove = true
	for queueName, stack in pairs( stacks ) do
		local num = #stack
		if num > 0 then
			remove = false
			local b, e = pcall( stack[ 1 ].fn, unpack( stack[ 1 ], 1, stack[ 1 ].n ) )
			if not b then
				ErrorNoHalt( "ULib queue error: " .. tostring( e ) .. "\n" )
			end
			table.remove( stack, 1 ) -- Remove the first inserted item. This is FIFO
		end
	end
	
	if remove then
		hook.Remove( "Think", "ULibQueueThink" )
		if game.IsDedicated() then
			hook.Remove( "GetGameDescription", "ULibQueueThink" )
		end
	end
end


--[[
	Function: queueFunctionCall

	Adds a function call to the queue to be called. Guaranteed to be called sometime after the current frame. Very handy
	when you need to delay a call for some reason. Uses a think hook, but it's only hooked when there's stuff in the queue.

	Parameters:

		fn - The function to call
		... - *(Optional)* The parameters to pass to the function

	Revisions:

		v2.40 - Initial (But dragged over from UPS).
]]
function ULib.queueFunctionCall( fn, ... )
	if type( fn ) ~= "function" then
		error( "queueFunctionCall received a bad function", 2 )
		return
	end

	ULib.namedQueueFunctionCall( "defaultQueueName", fn, ... )
end

--[[
	Function: namedQueueFunctionCall

	Exactly like <queueFunctionCall()>, but allows for separately running queues to exist.
	
	Parameters:

		queueName - The unique name of the queue (the queue group)
		fn - The function to call
		... - *(Optional)* The parameters to pass to the function

	Revisions:

		v2.50 - Initial.
]]
function ULib.namedQueueFunctionCall( queueName, fn, ... )
	if type( fn ) ~= "function" then
		error( "queueFunctionCall received a bad function", 2 )
		return
	end

	stacks[ queueName ] = stacks[ queueName ] or {}
	table.insert( stacks[ queueName ], { fn=fn, n=select( "#", ... ), ... } )
	hook.Add( "Think", "ULibQueueThink", onThink, -20 )
	if game.IsDedicated() then -- If it's a ded server we need another hook to make sure stuff runs even before players join
		hook.Add( "GetGameDescription", "ULibQueueThink", onThink, -20 )
	end
end


--[[
	Function: backupFile

	Copies a file to a backup file. If a backup file already exists, makes incrementing numbered backup files.

	Parameters:

		f - The file to backup

	Returns:

		The pathname of the file it was backed up to.

	Revisions:

		v2.40 - Initial.
]]
function ULib.backupFile( f )
	local contents = file.Read( f, "DATA" )
	local filename = f:GetFileFromFilename():sub( 1, -5 ) -- Remove '.txt'
	local folder = f:GetPathFromFilename()

	local num = 1
	local targetPath = folder .. filename .. "_backup.txt"
	while file.Exists( targetPath, "DATA" ) do
		num = num + 1
		targetPath = folder .. filename .. "_backup" .. num .. ".txt"
	end

	-- We now have a filename that doesn't yet exist!
	file.Write( targetPath, contents )

	return targetPath
end

--[[
	Function: nameCheck

	Checks all players' names at regular intervals to detect name changes. Calls ULibPlayerNameChanged if the name changed. *DO NOT CALL DIRECTLY*

	Revisions:

		2.20 - Initial
]]
function ULib.nameCheck()
	local players = player.GetAll()
	for _, ply in ipairs( players ) do
		if not ply.ULibLastKnownName then ply.ULibLastKnownName = ply:Nick() end

		if ply.ULibLastKnownName ~= ply:Nick() then
			hook.Call( ULib.HOOK_PLAYER_NAME_CHANGED, nil, ply, ply.ULibLastKnownName, ply:Nick() )
			ply.ULibLastKnownName = ply:Nick()
		end
	end
end
timer.Create( "ULibNameCheck", 1, 0, ULib.nameCheck )


--[[
	Function: getPlyByUID

	Parameters:

		uid - The uid to lookup.

	Returns:

		The player that has the specified unique id, nil if none exists.

	Revisions:

		v2.40 - Initial.
]]
function ULib.getPlyByUID( uid )
	local players = player.GetAll()
	for _, ply in ipairs( players ) do
		if ply:UniqueID() == uid then
			return ply
		end
	end

	return nil
end


--[[
	Function: pcallError
	
	An adaptation of a function that used to exist before GM13, allows you to 
	call functions safely and print errors (if it errors).

	Parameters:

		... - Arguments to pass to the function

	Returns:

		The same thing regular pcall returns

	Revisions:

		v2.50 - Initial.
]]
function ULib.pcallError( ... )
	local returns = { pcall( ... ) }
	
	if not returns[ 1 ] then -- The status flag
		ErrorNoHalt( returns[ 2 ] ) -- The error message
	end
	
	return unpack( returns )	
end

--- TEMP fix for garry's broken API (Hopefully he fixes this soon, still broken as of official GM13 release)

local oldExists = file.Exists
function file.Exists( path, option )
	if option == "DATA" then
		option = "GAME"
		path = "data/" .. path
	end
	return oldExists( path, option )
end

local oldRead = file.Read
function file.Read( path, option )
	if option == "DATA" then
		option = "GAME"
		path = "data/" .. path
	end
	return oldRead( path, option )
end
