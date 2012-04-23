--[[
	Title: Tables

	Some table helpers.
]]

-- Based off "RecursiveReadOnlyTables" by VeLoSo (http://lua-users.org/wiki/RecursiveReadOnlyTables)

-- cache the metatables of all existing read-only tables,
-- so our functions can get to them, but user code can't
local metatable_cache = setmetatable( {}, { __mode = "k" } )

local function make_getter( real_table )
	local function getter( dummy, key )
		local ret = real_table[ key ]
		if type( ret ) == "table" and not metatable_cache[ ret ] then
			ret = ULib.makeReadOnly( ret )
		end
		return ret
	end
	return getter
end

local function setter()
	ULib.error( "Attempt to modify read-only table!" )
end

local function make_pairs( real_table )
	local function pairs()
		local key, value, cur_key = nil, nil, nil
		local function nexter() -- both args dummy
			key, value = next( real_table, cur_key )
			cur_key = key
			if type( key ) == "table" and not metatable_cache[ key ] then
				key = ULib.makeReadOnly( key )
			end
			if type( value ) == "table" and not metatable_cache[ value ] then
				value = ULib.makeReadOnly( value )
			end
			return key, value
		end
		return nexter -- values 2 and 3 dummy
	end
	return pairs
end


--[[
	Function: makeReadOnly

	Makes a table and all recursive tables read-only

	Parameters:

		t - The table to make read-only

	Returns:

		The table read-only'fied
]]
function ULib.makeReadOnly( t )
	local new={}
	local mt={
		__metatable = "read only table",
		__index = make_getter( t ),
		__newindex = setter,
		__pairs = make_pairs( t ),
		__type = "read-only table" }
	setmetatable( new, mt )
	metatable_cache[ new ] = mt
	return new
end


--[[
	Function: ropairs

	The equivalent of "pairs" for a readonly table, since "pairs" won't work.

	Parameters:

		t - The table
]]
function ULib.ropairs( t )
	local mt = metatable_cache[ t ]
	if mt==nil then
		ULib.error( "bad argument #1 to 'ropairs' (read-only table expected, got " .. type(t) .. ")" )
	end
	return mt.__pairs()
end


--[[
	Function: findInTable

	Finds a value in a table. As opposed to table.HasValue(), this function will *only* check numeric keys, and will return a number of where the value is.

	Parameters:

		t - The table to check
		check - The value to check if it exists in t. Can be any type.
		init - *(Optional, defaults to 1)* The value to start from.
		last - *(Optional, defaults to the length of the table)* The value to end at.
		recursive - *(Optional, default to false)* If true, it will check any subtables it comes across.

	Returns:

		The number of the key where check resides, false if none is found. If init > last it returns false as well.
]]
function ULib.findInTable( t, check, init, last, recursive )
	init = init or 1
	last = last or #t

	if init > last then return false end

	for i=init, last do
		if t[ i ] == check then return i end

		if type( t[ i ] ) == "table" and recursive then return ULib.findInTable( v, check, 1, recursive ) end
	end

	return false
end

--[[
	Function: matrixTable

	Splits a table into a number of given columns. Does not change original table.

	Parameters:

		t - The table to split
		columns, The number of columns to create

	Returns:

		The new table with the column being the first key and the row being the second key.

	Revisions:

		v2.10 - Initial
]]
function ULib.matrixTable( t, columns )
	local baserows = math.floor( #t / columns )
	local remainder = math.fmod( #t, columns )
	local nt = {} -- New table after we process
	local curn = 1 -- What value to grab next from our old table

	for i=1, columns do
		local numtograb = baserows
		if i <= remainder then
			numtograb = baserows + 1
		end

		nt[ i ] = {}
		for n=0, numtograb - 1 do
			table.insert( nt[ i ], t[ curn + n ] )
		end
		curn = curn + numtograb
	end

	return nt
end