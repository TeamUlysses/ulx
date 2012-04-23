--[[
	Title: Hook

	This overrides garry's default hook system. We need this better hook system for any serious development.
	We're implementing hook priorities. hook.Add() now takes an additional parameter of type number between -20 and 20.
	0 is default (so we remain backwards compatible). -20 and 20 are read only (ignores returned values).
	Hooks are called in order from -20 on up.
]]

-- This file is coded a little awkwardly because we're trying to implement a new behavior while remaining as true to the old behavior as possible.

-- Globals that we are going to use
local ipairs = ipairs
local pairs = pairs
local ErrorNoHalt = ErrorNoHalt
local pcall = pcall
local tostring = tostring
local concommand = concommand
local CLIENT = CLIENT
local type = type
local table = table

--[[ Needed for tests, below
local print = print
local assert = assert
local error = error --]]

-- Grab all previous hooks from the pre-existing hook module.
local OldHooks = hook.GetTable()

-----------------------------------------------------------
--   Name: hook
--   Desc: For scripts to hook onto Gamemode events
-----------------------------------------------------------
module( "hook" )


-- Local variables
local Hooks = {}
local BackwardsHooks = {} -- A table fully to garry's spec for aVoN
local currentHooks = {} -- Used to track what hooks are currently running

local function sortHooks( event_name )
	table.sort( Hooks[ event_name ], function( a, b ) -- Sort by priority, then name
		if a == nil then return false -- Move nil to end
		elseif b == nil then return true -- Keep nil at end
		elseif a.priority < b.priority then return true
		elseif a.priority == b.priority and tostring( a.name ) < tostring( b.name ) then return true
		else return false end
	end )
end


-- Exposed Functions

--[[
	Function: hook.GetTable

	Returns:

		The table filled with all the hooks in a format that is backwards compatible with garry's.
]]
function GetTable()
	return BackwardsHooks
end

--[[
	Function: hook.Add

	Our new and improved hook.Add function.
	Read the file description for more information on how the hook priorities work.

	Parameters:

		event_name - The name of the event (IE "PlayerInitialSpawn").
		name - The unique name of your hook.
			This is only so that if the file is reloaded, it can be unhooked (or you can unhook it yourself).
		func - The function callback to call
		priority - *(Optional, defaults to 0)* Priority from -20 to 20. Remember that -20 and 20 are read-only.
]]
function Add( event_name, name, func, priority )
	if not Hooks[ event_name ] then
		BackwardsHooks[ event_name ] = {}
		Hooks[ event_name ] = {}
	end

	priority = priority or 0

	-- Make sure the name is unique
	Remove( event_name, name )

	table.insert( Hooks[ event_name ], { name=name, fn=func, priority=priority } )
	sortHooks( event_name )
	BackwardsHooks[ event_name ][ name ] = func -- Keep the classic style too so we won't break anything
end

--[[
	Function: hook.Remove

	Parameters:

		event_name - The name of the event (IE "PlayerInitialSpawn").
		name - The unique name of your hook. Use the same name you used in hook.Add()
]]
function Remove( event_name, name )
	for index, value in ipairs( Hooks[ event_name ] ) do
		if value.name == name then
			table.remove( Hooks[ event_name ], index )
			break
		end
	end

	BackwardsHooks[ event_name ][ name ] = nil
end

--[[
	Function: hook.Call

	Normally, you don't want to call this directly. Use gamemode.Call() instead.

	Parameters:

		name - The name of the event
		gm - The gamemode table
		... - Any other params to pass
]]
function Call( name, gm, ... )
	table.insert( currentHooks, name )

	local b, rA, rB, rC, rD, rE, rF, rG, rH
	local HookTable = Hooks[ name ]
	local HookRemoved = false -- Keep track of whether or not a hook was removed

	if HookTable then
		for k=1, #HookTable do
			v = HookTable[ k ]
			if not v then
				HookRemoved = true -- Trigger a resort
			elseif not v.fn then
				ErrorNoHalt( "ERROR: Hook '" .. tostring( v.name ) .. "' tried to call a nil function!\n" )
				ErrorNoHalt( "Removing Hook '" .. tostring( v.name ) .. "'\n" )
				HookTable[ k ] = nil -- remove this hook
				BackwardsHooks[ name ][ v.name ] = nil
				HookRemoved = true
				break

			else
				-- Call hook function
				b, rA, rB, rC, rD, rE, rF, rG, rH = pcall( v.fn, ... )

				if not b then
					ErrorNoHalt( "ERROR: Hook '" .. tostring( v.name ) .. "' Failed: " .. tostring( rA ) .. "\n" )
					ErrorNoHalt( "Removing Hook '" .. tostring( v.name ) .. "'\n" )
					HookTable[ k ] = nil -- remove this hook
					BackwardsHooks[ name ][ v.name ] = nil
					HookRemoved = true

				else
					-- Allow hooks to override return values if it's within the limits (-20 and 20 are read only)
					if rA ~= nil and v.priority > -20 and v.priority < 20 then
						table.remove( currentHooks ) -- Pop
						if HookRemoved then
							sortHooks( name )
						end
						return rA, rB, rC, rD, rE, rF, rG, rH
					end
				end
			end
		end
	end

	if gm then
		local GamemodeFunction = gm[ name ]
		if not GamemodeFunction then
			table.remove( currentHooks ) -- Pop
			if HookRemoved then
				sortHooks( name )
			end
			return nil
		end

		if type( GamemodeFunction ) ~= "function" then
			Msg( "Calling Non Function!? ", GamemodeFunction, "\n" )
		end

		-- This calls the actual gamemode function - after all the hooks have had chance to override
		b, rA, rB, rC, rD, rE, rF, rG, rH = pcall( GamemodeFunction, gm, ... )

		if not b then
			gm[ name .. "_ERRORCOUNT" ] = gm[ name .. "_ERRORCOUNT" ] or 0
			gm[ name .. "_ERRORCOUNT" ] = gm[ name .. "_ERRORCOUNT" ] + 1
			ErrorNoHalt( "ERROR: GAMEMODE:'" .. tostring( name ) .. "' Failed: " .. tostring( rA ) .. "\n" )

			table.remove( currentHooks ) -- Pop
			if HookRemoved then
				sortHooks( name )
			end
			return nil
		end

		table.remove( currentHooks ) -- Pop
		if HookRemoved then
			sortHooks( name )
		end
		return rA, rB, rC, rD, rE, rF, rG, rH
	end

	table.remove( currentHooks ) -- Pop
	if HookRemoved then
		sortHooks( name )
	end
end

--[[
	Function: hook.getCurrentHooks

	Returns the hooks that are currently processing, if any.

	Returns:

		A table of the current hooks that are processing, starting with the ones that started first.
		The table is empty if no hooks are currently executing.

	Revisions:

		v2.40 - Initial.
]]
function getCurrentHooks()
	return currentHooks
end

--[[
	Function: hook.isInHook

	Returns true if the specified hook is currently processing

	Parameters:

		name - The name of the hook to check

	Returns:

		true if the hook is executing, false otherwise

	Revisions:

		v2.40 - Initial.
]]
local failed = false
local shouldFail = false
local i, t

function isInHook( name )
	return table.HasValue( currentHooks, name )
end

-- Bring in all the old hooks
for event_name, t in pairs( OldHooks ) do
	for name, func in pairs( t ) do
		Add( event_name, name, func, 0 )
	end
end


--[[
-- Since the correctness of this file is so important, we've made a little test suite
local function appendGenerator( n )
	return function( t )
		table.insert( t, n )
	end
end

local function returnRange()
	return 1, 2, 3, 4, 5, 6, 7, 8
end

local function noop()
end

local function err()
	if shouldFail then
		error( "this error is normal!" )
	else
		error( "this error is bad!" )
		failed = true
	end
end

local function doTests( ply, cmd, argv )
	print( "Being run on client: " .. tostring( CLIENT ) )

	-- First make sure there's no return value leakage...
	Add( "LeakageA", "a", returnRange )
	t = { Call( "LeakageA", _ ) }
	assert( #t == 8 )
	for k, v in pairs( t ) do
		assert( k == v )
	end

	Add( "LeakageB", "a", noop )
	t = { Call( "LeakageB", _ ) }
	assert( #t == 0 )

	-- Now let's make sure errors are handled correctly...
	shouldFail = true
	Add( "ErrCheck", "a", noop )
	Add( "ErrCheck", "b", err )
	Add( "ErrCheck", "c", noop )
	Add( "ErrCheck", "d", returnRange )
	t = { Call( "ErrCheck", _ ) }
	assert( #t == 8 )
	assert( #Hooks.ErrCheck == 3 and Hooks.ErrCheck[4] == nil ) -- Should have been reduced so that the 'b' got removed

	shouldFail = false
	t = { Call( "ErrCheck", _ ) }
	assert( #t == 8 )

	-- Check for override
	Add( "ErrCheck", "d", noop, 19 ) -- Different priority, same name should still override
	t = { Call( "ErrCheck", _ ) }
	assert( #t == 0 )

	-- Check for order and readonly'ness...
	Add( "Order", "n20a", returnRange, -20 )
	Add( "Order", "a", appendGenerator( 5 ) )
	Add( "Order", "n20c", appendGenerator( 3 ), -20 ) -- Should be alphabetized
	Add( "Order", "n20a", appendGenerator( 1 ), -20 )
	Add( "Order", "n20b", appendGenerator( 2 ), -20 )
	Add( "Order", "n10a", appendGenerator( 4 ), -10 )
	Add( "Order", "10a", appendGenerator( 6 ), 10 )
	Add( "Order", "20a", returnRange, 20 )
	Add( "Order", "20aa", appendGenerator( 7 ), 20 )

	t = {}
	Call( "Order", _, t )
	assert( #t == 7 )
	for k, v in pairs( t ) do
		assert( k == v )
	end

	if failed then
		print( "Tests failed!" )
	else
		print( "All tests passed!" )
	end
end

concommand.Add( "run_hook_tests", doTests )
--]]
