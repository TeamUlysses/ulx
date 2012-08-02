--XLIB -- by Stickly Man!
--A library of helper functions used by XGUI for creating derma controls with a single line of code.

--Currently a bit disorganized and unstandardized, (just put in things as I needed them). I'm hoping to fix that soon.
--Also has a few ties into XGUI for keyboard focus stuff.

local function xlib_init()
	xlib = {}

	function xlib.makecheckbox( t )
		local pnl = vgui.Create( "DCheckBoxLabel", t.parent )
		pnl:SetPos( t.x, t.y )
		pnl:SetText( t.label or "" )
		pnl:SizeToContents()
		pnl:SetValue( t.value or 0 )
		if t.convar then pnl:SetConVar( t.convar ) end
		if t.textcolor then pnl:SetTextColor( t.textcolor ) end
		if not t.tooltipwidth then t.tooltipwidth = 250 end
		if t.tooltip then
			if t.tooltipwidth ~= 0 then
				t.tooltip = xlib.wordWrap( t.tooltip, t.tooltipwidth, "MenuItem" )
			end
			pnl:SetToolTip( t.tooltip )
		end
		if t.disabled then pnl:SetDisabled( t.disabled ) end
		--Replicated Convar Updating
		if t.repconvar then
			xlib.checkRepCvarCreated( t.repconvar )
			pnl:SetValue( GetConVar( t.repconvar ):GetBool() )
			function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
				if cl_cvar == t.repconvar:lower() then
					pnl:SetValue( new_val )
				end
			end
			hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
			function pnl:OnChange( bVal )
				RunConsoleCommand( t.repconvar, tostring( bVal and 1 or 0 ) )
			end
			pnl.Think = function() end --Override think functions to remove Garry's convar check to (hopefully) speed things up
			pnl.ConVarNumberThink = function() end
			pnl.ConVarStringThink = function() end
			pnl.ConVarChanged = function() end
		end
		--We need to set the enabled/disabled state of the checkbox whenever PerformLayout is called, otherwise if it's disabled before PerformLayout is first called, it won't look like it is.
		local tempfunc = pnl.PerformLayout
		pnl.PerformLayout = function( self )
			tempfunc( self )
			pnl:SetDisabled( pnl:GetDisabled() )
		end
		return pnl
	end

	function xlib.makelabel( t )
		local pnl = vgui.Create( "DLabel", t.parent )
		pnl:SetPos( t.x, t.y )
		pnl:SetText( t.label or "" )
		if not t.tooltipwidth then t.tooltipwidth = 250 end
		if t.tooltip then
			if t.tooltipwidth ~= 0 then
				t.tooltip = xlib.wordWrap( t.tooltip, t.tooltipwidth, "MenuItem" )
			end
			pnl:SetToolTip( t.tooltip )
			pnl:SetMouseInputEnabled( true )
		end
		
		if t.font then pnl:SetFont( t.font ) end
		if t.w and t.wordwrap then
			pnl:SetText( xlib.wordWrap( t.label, t.w, t.font or "default" ) )
		end
		pnl:SizeToContents()
		if t.w then pnl:SetWidth( t.w ) end
		if t.h then pnl:SetHeight( t.h ) end
		if t.textcolor then pnl:SetTextColor( t.textcolor ) end

		return pnl
	end

	function xlib.makepanellist( t )
		local pnl = vgui.Create( "DPanelList", t.parent )
		pnl:SetPos( t.x, t.y )
		pnl:SetSize( t.w, t.h )
		pnl:SetSpacing( t.spacing or 5 )
		pnl:SetPadding( t.padding or 5 )
		pnl:EnableVerticalScrollbar( t.vscroll or true )
		pnl:EnableHorizontal( t.hscroll or false )
		pnl:SetAutoSize( t.autosize )
		return pnl
	end

	function xlib.makebutton( t )
		local pnl = vgui.Create( "DButton", t.parent )
		pnl:SetSize( t.w, t.h or 20 )
		pnl:SetPos( t.x, t.y )
		pnl:SetText( t.label or "" )
		pnl:SetDisabled( t.disabled )
		return pnl
	end

	function xlib.makesysbutton( t )
		local pnl = vgui.Create( "DSysButton", t.parent )
		pnl:SetType( t.btype )
		pnl:SetSize( t.w, t.h or 20 )
		pnl:SetPos( t.x, t.y )
		pnl:SetDisabled( t.disabled )
		return pnl
	end

	function xlib.makeframe( t )
		local pnl = vgui.Create( "DFrame", t.parent )
		pnl:SetSize( t.w, t.h )
		if t.nopopup ~= true then pnl:MakePopup() end
		pnl:SetPos( t.x or ScrW()/2-t.w/2, t.y or ScrH()/2-t.h/2 )
		pnl:SetTitle( t.label or "" )
		if t.draggable ~= nil then pnl:SetDraggable( t.draggable ) end
		if t.showclose ~= nil then pnl:ShowCloseButton( t.showclose ) end
		if t.skin then pnl:SetSkin( t.skin ) end
		if t.visible ~= nil then pnl:SetVisible( t.visible ) end
		return pnl
	end

	function xlib.maketextbox( t )
		local pnl = vgui.Create( "DTextEntry", t.parent )
		pnl:SetPos( t.x, t.y )
		pnl:SetWide( t.w )
		pnl:SetTall( t.h or 20 )
		pnl:SetEnterAllowed( true )
		if t.convar then pnl:SetConVar( t.convar ) end
		if t.text then pnl:SetText( t.text ) end
		if t.enableinput then pnl:SetEnabled( t.enableinput ) end
		pnl.selectAll = t.selectall
		if not t.tooltipwidth then t.tooltipwidth = 250 end
		if t.tooltip then
			if t.tooltipwidth ~= 0 then
				t.tooltip = xlib.wordWrap( t.tooltip, t.tooltipwidth, "MenuItem" )
			end
			pnl:SetToolTip( t.tooltip )
		end

		pnl.enabled = true
		function pnl:SetDisabled( val ) --Do some funky stuff to simulate enabling/disabling of a textbox
			pnl.enabled = not val
			pnl:SetEnabled( not val )
			pnl:SetPaintBackgroundEnabled( val )
		end
		if t.disabled then pnl:SetDisabled( t.disabled ) end

		--Replicated Convar Updating
		if t.repconvar then
			xlib.checkRepCvarCreated( t.repconvar )
			pnl:SetValue( GetConVar( t.repconvar ):GetString() )
			function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
				if cl_cvar == t.repconvar:lower() then
					pnl:SetValue( new_val )
				end
			end
			hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
			function pnl:UpdateConvarValue()
				RunConsoleCommand( t.repconvar, self:GetValue() )
			end
			function pnl:OnEnter()
				RunConsoleCommand( t.repconvar, self:GetValue() )
			end
			pnl.Think = function() end --Override think functions to remove Garry's convar check to (hopefully) speed things up
			pnl.ConVarNumberThink = function() end
			pnl.ConVarStringThink = function() end
			pnl.ConVarChanged = function() end
		end
		return pnl
	end

	function xlib.makelistview( t )
		local pnl = vgui.Create( "DListView", t.parent )
		pnl:SetPos( t.x, t.y )
		pnl:SetSize( t.w, t.h )
		pnl:SetMultiSelect( t.multiselect )
		pnl:SetHeaderHeight( t.headerheight or 20 )
		return pnl
	end

	function xlib.makecat( t )
		local pnl = vgui.Create( "DCollapsibleCategory", t.parent )
		pnl:SetPos( t.x, t.y )
		pnl:SetSize( t.w, t.h )
		pnl:SetLabel( t.label or "" )
		pnl:SetContents( t.contents )

		if t.expanded ~= nil then pnl:SetExpanded( t.expanded ) end
		if t.checkbox then
			pnl.checkBox = vgui.Create( "DCheckBox", pnl.Header )
			pnl.checkBox:SetValue( t.expanded )
			function pnl.checkBox:DoClick()
				self:Toggle()
				pnl:Toggle()
			end
			function pnl.Header:OnMousePressed( mcode )
				if ( mcode == MOUSE_LEFT ) then
					self:GetParent():Toggle()
					self:GetParent().checkBox:Toggle()
					return
				end
				return self:GetParent():OnMousePressed( mcode )
			end
			local tempfunc = pnl.PerformLayout
			pnl.PerformLayout = function( self )
				tempfunc( self )
				self.checkBox:SetPos( self:GetWide()-18, 5 )
			end
		end

		function pnl:SetOpen( bVal )
			if not self:GetExpanded() and bVal then
				pnl.Header:OnMousePressed( MOUSE_LEFT ) --Call the mouse function so it properly toggles the checkbox state (if it exists)
			elseif self:GetExpanded() and not bVal then
				pnl.Header:OnMousePressed( MOUSE_LEFT )
			end
		end

		return pnl
	end

	function xlib.makepanel( t )
		local pnl = vgui.Create( "DPanel", t.parent )
		pnl:SetPos( t.x, t.y )
		pnl:SetSize( t.w, t.h )
		if t.visible ~= nil then pnl:SetVisible( t.visible ) end
		return pnl
	end

	function xlib.makeXpanel( t )
		pnl = vgui.Create( "xlibPanel", t.parent )
		pnl:MakePopup()
		pnl:SetPos( t.x, t.y )
		pnl:SetSize( t.w, t.h )
		if t.visible ~= nil then pnl:SetVisible( t.visible ) end
		return pnl
	end

	function xlib.makenumberwang( t )
		local pnl = vgui.Create( "DNumberWang", t.parent )
		pnl:SetPos( t.x, t.y )
		pnl:SetDecimals( t.decimal or 0 )
		pnl:SetMinMax( t.min or 0, t.max or 255 )
		pnl:SizeToContents()
		pnl:SetValue( t.value )
		if t.w then pnl:SetWide( t.w ) end
		if t.h then pnl:SetTall( t.h ) end
		return pnl
	end

	function xlib.makemultichoice( t )
		local pnl = vgui.Create( "DMultiChoice", t.parent )
		pnl:SetText( t.text or "" )
		pnl:SetPos( t.x, t.y )
		pnl:SetSize( t.w, t.h or 20 )
		pnl.TextEntry.selectAll = t.selectall
		pnl:SetEditable( t.enableinput or false )

		if ( t.enableinput == true ) then
			pnl.DropButton.OnMousePressed = function( button, mcode )
				hook.Call( "OnTextEntryLoseFocus", nil, pnl.TextEntry )
				pnl:OpenMenu( pnl.DropButton )
			end
			pnl.TextEntry.OnMousePressed = function( self )
				hook.Call( "OnTextEntryGetFocus", nil, self )
			end
			pnl.TextEntry.OnLoseFocus = function( self )
				hook.Call( "OnTextEntryLoseFocus", nil, self )
				self:UpdateConvarValue()
			end
		end

		if not t.tooltipwidth then t.tooltipwidth = 250 end
		if t.tooltip then
			if t.tooltipwidth ~= 0 then
				t.tooltip = xlib.wordWrap( t.tooltip, t.tooltipwidth, "MenuItem" )
			end
			pnl:SetToolTip( t.tooltip )
		end

		if t.choices then
			for i, v in ipairs( t.choices ) do
				pnl:AddChoice( v )
			end
		end

		pnl.enabled = true
		function pnl:SetDisabled( val ) --Do some funky stuff to simulate enabling/disabling of a textbox
			self.enabled = not val
			self.TextEntry:SetEnabled( not val )
			self.TextEntry:SetPaintBackgroundEnabled( val )
			self.DropButton:SetDisabled( val )
			self.DropButton:SetMouseInputEnabled( not val )
			self:SetMouseInputEnabled( not val )
		end
		if t.disabled then pnl:SetDisabled( t.disabled ) end

		--Add support for Spacers
		function pnl:OpenMenu( pControlOpener ) --Garrys function with no comments, just adding a few things.
			if ( pControlOpener ) then
				if ( pControlOpener == self.TextEntry ) then
					return
				end
			end
			if ( #self.Choices == 0 ) then return end
			if ( self.Menu ) then
				self.Menu:Remove()
				self.Menu = nil
				return
			end
			self.Menu = DermaMenu()
				for k, v in pairs( self.Choices ) do
					if v == "--*" then --This is the string to determine where to add the spacer
						self.Menu:AddSpacer()
					else
						self.Menu:AddOption( v, function() self:ChooseOption( v, k ) end )
					end
				end
				local x, y = self:LocalToScreen( 0, self:GetTall() )
				self.Menu:SetMinimumWidth( self:GetWide() )
				self.Menu:Open( x, y, false, self )
			ULib.queueFunctionCall( self.RequestFocus, self ) --Force the menu to request focus when opened, to prevent the menu being open, but the focus being to the controls behind it.
		end

		--Replicated Convar Updating
		if t.repconvar then
			xlib.checkRepCvarCreated( t.repconvar )
			if t.isNumberConvar then --This is for convar settings stored via numbers (like ulx_rslotsMode)
				if t.numOffset == nil then t.numOffset = 1 end
				local cvar = GetConVar( t.repconvar ):GetInt()
				if tonumber( cvar ) and cvar + t.numOffset <= #pnl.Choices and cvar + t.numOffset > 0 then
					pnl:ChooseOptionID( cvar + t.numOffset )
				else
					pnl:SetText( "Invalid Convar Value" )
				end
				function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
					if cl_cvar == t.repconvar:lower() then
						if tonumber( new_val ) and new_val + t.numOffset <= #pnl.Choices and new_val + t.numOffset > 0 then
							pnl:ChooseOptionID( new_val + t.numOffset )
						else
							pnl:SetText( "Invalid Convar Value" )
						end
					end
				end
				hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
				function pnl:OnSelect( index )
					RunConsoleCommand( t.repconvar, tostring( index - t.numOffset ) )
				end
			else  --Otherwise, use each choice as a string for the convar
				pnl:SetText( GetConVar( t.repconvar ):GetString() )
				function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
					if cl_cvar == t.repconvar:lower() then
						pnl:SetText( new_val )
					end
				end
				hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
				function pnl:OnSelect( index, value )
					RunConsoleCommand( t.repconvar, value )
				end
			end
		end
		return pnl
	end

	function xlib.maketree( t )
		local pnl = vgui.Create( "DTree", t.parent )
		pnl:SetPos( t.x, t.y )
		pnl:SetSize( t.w, t.h )
		return pnl
	end

	function xlib.makecolorpicker( t )
		local pnl = vgui.Create( "xlibColorPanel", t.parent )
		pnl:SetPos( t.x, t.y )
		if t.noalphamodetwo then pnl:NoAlphaModeTwo() end --Provide an alternate layout with no alpha bar.
		if t.addalpha then 
			pnl:AddAlphaBar()
			if t.alphamodetwo then pnl:AlphaModeTwo() end
		end
		if t.color then pnl:SetColor( t.color ) end
		if t.repconvar then
			xlib.checkRepCvarCreated( t.repconvar )
			local col = GetConVar( t.repconvar ):GetString()
			if col == "0" then col = "0 0 0" end
			col = string.Split( col, " " )
			pnl:SetColor( Color( col[1], col[2], col[3] ) )
			function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
				if cl_cvar == t.repconvar:lower() then
					local col = string.Split( new_val, " " )
					pnl:SetColor( Color( col[1], col[2], col[3] ) )
				end
			end
			hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
			function pnl:OnChange( color )
				RunConsoleCommand( t.repconvar, color.r .. " " .. color.g .. " " .. color.b )
			end
		end
		return pnl
	end

	--Thanks to Megiddo for this code! :D
	function xlib.wordWrap( text, width, font )
		surface.SetFont( font )
		text = text:Trim()
		local output = ""
		local pos_start, pos_end = 1, 1
		while true do
			local begin, stop = text:find( "%s+", pos_end + 1 )
			if (surface.GetTextSize( text:sub( pos_start, begin or -1 ):Trim() ) > width and pos_end - pos_start > 0) then -- If it's not going to fit, split into a newline
				output = output .. text:sub( pos_start, pos_end ):Trim() .. "\n"
				pos_start = pos_end + 1
				pos_end = pos_end + 1
			else
				pos_end = stop
			end

			if not stop then -- We've hit our last word
				output = output .. text:sub( pos_start ):Trim()
				break
			end
		end
		return output
	end

	--Includes Garry's ever-so-awesome progress bar!
	include( "menu/ProgressBar.lua" )
	function xlib.makeprogressbar( t )
		pnl = vgui.Create( "DProgressBar", t.parent )
		pnl:SetPos( t.x, t.y )
		pnl:SetSize( t.w or 100, t.h or 20 )
		pnl:SetMin( t.min or 0 )
		pnl:SetMax( t.max or 100 )
		pnl:SetValue( t.value or 0 )
		if t.percent then
			pnl.m_bLabelAsPercentage = true
			pnl:UpdateText()
		end
		return pnl
	end

	function xlib.checkRepCvarCreated( cvar )
		if GetConVar( cvar ) == nil then
			CreateClientConVar( cvar:lower(), 0, false, false ) --Replicated cvar hasn't been created via ULib. Create a temporary one to prevent errors
		end
	end

	--------------------------------------------------
	--Megiddo and I are sick of number sliders and their spam of updating convars. Lets modify the NumSlider so that it only sets the value when the mouse is released! (And allows for textbox input)
	--------------------------------------------------
	function xlib.makeslider( t )
		local pnl = vgui.Create( "DNumSlider", t.parent )
		if t.fixclip ~= false then --Fixes clipping errors on the Knob by default, but disables it if specified.
			pnl.Slider.Knob:SetSize( 13, 13 )
			pnl.Slider.Knob:SetPos( 0, 0 )
			pnl.Slider.Knob:NoClipping( false )
		end
		pnl:SetText( t.label or "" )
		pnl:SetMinMax( t.min or 0, t.max or 100 )
		pnl:SetDecimals( t.decimal or 0 )
		if t.convar then pnl:SetConVar( t.convar ) end
		if not t.tooltipwidth then t.tooltipwidth = 250 end
		if t.tooltip then
			if t.tooltipwidth ~= 0 then
				t.tooltip = xlib.wordWrap( t.tooltip, t.tooltipwidth, "MenuItem" )
			end
			pnl:SetToolTip( t.tooltip )
		end
		pnl:SetPos( t.x, t.y )
		pnl:SetWidth( t.w )
		pnl:SizeToContents()
		pnl.Label:SetTextColor( t.textcolor )
		pnl.Wang.TextEntry.selectAll = t.selectall
		if t.value then pnl:SetValue( t.value ) end

		pnl.Wang.TextEntry.OnLoseFocus = function( self )
			hook.Call( "OnTextEntryLoseFocus", nil, self )
			self:UpdateConvarValue()
			pnl.Wang:SetValue( pnl.Wang.TextEntry:GetValue() )
		end

		--Slider update stuff (Most of this code is copied from the default DNumSlider)
		pnl.Slider.TranslateValues = function( self, x, y )
			--Store the value and update the textbox to the new value
			pnl_x = x
			local val = pnl.Wang.m_numMin + ( ( pnl.Wang.m_numMax - pnl.Wang.m_numMin ) * x )
			if pnl.Wang.m_iDecimals == 0 then
				val = Format( "%i", val )
			else
				val = Format( "%." .. pnl.Wang.m_iDecimals .. "f", val )
				-- Trim trailing 0's and .'s 0 this gets rid of .00 etc
				val = string.TrimRight( val, "0" )
				val = string.TrimRight( val, "." )
			end
			pnl.Wang.TextEntry:SetText( val )
			return x, y
		end
		pnl.Slider.OnMouseReleased = function( self, mcode )
			pnl.Slider:SetDragging( false )
			pnl.Slider:MouseCapture( false )
			--Update the actual value to the value we stored earlier
			pnl.Wang:SetFraction( pnl_x )
		end

		--This makes it so the value doesnt change while you're typing in the textbox
		pnl.Wang.TextEntry.OnTextChanged = function() end

		--NumberWang update stuff(Most of this code is copied from the default DNumberWang)
		pnl.Wang.OnCursorMoved = function( self, x, y )
			if ( not self.Dragging ) then return end
			local fVal = self:GetFloatValue()
			local y = gui.MouseY()
			local Diff = y - self.HoldPos
			local Sensitivity = math.abs(Diff) * 0.025
			Sensitivity = Sensitivity / ( self:GetDecimals() + 1 )
			fVal = math.Clamp( fVal + Diff * Sensitivity, self.m_numMin, self.m_numMax )
			self:SetFloatValue( fVal )
			local x, y = self.Wanger:LocalToScreen( self.Wanger:GetWide() * 0.5, 0 )
			input.SetCursorPos( x, self.HoldPos )
			--Instead of updating the value, we're going to store it for later
			pnl_fVal = fVal

			if ( ValidPanel( self.IndicatorT ) ) then self.IndicatorT:InvalidateLayout() end
			if ( ValidPanel( self.IndicatorB ) ) then self.IndicatorB:InvalidateLayout() end

			--Since we arent updating the value, we need to manually set the value of the textbox. YAY!!
			val = tonumber( fVal )
			val = val or 0
			if ( self.m_iDecimals == 0 ) then
				val = Format( "%i", val )
			elseif ( val ~= 0 ) then
				val = Format( "%."..self.m_iDecimals.."f", val )
				val = string.TrimRight( val, "0" )
				val = string.TrimRight( val, "." )
			end
			self.TextEntry:SetText( val )
		end

		pnl.Wang.OnMouseReleased = function( self, mousecode )
			if ( self.Dragging ) then
				self:EndWang()
				self:SetValue( pnl_fVal )
			return end
		end

		pnl.enabled = true
		pnl.SetDisabled = function( self, bval )
			self.enabled = not bval
			self:SetMouseInputEnabled( not bval )
			self.Slider.Knob:SetVisible( not bval )
			self.Wang.TextEntry:SetPaintBackgroundEnabled( bval )
		end
		if t.disabled then pnl:SetDisabled( t.disabled ) end

		--Replicated Convar Updating
		if t.repconvar then
			xlib.checkRepCvarCreated( t.repconvar )
			pnl:SetValue( GetConVar( t.repconvar ):GetFloat() )
			function pnl.ConVarUpdated( sv_cvar, cl_cvar, ply, old_val, new_val )
				if cl_cvar == t.repconvar:lower() then
					pnl:SetValue( new_val )
				end
			end
			hook.Add( "ULibReplicatedCvarChanged", "XLIB_" .. t.repconvar, pnl.ConVarUpdated )
			function pnl:OnValueChanged( val )
				RunConsoleCommand( t.repconvar, tostring( val ) )
			end
			pnl.Wang.TextEntry.ConVarStringThink = function() end --Override think functions to remove Garry's convar check to (hopefully) speed things up
			pnl.ConVarNumberThink = function() end
			pnl.ConVarStringThink = function() end
			pnl.ConVarChanged = function() end
		end
		return pnl
	end

	-----------------------------------------
	--A stripped-down customized DPanel allowing for textbox input!
	-----------------------------------------
	local PANEL = {}
	AccessorFunc( PANEL, "m_bPaintBackground", "PaintBackground" )
	Derma_Hook( PANEL, "Paint", "Paint", "Panel" )
	Derma_Hook( PANEL, "ApplySchemeSettings", "Scheme", "Panel" )

	function PANEL:Init()
		self:SetPaintBackground( true )
	end

	derma.DefineControl( "xlibPanel", "", PANEL, "EditablePanel" )

	-----------------------------------------
	--A copy of Garry's ColorCtrl used in the sandbox spawnmenu, with the following changes:
	-- -Doesn't use convars whatsoever
	-- -Is a fixed size, but you can have it with/without the alphabar, and there's two layout styles without the alpha bar.
	-- -Has two functions: OnChange and OnChangeImmediate for greater control of handling changes.
	-----------------------------------------
	local PANEL = {}
	function PANEL:Init()
		self.showAlpha=false

		self:SetSize( 130, 135 )

		self.RGBBar = vgui.Create( "DRGBBar", self )
		self.RGBBar.OnColorChange = function( ctrl, color )
			if ( self.showAlpha ) then
				color.a = self.txtA:GetValue()
			end
			self:SetBaseColor( color )
		end
		self.RGBBar:SetSize( 15, 100 )
		self.RGBBar:SetPos( 5,5 )
		self.RGBBar.OnMouseReleased = function( self, mcode )
			self:SetDragging( false )
			self:MouseCapture( false )
			self:GetParent():OnChange( self:GetParent():GetColor() )
		end

		self.ColorCube = vgui.Create( "DColorCube", self )
		self.ColorCube.OnUserChanged = function( ctrl ) self:ColorCubeChanged( ctrl ) end
		self.ColorCube:SetSize( 100, 100 )
		self.ColorCube:SetPos( 25,5 )
		self.ColorCube.OnMouseReleased = function( self, mcode )
			self:SetDragging( false )
			self:MouseCapture( false )
			self:GetParent():OnChange( self:GetParent():GetColor() )
		end

		self.txtR = xlib.makenumberwang{ x=7, y=110, w=35, value=255, parent=self }
		self.txtR.OnValueChanged = function( self, val )
			local p = self:GetParent()
			p:SetColor( Color( val, p.txtG:GetValue(), p.txtB:GetValue(), p.showAlpha and p.txtA:GetValue() ) )
		end
		self.txtR.TextEntry.OnEnter = function( self )
			local val = tonumber( self:GetValue() )
			if not val then val = 0 end
			self:GetParent():OnValueChanged( val )
		end
		self.txtR.TextEntry.OnTextChanged = function( self )
			local val = tonumber( self:GetValue() )
			if not val then val = 0 end
			if val ~= math.Clamp( val, 0, 255 ) then self:SetValue( math.Clamp( val, 0, 255 ) ) end
			self:GetParent():GetParent():UpdateColorText()
		end
		self.txtR.TextEntry.OnLoseFocus = function( self )
			if not tonumber( self:GetValue() ) then self:SetValue( "0" ) end
			local p = self:GetParent():GetParent()
			p:OnChange( p:GetColor() )
			hook.Call( "OnTextEntryLoseFocus", nil, self )
		end
		function self.txtR.OnMouseReleased( self, mousecode )
			if ( self.Dragging ) then
				self:GetParent():OnChange( self:GetParent():GetColor() )
				self:EndWang()
			return end
		end
		self.txtG = xlib.makenumberwang{ x=47, y=110, w=35, value=100, parent=self }
		self.txtG.OnValueChanged = function( self, val )
			local p = self:GetParent()
			p:SetColor( Color( p.txtR:GetValue(), val, p.txtB:GetValue(), p.showAlpha and p.txtA:GetValue() ) )
		end
		self.txtG.TextEntry.OnEnter = function( self )
			local val = tonumber( self:GetValue() )
			if not val then val = 0 end
			self:GetParent():OnValueChanged( val )
		end
		self.txtG.TextEntry.OnTextChanged = function( self )
			local val = tonumber( self:GetValue() )
			if not val then val = 0 end
			if val ~= math.Clamp( val, 0, 255 ) then self:SetValue( math.Clamp( val, 0, 255 ) ) end
			self:GetParent():GetParent():UpdateColorText()
		end
		self.txtG.TextEntry.OnLoseFocus = function( self )
			if not tonumber( self:GetValue() ) then self:SetValue( "0" ) end
			local p = self:GetParent():GetParent()
			p:OnChange( p:GetColor() )
			hook.Call( "OnTextEntryLoseFocus", nil, self )
		end
		function self.txtG.OnMouseReleased( self, mousecode )
			if ( self.Dragging ) then
				self:GetParent():OnChange( self:GetParent():GetColor() )
				self:EndWang()
			return end
		end
		self.txtB = xlib.makenumberwang{ x=87, y=110, w=35, value=100, parent=self }
		self.txtB.OnValueChanged = function( self, val )
			local p = self:GetParent()
			p:SetColor( Color( p.txtR:GetValue(), p.txtG:GetValue(), val, p.showAlpha and p.txtA:GetValue() ) )
		end
		self.txtB.TextEntry.OnEnter = function( self )
			local val = tonumber( self:GetValue() )
			if not val then val = 0 end
			self:GetParent():OnValueChanged( val )
		end
		self.txtB.TextEntry.OnTextChanged = function( self )
			local val = tonumber( self:GetValue() )
			if not val then val = 0 end
			if val ~= math.Clamp( val, 0, 255 ) then self:SetValue( math.Clamp( val, 0, 255 ) ) end
			self:GetParent():GetParent():UpdateColorText()
		end
		self.txtB.TextEntry.OnLoseFocus = function( self )
			if not tonumber( self:GetValue() ) then self:SetValue( "0" ) end
			local p = self:GetParent():GetParent()
			p:OnChange( p:GetColor() )
			hook.Call( "OnTextEntryLoseFocus", nil, self )
		end
		function self.txtB.OnMouseReleased( self, mousecode )
			if ( self.Dragging ) then
				self:GetParent():OnChange( self:GetParent():GetColor() )
				self:EndWang()
			return end
		end

		self:SetColor( Color( 255, 0, 0, 255 ) )
	end

	function PANEL:AddAlphaBar()
		self.showAlpha = true
		self.txtA = xlib.makenumberwang{ x=150, y=82, w=35, value=255, parent=self }
		self.txtA.OnValueChanged = function( self, val )
			local p = self:GetParent()
			p:SetColor( Color( p.txtR:GetValue(), p.txtG:GetValue(), p.txtB:GetValue(), val ) )
		end
		self.txtA.TextEntry.OnEnter = function( self )
			local val = tonumber( self:GetValue() )
			if not val then val = 0 end
			self:GetParent():OnValueChanged( val )
		end
		self.txtA.TextEntry.OnTextChanged = function( self )
			local p = self:GetParent():GetParent()
			local val = tonumber( self:GetValue() )
			if not val then val = 0 end
			if val ~= math.Clamp( val, 0, 255 ) then self:SetValue( math.Clamp( val, 0, 255 ) ) end
			p.AlphaBar:SetSlideY( 1 - ( val / 255) )
			p:OnChangeImmediate( p:GetColor() )
		end
		self.txtA.TextEntry.OnLoseFocus = function( self )
			if not tonumber( self:GetValue() ) then self:SetValue( "0" ) end
			local p = self:GetParent():GetParent()
			p:OnChange( p:GetColor() )
			hook.Call( "OnTextEntryLoseFocus", nil, self )
		end
		function self.txtA.OnMouseReleased( self, mousecode )
			if ( self.Dragging ) then
				self:GetParent():OnChange( self:GetParent():GetColor() )
				self:EndWang()
			return end
		end

		self.AlphaBar = vgui.Create( "DAlphaBar", self )
		self.AlphaBar.OnChange = function( ctrl, alpha ) self:SetColorAlpha( alpha ) end
		self.AlphaBar:SetPos( 25,5 )
		self.AlphaBar:SetSize( 15, 100 )
		self.AlphaBar:SetSlideY( 1 )
		self.AlphaBar.OnMouseReleased = function( self, mcode )
			self:SetDragging( false )
			self:MouseCapture( false )
			self:GetParent():OnChange( self:GetParent():GetColor() )
		end

		self.ColorCube:SetPos( 45,5 )
		self:SetSize( 190, 110 )
		self.txtR:SetPos( 150, 7 )
		self.txtG:SetPos( 150, 32 )
		self.txtB:SetPos( 150, 57 )
	end
	
	function PANEL:AlphaModeTwo()
		self:SetSize( 156, 135 )
		self.AlphaBar:SetPos( 28,5 )
		self.ColorCube:SetPos( 51,5 )
		self.txtR:SetPos( 5, 110 )
		self.txtG:SetPos( 42, 110 )
		self.txtB:SetPos( 79, 110 )
		self.txtA:SetPos( 116, 110 )
	end

	function PANEL:NoAlphaModeTwo()
		self:SetSize( 170, 110 )
		self.txtR:SetPos( 130, 7 )
		self.txtG:SetPos( 130, 32 )
		self.txtB:SetPos( 130, 57 )
	end

	function PANEL:UpdateColorText()
		self.RGBBar:SetColor( Color( self.txtR:GetValue(), self.txtG:GetValue(), self.txtB:GetValue(), self.showAlpha and self.txtA:GetValue() ) )
		self.ColorCube:SetColor( Color( self.txtR:GetValue(), self.txtG:GetValue(), self.txtB:GetValue(), self.showAlpha and self.txtA:GetValue() ) )
		if ( self.showAlpha ) then self.AlphaBar:SetImageColor( Color( self.txtR:GetValue(), self.txtG:GetValue(), self.txtB:GetValue(), self.txtA:GetValue() ) ) end
		self:OnChangeImmediate( self:GetColor() )
	end

	function PANEL:SetColor( color )
		self.RGBBar:SetColor( color )
		self.ColorCube:SetColor( color )

		if tonumber( self.txtR.TextEntry:GetValue() ) ~= color.r then self.txtR.TextEntry:SetText( color.r or 255 ) end
		if tonumber( self.txtG.TextEntry:GetValue() ) ~= color.g then self.txtG.TextEntry:SetText( color.g or 0 ) end
		if tonumber( self.txtB.TextEntry:GetValue() ) ~= color.b then self.txtB.TextEntry:SetText( color.b or 0 ) end

		if ( self.showAlpha ) then
			self.txtA.TextEntry:SetText( color.a or 0 )
			self.AlphaBar:SetImageColor( color )
			self.AlphaBar:SetSlideY( 1 - ( ( color.a or 0 ) / 255) )
		end

		self:OnChangeImmediate( color )
	end

	function PANEL:SetBaseColor( color )
        self.ColorCube:SetBaseRGB( color )

		self.txtR.TextEntry:SetText(self.ColorCube.m_OutRGB.r)
		self.txtG.TextEntry:SetText(self.ColorCube.m_OutRGB.g)
		self.txtB.TextEntry:SetText(self.ColorCube.m_OutRGB.b)

		if ( self.showAlpha ) then
			self.AlphaBar:SetImageColor( self:GetColor() )
		end
		self:OnChangeImmediate( self:GetColor() )
	end

	function PANEL:SetColorAlpha( alpha )
		if ( self.showAlpha ) then
			alpha = alpha or 0
			self.txtA:SetValue(alpha)
		end
	end

	function PANEL:ColorCubeChanged( cube )
		self.txtR.TextEntry:SetText(cube.m_OutRGB.r)
		self.txtG.TextEntry:SetText(cube.m_OutRGB.g)
		self.txtB.TextEntry:SetText(cube.m_OutRGB.b)
		if ( self.showAlpha ) then
			self.AlphaBar:SetImageColor( self:GetColor() )
		end
		self:OnChangeImmediate( self:GetColor() )
	end

	function PANEL:GetColor()
		local color = Color( self.txtR:GetValue(), self.txtG:GetValue(), self.txtB:GetValue() )
		if ( self.showAlpha ) then
			color.a = self.txtA:GetValue() --math.Round( 255 - (self.AlphaBar:GetSlideY() * 255) )
		else
			color.a = 255
		end
		return color
	end

	function PANEL:PerformLayout()
		self:SetColor( Color( self.txtR:GetValue(), self.txtG:GetValue(), self.txtB:GetValue(), self.showAlpha and self.txtA:GetValue() ) )
	end

	function PANEL:OnChangeImmediate( color )
		--For override
	end

	function PANEL:OnChange( color )
		--For override
	end

	vgui.Register( "xlibColorPanel", PANEL, "DPanel" )

end

hook.Add( "ULibLocalPlayerReady", "InitXLIB", xlib_init, -20 )