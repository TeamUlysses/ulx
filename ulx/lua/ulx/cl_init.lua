if not ulx then
	ulx = {}
	include( "ulx/sh_defines.lua" )
	include( "ulx/cl_lib.lua" )
	include( "ulx/sh_base.lua" )

	local sh_modules = file.FindInLua( "ulx/modules/sh/*.lua" )
	local cl_modules = file.FindInLua( "ulx/modules/cl/*.lua" )

	for _, file in ipairs( cl_modules ) do
		Msg( "[ULX] Loading CLIENT module: " .. file .. "\n" )
		include( "ulx/modules/cl/" .. file )
	end

	for _, file in ipairs( sh_modules ) do
		Msg( "[ULX] Loading SHARED module: " .. file .. "\n" )
		include( "ulx/modules/sh/" .. file )
	end
end

function ulx.clInit( v, r )
	ulx.version = v -- Yah, I know, we should have the version from shared anyways.... but doesn't make sense to send one and not the other.
	ulx.revision = r

	Msg( "ULX version " .. ulx.getVersion() .. " loaded.\n" )
end
usermessage.Hook( "ulx_initplayer", init )
