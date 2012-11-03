--[[
	Title: Client initialization
	
	Client-side initialization. In here we include all the necessary files.
]]

if not file.Exists( "lua_temp/ups/cl_init.lua", true ) then return end -- If this file doesn't exist then the server isn't running UPS.
module( "UPS", package.seeall )

local function init()
	include( "ups/sh_defines.lua" )
	include( "ups/cl_lib.lua" )
	include( "ups/sh_lib.lua" )
	include( "ups/sh_friends.lua" )

	local sh_modules = file.FindInLua( "ups/modules/sh/*.lua" )
	local cl_modules = file.FindInLua( "ups/modules/cl/*.lua" )

	for _, file in ipairs( cl_modules ) do
		include( "ups/modules/cl/" .. file )
	end

	for _, file in ipairs( sh_modules ) do
		include( "ups/modules/sh/" .. file )
	end
end
usermessage.Hook( "ups_client_init", init )
