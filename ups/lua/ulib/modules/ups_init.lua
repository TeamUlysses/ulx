if not SinglePlayer() then
	if SERVER then
		include( "ups/init.lua" )
	else
		include( "ups/cl_init.lua" )
	end
end
