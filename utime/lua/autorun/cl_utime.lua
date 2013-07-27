-- Written by Team Ulysses, http://ulyssesmod.net/
module( "Utime", package.seeall )
if not CLIENT then return end

local gpanel

--Now convars!
local utime_enable = CreateClientConVar( "utime_enable", "1.0", true, false )
local utime_outsidecolor_r = CreateClientConVar( "utime_outsidecolor_r", "256.0", true, false )
local utime_outsidecolor_g = CreateClientConVar( "utime_outsidecolor_g", "256.0", true, false )
local utime_outsidecolor_b = CreateClientConVar( "utime_outsidecolor_b", "256.0", true, false )
local utime_outsidetext_r = CreateClientConVar( "utime_outsidetext_r", "0.0", true, false )
local utime_outsidetext_g = CreateClientConVar( "utime_outsidetext_g", "0.0", true, false )
local utime_outsidetext_b = CreateClientConVar( "utime_outsidetext_b", "0.0", true, false )

local utime_insidecolor_r = CreateClientConVar( "utime_insidecolor_r", "256.0", true, false )
local utime_insidecolor_g = CreateClientConVar( "utime_insidecolor_g", "256.0", true, false )
local utime_insidecolor_b = CreateClientConVar( "utime_insidecolor_b", "256.0", true, false )
local utime_insidetext_r = CreateClientConVar( "utime_insidetext_r", "0", true, false )
local utime_insidetext_g = CreateClientConVar( "utime_insidetext_g", "0", true, false )
local utime_insidetext_b = CreateClientConVar( "utime_insidetext_b", "0", true, false )

local utime_pos_x = CreateClientConVar( "utime_pos_x", "0.0", true, false )
local utime_pos_y = CreateClientConVar( "utime_pos_y", "0.0", true, false )

local PANEL = {}
PANEL.Small = 40
PANEL.TargetSize = PANEL.Small
PANEL.Large = 100
PANEL.Wide = 160

function initialize()
	gpanel = vgui.Create( "UTimeMain" )
	gpanel:SetSize( gpanel.Wide, gpanel.Small )
	hook.Remove( "OnEntityCreated", "UtimeInitialize" )
end
hook.Add( "InitPostEntity", "UtimeInitialize", initialize )

function think()
	if not LocalPlayer():IsValid() or gpanel == nil then return end

	if not utime_enable:GetBool() or not IsValid( LocalPlayer() ) or
			(IsValid( LocalPlayer():GetActiveWeapon() ) and LocalPlayer():GetActiveWeapon():GetClass() == "gmod_camera") then
		gpanel:SetVisible( false )
	else
		gpanel:SetVisible( true )
	end

	--gpanel:SetPos( ScrW() - gpanel:GetWide() - 20, 20 )
	gpanel:SetPos( (ScrW() - gpanel:GetWide()) * utime_pos_x:GetFloat() / 100, (ScrH() - gpanel.Large) * utime_pos_y:GetFloat() / 100 )

	local textColor = Color( utime_outsidetext_r:GetInt(), utime_outsidetext_g:GetInt(), utime_outsidetext_b:GetInt(), 255 )
	gpanel.lblTotalTime:SetTextColor( textColor )
	gpanel.lblSessionTime:SetTextColor( textColor )
	gpanel.total:SetTextColor( textColor )
	gpanel.session:SetTextColor( textColor )

	local insideTextColor = Color( utime_insidetext_r:GetInt(), utime_insidetext_g:GetInt(), utime_insidetext_b:GetInt(), 255 )
	gpanel.playerInfo.lblTotalTime:SetTextColor( insideTextColor )
	gpanel.playerInfo.lblSessionTime:SetTextColor( insideTextColor )
	gpanel.playerInfo.lblNick:SetTextColor( insideTextColor )
	gpanel.playerInfo.total:SetTextColor( insideTextColor )
	gpanel.playerInfo.session:SetTextColor( insideTextColor )
	gpanel.playerInfo.nick:SetTextColor( insideTextColor )
end
timer.Create( "UTimeThink", 0.6, 0, think )

local texGradient = surface.GetTextureID( "gui/center_gradient" )

--PANEL.InnerColor = Color( 250, 250, 245, 255 )
--PANEL.OuterColor = Color( 0, 150, 245, 200 )

-----------------------------------------------------------
--	 Name: Paint
-----------------------------------------------------------
function PANEL:Paint(w,h)
		local wide = self:GetWide()
		local tall = self:GetTall()

		local outerColor = Color( utime_outsidecolor_r:GetInt(), utime_outsidecolor_g:GetInt(), utime_outsidecolor_b:GetInt(), 200 )
		draw.RoundedBox( 4, 0, 0, wide, tall, outerColor ) -- Draw our base

		surface.SetTexture( texGradient )
		surface.SetDrawColor( 255, 255, 255, 50 )
		surface.SetDrawColor( outerColor )
		surface.DrawTexturedRect( 0, 0, wide, tall )  -- Draw gradient overlay

		if self:GetTall() > self.Small + 4 then -- Draw the white background for another player's info
				local innerColor = Color( utime_insidecolor_r:GetInt(), utime_insidecolor_g:GetInt(), utime_insidecolor_b:GetInt(), 255 )
				draw.RoundedBox( 4, 2, self.Small, wide - 4, tall - self.Small - 2, innerColor )

				surface.SetTexture( texGradient )
				surface.SetDrawColor( color_white )
				surface.SetDrawColor( innerColor )
				surface.DrawTexturedRect( 2, self.Small, wide - 4, tall - self.Small - 2 ) -- Gradient overlay
		end

		return true
end

-----------------------------------------------------------
--	 Name: Init
-----------------------------------------------------------
function PANEL:Init()
		self.Size = self.Small

		self.playerInfo			= vgui.Create( "UTimePlayerInfo", self )

		self.lblTotalTime		= vgui.Create( "DLabel", self )
		self.lblSessionTime		= vgui.Create( "DLabel", self )

		self.total				= vgui.Create( "DLabel", self )
		self.session			= vgui.Create( "DLabel", self )
end

-----------------------------------------------------------
--	 Name: ApplySchemeSettings
-----------------------------------------------------------
function PANEL:ApplySchemeSettings()
		self.lblTotalTime:SetFont( "DermaDefault" )
		self.lblSessionTime:SetFont( "DermaDefault" )
		self.total:SetFont( "DermaDefault" )
		self.session:SetFont( "DermaDefault" )

		self.lblTotalTime:SetTextColor( color_black )
		self.lblSessionTime:SetTextColor( color_black )
		self.total:SetTextColor( color_black )
		self.session:SetTextColor( color_black )
end

-----------------------------------------------------------
--	 Name: Think
-----------------------------------------------------------
local locktime = 0
function PANEL:Think()
	if self.Size == self.Small then
		self.playerInfo:SetVisible( false )
	else
		self.playerInfo:SetVisible( true )
	end

	local tr = util.GetPlayerTrace( LocalPlayer(), LocalPlayer():GetAimVector() )
	local trace = util.TraceLine( tr )
	if trace.Entity and trace.Entity:IsValid() and trace.Entity:IsPlayer() and not trace.Entity:GetNWBool("disguised", false) then -- Last conditional is TTT disguiser
		self.TargetSize = self.Large
		self.playerInfo:SetPlayer( trace.Entity )
		locktime = CurTime()
	end

	if locktime + 2 < CurTime() then
		self.TargetSize = self.Small
	end

	if self.Size ~= self.TargetSize then
		self.Size = math.Approach( self.Size, self.TargetSize, (math.abs( self.Size - self.TargetSize ) + 1) * 8 * FrameTime() )
		self:PerformLayout()
	end

	self.total:SetText( timeToStr( LocalPlayer():GetUTimeTotalTime() ) )
	self.session:SetText( timeToStr( LocalPlayer():GetUTimeSessionTime() ) )
end

-----------------------------------------------------------
--	 Name: PerformLayout
-----------------------------------------------------------
function PANEL:PerformLayout()
	self:SetSize( self:GetWide(), self.Size )

	self.lblTotalTime:SetSize( 52, 18 )
	self.lblTotalTime:SetPos( 8, 2 )
	self.lblTotalTime:SetText( "Total: " )

	self.lblSessionTime:SetSize( 52, 18 )
	self.lblSessionTime:SetPos( 8, 20 )
	self.lblSessionTime:SetText( "Session: " )

	self.total:SetSize( self:GetWide() - 52, 18 )
	self.total:SetPos( 52, 2 )

	self.session:SetSize( self:GetWide() - 52, 18 )
	self.session:SetPos( 52, 20 )

	self.playerInfo:SetPos( 0, 42 )
	self.playerInfo:SetSize( self:GetWide() - 8, self:GetTall() - 42 )
end

vgui.Register( "UTimeMain", PANEL, "Panel" )

local INFOPANEL = {}

-----------------------------------------------------------
--	 Name: Init
-----------------------------------------------------------
function INFOPANEL:Init()
	self.lblTotalTime		= vgui.Create( "DLabel", self )
	self.lblSessionTime		= vgui.Create( "DLabel", self )
	self.lblNick			= vgui.Create( "DLabel", self )

	self.total				= vgui.Create( "DLabel", self )
	self.session			= vgui.Create( "DLabel", self )
	self.nick				= vgui.Create( "DLabel", self )
end

-----------------------------------------------------------
--	 Name: SetPlayer
-----------------------------------------------------------
function INFOPANEL:SetPlayer( ply )
		self.Player = ply
end

-----------------------------------------------------------
--	 Name: ApplySchemeSettings
-----------------------------------------------------------
function INFOPANEL:ApplySchemeSettings()
		self.lblTotalTime:SetFont( "DermaDefault" )
		self.lblSessionTime:SetFont( "DermaDefault" )
		self.lblNick:SetFont( "DermaDefault" )
		self.total:SetFont( "DermaDefault" )
		self.session:SetFont( "DermaDefault" )
		self.nick:SetFont( "DermaDefault" )

		self.lblTotalTime:SetTextColor( color_black )
		self.lblSessionTime:SetTextColor( color_black )
		self.lblNick:SetTextColor( color_black )
		self.total:SetTextColor( color_black )
		self.session:SetTextColor( color_black )
		self.nick:SetTextColor( color_black )
end

-----------------------------------------------------------
--	 Name: Think
-----------------------------------------------------------
function INFOPANEL:Think()
		local ply = self.Player
		if not ply or not ply:IsValid() or not ply:IsPlayer() then -- Disconnected
				self:GetParent().TargetSize = self:GetParent().Small
				return
		end

		self.total:SetText( timeToStr( ply:GetUTime() + CurTime() - ply:GetUTimeStart() ) )
		self.session:SetText( timeToStr( CurTime() - ply:GetUTimeStart() ) )
		self.nick:SetText( ply:Nick() )
end

-----------------------------------------------------------
--	 Name: PerformLayout
-----------------------------------------------------------
function INFOPANEL:PerformLayout()
		self.lblNick:SetSize( 52, 18 )
		self.lblNick:SetPos( 8, 0 )
		self.lblNick:SetText( "Nick: " )

		self.lblTotalTime:SetSize( 52, 18 )
		self.lblTotalTime:SetPos( 8, 18 )
		self.lblTotalTime:SetText( "Total: " )

		self.lblSessionTime:SetSize( 52, 18 )
		self.lblSessionTime:SetPos( 8, 36 )
		self.lblSessionTime:SetText( "Session: " )

		self.nick:SetSize( self:GetWide() - 52, 18 )
		self.nick:SetPos( 52, 0 )

		self.total:SetSize( self:GetWide() - 52, 18 )
		self.total:SetPos( 52, 18 )

		self.session:SetSize( self:GetWide() - 52, 18 )
		self.session:SetPos( 52, 36 )
end

-----------------------------------------------------------
--	 Name: Paint
-----------------------------------------------------------
function INFOPANEL:Paint()
		return true
end

vgui.Register( "UTimePlayerInfo", INFOPANEL, "Panel" )



----------------------------------------------------------------------------------------------------------
-- Now for the control panels!
----------------------------------------------------------------------------------------------------------

function resetCvars()
		RunConsoleCommand( "utime_outsidecolor_r", "0" )
		RunConsoleCommand( "utime_outsidecolor_g", "150" )
		RunConsoleCommand( "utime_outsidecolor_b", "245" )

		RunConsoleCommand( "utime_outsidetext_r", "255" )
		RunConsoleCommand( "utime_outsidetext_g", "255" )
		RunConsoleCommand( "utime_outsidetext_b", "255" )

		RunConsoleCommand( "utime_insidecolor_r", "250" )
		RunConsoleCommand( "utime_insidecolor_g", "250" )
		RunConsoleCommand( "utime_insidecolor_b", "245" )

		RunConsoleCommand( "utime_insidetext_r", "0" )
		RunConsoleCommand( "utime_insidetext_g", "0" )
		RunConsoleCommand( "utime_insidetext_b", "0" )

		RunConsoleCommand( "utime_pos_x", "98" )
		RunConsoleCommand( "utime_pos_y", "8" )
		buildCP( controlpanel.Get( "Utime" ) )
end
concommand.Add( "utime_reset", resetCvars )

function buildCP( cpanel )
		cpanel:ClearControls()
		cpanel:AddControl( "Header", { Text = "UTime by Megiddo (Team Ulysses)" } )
		cpanel:AddControl( "Checkbox", { Label = "Enable", Command = "utime_enable" }  )
		cpanel:AddControl( "Slider", { Label = "Position X", Command = "utime_pos_x", Type = "Float", Min = "0", Max = "100" }	)
		cpanel:AddControl( "Slider", { Label = "Position Y", Command = "utime_pos_y", Type = "Float", Min = "0", Max = "100" }	)
		cpanel:AddControl( "Color", { Label = "Outside Color", Red = "utime_outsidecolor_r", Green = "utime_outsidecolor_g", Blue = "utime_outsidecolor_b", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1", Multiplier = "255" }	 )
		cpanel:AddControl( "Color", { Label = "Outside Text Color", Red = "utime_outsidetext_r", Green = "utime_outsidetext_g", Blue = "utime_outsidetext_b", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1", Multiplier = "255" }  )
		cpanel:AddControl( "Color", { Label = "Inside Color", Red = "utime_insidecolor_r", Green = "utime_insidecolor_g", Blue = "utime_insidecolor_b", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1", Multiplier = "255" }	 )
		cpanel:AddControl( "Color", { Label = "Inside Text Color", Red = "utime_insidetext_r", Green = "utime_insidetext_g", Blue = "utime_insidetext_b", ShowAlpha = "0", ShowHSV = "1", ShowRGB = "1", Multiplier = "255" }  )
		cpanel:AddControl( "Button", { Text = "Reset", Label = "Reset colors and position", Command = "utime_reset" } )
end

function spawnMenuOpen()
		buildCP( controlpanel.Get( "Utime" ) )
end
hook.Add( "SpawnMenuOpen", "UtimeSpawnMenuOpen", spawnMenuOpen )

function popToolMenu()
		spawnmenu.AddToolMenuOption( "Utilities", "Utime Controls", "Utime", "Utime", "", "", buildCP )
end
hook.Add( "PopulateToolMenu", "UtimePopulateTools", popToolMenu )

function onEntCreated( ent )
		if LocalPlayer():IsValid() then -- LocalPlayer was created and is valid now
				if utime_outsidecolor_r:GetInt() == 256 then resetCvars() end
		end
end
hook.Add( "OnEntityCreated", "UTimeLocalPlayerCheck", onEntCreated ) -- Flag server when we created LocalPlayer()
