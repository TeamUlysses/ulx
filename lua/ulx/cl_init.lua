if not ulx then
	ulx = {}
	include( "ulx/sh_defines.lua" )
	include( "ulx/cl_lib.lua" )
	include( "ulx/sh_base.lua" )

	local sh_modules = file.Find( "ulx/modules/sh/*.lua", "LUA" )
	local cl_modules = file.Find( "ulx/modules/cl/*.lua", "LUA" )

	for _, file in ipairs( cl_modules ) do
		Msg( "[ULX] Loading CLIENT module: " .. file .. "\n" )
		include( "ulx/modules/cl/" .. file )
	end

	for _, file in ipairs( sh_modules ) do
		Msg( "[ULX] Loading SHARED module: " .. file .. "\n" )
		include( "ulx/modules/sh/" .. file )
	end
end
