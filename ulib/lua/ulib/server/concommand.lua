--[[
	Title: Concommand Helpers

	Server-side compliment of the shared commands.lua
]]

--[[
	Table: sayCmds

	This table holds our say commands.
]]
ULib.sayCmds = {}

--[[
	Function: sayCmdCheck

	Say callback which will check to see if there's a say command being used. *DO NOT CALL DIRECTLY*

	Parameters:

		ply - The player.
		strText - The text.
		bTeam - Team say.

	Revisions:

		v2.10 - Made case-insensitive
]]
local function sayCmdCheck( ply, strText, bTeam )
	local match
	for str, data in pairs( ULib.sayCmds ) do
		local str2 = str
		if strText:len() < str:len() then -- Go ahead and allow commands w/o spaces
			str2 = string.Trim( str )
		end

		if strText:sub( 1, str2:len() ):lower() == str2 then
			if not match or match:len() <= str:len() then -- Don't rematch if there's a more specific one already.
				match = str
			end
		end
	end

	if match then -- We've got a winner!
		local data = ULib.sayCmds[ match ]

		local args = string.Trim( strText:sub( match:len() + 1 ) ) -- Strip the caller command out
		local argv = ULib.splitArgs( args )

		-- ULib command callback
		if data.__cmd then
			local return_value = hook.Call( ULib.HOOK_COMMAND_CALLED, _, ply, data.__cmd, argv )
			if return_value == false then
				return nil
			end
		end

		if not ULib.ucl.query( ply, data.access ) then
			ULib.tsay( ply, "You do not have access to this command, " .. ply:Nick() .. "." )
			-- Print their name to intimidate them :)
			return "" -- Block from appearing
		end

		local fn = data.fn
		local hide = data.hide

		ULib.pcallError( fn, ply, match:Trim(), argv, args )
		if hide then return "" end
	end

	return nil
end
hook.Add( "PlayerSay", "ULib_saycmd", sayCmdCheck, -10 ) -- High-priority


--[[
	Function: addSayCommand

	Just like ULib's <concommand()> except that the callback is called when the command is said in chat instead of typed in the console.

	Parameters:

		say_cmd - A command string for says. IE: "!kick", then when someone says "!kick", it'll call the callback.
		fn_call - The function to call when the command's called.
		access - The access string to associate access with this say command. (IE: "ulx kick"). Remember to call <ULib.ucl.registerAccess()> if the access string isn't being used in a command.
		hide_say - *(Optional, defaults to false)* If true, will hide the chat message. Use this if you don't want other people to see the command.
		nospace - *(Optional, defaults to false)* If true, a space won't be required after the command "IE: !slapbob" vs "!slap bob".

	Revisions:

		v2.10 - Added nospace parameter, made case insensitive
		v2.40 - Removed the command help parameter, now accepts nil as access (for always allowed)
]]
function ULib.addSayCommand( say_cmd, fn_call, access, hide_say, nospace )
	say_cmd = string.Trim( say_cmd:lower() )

	if not nospace then
		say_cmd = say_cmd .. " "
	end

	ULib.sayCmds[ say_cmd ] = { fn=fn_call, hide=hide_say, access=access }
end


--[[
	Function: removeSayCommand

	Removes a say command.

	Parameters:

		say_cmd - The command string for says to remove.
]]
function ULib.removeSayCommand( say_cmd )
	ULib.sayCmds[ say_cmd ] = nil -- Remove both forms
	ULib.sayCmds[ say_cmd .. " " ] = nil
end
