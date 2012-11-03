module( "UPS", package.seeall )

local clientcvarprefix = "ups_cl_disableplayer"
local clientglobalcvarprefix = "ups_cl_disableglobal"

cDisableUPS = CreateClientConVar( clientcvarprefix, "0", true, true )

local idcvars = {}
for _, id in ipairs( accessIds ) do
	table.insert( idcvars, {id = id, cvar=CreateClientConVar( clientcvarprefix .. "_" .. id, "0", true, true )} )
end

local function buildCMenu( panel ) -- Client menu
	panel:AddControl( "Label", { Text = "Disable UPS:" } )
	panel:AddControl( "Checkbox", { 
			Label = "Everything (overrides controls below)",
			Command = cDisableUPS:GetName(),
		} )	
	
	for _, data in ipairs( idcvars ) do
		panel:AddControl( "Checkbox", { 
				Label = data.id:sub( 1, 1 ):upper() .. data.id:sub( 2 ) .. " protection",
				Command = data.cvar:GetName(),
			} )				
	end
end
UPS.addToMenu( UPS.ID_MCLIENT, buildCMenu ) 

local function buildAMenu( panel ) -- Admin menu
	panel:ClearControls()
	panel:AddHeader()
	
	-- Global
	panel:AddControl( "Label", { Text = "Disable for EVERYONE:" } )
	panel:AddControl( "Checkbox", { Label = "Everything (overrides controls below)", Command = clientglobalcvarprefix } )

	for _, id in ipairs( accessIds ) do
		panel:AddControl( "Checkbox", { 
				Label = id:sub( 1, 1 ):upper() .. id:sub( 2 ) .. " protection",
				Command = clientglobalcvarprefix .. "_" .. id,
			} )				
	end
	panel:AddControl( "Label", { Text = "" } ) -- Spacing
	
	-- Per player
	local players = player.GetAll()
	for _, ply in ipairs( players ) do
		if ply:IsValid() then
			local entid = ply:EntIndex()
			panel:AddControl( "Label", { Text = "Disable for " .. ply:Nick() .. ":" } )
			panel:AddControl( "Checkbox", { Label = "Everything (overrides controls below)", Command = clientcvarprefix .. entid } )
		
			for _, id in ipairs( accessIds ) do
				panel:AddControl( "Checkbox", { 
						Label = id:sub( 1, 1 ):upper() .. id:sub( 2 ) .. " protection",
						Command = clientcvarprefix .. "_" .. id .. entid,
					} )				
			end
			panel:AddControl( "Label", { Text = "" } ) -- Spacing	
		end
	end
end

local function spawnMenuOpen()
	buildAMenu( GetControlPanel( "UPSDisable" ) )
end
hook.Add( "SpawnMenuOpen", "UPSAdminDisableSpawnMenuOpen", spawnMenuOpen )