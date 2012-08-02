require( "datastream" )

if not ULib then
	ULib = {}
	--[[
	if file.Exists( "../lua/includes/modules/gm_ulib.dll" ) then
		require( "ulib" ) -- Lua engine load
		if not ULib.pluginLoaded() then -- It stays loaded across maps so use this to check
			game.ConsoleCommand( "plugin_load ../../../gmodbeta2007/lua/includes/modules/gm_ulib\n" ) -- So we don't have to bother with a .vdf file
		end
	end
	]]

	if not ULib.consoleCommand then ULib.consoleCommand = game.ConsoleCommand end -- In case they remove our module or it doesn't load

	Msg( "///////////////////////////////\n" )
	Msg( "//      Ulysses Library      //\n" )
	Msg( "///////////////////////////////\n" )
	Msg( "// Loading...                //\n" )

	Msg( "//  shared/defines.lua       //\n" )
	include( "ulib/shared/defines.lua" )
	Msg( "//  shared/datastream.lua    //\n" )
	include( "ulib/shared/datastream.lua" )
	Msg( "//  shared/misc.lua          //\n" )
	include( "ulib/shared/misc.lua" )
	Msg( "//  shared/util.lua          //\n" )
	include( "ulib/shared/util.lua" )
	Msg( "//  server/upgrade.lua       //\n" )
	include( "ulib/server/upgrade.lua" )
	Msg( "//  shared/hook.lua          //\n" )
	include( "ulib/shared/hook.lua" )
	Msg( "//  shared/table.lua         //\n" )
	include( "ulib/shared/tables.lua" )
	Msg( "//  shared/player.lua        //\n" )
	include( "ulib/shared/player.lua" )
	Msg( "//  server/player.lua        //\n" )
	include( "ulib/server/player.lua" )
	Msg( "//  shared/messages.lua      //\n" )
	include( "ulib/shared/messages.lua" )
	Msg( "//  shared/commands.lua      //\n" )
	include( "ulib/shared/commands.lua" )
	Msg( "//  server/concommand.lua    //\n" )
	include( "ulib/server/concommand.lua" )
	Msg( "//  server/util.lua          //\n" )
	include( "ulib/server/util.lua" )
	Msg( "//  shared/sh_ucl.lua        //\n" )
	include( "ulib/shared/sh_ucl.lua" )
	Msg( "//  server/ucl.lua           //\n" )
	include( "ulib/server/ucl.lua" )
	Msg( "//  server/phys.lua          //\n" )
	include( "ulib/server/phys.lua" )
	Msg( "//  server/player_ext.lua    //\n" )
	include( "server/player_ext.lua" )
	Msg( "//  server/entity_ext.lua    //\n" )
	include( "server/entity_ext.lua" )
	Msg( "// Load Complete!            //\n" )
	Msg( "///////////////////////////////\n" )

	AddCSLuaFile( "ulib/cl_init.lua" )
	AddCSLuaFile( "autorun/ulib_init.lua" )
	local folder = "ulib/shared"
	local files = file.FindInLua( folder .. "/" .. "*.lua" )
	for _, file in ipairs( files ) do
		AddCSLuaFile( folder .. "/" .. file )
	end

	folder = "ulib/client"
	files = file.FindInLua( folder .. "/" .. "*.lua" )
	for _, file in ipairs( files ) do
		AddCSLuaFile( folder .. "/" .. file )
	end

	--Shared modules
	local files = file.FindInLua( "ulib/modules/*.lua" )
	if #files > 0 then
		for _, file in ipairs( files ) do
			Msg( "[ULIB] Loading SHARED module: " .. file .. "\n" )
			include( "ulib/modules/" .. file )
			AddCSLuaFile( "ulib/modules/" .. file )
		end
	end

	--Server modules
	local files = file.FindInLua( "ulib/modules/server/*.lua" )
	if #files > 0 then
		for _, file in ipairs( files ) do
			Msg( "[ULIB] Loading SERVER module: " .. file .. "\n" )
			include( "ulib/modules/server/" .. file )
		end
	end

	--Client modules
	local files = file.FindInLua( "ulib/modules/client/*.lua" )
	if #files > 0 then
		for _, file in ipairs( files ) do
			Msg( "[ULIB] Loading CLIENT module: " .. file .. "\n" )
			AddCSLuaFile( "ulib/modules/client/" .. file )
		end
	end

	local function clReady( ply )
		ply.ulib_ready = true
		hook.Call( ULib.HOOK_LOCALPLAYERREADY, _, ply )
	end
	concommand.Add( "ulib_cl_ready", clReady ) -- Called when the c-side player object is ready
end
