--[[
	Title: Client HUD
	
	This file takes care of the client hud.
]]

module( "UPS", package.seeall )
if not CLIENT then return end

local gpanel

-- Config convars
local ups_hudenable = CreateClientConVar( "ups_hudenable", "1.0", true, false ) 
local ups_hudcolor_r = CreateClientConVar( "ups_hudcolor_r", "256.0", true, false ) 
local ups_hudcolor_g = CreateClientConVar( "ups_hudcolor_g", "256.0", true, false ) 
local ups_hudcolor_b = CreateClientConVar( "ups_hudcolor_b", "256.0", true, false ) 
local ups_hudtext_r = CreateClientConVar( "ups_hudtext_r", "256.0", true, false ) 
local ups_hudtext_b = CreateClientConVar( "ups_hudtext_b", "256.0", true, false ) 
local ups_hudtext_g = CreateClientConVar( "ups_hudtext_g", "256.0", true, false ) 

local ups_pos_x = CreateClientConVar( "ups_pos_x", "0.0", true, false )
local ups_pos_y = CreateClientConVar( "ups_pos_y", "0.0", true, false )

local lastPhysgunProp
local function trackLastProp( ply, ent )
	if not ent or not ent:IsValid() then -- Something removed the ent
		return
	end
	
	if ply ~= LocalPlayer() then return end -- Not interested
	lastPhysgunProp = ent
end
hook.Add( "PhysgunPickup", "UPSHUDCheckLastPickup", trackLastProp )

local function trackLastPropDrop( ply, ent )
	if not ent or not ent:IsValid() then -- Something removed the ent
		return
	end
	
	if ply ~= LocalPlayer() then return end -- Not interested
	lastPhysgunProp = nil
end
hook.Add( "PhysgunDrop", "UPSHUDCheckLastPickup", trackLastPropDrop )

local showOnWeps = {
	["weapon_physgun"] = true,
	["weapon_physcannon"] = true,
	["gmod_tool"] = true,
}
function think()
	local curWep = "none"
	if LocalPlayer():GetActiveWeapon():IsValid() then
		curWep = LocalPlayer():GetActiveWeapon():GetClass()
	end
	
	if not ups_hudenable:GetBool() or LocalPlayer():GetVehicle():IsValid() or not showOnWeps[ curWep ] then -- Easy no
		gpanel:SetVisible( false )
		return
	end
	
	local ent
	-- If they're physgunning a prop don't bother tracing, just use what they're gunning.
	if curWep ~= "weapon_physgun" or not LocalPlayer():KeyDown( IN_ATTACK ) then
		local tr = utilx.GetPlayerTrace( LocalPlayer(), LocalPlayer():GetCursorAimVector() )
		local trace = util.TraceLine( tr )
		ent = trace.Entity
	else
		ent = lastPhysgunProp
	end
	
	if not ent or not ent:IsValid() or table.HasValue( ignoreList, ent:GetClass() ) then
		gpanel:SetVisible( false )
		return
	end		
	
	gpanel:SetVisible( true )
	
	gpanel:SetPos( (ScrW() - gpanel:GetWide()) * ups_pos_x:GetFloat() / 100, (ScrH() - gpanel:GetTall()) * ups_pos_y:GetFloat() / 100 )	

	local textColor = Color( ups_hudtext_r:GetInt(), ups_hudtext_g:GetInt(), ups_hudtext_b:GetInt(), 255 )
	gpanel.lblNick:SetTextColor( textColor )
	
	local name = "Unknown" -- Default
	local id = ent:UPSGetOwner()
	if id == OWNERID_MAP then
		name = "The Map"
	elseif id == OWNERID_UPFORGRABS then
		name = "Up for grabs!"
	elseif id == OWNERID_DEFER then
		name = "Please wait..."
	else
		name = nameFromID( id ) or name -- Using "or name" in case we get nil back
	end
	
	gpanel.nick:SetText( name )		
	gpanel.nick:SetTextColor( textColor )
end
timer.Create( "UPSHUDThink", 0.3, 0, think ) 

local texGradient = surface.GetTextureID( "gui/center_gradient" )

local PANEL = {}

-----------------------------------------------------------
--   Name: Paint
-----------------------------------------------------------
function PANEL:Paint()	
	local wide = self:GetWide()
	local tall = self:GetTall()
	
	local outerColor = Color( ups_hudcolor_r:GetInt(), ups_hudcolor_g:GetInt(), ups_hudcolor_b:GetInt(), 200 )
	draw.RoundedBox( 4, 0, 0, wide, tall, outerColor ) -- Draw our base
	
	surface.SetTexture( texGradient )
	surface.SetDrawColor( 255, 255, 255, 50 )
	surface.DrawTexturedRect( 0, 0, wide, tall )  -- Draw gradient overlay		
	
	return true
end

-----------------------------------------------------------
--   Name: Init
-----------------------------------------------------------
function PANEL:Init()	
	self.lblNick = vgui.Create( "DLabel", self )
	self.nick    = vgui.Create( "DLabel", self )
end

-----------------------------------------------------------
--   Name: ApplySchemeSettings
-----------------------------------------------------------
function PANEL:ApplySchemeSettings()
	self.lblNick:SetFont( "Trebuchet18" )
	self.nick:SetFont( "Trebuchet18" )
end

-----------------------------------------------------------
--   Name: Think
-----------------------------------------------------------
function PANEL:Think()
end

-----------------------------------------------------------
--   Name: PerformLayout
-----------------------------------------------------------
function PANEL:PerformLayout()
	self.lblNick:SetSize( 52, 18 )
	self.lblNick:SetPos( 8, 2 )
	self.lblNick:SetText( "Owner: " )
	
	self.nick:SetSize( self:GetWide() - 65, 18 )
	self.nick:SetPos( 55, 2 )
end

vgui.Register( "UPSHUDOwner", PANEL, "Panel" )

----------------------------------------------------------------------------------------------------------
-- Now for the control panels!
----------------------------------------------------------------------------------------------------------

local function buildCP( cpanel )
	cpanel:ClearControls()
	cpanel:AddHeader()
	cpanel:AddControl( "Slider", { Label = "Position X", Command = "ups_pos_x", Type = "Float", Min = "0", Max = "100" }  )
	cpanel:AddControl( "Slider", { Label = "Position Y", Command = "ups_pos_y", Type = "Float", Min = "0", Max = "100" }  )	
	cpanel:AddControl( "Color", { Label = "Background Color", Red = "ups_hudcolor_r", Green = "ups_hudcolor_g", Blue = "ups_hudcolor_b", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1", Multiplier = "255" }  )
	cpanel:AddControl( "Color", { Label = "Text Color", Red = "ups_hudtext_r", Green = "ups_hudtext_g", Blue = "ups_hudtext_b", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1", Multiplier = "255" }  )
	cpanel:AddControl( "Button", { Text = "Reset", Label = "Reset colors and position", Command = "upshud_reset" } )
end

local function resetCvars()
	RunConsoleCommand( "ups_hudcolor_r", "0" )
	RunConsoleCommand( "ups_hudcolor_g", "150" )
	RunConsoleCommand( "ups_hudcolor_b", "245" )
	RunConsoleCommand( "ups_hudtext_r", "225" )
	RunConsoleCommand( "ups_hudtext_g", "225" )
	RunConsoleCommand( "ups_hudtext_b", "225" )
	RunConsoleCommand( "ups_pos_x", "98" )	
	RunConsoleCommand( "ups_pos_y", "98" )	
	buildCP( GetControlPanel( "UPSHUD" ) )
end
concommand.Add( "upshud_reset", resetCvars )

local function spawnMenuOpen()
	buildCP( GetControlPanel( "UPSHUD" ) )
end
hook.Add( "SpawnMenuOpen", "UPSHUDSpawnMenuOpen", spawnMenuOpen )

-- Init panel
gpanel = vgui.Create( "UPSHUDOwner" )
gpanel:SetSize( 250, 24 )
gpanel:SetVisible( false ) -- Otherwise we'll see it blink on join	

-- Reset cvars if they haven't been initialized yet
--hook.Add( ULib.HOOK_LOCALPLAYERREADY, "UPSResetGUI", function()
	if ups_hudcolor_r:GetInt() == 256 then resetCvars() end
--end )
