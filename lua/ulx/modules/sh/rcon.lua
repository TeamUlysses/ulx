-- This module holds any type of remote execution functions (IE, 'dangerous')
local CATEGORY_NAME = "Rcon"

function ulx.rcon( calling_ply, command )
	ULib.consoleCommand( command .. "\n" )

	ulx.fancyLogAdmin( calling_ply, true, "#A ran rcon command: #s", command )
end
local rcon = ulx.command( CATEGORY_NAME, "ulx rcon", ulx.rcon, "!rcon", true )
rcon:addParam{ type=ULib.cmds.StringArg, hint="command", ULib.cmds.takeRestOfLine }
rcon:defaultAccess( ULib.ACCESS_SUPERADMIN )
rcon:help( "Execute command on server console." )

function ulx.luaRun( calling_ply, command )
	local return_results = false
	if command:sub( 1, 1 ) == "=" then
		command = "tmp_var" .. command
		return_results = true
	end

	RunString( command )

	if return_results then
		if type( tmp_var ) == "table" then
			ULib.console( calling_ply, "Result:" )
			local lines = ULib.explode( "\n", ulx.dumpTable( tmp_var ) )
			local chunk_size = 50
			for i=1, #lines, chunk_size do -- Break it up so we don't overflow the client
				ULib.queueFunctionCall( function()
					for j=i, math.min( i+chunk_size-1, #lines ) do
						ULib.console( calling_ply, lines[ j ]:gsub( "%%", "<p>" ) )
					end
				end )
			end
		else
			ULib.console( calling_ply, "Result: " .. tostring( tmp_var ):gsub( "%%", "<p>" ) )
		end
	end

	ulx.fancyLogAdmin( calling_ply, true, "#A ran lua: #s", command )
end
local luarun = ulx.command( CATEGORY_NAME, "ulx luarun", ulx.luaRun )
luarun:addParam{ type=ULib.cmds.StringArg, hint="command", ULib.cmds.takeRestOfLine }
luarun:defaultAccess( ULib.ACCESS_SUPERADMIN )
luarun:help( "Executes lua in server console. (Use '=' for output)" )

function ulx.exec( calling_ply, config )
	if string.sub( config, -4 ) ~= ".cfg" then config = config .. ".cfg" end
	if not ULib.fileExists( "cfg/" .. config ) then
		ULib.tsayError( calling_ply, "That config does not exist!", true )
		return
	end

	ULib.execFile( "cfg/" .. config )
	ulx.fancyLogAdmin( calling_ply, "#A executed file #s", config )
end
local exec = ulx.command( CATEGORY_NAME, "ulx exec", ulx.exec )
exec:addParam{ type=ULib.cmds.StringArg, hint="file" }
exec:defaultAccess( ULib.ACCESS_SUPERADMIN )
exec:help( "Execute a file from the cfg directory on the server." )

function ulx.cexec( calling_ply, target_plys, command )
	for _, v in ipairs( target_plys ) do
		v:ConCommand( command )
	end

	ulx.fancyLogAdmin( calling_ply, "#A ran #s on #T", command, target_plys )
end
local cexec = ulx.command( CATEGORY_NAME, "ulx cexec", ulx.cexec, "!cexec" )
cexec:addParam{ type=ULib.cmds.PlayersArg }
cexec:addParam{ type=ULib.cmds.StringArg, hint="command", ULib.cmds.takeRestOfLine }
cexec:defaultAccess( ULib.ACCESS_SUPERADMIN )
cexec:help( "Run a command on console of target(s)." )

function ulx.ent( calling_ply, classname, params )
	if not calling_ply:IsValid() then
		Msg( "Can't create entities from dedicated server console.\n" )
		return
	end

	classname = classname:lower()
	newEnt = ents.Create( classname )

	-- Make sure it's a valid ent
	if not newEnt or not newEnt:IsValid() then
		ULib.tsayError( calling_ply, "Unknown entity type (" .. classname .. "), aborting.", true )
		return
	end

	local trace = calling_ply:GetEyeTrace()
	local vector = trace.HitPos
	vector.z = vector.z + 20

	newEnt:SetPos( vector ) -- Note that the position can be overridden by the user's flags

	params:gsub( "([%w%p]+)\"?:\"?([%w%p]+)", function( key, value )
		newEnt:SetKeyValue( key, value )
	end )

	newEnt:Spawn()
	newEnt:Activate()

	undo.Create( "ulx_ent" )
		undo.AddEntity( newEnt )
		undo.SetPlayer( calling_ply )
	undo.Finish()

	if not params or params == "" then
		ulx.fancyLogAdmin( calling_ply, "#A created ent #s", classname )
	else
		ulx.fancyLogAdmin( calling_ply, "#A created ent #s with params #s", classname, params )
	end
end
local ent = ulx.command( CATEGORY_NAME, "ulx ent", ulx.ent )
ent:addParam{ type=ULib.cmds.StringArg, hint="classname" }
ent:addParam{ type=ULib.cmds.StringArg, hint="<flag>:<value>", ULib.cmds.takeRestOfLine, ULib.cmds.optional }
ent:defaultAccess( ULib.ACCESS_SUPERADMIN )
ent:help( "Spawn an ent, separate flag and value with ':'." )
