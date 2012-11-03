--[[
	Title: Client initialization
	
	Client-side initialization. In here we include all the necessary files.
]]

module( "UPS", package.seeall )

local function init()
	include( "ups/sh_defines.lua" )
	include( "ups/cl_lib.lua" )
	include( "ups/sh_lib.lua" )
	include( "ups/sh_friends.lua" )

	local sh_modules = file.Find( "ups/modules/sh/*.lua", "LUA" )
	local cl_modules = file.Find( "ups/modules/cl/*.lua", "LUA" )

	for _, file in ipairs( cl_modules ) do
		include( "ups/modules/cl/" .. file )
	end

	for _, file in ipairs( sh_modules ) do
		include( "ups/modules/sh/" .. file )
	end
end
usermessage.Hook( "ups_client_init", init )
