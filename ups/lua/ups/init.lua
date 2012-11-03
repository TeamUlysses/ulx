--[[
	Title: Server initialization
	
	Server-side initialization. In here we include all the necessary files and make sure the clients receive the proper files as well.
]]

module( "UPS", package.seeall )

local sv_modules = file.FindInLua( "ups/modules/*.lua" )
local sh_modules = file.FindInLua( "ups/modules/sh/*.lua" )
local cl_modules = file.FindInLua( "ups/modules/cl/*.lua" )

Msg( "/=================================\\\n" )
Msg( "||    Ulysses Prop Share(UPS)    ||\n" )
Msg( "||-------------------------------||\n" )
Msg( "|| Loading...                    ||\n" )

Msg( "||  sh_defines.lua               ||\n" )
include( "sh_defines.lua" )
Msg( "||  sh_lib.lua                   ||\n" )
include( "sh_lib.lua" )
Msg( "||  lib.lua                      ||\n" )
include( "lib.lua" )
Msg( "||  sh_friends.lua               ||\n" )
include( "sh_friends.lua" )
Msg( "||  base.lua                     ||\n" )
include( "base.lua" )

for _, file in ipairs( sv_modules ) do
	Msg( "||  MODULE: " .. file .. string.rep( " ", 21 - file:len() ) .. "||\n" )
	include( "modules/" .. file )
end

for _, file in ipairs( sh_modules ) do
	Msg( "||  MODULE: " .. file .. string.rep( " ", 21 - file:len() ) .. "||\n" )
	include( "modules/sh/" .. file )
end	

Msg( "|| Load Complete!                ||\n" )
Msg( "\\=================================/\n" )

AddCSLuaFile( "ups/cl_init.lua" )	
AddCSLuaFile( "ups/sh_defines.lua" )
AddCSLuaFile( "ups/cl_lib.lua" )
AddCSLuaFile( "ups/sh_lib.lua" )
AddCSLuaFile( "ups/sh_friends.lua" )
AddCSLuaFile( "autorun/client/ups_preinit.lua" )

-- Find c-side modules and load them
for _, file in ipairs( cl_modules ) do
	AddCSLuaFile( "ups/modules/cl/" .. file )
end

for _, file in ipairs( sh_modules ) do
	AddCSLuaFile( "ups/modules/sh/" .. file )
end
