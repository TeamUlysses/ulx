--[[
	File: Commands
]]

ULib.cmds = {}
local cmds = ULib.cmds -- To save my fingers

--[[
	Variable: cmds.optional

	This is used when specifying an argument to flag the argument as optional.
]]
cmds.optional = {} -- This is just a key, ignore the fact that it's a table.

--[[
	Variable: cmds.restrictToCompletes

	This is used when specifying a string argument to flag that only what was
	specified for autocomplete is allowed to be passed as a valid argument.
]]
cmds.restrictToCompletes = {} -- Key

--[[
	Variable: cmds.takeRestOfLine

	This is used when specifying a string argument to flag that this argument
	should use up any remaining args, whether quoted as one arg or not. This
	is useful for things like specifying a ban reason where you don't want to
	force users to write an entire sentence within quotes.
]]
cmds.takeRestOfLine = {} -- Key

--[[
	Variable: cmds.round

	This is used when specifying a number argument to flag the argument to round
	the number to the nearest integer.
]]
cmds.round = {} -- Key

--[[
	Variable: cmds.ignoreCanTarget

	This is used when specifying a command that should ignore the can_target
	property in the groups config. IE, private say in ULX uses this so that
	users can target admins to chat with them.
]]
cmds.ignoreCanTarget = {} -- Key

--[[
	Variable: cmds.allowTimeString

	This is used when specyfing a number argument that should allow time string
	representations to be parsed (eg, '1w1d' for 1 week 1 day).
]]
cmds.allowTimeString = {} -- Key


--[[
	Class: cmds.BaseArg

	Just defines the basics for us, used in autocomplete and command callbacks.
	These default implementations just throw an error if called. You shouldn't
	need any great knowledge about the functions in these types, just that
	they exist and how to pass in restrictions.

	Revisions:

		2.40 - Initial
]]
cmds.BaseArg = inheritsFrom( nil )


--[[
	Function: cmds.BaseArg:parseAndValidate

	Used to, you guessed it, parse and validate an argument specified by a user.
	Takes user command line input and converts it to a regular lua variable of
	the correct type.

	Parameters:

		ply - The player using the command. Useful for querying.
		arg - The arg to parse. It's already properly trimmed.
		cmdInfo - A table containing data about this command.
		plyRestrictions - The restrictions from the access tag for this player.

	Returns:

		The parsed arg correctly typed if it validated, false and an
		explanation otherwise.
]]
function cmds.BaseArg:parseAndValidate( ply, arg, cmdInfo, plyRestrictions )
	error( "Unimplemented BaseArg:parseAndValidate called" )
end


--[[
	Function: cmds.BaseArg:complete

	Used to autocomplete a command. Passes back the options the player has in
	using this command.

	Parameters:

		arg - The arg to parse. It's already properly trimmed.
		cmdInfo - A table containing data about this command.
		plyRestrictions - The restrictions from the access tag for this player.

	Returns:

		A table of strings containing the options that are available.
]]
function cmds.BaseArg:complete( arg, cmdInfo, plyRestrictions )
	error( "Unimplemented BaseArg:complete called" )
end


--[[
	Function: cmds.BaseArg:usage

	Prints a basic usage message for this parameter.

	Parameters:

		cmdInfo - A table containing data about this command.
		plyRestrictions - The restrictions from the access tag for this player.

	Returns:

		A string describing what this parameter is and how to use it.
]]
function cmds.BaseArg:usage( cmdInfo, plyRestrictions )
	error( "Unimplemented BaseArg:usage called" )
end


--[[
	Class: cmds.NumArg

	A number arg, inherits from <cmds.BaseArg>. Restrictions can include a numeric
	value for keys 'min', 'max', and 'default'. All do what you think they do.
	If the argument is optional and no default is specified, 0 is used for
	default. You can specify the allowTimeString key to allow time string
	representations. Lastly, you can specify a value for the key 'hint' for a
	hint on	what this argument is for, IE "damage".

	Example:

		The following code creates a command that accepts an optional numeric
		second argument that defaults to 0 and has to be at least 0.

:cmd = ULib.cmds.TranslateCommand( "ugm slap", ULib.slap )
:cmd:addParam{ type=ULib.cmds.PlayerArg, target="*", default="^", ULib.cmds.optional }
:cmd:addParam{ type=ULib.cmds.NumArg, min=0, default=0, ULib.cmds.optional }

	Revisions:

		2.40 - Initial
]]
cmds.NumArg = inheritsFrom( cmds.BaseArg )


--[[
	Function: cmds.NumArg:processRestrictions

	A helper function to help us figure out restrictions on this command.
]]
function cmds.NumArg:processRestrictions( cmdRestrictions, plyRestrictions )
	-- First, reset
	self.min = nil
	self.max = nil

	local allowTimeString = table.HasValue( cmdRestrictions, cmds.allowTimeString )

	if plyRestrictions then -- Access tag restriction
		if not plyRestrictions:find( ":" ) then -- Assume they only want one number here
			self.min = plyRestrictions
			self.max = plyRestrictions
		else
			local timeStringMatcher = "[-hdwy%d]*"
			dummy, dummy, self.min, self.max = plyRestrictions:find( "^(" .. timeStringMatcher .. "):(" .. timeStringMatcher .. ")$" )
		end

		if not allowTimeString then
			self.min = tonumber( self.min )
			self.max = tonumber( self.max )
		else
			self.min = ULib.stringTimeToSeconds( self.min )
			self.max = ULib.stringTimeToSeconds( self.max )
		end
	end

	if allowTimeString and not self.timeStringsParsed then
		self.timeStringsParsed = true
		cmdRestrictions.min = ULib.stringTimeToSeconds( cmdRestrictions.min )
		cmdRestrictions.max = ULib.stringTimeToSeconds( cmdRestrictions.max )
		cmdRestrictions.default = ULib.stringTimeToSeconds( cmdRestrictions.default )
	end

	if cmdRestrictions.min and (not self.min or self.min < cmdRestrictions.min) then
		self.min = cmdRestrictions.min
	end

	if cmdRestrictions.max and (not self.max or self.max > cmdRestrictions.max) then
		self.max = cmdRestrictions.max
	end
end


--[[
	Function: cmds.NumArg:parseAndValidate

	See <cmds.BaseArg:parseAndValidate>
]]
function cmds.NumArg:parseAndValidate( ply, arg, cmdInfo, plyRestrictions )
	self:processRestrictions( cmdInfo, plyRestrictions )

	if not arg and self.min and self.min == self.max then -- Arg's not valid, min is, and it's equal to max
		return self.min
	end

	if not arg and table.HasValue( cmdInfo, cmds.optional ) then
		arg = cmdInfo.default or 0 -- Set it, needs to go through our process
	end

	local allowTimeString = table.HasValue( cmdInfo, cmds.allowTimeString )
	local num -- We check if it's nil after we see if a default has been provided for them
	if not allowTimeString then
		num = tonumber( arg )
	else
		num = ULib.stringTimeToSeconds( arg )
	end

	local typeString
	if not allowTimeString then
		typeString = "number"
	else
		typeString = "number or time string"
	end

	if not num then
		return nil, string.format( "invalid " .. typeString .. " \"%s\" specified", tostring( arg ) )
	end

	if self.min and num < self.min then
		return nil, string.format( "specified " .. typeString .. " (%s) was below your allowed minimum value of %g", arg, self.min )
	end

	if self.max and num > self.max then
		return nil, string.format( "specified " .. typeString .. " (%s) was above your allowed maximum value of %g", arg, self.max )
	end

	if table.HasValue( cmdInfo, cmds.round ) then
		return math.Round( num )
	end
	return num
end


--[[
	Function: cmds.NumArg:complete

	See <cmds.BaseArg:complete>
]]
function cmds.NumArg:complete( ply, arg, cmdInfo, plyRestrictions )
	return { self:usage( cmdInfo, plyRestrictions ) }
end


--[[
	Function: cmds.NumArg:usage

	See <cmds.BaseArg:usage>
]]
function cmds.NumArg:usage( cmdInfo, plyRestrictions )
	self:processRestrictions( cmdInfo, plyRestrictions )
	local isOptional = table.HasValue( cmdInfo, cmds.optional )

	local str = cmdInfo.hint or "number"

	if self.min == self.max and self.min then -- Equal but not nil
		return "<" .. str .. ": " .. self.min .. ">"
	else
		str = "<" .. str
		if self.min or self.max or cmdInfo.default or isOptional then
			str = str .. ": "
		end
		if self.min then
			str = str .. self.min .. "<="
		end
		if self.min or self.max then
			str = str .. "x"
		end
		if self.max then
			str = str .. "<=" .. self.max
		end
		if cmdInfo.default or isOptional then
			if self.min or self.max then
					str = str .. ", "
			end
			str = str .. "default " .. (cmdInfo.default or 0)
		end
		str = str .. ">"

		if isOptional then
			str = "[" .. str .. "]"
		end
		return str
	end
end


--[[
	Class: cmds.BoolArg

	A boolean arg, inherits from <cmds.BaseArg>. You can specify a value for the key
	'hint' for a hint on what this argument is for, IE "revoke access".

	Example:

		The following code creates a command that accepts an option boolean
		third argument that defaults to false.

:local groupallow = ULib.cmds.TranslateCommand( "ulx groupallow", ulx.groupallow )
:groupallow:addParam{ type=ULib.cmds.StringArg }
:groupallow:addParam{ type=ULib.cmds.StringArg }
:groupallow:addParam{ type=ULib.cmds.BoolArg, hint="revoke access", ULib.cmds.optional }

	Revisions:

		2.40 - Initial
]]
cmds.BoolArg = inheritsFrom( cmds.BaseArg )


--[[
	Function: cmds.BoolArg:processRestrictions

	A helper function to help us figure out restrictions on this command.
]]
function cmds.BoolArg:processRestrictions( cmdRestrictions, plyRestrictions )
	-- First, reset
	self.restrictedTo = nil

	if plyRestrictions and plyRestrictions ~= "*" then -- Access tag restriction
		self.restrictedTo = ULib.toBool( plyRestrictions )
	end

	-- There'd be no point in having command-level restrictions on this, so nothing is implemented for it.
end


--[[
	Function: cmds.BoolArg:parseAndValidate

	See <cmds.BaseArg:parseAndValidate>
]]
function cmds.BoolArg:parseAndValidate( ply, arg, cmdInfo, plyRestrictions )
	self:processRestrictions( cmdInfo, plyRestrictions )

	if not arg and table.HasValue( cmdInfo, cmds.optional ) then
		-- Yah, I know this following statement could be 'false or false', but it's still false.
		arg = cmdInfo.default or false -- Set it, needs to go through our process
	end

	local desired = ULib.toBool( arg )

	if self.restrictedTo ~= nil and desired ~= self.restrictedTo then
		return nil, "you are not allowed to specify " .. tostring( desired ) .. " here"
	end

	return desired
end


--[[
	Function: cmds.BoolArg:complete

	See <cmds.BaseArg:complete>
]]
function cmds.BoolArg:complete( ply, arg, cmdInfo, plyRestrictions )
	self:processRestrictions( cmdInfo, plyRestrictions )
	local ret = { self:usage( cmdInfo, plyRestrictions ) }

	if not self.restrictedTo then
		table.insert( ret, "0" )
	end

	if self.restrictedTo ~= false then
		table.insert( ret, "1" )
	end

	return ret
end


--[[
	Function: cmds.BoolArg:usage

	See <cmds.BaseArg:usage>
]]
function cmds.BoolArg:usage( cmdInfo, plyRestrictions )
	self:processRestrictions( cmdInfo, plyRestrictions )
	local isOptional = table.HasValue( cmdInfo, cmds.optional )

	local str = "<"
	if cmdInfo.hint then
		str = str .. cmdInfo.hint .. ": "
	end

	if self.restrictedTo ~= nil then
		str = str .. (self.restrictedTo and "1>" or "0>")
	else
		str = str .. "0/1>"
	end

	if isOptional then
		str = "[" .. str .. "]"
	end

	return str
end


--[[
	Class: cmds.PlayerArg

	A player arg, inherits from <cmds.BaseArg>. Can be restricted by specifying a
	string in the key 'target'. This string is passed to <getUser()> with
	keywords enabled to get a list of players this user is allowed to target.

	Example:

		The following code creates a command that accepts an optional player
		argument that defaults to self and cannot be any superadmins.

:cmd = ULib.cmds.TranslateCommand( "ugm slap", ULib.slap )
:cmd:addParam{ type=ULib.cmds.PlayerArg, target="!%superadmin", default="^", ULib.cmds.optional }
:cmd:addParam{ type=ULib.cmds.NumArg, min=0, default=0, ULib.cmds.optional }


	Revisions:

		2.40 - Initial
]]
cmds.PlayerArg = inheritsFrom( cmds.BaseArg )


--[[
	Function: cmds.PlayerArg:processRestrictions

	A helper function to help us figure out restrictions on this command.
]]
function cmds.PlayerArg:processRestrictions( ply, cmdRestrictions, plyRestrictions )
	self.restrictedTargets = nil -- Reset
	cmds.PlayerArg.restrictedTargets = nil -- Because of inheritance, make sure this is reset too
	local ignore_can_target = false
	if plyRestrictions and plyRestrictions:sub( 1, 1 ) == "$" then
		plyRestrictions = plyRestrictions:sub( 2 )
		ignore_can_target = true
	end

	if cmdRestrictions.target then
		-- Realize it can be false after this, meaning they can target no-one connected.
		self.restrictedTargets = ULib.getUsers( cmdRestrictions.target, true, ply )
	end

	if plyRestrictions and plyRestrictions ~= "" then -- Access tag restriction
		local restricted = ULib.getUsers( plyRestrictions, true, ply )
		if not restricted or not self.restrictedTargets then -- Easy, just set it
			self.restrictedTargets = restricted

		else -- Make a subset! We want to remove any values from self.restrictedTargets that aren't in restricted
			local i = 1
			while self.restrictedTargets[ i ] do
				if not table.HasValue( restricted, self.restrictedTargets[ i ] ) then
					table.remove( self.restrictedTargets, i )
				else
					i = i + 1
				end
			end
		end
	end

	if ply:IsValid() and not ignore_can_target and not table.HasValue( cmdRestrictions, cmds.ignoreCanTarget ) and ULib.ucl.getGroupCanTarget( ply:GetUserGroup() ) then -- can_target restriction
		local restricted = ULib.getUsers( ULib.ucl.getGroupCanTarget( ply:GetUserGroup() ) .. ",^", true, ply ) -- Allow self on top of restrictions
		if not restricted or not self.restrictedTargets then -- Easy, just set it
			self.restrictedTargets = restricted

		else -- Make a subset! We want to remove any values from self.restrictedTargets that aren't in restricted
			local i = 1
			while self.restrictedTargets[ i ] do
				if not table.HasValue( restricted, self.restrictedTargets[ i ] ) then
					table.remove( self.restrictedTargets, i )
				else
					i = i + 1
				end
			end
		end
	end
end


--[[
	Function: cmds.PlayerArg:parseAndValidate

	See <cmds.BaseArg:parseAndValidate>
]]
function cmds.PlayerArg:parseAndValidate( ply, arg, cmdInfo, plyRestrictions )
	self:processRestrictions( ply, cmdInfo, plyRestrictions )

	if not arg and table.HasValue( cmdInfo, cmds.optional ) then
		arg = cmdInfo.default or "^" -- Set it, needs to go through our process
	end

	local target, err_msg1 = ULib.getUser( arg, true, ply )

	local return_value, err_msg2 = hook.Call( ULib.HOOK_PLAYER_TARGET, _, ply, cmdInfo.cmd, target )
	if return_value == false then
		return nil, err_msg2 or "you cannot target this person"
	elseif type( return_value ) == "Player" then
		target = return_value
	end

	if return_value ~= true then -- Go through our "normal" restriction process
		if not target then return nil, err_msg1 or "no target found" end

		if self.restrictedTargets == false or (self.restrictedTargets and not table.HasValue( self.restrictedTargets, target )) then
			return nil, "you cannot target this person"
		end
	end

	return target
end


--[[
	Function: cmds.PlayerArg:complete

	See <cmds.BaseArg:complete>
]]
function cmds.PlayerArg:complete( ply, arg, cmdInfo, plyRestrictions )
	self:processRestrictions( ply, cmdInfo, plyRestrictions )

	local targets
	if self.restrictedTargets == false then -- No one allowed
		targets = {}
	elseif arg == "" then
		targets = player.GetAll()
	else
		targets = ULib.getUsers( arg, true, ply )
		if not targets then targets = {} end -- No one found
	end

	if self.restrictedTargets then
		local i = 1
		while targets[ i ] do
			if not table.HasValue( self.restrictedTargets, targets[ i ] ) then
				table.remove( targets, i )
			else
				i = i + 1
			end
		end
	end

	local names = {}
	for _, ply in ipairs( targets ) do
		table.insert( names, string.format( '"%s"', ply:Nick() ) )
	end
	table.sort( names )

	if #names == 0 then
		return { self:usage( cmdInfo, plyRestrictions ) }
	end

	return names
end


--[[
	Function: cmds.PlayerArg:usage

	See <cmds.BaseArg:usage>
]]
function cmds.PlayerArg:usage( cmdInfo, plyRestrictions )
	-- self:processRestrictions( cmdInfo, plyRestrictions )
	local isOptional = table.HasValue( cmdInfo, cmds.optional )

	if isOptional then
		if not cmdInfo.default or cmdInfo.default == "^" then
			return "[<player, defaults to self>]"
		else
			return "[<player, defaults to \"" .. cmdInfo.default .. "\">]"
		end
	end
	return "<player>"
end


--[[
	Class: cmds.PlayersArg

	A table of players arg, inherits from <cmds.PlayerArg>. Can be restricted by
	specifying a string in the key 'target'. This string is passed to
	<getUsers()> with  keywords enabled to get a list of players this user is
	allowed to target.

	Revisions:

		2.40 - Initial
]]
cmds.PlayersArg = inheritsFrom( cmds.PlayerArg )


--[[
	Function: cmds.PlayersArg:parseAndValidate

	See <cmds.PlayerArg:parseAndValidate>
]]
function cmds.PlayersArg:parseAndValidate( ply, arg, cmdInfo, plyRestrictions )
	self:processRestrictions( ply, cmdInfo, plyRestrictions )

	if not arg and table.HasValue( cmdInfo, cmds.optional ) then
		arg = cmdInfo.default or "^" -- Set it, needs to go through our process
	end

	local targets = ULib.getUsers( arg, true, ply )

	local return_value, err_msg = hook.Call( ULib.HOOK_PLAYER_TARGETS, _, ply, cmdInfo.cmd, targets )
	if return_value == false then
		return nil, err_msg or "you cannot target this person or these persons"
	elseif type( return_value ) == "table" then
		if #return_value == 0 then
			return nil, err_msg or "you cannot target this person or these persons"
		else
			targets = return_value
		end
	end

	if return_value ~= true then -- Go through our "normal" restriction process
		if not targets then return nil, "no targets found" end

		if self.restrictedTargets then
			local i = 1
			while targets[ i ] do
				if not table.HasValue( self.restrictedTargets, targets[ i ] ) then
					table.remove( targets, i )
				else
					i = i + 1
				end
			end
		end

		if self.restrictedTargets == false or #targets == 0 then
			return nil, "you cannot target this person or these persons"
		end
	end

	return targets
end


--[[
	Function: cmds.PlayersArg:usage

	See <cmds.PlayerArg:usage>
]]
function cmds.PlayersArg:usage( cmdInfo, plyRestrictions )
	-- self:processRestrictions( cmdInfo, plyRestrictions )
	local isOptional = table.HasValue( cmdInfo, cmds.optional )

	if isOptional then
		if not cmdInfo.default or cmdInfo.default == "^" then
			return "[<players, defaults to self>]"
		else
			return "[<players, defaults to \"" .. cmdInfo.default .. "\">]"
		end
	end
	return "<players>"
end


--[[
	Class: cmds.CallingPlayerArg

	Simply used to retrieve the player using the command. No validation needed.

	Revisions:

		2.40 - Initial
]]
cmds.CallingPlayerArg = inheritsFrom( cmds.BaseArg )
cmds.CallingPlayerArg.invisible = true -- Not actually specified


--[[
	Function: cmds.CallingPlayerArg:parseAndValidate

	See <cmds.BaseArg:parseAndValidate>
]]
function cmds.CallingPlayerArg:parseAndValidate( ply, arg, cmdInfo, plyRestrictions )
	return ply
end


--[[
	Class: cmds.StringArg

	A player arg, inherits from <cmds.BaseArg>. You can specify completes with a
	table of strings for the key 'completes'. Can be restricted to these by
	specifying ULib.cmds.restrictToCompletes. Can also specify
	ULib.cmds.takeRestOfLine to make it take up the rest of the command line
	arguments. 'autocomplete_fn' can be specified with the value of a function
	to call for autocompletes (this is an override). Can specify a value for
	the key 'repeat_min' when the argument repeats at least n times (this
	implies ULib.cmds.takeRestOfLine). Though it's not (currently) used by ULib,
	you can also specify 'repeat_max' to mean that the argument repeats at most
	n times. Lastly, you can specify a value for the key 'hint' for a hint on
	what this argument is for, IE "groupname".

	Example:

		The following code creates a command that accepts a first argument that
		is restricted to a list of strings, this same list is also used for
		autocompletes. A descriptive error is provided if they specify an
		invalid group.

:local groupallow = ULib.cmds.TranslateCommand( "ulx groupallow", ulx.groupallow )
:groupallow:addParam{ type=ULib.cmds.StringArg, completes=ulx.group_names, hint="group", error="invalid group \"%s\" specified", ULib.cmds.restrictToCompletes }

	Revisions:

		2.40 - Initial
]]
cmds.StringArg = inheritsFrom( cmds.BaseArg )


--[[
	Function: cmds.StringArg:processRestrictions

	A helper function to help us figure out restrictions on this command.
]]
function cmds.StringArg:processRestrictions( cmdRestrictions, plyRestrictions )
	self.restrictedCompletes = table.Copy( cmdRestrictions.completes ) -- Reset
	self.playerLevelRestriction = nil -- Reset

	if plyRestrictions and plyRestrictions ~= "*" then -- Access tag restriction
		self.playerLevelRestriction = true
		local restricted = ULib.explode( ",", plyRestrictions )
		if not self.restrictedCompletes or not table.HasValue( cmdRestrictions, cmds.restrictToCompletes ) then -- Easy, just set it
			self.restrictedCompletes = restricted

		else -- Make a subset! We want to remove any values from self.restrictedCompletes that aren't in restricted
			local i = 1
			while self.restrictedCompletes[ i ] do
				if not table.HasValue( restricted, self.restrictedCompletes[ i ] ) then
					table.remove( self.restrictedCompletes, i )
				else
					i = i + 1
				end
			end
		end
	end
end


--[[
	Function: cmds.StringArg:parseAndValidate

	See <cmds.BaseArg:parseAndValidate>
]]
function cmds.StringArg:parseAndValidate( ply, arg, cmdInfo, plyRestrictions )
	self:processRestrictions( cmdInfo, plyRestrictions )

	if not arg and table.HasValue( cmdInfo, cmds.optional ) then
		return cmdInfo.default or ""
	end

	if arg:find( "%c" ) then
		return nil, "string cannot contain control characters"
	end

	if table.HasValue( cmdInfo, cmds.restrictToCompletes ) or self.playerLevelRestriction then
		if self.restrictedCompletes and not table.HasValue( self.restrictedCompletes, arg ) then
			if cmdInfo.error then
				return nil, string.format( cmdInfo.error, arg ) -- If it has '%s', replace with arg
			else
				return nil, "invalid string"
			end
		end
	end

	return arg -- Everything's valid
end


--[[
	Function: cmds.StringArg:complete

	See <cmds.BaseArg:complete>
]]
function cmds.StringArg:complete( ply, arg, cmdInfo, plyRestrictions )
	if cmdInfo.autocomplete_fn then
		return cmdInfo.autocomplete_fn( ply, arg, cmdInfo, plyRestrictions )
	end

	self:processRestrictions( cmdInfo, plyRestrictions )

	if self.restrictedCompletes then
		local ret = {}
		for _, v in ipairs( self.restrictedCompletes ) do
			if v:lower():sub( 1, arg:len() ) == arg:lower() then
				if v:find( "%s" ) then
					v = string.format( '"%s"', v )
				end
				table.insert( ret, v )
			end
		end

		if #ret == 0 then
			return {self:usage( cmdInfo, plyRestrictions )}
		end
		return ret
	else
		return {self:usage( cmdInfo, plyRestrictions )}
	end
end


--[[
	Function: cmds.StringArg:usage

	See <cmds.BaseArg:usage>
]]
function cmds.StringArg:usage( cmdInfo, plyRestrictions )
	local isOptional = table.HasValue( cmdInfo, cmds.optional )
	local str = cmdInfo.hint or "string"

	if cmdInfo.repeat_min or table.HasValue( cmdInfo, cmds.takeRestOfLine ) then
		str = "{" .. str .. "}"
	else
		str = "<" .. str .. ">"
	end

	if isOptional then
		str = "[" .. str .. "]"
	end

	return str
end


--------


local translatedCmds = {} -- To save my fingers, quicker access time, etc

--[[
	Table: cmds.translatedCmds

	Holds all the commands that are set up through the translator. I won't
	bother explaining the contents here, just inspect them with PrintTable.
]]
cmds.translatedCmds = translatedCmds

local function translateCmdCallback( ply, commandName, argv )
	local cmd = translatedCmds[ commandName:lower() ]
	if not cmd then return error( "Invalid command!" ) end

	local isOpposite = cmd.opposite == commandName

	local access, accessTag = ULib.ucl.query( ply, commandName )
	if not access then
		ULib.tsayError( ply, "You don't have access to this command, " .. ply:Nick() .. "!", true ) -- Print their name to intimidate them :)
		return
	end

	local accessPieces = {}
	if accessTag then
		accessPieces = ULib.splitArgs( accessTag, "<", ">" )
	end

	local args = {}
	local argNum = 1
	for i, argInfo in ipairs( cmd.args ) do -- Translate each input arg into our output
		if isOpposite and cmd.oppositeArgs[ i ] then
			table.insert( args, cmd.oppositeArgs[ i ] )
		else
			if not argInfo.type.invisible and not argInfo.invisible and not argv[ argNum ] and not table.HasValue( argInfo, cmds.optional ) then
				ULib.tsayError( ply, "Usage: " .. commandName .. " " .. cmd:getUsage( ply ), true )
				return
			end

			local arg
			if not argInfo.repeat_min and not table.HasValue( argInfo, cmds.takeRestOfLine ) then
				arg = argv[ argNum ]
			elseif not argInfo.repeat_min then
				arg = ""
				for i=argNum, #argv do
					if argv[ i ]:find( "%s" ) then
						arg = arg .. " " .. string.format( '"%s"', argv[ i ] )
					else
						arg = arg .. " " .. argv[ i ]
					end
				end

				arg = arg:Trim()
				if arg:sub( 1, 1 ) == "\"" and arg:sub( -1, -1 ) == "\""
					and arg:find( "\"", 2, true ) == arg:len() then -- If balanced single pair quotes, strip them
					arg = ULib.stripQuotes( arg )
				end
			end

			if not argInfo.repeat_min then
				local ret, err = argInfo.type:parseAndValidate( ply, arg, argInfo, accessPieces[ argNum ] )
				if ret == nil then
					ULib.tsayError( ply, string.format( "Command \"%s\", argument #%i: %s", commandName, argNum, err ), true )
					return
				end
				table.insert( args, ret )
			else
				if #argv - argNum + 1 < argInfo.repeat_min then
					ULib.tsayError( ply, string.format( "Command \"%s\", argument #%i: %s", commandName, #argv+1, "expected additional argument(s)" ), true )
					return
				end
				for i=argNum, #argv do
					local ret, err = argInfo.type:parseAndValidate( ply, argv[ i ], argInfo, accessPieces[ argNum ] )
					if ret == nil then
						ULib.tsayError( ply, string.format( "Command \"%s\", argument #%i: %s", commandName, i, err ), true )
						return
					end
					table.insert( args, ret )
				end
			end
		end

		if not argInfo.type.invisible and not argInfo.invisible then
			argNum = argNum + 1
		end
	end

	cmd:call( isOpposite, unpack( args ) )
	hook.Call( ULib.HOOK_POST_TRANSLATED_COMMAND, _, ply, commandName, args )
end

local function translateAutocompleteCallback( commandName, args )
	-- This function is some of the most obfuscated code I've ever written... really sorry about this.
	-- This function was the unfortunate victim of feeping creaturism
	local cmd = translatedCmds[ commandName:lower() ]
	if not cmd then return error( "Invalid command!" ) end

	local isOpposite = cmd.opposite == commandName
	local ply
	if CLIENT then
		ply = LocalPlayer()
	else
		-- Assume listen server, seems to be the only time this can happen
		ply = Entity( 1 ) -- Should be first player
		if not ply or not ply:IsValid() or not ply:IsListenServerHost() then
			return error( "Assumption fail!" )
		end
	end

	local access, accessTag = ULib.ucl.query( ply, commandName ) -- We don't actually care if they have access or not, complete anyways
	local takes_rest_of_line = table.HasValue( cmd.args[ #cmd.args ], cmds.takeRestOfLine ) or cmd.args[ #cmd.args ].repeat_min

	local accessPieces = {}
	if accessTag then
		accessPieces = ULib.splitArgs( accessTag, "<", ">" )
	end

	local ret = {}
	local argv, mismatched_quotes = ULib.splitArgs( args )
	local argn = #argv
	-- If the last character is a space and they're not in a quote right now...
	local on_new_arg = args == "" or (args:sub( -1 ) == " " and not mismatched_quotes)
	if on_new_arg then argn = argn + 1 end
	local hidden_argn = argn -- Argn with invisible included
	for i=1, argn do
		if cmd.args[ i ] and (cmd.args[ i ].type.invisible or cmd.args[ i ].invisible) then
			hidden_argn = hidden_argn + 1
		end
	end
	while cmd.args[ hidden_argn ] and (cmd.args[ hidden_argn ].type.invisible or cmd.args[ hidden_argn ].invisible) do
		hidden_argn = hidden_argn + 1 -- Advance to next visible arg
	end
	-- Now, if this is taking the rest of the line... forget the above
	if hidden_argn > #cmd.args and takes_rest_of_line then
		hidden_argn = #cmd.args
		argn = hidden_argn
		for i=1, argn do
			if cmd.args[ i ] and (cmd.args[ i ].type.invisible or cmd.args[ i ].invisible) then
				argn = argn - 1
			end
		end
	end
	local completedArgs = ""
	local partialArg = ""
	for i=1, #argv do
		local str = argv[ i ]
		if str:find( "%s" ) then
			str = string.format( '"%s"', str )
		end
		if i < argn or (cmd.args[ #cmd.args ].repeat_min and i < #argv+(on_new_arg and 1 or 0)) then
			completedArgs = completedArgs .. str .. " "
		else
			partialArg = partialArg .. str .. " "
		end
	end
	completedArgs = completedArgs:Trim()
	partialArg = ULib.stripQuotes( partialArg:Trim() )

	if isOpposite and cmd.oppositeArgs[ hidden_argn ] then
		local str = commandName .. " "
		if completedArgs and completedArgs:len() > 0 then
			str = str .. completedArgs .. " "
		end
		table.insert( ret, str .. cmd.oppositeArgs[ hidden_argn ] )
	elseif cmd.args[ hidden_argn ] then
		-- First, get the completes as reported by this type
		if cmd.args[ #cmd.args ].repeat_min then
			partialArg = argv[ #argv ]
			if args == "" or (args:sub( -1 ) == " " and not mismatched_quotes) then partialArg = nil end
		end
		ret = cmd.args[ hidden_argn ].type:complete( ply, partialArg or "", cmd.args[ hidden_argn ], accessPieces[ argn ] )

		-- Now let's add the prefix to the completes
		local prefix = commandName .. " "
		if completedArgs:len() > 0 then
			prefix = prefix .. completedArgs .. " "
		end
		for k, v in ipairs( ret ) do
			ret[ k ] = prefix .. v
		end
	end

	return ret
end


--[[
	Class: cmds.TranslateCommand

	Offers an abstraction on the "console command" concept. Think of this class
	as a translator sitting between the user and your program. You tell this
	translator what arguments and types you're expecting from the user and the
	translator handles the rest.

	If the user tries to use a command with the incorrect number or wrong type
	of args, the translator informs the user of the problem and suggests how to
	fix it. If the user has everything correct, the translator calls the
	callback with the correctly typed and validated arguments.

	Revisions:

		v2.40 - Initial
]]
cmds.TranslateCommand = inheritsFrom( nil )


--[[
	Function: cmds.TranslateCommand:instantiate

	Parameters:
		cmd - The command you're creating. IE, "ulx slap".
		fn - *(Optional on client since it's ignored)* The function callback for this command. The callback receives
			the arguments you specify.
		say_cmd - *(Optional)* Specify a say command or commands (as a table) to be tied in.
		hide_say - *(Optional, defaults to false)* Hide the chat when the say
			command is used?
		no_space_in_say - *(Optional, defaults to false)* Is a space between
			the chat command and arguments required?
]]
function cmds.TranslateCommand:instantiate( cmd, fn, say_cmd, hide_say, no_space_in_say )
	ULib.checkArg( 1, "ULib.cmds.TranslateCommand", "string", cmd, 5 )
	if SERVER then
		ULib.checkArg( 2, "ULib.cmds.TranslateCommand", "function", fn, 5 )
	else
		ULib.checkArg( 2, "ULib.cmds.TranslateCommand", {"nil", "function"}, fn, 5 )
	end
	ULib.checkArg( 3, "ULib.cmds.TranslateCommand", {"nil", "string", "table"}, say_cmd, 5 )
	ULib.checkArg( 4, "ULib.cmds.TranslateCommand", {"nil", "boolean"}, hide_say, 5 )
	ULib.checkArg( 5, "ULib.cmds.TranslateCommand", {"nil", "boolean"}, no_space_in_say, 5 )

	self.args = {}
	self.fn = fn
	self.cmd = cmd -- We need this for usage print
	translatedCmds[ cmd:lower() ] = self

	cmds.addCommand( cmd, translateCmdCallback, translateAutocompleteCallback, cmd, say_cmd, hide_say, no_space_in_say )
end


--[[
	Function: cmds.TranslateCommand:addParam

	Add an argument to this command. See the types above for more usage info.

	Parameters:

		t - A table containing the information on this argument.
]]
function cmds.TranslateCommand:addParam( t )
	ULib.checkArg( 1, "ULib.cmds.TranslateCommand:addParam", "table", t )

	t.cmd = self.cmd
	table.insert( self.args, t )
end


--[[
	Function: cmds.TranslateCommand:setOpposite

	Set the command opposite for this command. IE, if the main command is
	"jail", the opposite might be "unjail". The same callback is called for
	both "jail" and "unjail". The parameters passed to this function specify
	required values for arguments passed to the callback. Any nil values still
	allow any valid values from the user. Automatically sets default access to
	be the same as the "non-opposite" command.

	Parameters:

		cmd - The name of the command for this opposite. IE, "unjail".
		args - The args to restrict or allow, in order.
		say_cmd - *(Optional)* Specify a say command to be tied in.
		hide_say - *(Optional, defaults to false)* Hide the chat when the say
			command is used?
		no_space_in_say - *(Optional, defaults to false)* Is a space between
			the chat command and arguments required?

	Example:

		This sets the opposite to "unjail", where the first parameter can still
		be any valid value, but the second value must be 0.

:myCmd:setOpposite( "unjail", { _, 0 }, "!unjail" )
]]
function cmds.TranslateCommand:setOpposite( cmd, args, say_cmd, hide_say, no_space_in_say )
	ULib.checkArg( 1, "ULib.cmds.TranslateCommand:setOpposite", "string", cmd )
	ULib.checkArg( 2, "ULib.cmds.TranslateCommand:setOpposite", "table", args )
	ULib.checkArg( 3, "ULib.cmds.TranslateCommand:setOpposite", {"nil", "string"}, say_cmd )
	ULib.checkArg( 4, "ULib.cmds.TranslateCommand:setOpposite", {"nil", "boolean"}, hide_say )
	ULib.checkArg( 5, "ULib.cmds.TranslateCommand:setOpposite", {"nil", "boolean"}, no_space_in_say )

	self.opposite = cmd
	translatedCmds[ cmd:lower() ] = self
	self.oppositeArgs = args

	cmds.addCommand( cmd, translateCmdCallback, translateAutocompleteCallback, cmd, say_cmd, hide_say, no_space_in_say )

	if self.default_access then
		self:defaultAccess( self.default_access )
	end
end


--[[
	Function: cmds.TranslateCommand:getUsage

	Parameters:
		ply - The player wanting the usage information. Used for player adding
			restriction info in the usage statement.

	Returns:

		A string of the usage information for this command.
]]
function cmds.TranslateCommand:getUsage( ply )
	ULib.checkArg( 1, "ULib.cmds.TranslateCommand:getUsage", {"Entity", "Player"}, ply )

	local access, accessTag = ULib.ucl.query( ply, self.cmd ) -- We only want the accessTag

	local accessPieces = {}
	if accessTag then
		accessPieces = ULib.explode( "%s+", accessTag )
	end

	local str = ""
	local argNum = 1
	for i, argInfo in ipairs( self.args ) do
		if not argInfo.type.invisible and not argInfo.invisible then
			str = str .. " " .. argInfo.type:usage( argInfo, accessPieces[ argNum ] )
			argNum = argNum + 1
		end
	end

	return str:Trim()
end


--[[
	Function: cmds.TranslateCommand:call

	This is just a pass-through function for calling the function callback. If
	you want to modify the behavior of TranslateCommand on the callback, this
	is the place to do it. For example, ULX overrides this to add logging info.

	Parameters:

		isOpposite - Is this the opposite command that's being called?
		... - The args that will be passed to the function callback.
]]
function cmds.TranslateCommand:call( isOpposite, ... )
	return self.fn( ... )
end


--[[
	Function: cmds.TranslateCommand:defaultAccess

	Parameters:

		access - The group or groups that should have access to this command by
			default.
]]
function cmds.TranslateCommand:defaultAccess( access )
	ULib.checkArg( 1, "ULib.cmds.TranslateCommand:defaultAccess", "string", access )

	if CLIENT then return end
	ULib.ucl.registerAccess( self.cmd, access, "Grants access to the " .. self.cmd .. " command", "Command" )

	if self.opposite then
		ULib.ucl.registerAccess( self.opposite, access, "Grants access to the " .. self.opposite .. " command", "Command" )
	end

	self.default_access = access
end

-----------------------------------------------------------------------------------------------------------
-- Onto the "simpler" command stuff that's just a slight abstraction over garry's default command system --
-----------------------------------------------------------------------------------------------------------

local routedCmds = {}
local sayCmds = {}
local sayCommandCallback

local function routedCommandCallback( ply, commandName, argv )
	local curtime = CurTime()
	if not ply.ulib_threat_level or ply.ulib_threat_time <= curtime then
		ply.ulib_threat_level = 1
		ply.ulib_threat_time = curtime + 3
		ply.ulib_threat_warned = nil
	elseif ply.ulib_threat_level >= 100 then
		if not ply.ulib_threat_warned then
			ULib.tsay( ply, "You are running too many commands too quickly, please wait before executing more" )
			ply.ulib_threat_warned = true
		end
		return
	else
		ply.ulib_threat_level = ply.ulib_threat_level + 1
	end


	if not routedCmds[ commandName:lower() ] then
		return error( "Base command \"" .. commandName .. "\" is not defined!" )
	end
	local orig_argv = argv
	local orig_commandName = commandName

	-- Valve error-correction
	local args = ""
	for k, v in ipairs( argv ) do
		args = string.format( '%s"%s" ', args, v )
	end
	args = string.Trim( args ) -- Remove that last space we added

	args = args:gsub( "\" \":\" \"", ":" ) -- Valve error correction.
	args = args:gsub( "\" \"'\" \"", "'" ) -- Valve error correction.
	argv = ULib.splitArgs( args ) -- We're going to go ahead and reparse argv to fix the errors.
	-- End Valve error-correction

	-- Find the most specific command we have defined
	local currTable = routedCmds[ commandName:lower() ]
	local nextWord = table.remove( argv, 1 )
	while nextWord and currTable[ nextWord:lower() ] do
		commandName = commandName .. " " .. nextWord
		currTable = currTable[ nextWord:lower() ]

		nextWord = table.remove( argv, 1 )
	end
	table.insert( argv, 1, nextWord ) -- Stick it in again, the last one was invalid
	-- Done finding

	if CLIENT and not currTable.__client_only then
		ULib.redirect( ply, orig_commandName, orig_argv )
		return
	end

	if not currTable.__fn then
		return error( "Attempt to call undefined command: " .. commandName )
	end

	local return_value = hook.Call( ULib.HOOK_COMMAND_CALLED, _, ply, commandName, argv )
	if return_value ~= false then
		currTable.__fn( ply, commandName, argv )
	end
end

if SERVER then
	sayCommandCallback = function( ply, sayCommand, argv )
		if not sayCmds[ sayCommand ] then
			return error( "Say command \"" .. sayCommand .. "\" is not defined!" )
		end

		sayCmds[ sayCommand ].__fn( ply, sayCmds[ sayCommand ].__cmd, argv )
	end

	local function hookRoute( ply, command, argv )
		concommand.Run( ply, table.remove( argv, 1 ), argv )
	end
	concommand.Add( "_u", hookRoute )
end

local function autocompleteCallback( commandName, args )
	args = args:gsub( "^%s*", "" ) -- Trim left side

	-- Find the most specific command we have defined
	local currTable = routedCmds[ commandName:lower() ]
	local dummy, dummy, nextWord = args:find( "^(%S+)%s" )
	while nextWord and currTable[ nextWord:lower() ] do
		commandName = commandName .. " " .. nextWord
		currTable = currTable[ nextWord:lower() ]
		args = args:gsub( ULib.makePatternSafe( nextWord ) .. "%s+", "", 1 )

		dummy, dummy, nextWord = args:find( "^(%S+)%s" )
	end
	-- Done finding

	if not currTable.__autocomplete then -- Do our best with any sub commands
		local ply
		if CLIENT then
			ply = LocalPlayer()
		else
			-- Assume listen server, seems to be the only time this can happen
			ply = Entity( 1 ) -- Should be first player
			if not ply or not ply:IsValid() or not ply:IsListenServerHost() then
				return error( "Assumption fail!" )
			end
		end

		local ret = {}
		for cmd, cmdInfo in pairs( currTable ) do
			if cmd ~= "__fn" and cmd ~= "__word" and cmd ~= "__access_string" and cmd ~= "__client_only" then
				if cmd:sub( 1, args:len() ) == args and (not cmdInfo.__access_string or ply:query( cmdInfo.__access_string )) then -- Ensure access
					table.insert( ret, commandName .. " " .. cmdInfo.__word ) -- Pull in properly cased autocomplete
				end
			end
		end

		table.sort( ret )
		return ret
	end

	return currTable.__autocomplete( commandName, args )
end


--[[
	Function: cmds.addCommand

	*You must run this function on BOTH client AND server.*
	This function is very similar to garry's concommand.Add() function with a
	few key differences.

	First, this function supports commands with spaces in the name. IE,
	"ulx slap" is handled just like you'd think it ought to be.

	Second, autocompletes for spaced commands work similar to how the default
	autocomplete in console works. IE, if you type "ulx sl" into the console,
	you'll see all commands starting with that ("ulx slap", "ulx slay").

	Third, it will automatically tie in chat commands.

	Parameters:

		cmd - The command you're creating. IE, "ulx slap".
		fn - *(Optional on clients since it's ignored)* The function callback
			for this command. The callback receives the same parameters as a
			callback from concommand.Add() does. This parameter is ignored on
			clients.
		autocomplete - *(Optional)* The callback for autocompletes. If left
			nil, ULib tries to intelligently figure out what commands there are
			to complete. This parameter is ignored on servers if it's not
			singleplayer or a listen server.
		access_string - *(Optional)* Access required for use this command. It's
			only used for autocomplete purposes and is NOT validated at the
			server.
		say_cmd - *(Optional)* Specify a say command or say commands as a table
			to be tied in.
		hide_say - *(Optional, defaults to false)* Hide the chat when the say
			command is used?
		no_space_in_say - *(Optional, defaults to false)* Is a space between
			the chat command and arguments required?

	Example:

		The code below creates a bunch of different commands under the first
		"myTest" command. If you type in "myTest " at console, you see all the
		available commands for the next step in autocompletes. Note that it's
		case-insensitive, but otherwise works exactly like you would expect.

:cmds.addCommand( "myTest", print )
:cmds.addCommand( "myTest hi", print )
:cmds.addCommand( "myTest hi2", print )
:cmds.addCommand( "myTest hi2 doOty", print, print )
:cmds.addCommand( "myTest hi2 doot", print, print )
:cmds.addCommand( "myTest hi2 color", print, function() return { "red", "green", "blue" } end )
:cmds.addCommand( "myTest rEd", print, print )
:cmds.addCommand( "myTest blue", print, print )
:cmds.addCommand( "myTest bluegreen", print, print )
:cmds.addCommand( "myTest green", print, print )

	Revisions:

		v2.40 - Initial
]]
function cmds.addCommand( cmd, fn, autocomplete, access_string, say_cmd, hide_say, no_space_in_say )
	ULib.checkArg( 1, "ULib.cmds.addCommand", "string", cmd )
	if SERVER then
		ULib.checkArg( 2, "ULib.cmds.addCommand", "function", fn )
	else
		ULib.checkArg( 2, "ULib.cmds.addCommand", {"nil", "function"}, fn )
	end
	ULib.checkArg( 3, "ULib.cmds.addCommand", {"nil", "function"}, autocomplete )
	ULib.checkArg( 4, "ULib.cmds.addCommand", {"nil", "string"}, access_string )
	ULib.checkArg( 5, "ULib.cmds.addCommand", {"nil", "string", "table"}, say_cmd )
	ULib.checkArg( 6, "ULib.cmds.addCommand", {"nil", "boolean"}, hide_say )
	ULib.checkArg( 7, "ULib.cmds.addCommand", {"nil", "boolean"}, no_space_in_say )

	local words = ULib.explode( "%s", cmd )
	local currTable = routedCmds

	for _, word in ipairs( words ) do
		local lowerWord = word:lower() -- Don't need it anymore
		currTable[ lowerWord ] = currTable[ lowerWord ] or {}
		currTable = currTable[ lowerWord ]
		currTable.__word = word
	end

	currTable.__fn = fn
	currTable.__autocomplete = autocomplete
	currTable.__access_string = access_string

	local dummy, dummy, prefix = cmd:find( "^(%S+)" )
	concommand.Add( prefix, routedCommandCallback, autocompleteCallback )

	if SERVER and say_cmd then
		if type( say_cmd ) == "string" then say_cmd = { say_cmd } end

		for i=1, #say_cmd do
			local t = {}
			sayCmds[ say_cmd[ i ] ] = t
			t.__fn = fn
			t.__cmd = cmd

			ULib.addSayCommand( say_cmd[ i ], sayCommandCallback, cmd, hide_say, no_space_in_say )

			local translatedCommand =  say_cmd[ i ] .. (no_space_in_say and "" or " ")
			ULib.sayCmds[ translatedCommand:lower() ].__cmd = cmd -- Definitely needs refactoring at some point...
		end
	end
end

--[[
	Function: cmds.addCommandClient

	Exactly like cmds.addCommand, except it will expect the callback to be run
	on the local client instead of the server.

	Revisions:

		v2.40 - Initial
]]
function cmds.addCommandClient( cmd, fn, autocomplete )
	ULib.checkArg( 1, "ULib.cmds.addCommandClient", "string", cmd )
	ULib.checkArg( 2, "ULib.cmds.addCommandClient", {"nil", "function"}, fn )
	ULib.checkArg( 3, "ULib.cmds.addCommandClient", {"nil", "function"}, autocomplete )

	local words = ULib.explode( "%s", cmd )
	local currTable = routedCmds

	for _, word in ipairs( words ) do
		local lowerWord = word:lower() -- Don't need it anymore
		currTable[ lowerWord ] = currTable[ lowerWord ] or {}
		currTable = currTable[ lowerWord ]
		currTable.__word = word
	end

	currTable.__fn = fn
	currTable.__autocomplete = autocomplete
	currTable.__client_only = true

	local dummy, dummy, prefix = cmd:find( "^(%S+)" )
	concommand.Add( prefix, routedCommandCallback, autocompleteCallback )
end
