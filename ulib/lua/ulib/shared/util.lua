--[[
	Title: Utilities

	Some utility functions. Unlike the functions in misc.lua, this file only holds HL2 specific functions.
]]

local dataFolder = "data"
--[[
	Function: fileExists

	Checks for the existence of a file by path.

	Parameters:

		f - The path to check, rooted at the garry's mod root directory.

	Returns:

		True if the file exists, false otherwise.

	Revisions:

		v2.51 - Initial revision (tired of Garry changing his API all the time).
]]
function ULib.fileExists( f )
	local isDataFolder = f:lower():sub( 1, dataFolder:len() ) ~= dataFolder
	fWoData = f:sub( dataFolder:len() + 2 ) -- +2 removes path seperator

	return file.Exists( f, "GAME" ) or (isDataFolder and file.Exists( fWoData, "DATA" ))
end

--[[
	Function: fileRead

	Reads a file and returns the contents. This function is not very forgiving on providing oddly formatted filepaths.

	Parameters:

		f - The file to read, rooted at the garrysmod directory.

	Returns:

		The file contents or nil if the file does not exist.

	Revisions:

		v2.51 - Initial revision (tired of Garry changing his API all the time).
]]
function ULib.fileRead( f )
	local isDataFolder = f:lower():sub( 1, dataFolder:len() ) == dataFolder
	fWoData = f:sub( dataFolder:len() + 2 ) -- +2 removes path seperator

	if not ULib.fileExists( f ) then
		return nil
	end

	if not isDataFolder then
		return file.Read( f, "GAME" )
	else
		if file.Exists( fWoData, "DATA" ) then
			return file.Read( fWoData, "DATA" )
		else
			return file.Read( f, "GAME" )
		end
	end
end

--[[
	Function: fileWrite

	Writes file content.

	Parameters:

		f - The file path to write to, rooted at the garrysmod directory.
		content - The content to write.

	Revisions:

		v2.51 - Initial revision (tired of Garry changing his API all the time).
]]
function ULib.fileWrite( f, content )
	local isDataFolder = f:lower():sub( 1, dataFolder:len() ) == dataFolder
	fWoData = f:sub( dataFolder:len() + 2 ) -- +2 removes path seperator

	if not isDataFolder then return nil end

	file.Write( fWoData, content )
end


--[[
	Function: fileAppend

	Append to file content.

	Parameters:

		f - The file path to append to, rooted at the garrysmod directory.
		content - The content to append.

	Revisions:

		v2.51 - Initial revision (tired of Garry changing his API all the time).
]]
function ULib.fileAppend( f, content )
	local isDataFolder = f:lower():sub( 1, dataFolder:len() ) == dataFolder
	fWoData = f:sub( dataFolder:len() + 2 ) -- +2 removes path seperator

	if not isDataFolder then return nil end

	file.Append( fWoData, content )
end


--[[
	Function: fileCreateDir

	Create a directory.

	Parameters:

		f - The directory path to create, rooted at the garrysmod directory.

	Revisions:

		v2.51 - Initial revision (tired of Garry changing his API all the time).
]]
function ULib.fileCreateDir( f )
	local isDataFolder = f:lower():sub( 1, dataFolder:len() ) == dataFolder
	fWoData = f:sub( dataFolder:len() + 2 ) -- +2 removes path seperator

	if not isDataFolder then return nil end

	file.CreateDir( fWoData )
end


--[[
	Function: fileDelete

	Delete file contents.

	Parameters:

		f - The file path to delete, rooted at the garrysmod directory.

	Revisions:

		v2.51 - Initial revision (tired of Garry changing his API all the time).
]]
function ULib.fileDelete( f )
	local isDataFolder = f:lower():sub( 1, dataFolder:len() ) == dataFolder
	fWoData = f:sub( dataFolder:len() + 2 ) -- +2 removes path seperator

	if not isDataFolder then return nil end

	file.Delete( fWoData )
end


--[[
	Function: fileIsDir

	Is file a directory?

	Parameters:

		f - The file path to check, rooted at the garrysmod directory.

	Returns:

		True if dir, false otherwise.

	Revisions:

		v2.51 - Initial revision (tired of Garry changing his API all the time).
]]
function ULib.fileIsDir( f )
	return file.IsDir( f, "GAME" )
end


--[[
	Function: execFile

	Executes a file on the console. Use this instead of the "exec" command when the config lies outside the cfg folder.

	Parameters:

		f - The file, relative to the garrysmod folder.
		queueName - The queue name to ULib.namedQueueFunctionCall to use.

	Revisions:

		v2.40 - No longer strips comments, removed ability to execute on players.
		v2.50 - Added option to conform to Garry's API changes and queueName to specify queue name to use.
		v2.51 - Removed option parameter.
]]
function ULib.execFile( f, queueName )
	if not ULib.fileExists( f ) then
		ULib.error( "Called execFile with invalid file! " .. f )
		return
	end

	ULib.execString( ULib.fileRead( f ), queueName )
end


--[[
	Function: execString

	Just like <execFile>, except acts on newline-delimited strings.

	Parameters:

		f - The string.
		queueName - The queue name to ULib.namedQueueFunctionCall to use.

	Revisions:

		v2.40 - Initial.
		v2.50 - Added queueName to specify queue name to use. Removed ability to execute on players.
]]
function ULib.execString( f, queueName )
	local lines = string.Explode( "\n", f )

	local buffer = ""
	local buffer_lines = 0
	local exec = "exec "
	for _, line in ipairs( lines ) do
		line = string.Trim( line )
		if line:lower():sub( 1, exec:len() ) == exec then
			local dummy, dummy, cfg = line:lower():find( "^exec%s+([%w%.]+)%s*/?/?.*$")
			if not cfg:find( ".cfg", 1, true ) then cfg = cfg .. ".cfg" end -- Add it if it's not there
			ULib.execFile( "cfg/" .. cfg, queueName )
		elseif line ~= "" then
			buffer = buffer .. line .. "\n"
			buffer_lines = buffer_lines + 1

			if buffer_lines >= 10 then
				ULib.namedQueueFunctionCall( queueName, ULib.consoleCommand, buffer )
				buffer_lines = 0
				buffer = ""
			end
		end
	end

	if buffer_lines > 0 then
		ULib.namedQueueFunctionCall( queueName, ULib.consoleCommand, buffer )
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
	if not ULib.fileIsDir( dir ) then
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
		if ULib.fileIsDir( dir .. "/" .. result[ i ] ) and recurse then
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
	queueName = queueName or "defaultQueueName"
	if type( fn ) ~= "function" then
		error( "queueFunctionCall received a bad function", 2 )
		return
	end

	stacks[ queueName ] = stacks[ queueName ] or {}
	table.insert( stacks[ queueName ], { fn=fn, n=select( "#", ... ), ... } )
	hook.Add( "Think", "ULibQueueThink", onThink, -20 )
end


--[[
	Function: backupFile

	Copies a file to a backup file. If a backup file already exists, makes incrementing numbered backup files.

	Parameters:

		f - The file to backup, rooted in the garrysmod directory.

	Returns:

		The pathname of the file it was backed up to.

	Revisions:

		v2.40 - Initial.
]]
function ULib.backupFile( f )
	local contents = ULib.fileRead( f )
	local filename = f:GetFileFromFilename():sub( 1, -5 ) -- Remove '.txt'
	local folder = f:GetPathFromFilename()

	local num = 1
	local targetPath = folder .. filename .. "_backup.txt"
	while ULib.fileExists( targetPath ) do
		num = num + 1
		targetPath = folder .. filename .. "_backup" .. num .. ".txt"
	end

	-- We now have a filename that doesn't yet exist!
	ULib.fileWrite( targetPath, contents )

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
