--[[
	Function: redirect

	This redirects any command to the server.

	*DO NOT CALL DIRECTLY*

	Parameters:

		ply - The player using the command
		command - The command being used
		argv - The table of arguments
]]
function ULib.redirect( ply, command, argv )
	RunConsoleCommand( "_u", command, unpack( argv ) )
end