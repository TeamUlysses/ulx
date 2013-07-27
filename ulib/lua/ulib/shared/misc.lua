--[[
	Title: Miscellaneous

	Some utility functions. Unlike the functions in util.lua, this file only holds non-HL2 specific functions.
]]

--[[
	Function: explode

	Split a string by a separator.

	Parameters:

		separator - The separator string.
		str - A string.
		limit - *(Optional)* Max number of elements in the table

	Returns:

		A table of str split by separator, nil and error message otherwise.

	Revisions:

		v2.10 - Initial (dragged over from a GM9 archive though)
]]
function ULib.explode( separator, str, limit )
	local t = {}
	local curpos = 1
	while true do -- We have a break in the loop
		local newpos, endpos = str:find( separator, curpos ) -- find the next separator in the string
		if newpos ~= nil then -- if found then..
			table.insert( t, str:sub( curpos, newpos - 1 ) ) -- Save it in our table.
			curpos = endpos + 1 -- save just after where we found it for searching next time.
		else
			if limit and table.getn( t ) > limit then
				return t -- Reached limit
			end
			table.insert( t, str:sub( curpos ) ) -- Save what's left in our array.
			break
		end
	end

	return t
end


--[[
	Function: stripComments

	Strips comments from a string

	Parameters:

		str - The string to stip comments from
		comment - The comment string. If it's found, whatever comes after it on that line is ignored. ( IE: "//" )
		blockcommentbeg - *(Optional)* The block comment begin string. ( IE: "/<star>" )
		blockcommentend - *(Optional, must be specified if above parameter is)* The block comment end string. ( IE: "<star>/" )

	Returns:

		The string with the comments stripped, nil and error otherwise.

	Revisions:

		v2.02 - Fixed block comments in more complicated files.
]]
function ULib.stripComments( str, comment, blockcommentbeg, blockcommentend )
	if blockcommentbeg and string.sub( blockcommentbeg, 1, string.len( comment ) ) == comment then -- If the first of the block comment is the linecomment ( IE: --[[ and -- ).
		string.gsub( str, ULib.makePatternSafe( comment ) .. "[%S \t]*", function ( match )
			if string.sub( match, 1, string.len( blockcommentbeg ) ) == blockcommentbeg then
				return "" -- No substitution, this is a block comment.
			end
			str = string.gsub( str, ULib.makePatternSafe( match ), "", 1 )
			return ""
		end )

		str = string.gsub( str, ULib.makePatternSafe( blockcommentbeg ) .. ".-" .. ULib.makePatternSafe( blockcommentend ), "" )
	else -- Doesn't need special processing.
		str = string.gsub( str, ULib.makePatternSafe( comment ) .. "[%S \t]*", "" )
		if blockcommentbeg and blockcommentend then
			str = string.gsub( str, ULib.makePatternSafe( blockcommentbeg ) .. ".-" .. ULib.makePatternSafe( blockcommentend ), "" )
		end
	end

	return str
end


--[[
	Function: makePatternSafe

	Makes a string safe for pattern usage, like in string.gsub(). Basically replaces all keywords with % and keyword.

	Parameters:

		str - The string to make pattern safe

	Returns:

		The pattern safe string
]]
function ULib.makePatternSafe( str )
	return str:gsub( "([%(%)%.%%%+%-%*%?%[%]%^%$])", "%%%1" )
end


--[[
	Function: stripQuotes

	Trims leading and tailing quotes from a string

	Parameters:

		s - The string to strip

	Returns:

		The stripped string
]]
function ULib.stripQuotes( s )
	return s:gsub( "^%s*[\"]*(.-)[\"]*%s*$", "%1" )
end


--[[
	Function: unescapeBackslash

	Converts '\\' to '\'

	Parameters:

		s - The string to convert

	Returns:

		The converted string
]]
function ULib.unescapeBackslash( s )
	return s:gsub( "\\\\", "\\" )
end


--[[
	Function: splitPort

	Parameters:

		ipAndPort - An IP address in the form xxx.xxx.xxx.xxx:xxxx

	Returns:

		The IP as the first return value, the port as the second return value

	Revisions:

		v2.40 - Initial.
]]
function ULib.splitPort( ipAndPort )
	return unpack( ULib.explode( ":", ipAndPort ) )
end

--[[
	Function: splitArgs

	This is similar to string.Explode( " ", str ) except that it will also obey quotation marks.

	Parameters:

		args - The string to split from
		start_token - The string character to start a string with.
		end_token - The string character to end a string with.

	Returns:

		A table containing the individual arguments and a boolean stating whether or not mismatched quotes were found.

	Example:

		:ULib.splitArgs( "This is a \"Cool sentence to\" make \"split up\"" )

		returns...

		:{ "This", "is", "a", "Cool sentence to", "make", "split up" }

	Notes:

		* Mismatched quotes will result in having the last quote grouping the remaining input into
			one argument.
		* Arguments outside of quotes are trimmed (via string.Trim), while what's inside quotes is not
			trimmed at all.

	Revisions:

		v2.10 - Can now handle tabs and trims strings before returning.
		v2.30 - Rewrite. Can now properly handle escaped quotes. New param, ignore_mismatch.
		v2.40 - Rewrite. Much more stable and predictable now. Removed ignore_mismatch param. As
			far as I can tell, it now matches the source engine's split arg behavior exactly. Also
			accepts tokens to consider a string.
]]
function ULib.splitArgs( args, start_token, end_token )
	args = args:Trim()
	local argv = {}
	local curpos = 1 -- Our current position within the string
	local in_quote = false -- Is the text we're currently processing in a quote?
	start_token = start_token or "\""
	end_token = end_token or "\""
	local args_len = args:len()

	while in_quote or curpos <= args_len do
		local quotepos = args:find( in_quote and end_token or start_token, curpos, true )

		-- The string up to the quote, the whole string if no quote was found
		local prefix = args:sub( curpos, (quotepos or 0) - 1 )
		if not in_quote then
			local trimmed = prefix:Trim()
			if trimmed ~= "" then -- Something to be had from this...
				local t = ULib.explode( "%s+", trimmed )
				table.Add( argv, t )
			end
		else
			table.insert( argv, prefix )
		end

		-- If a quote was found, reduce our position and note our state
		if quotepos ~= nil then
			curpos = quotepos + 1
			in_quote = not in_quote
		else -- Otherwise we've processed the whole string now
			break
		end
	end

	return argv, in_quote
end


--[[
	Function: parseKeyValues

	Parses a keyvalue formatted string into a table.

	Parameters:

		str - The string to parse.
		convert - *(Optional, defaults to false)* Setting this to true will convert garry's keyvalues to a better form. This has two effects.
		  First, it will remove the "Out"{} wrapper. Second, it will convert any keys that equate to a number to a number.

	Returns:

		The table, nil and error otherwise. *If you find you're missing information from the table, the file format might be incorrect.*

	Example format:
:test
:{
:	"howdy"   "bbq"
:
:	foo
:	{
:		"bar"   "false"
:	}
:
:}

	Revisions:

		v2.10 - Initial (but tastefully stolen from a GM9 version)
		v2.30 - Rewrite. Much more robust and properly unescapes backslashes now.
		v2.40 - Properly handles escaped quotes now.
]]
function ULib.parseKeyValues( str, convert )
	local lines = ULib.explode( "\r?\n", str )
	local parent_tables = {} -- Traces our way to root
	local current_table = {}
	local is_insert_last_op = false

	for i, line in ipairs( lines ) do
		local tmp_string = string.char( 01, 02, 03 ) -- Replacement
		local tokens = ULib.splitArgs( (line:gsub( "\\\"", tmp_string )) )
		for i, token in ipairs( tokens ) do
			tokens[ i ] = ULib.unescapeBackslash( token ):gsub( tmp_string, "\"" )
		end

		local num_tokens = #tokens

		if num_tokens == 1 then
			local token = tokens[ 1 ]
			if token == "{" then
				local new_table = {}
				if is_insert_last_op then
					current_table[ table.remove( current_table ) ] = new_table
				else
					table.insert( current_table, new_table )
				end
				is_insert_last_op = false
				table.insert( parent_tables, current_table )
				current_table = new_table

			elseif token == "}" then
				is_insert_last_op = false
				current_table = table.remove( parent_tables )
				if current_table == nil then
					return nil, "Mismatched recursive tables on line " .. i
				end

			else
				is_insert_last_op = true
				table.insert( current_table, tokens[ 1 ] )
			end

		elseif num_tokens == 2 then
			is_insert_last_op = false
			if convert and tonumber( tokens[ 1 ] ) then
				tokens[ 1 ] = tonumber( tokens[ 1 ] )
			end

			current_table[ tokens[ 1 ] ] = tokens[ 2 ]

		elseif num_tokens > 2 then
			return nil, "Bad input on line " .. i
		end
	end

	if #parent_tables ~= 0 then
		return nil, "Mismatched recursive tables"
	end

	if convert and table.Count( current_table ) == 1 and
		type( current_table.Out ) == "table" then -- If we caught a stupid garry-wrapper

		current_table = current_table.Out
	end

	return current_table
end


--[[
	Function: makeKeyValues

	Makes a key values string from a table.

	Parameters:

		t - The table to make the keyvalues from. This can only contain tables, numbers, and strings.
		tab - *Only for internal use*, this helps make inline tables look better.
		completed - A list of table values that have already been parsed, this is *only for internal use* to make sure we don't hit an infinite loop.

	Returns:

		The string, nil and error otherwise.

	Notes:

		If you use numbers as keys in the table, just the values will be used.

	Example table format:
:{ test = { howdy = "bbq", foo = { bar = "false" } } }

	Example return format:
:test
:{
:	"howdy"	  "bbq"
:
:	foo
:	{
:		"bar"	"false"
:	}
:
:}

	Revisions:

		v2.10 - Initial (but tastefully stolen from a GM9 version)
		v2.40 - Increased performance for insanely high table counts.
]]
function ULib.makeKeyValues( t, tab, completed )
	ULib.checkArg( 1, "ULib.makeKeyValues", "table", t )

	tab = tab or ""
	completed = completed or {}
	if completed[ t ] then return "" end -- We've already done this table.
	completed[ t ] = true

	local str = ""

	for k, v in pairs( t ) do
		str = str .. tab
		if type( k ) ~= "number" then
			str = string.format( "%s%q\t", str, tostring( k ) )
		end

		if type( v ) == "table" then
			str = string.format( "%s\n%s{\n%s%s}\n", str, tab, ULib.makeKeyValues( v, tab .. "\t", completed ), tab )
		elseif type( v ) == "string" then
			str = string.format( "%s%q\n", str, v )
		else
			str = str .. tostring( v ) .. "\n"
		end
	end

	return str
end


--[[
	Function: toBool

	Converts a bool, nil, string, or number to a bool

	Parameters:

		x - The string or number

	Returns:

		The bool

	Revisions:

		v2.10 - Initial.
		v2.40 - Added ability to convert nils and bools.
]]
function ULib.toBool( x )
	if type( x ) == "boolean" then return x end
	if x == nil then return false end

	if tonumber( x ) ~= nil then
		x = math.Round( tonumber( x ) )
		if x == 0 then
			return false
		else
			return true
		end
	end

	x = x:lower()
	if x == "t" or x == "true" or x == "yes" or x == "y" then
		return true
	else
		return false
	end
end


--[[
	Function: findVar

	Given a string, find a var starting from the global namespace. This will correctly parse tables. IE, "ULib.serialize".

	Parameters:

		var - The variable you wish to find

	Returns:

		The variable or nil

	Revisions:

		v2.40 - Removed dependency on gmod functions.
]]
function ULib.findVar( var )
	if not var then error( "Nil param passed to ULib.findVar", 2 ) end
	local loc = ULib.explode( "%.", var )
	local x = _G
	for _, v in ipairs( loc ) do
		x = x[ v ]
		if not x then return end
	end

	return x
end


--[[
	Function: throwBadArg

	Throws an error similar to the lua "bad argument #x to <fn_name> (<type> expected, got <type>).

	Parameters:

		argnum - *(Optional)* The argument number that was bad.
		fnName - *(Optional)* The name of the function being called.
		expected - *(Optional)* The string of the type you expected.
		data - *(Optional)* The actual data you got.
		throwLevel - *(Optional, defaults to 3)* How many levels up to throw the error.

	Returns:

		Never returns, throws an error

	Revisions:

		v2.40 - Initial.
]]
function ULib.throwBadArg( argnum, fnName, expected, data, throwLevel )
	throwLevel = throwLevel or 3

	local str = "bad argument"
	if argnum then
		str = str .. " #" .. tostring( argnum )
	end
	if fnName then
		str = str .. " to " .. fnName
	end
	if expected or data then
		str = str .. " ("
		if expected then
			str = str .. expected .. " expected"
		end
		if expected and data then
			str = str .. ", "
		end
		if data then
			str = str .. "got " .. type( data )
		end
		str = str .. ")"
	end

	error( str, throwLevel )
end


--[[
	Function: checkArg

	Checks to see if an arg matches what is expected, if not, calls throwBadArg().

	Parameters:

		argnum - *(Optional)* The argument number you're.
		fnName - *(Optional)* The name of the function being called.
		expected - The string of the type you expect or a table of types you expect.
		data - The actual data you got.
		throwLevel - *(Optional, defaults to 4)* How many levels up to throw the error.

	Returns:

		Never returns if the data is bad, throws an error. Otherwise returns nil.

	Revisions:

		v2.40 - Initial.
]]
function ULib.checkArg( argnum, fnName, expected, data, throwLevel )
	throwLevel = throwLevel or 4
	if type( expected ) == "string" then
		if type( data ) == expected then
			return
		else
			return ULib.throwBadArg( argnum, fnName, expected, data, throwLevel )
		end
	else
		if table.HasValue( expected, type( data ) ) then
			return
		else
			return ULib.throwBadArg( argnum, fnName, table.concat( expected, "," ), data, throwLevel )
		end
	end
end


--[[
	Function: isValidSteamID

	Checks to see if a given string is a valid steamid.

	Parameters:

		steamid - The string of the supposed steamid.

	Returns:

		True if it's valid, false if not.

	Revisions:

		v2.40 - Initial.
]]
function ULib.isValidSteamID( steamid )
	return steamid:match( "^STEAM_%d:%d:%d+$" ) ~= nil
end


--[[
	Function: isValidIP

	Checks to see if a given string is a valid IPv4 address.

	Parameters:

		ip - The string of the supposed ip.

	Returns:

		True if it's valid, false if not.

	Revisions:

		v2.40 - Initial.
]]
function ULib.isValidIP( ip )
	if ip:find( "^%d%d?%d?%.%d%d?%d?%.%d%d?%d?%.%d%d?%d?$" ) then
		return true
	else
		return false
	end
end


--[[
	Function: removeCommentHeader

	Removes a comment header.

	Parameters:

		data - The string to remove the comment from.
		comment_char - The comment char.

	Returns:

		Data without the comment header.

	Revisions:

		v2.40 - Initial.
]]
function ULib.removeCommentHeader( data, comment_char )
	comment_char = comment_char or ";"
	local lines = ULib.explode( "\r?\n", data )
	local end_comment_line = 0
	for _, line in ipairs( lines ) do
		local trimmed = line:Trim()
		if trimmed == "" or trimmed:sub( 1, 1 ) == comment_char then
			end_comment_line = end_comment_line + 1
		else
			break
		end
	end

	local not_comment = table.concat( lines, "\n", end_comment_line + 1 )
	return not_comment:Trim()
end


--[[
	Function: stringTimeToSeconds

	Converts a string containing time information to seconds.

	Parameters:

		str - The time string. Defaults to minutes, "h" is for hours, "d" is for days, "w" is for weeks.

	Returns:

		The number of minutes represented by the string or nil if it's unable to parse the string.

	Revisions:

		v2.41 - Initial
		v2.43 - Added year parameter
]]
function ULib.stringTimeToSeconds( str )
	if str == nil or type( str ) == "number" then
		return str
	end

	str = str:gsub( " ", "" )
	local minutes = 0
	local keycode_location = str:find( "%a" )
	while keycode_location do
		local keycode = str:sub( keycode_location, keycode_location )
		local num = tonumber( str:sub( 1, keycode_location - 1 ) )
		if not num then
			return nil
		end

		local multiplier
		if keycode == "h" then
			multiplier = 60
		elseif keycode == "d" then
			multiplier = 60 * 24
		elseif keycode == "w" then
			multiplier = 60 * 24 * 7
		elseif keycode == "y" then
			multiplier = 60 * 24 * 365
		else
			return nil
		end

		str = str:sub( keycode_location + 1 )
		keycode_location = str:find( "%a" )
		minutes = minutes + num * multiplier
	end

	local num = 0
	if str ~= "" then
		num = tonumber( str )
	end

	if num == nil then
		return nil
	end

	return minutes + num
end


--[[
	Section: Inheritance
]]

--[[
	Function: inheritsFrom

	Creates a psudeo-inheritance for lua. It will search for variables that do
	not exist in derived 'classes' in the parent 'classes', among other things
	explained below.

	Parameters:

		baseClass - The class to derive from. This value *must* either be nil
			or a class created using <inheritsFrom()>.

	Returns:

		The table of the derived class.

	Revisions:

		v2.40 - Initial.

	Notes:

		* Adapted with improvements from a lua-users inheritance tutorial
		<http://lua-users.org/wiki/InheritanceTutorial>.
		* Create using Class:create( ... ) or Class( ... ) (equivalent).
		* Whatever's passed in the '...', above, is passed to
		derived_class:instantiate(). This allows for a 'constructor'.

	See Also:

		* <root_class>
		* <root_class:create>
		* <root_class:class>
		* <root_class:superClass>
		* <root_class:instantiate>
		* <root_class:isa>

	Example:

:b = inherits_from( nil )
:function b:instantiate( ... )
:	print( "base", unpack( arg ) )
:end
:
:d = inherits_from( b )
:function d:instantiate( ... )
:	print( "derived", unpack( arg ) )
:end
:
:b1 = b( "should be base" )
:d1 = d( "should be derived" )
:print( "d1 is d?", d1:isa( d ), "is b?", d1:isa( b ) )
:print( "b1 is d?", b1:isa( d ), "is b?", b1:isa( b ) )

	Output:

:base	 should be base
:derived should be derived
:d1 is d?		 true	 is b?	 true
:b1 is d?		 false	 is b?	 true
]]
function inheritsFrom( base_class )
	local new_class = {}

	-- The meta-table for INSTANCES (IE, created with Class:create())
	local instance_mt = { __index = new_class, class=new_class, base_class=base_class }

	-- The meta-table for the root_class (this will only ever have one table associated with it)
	local class_mt = table.Copy( instance_mt ) -- Only a few differences so copy
	class_mt.__index = base_class or root_class -- Use base or our special meta-base
	class_mt.__call = root_class.call -- Set up call alias
	class_mt.class = new_class -- Set up alias to ourself
	class_mt.instance_mt = instance_mt -- Need this for root_class:create()

	setmetatable( new_class, class_mt )

	return new_class
end


--[[
	Table: root_class

	This is a local table that holds our functions that we want *all* classes
	to have.
]]
root_class = {}


--[[
	Function: root_class:call

	This is a utility function used by the metatable __call to resolve Class( ... ) to Class:create( ... ).

	Parameters:

		parent_table - The table of the caller.
		... - Extra construction parameters, passed to Class:instantiate.

	Returns:

		The 'class instance'.

	Revisions:

		v2.40 - Initial.
]]
function root_class.call( parent_table, ... )
	return parent_table:class():create( ... )
end


--[[
	Function: root_class:create

	This is used to create new 'class instances'.

	Parameters:

		... - Extra construction parameters, passed to Class:instantiate.

	Revisions:

		v2.40 - Initial.
]]
function root_class:create( ... )
	local newinst = {}
	setmetatable( newinst, getmetatable( self ).instance_mt )
	newinst:instantiate( ... ) -- 'Constructor'
	return newinst
end


-- Return the class object of the instance
function root_class:class()
	return getmetatable( self ).class
end


-- Return the super class object of the instance
function root_class:superClass()
	base_class = getmetatable( self ).base_class
	return base_class ~= root_class and base_class or nil -- Nil if root class
end


-- We need to make sure this func exists, but can be overridden
function root_class:instantiate()
end


-- Return true if the caller is an instance of theClass
function root_class:isa( target_class )
	local cur_class = self:class()

	while cur_class and not b_isa do
		if cur_class == target_class then
			return true
		else
			cur_class = cur_class:superClass()
		end
	end

	return false
end

function isClass( obj )
	return type( obj ) == "table" and type( obj.isa ) == "function" and obj:isa( root_class )
end


-- This wonderful bit of following code will make sure that no rogue coder can screw us up by changing the value of '_'
_ = nil -- Make sure we're starting out right.
local meta = getmetatable( _G ) or {}
if type( meta ) == "boolean" then return end -- Metatable is protected, so we aren't able to run this code without erroring.
local old__newindex = meta.__newindex
setmetatable( _G, meta )
function meta.__newindex( t, k, v )
	if k == "_" then
		-- If you care enough to fix bad scripts uncomment this following line.
		-- error( "attempt to modify global variable '_'", 2 )
		return
	end

	if old__newindex then
		old__newindex( t, k, v )
	else
		rawset( t, k, v )
	end
end
