--[[
	Title: Shared definitions
	
	This file is necessary to correctly implement one of garry's map keyvalues.
]]

-- Nothing should override this function, make it high priority.
local function gm_toolfix( ply, tr, toolmode )
	if not tr.Entity or not tr.Entity:IsValid() then -- Something removed the ent
		return
	end
	
	if tr.Entity.m_tblToolsAllowed and table.HasValue( tr.Entity.m_tblToolsAllowed, toolmode ) then 
		return true
	end
end
hook.Add( "CanTool", "UPSgm_toolfix", gm_toolfix, -18 ) 