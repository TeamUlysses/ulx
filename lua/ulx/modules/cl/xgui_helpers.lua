--xgui_helpers -- by Stickly Man!
--A set of generic functions to help with various XGUI-related things.

function xgui.load_helpers()
	--These handle keyboard focus for textboxes within XGUI.
	local function getKeyboardFocus( pnl )
		if pnl:HasParent( xgui.base ) then
			xgui.anchor:SetKeyboardInputEnabled( true )
		end
		if pnl.selectAll then
			pnl:SelectAllText()
		end
	end
	hook.Add( "OnTextEntryGetFocus", "XGUI_GetKeyboardFocus", getKeyboardFocus )

	local function loseKeyboardFocus( pnl )
		if pnl:HasParent( xgui.base ) then
			xgui.anchor:SetKeyboardInputEnabled( false )
		end
	end
	hook.Add( "OnTextEntryLoseFocus", "XGUI_LoseKeyboardFocus", loseKeyboardFocus )


	---------------------------------
	--Code for creating the XGUI base
	---------------------------------
	function xgui.makeXGUIbase()
		xgui.anchor = xlib.makeXpanel{ w=600, h=420, x=ScrW()/2-300, y=ScrH()/2-270 }
		xgui.anchor:SetVisible( false )
		xgui.anchor:SetKeyboardInputEnabled( false )
		xgui.anchor.Paint = function( self, w, h ) hook.Call( "XLIBDoAnimation" ) end
		xgui.anchor:SetAlpha( 0 )

		xgui.base = xlib.makepropertysheet{ x=0, y=0, w=600, h=400, parent=xgui.anchor, offloadparent=xgui.null }
		xgui.base.animOpen = function() --First 4 are fade animations, last (or invalid choice) is the default fade animation.
			xgui.settings.animIntype = tonumber( xgui.settings.animIntype )
			if xgui.settings.animIntype == 2 then
				xlib.addToAnimQueue( function() xgui.anchor:SetAlpha(255) end )
				xlib.addToAnimQueue( "pnlSlide", { panel=xgui.anchor, startx=xgui.x, starty=-490, endx=xgui.x, endy=xgui.y, setvisible=true } )
			elseif xgui.settings.animIntype == 3 then
				xlib.addToAnimQueue( function() xgui.anchor:SetAlpha(255) end )
				xlib.addToAnimQueue( "pnlSlide", { panel=xgui.anchor, startx=-610, starty=xgui.y, endx=xgui.x, endy=xgui.y, setvisible=true } )
			elseif xgui.settings.animIntype == 4 then
				xlib.addToAnimQueue( function() xgui.anchor:SetAlpha(255) end )
				xlib.addToAnimQueue( "pnlSlide", { panel=xgui.anchor, startx=xgui.x, starty=ScrH(), endx=xgui.x, endy=xgui.y, setvisible=true } )
			elseif xgui.settings.animIntype == 5 then
				xlib.addToAnimQueue( function() xgui.anchor:SetAlpha(255) end )
				xlib.addToAnimQueue( "pnlSlide", { panel=xgui.anchor, startx=ScrW(), starty=xgui.y, endx=xgui.x, endy=xgui.y, setvisible=true } )
			else
				xlib.addToAnimQueue( function() xgui.anchor:SetPos( xgui.x, xgui.y ) end )
				xlib.addToAnimQueue( "pnlFade", { panelIn=xgui.anchor } )
			end
			xlib.animQueue_start()
		end
		xgui.base.animClose = function()
			xgui.settings.animOuttype = tonumber( xgui.settings.animOuttype )
			if xgui.settings.animOuttype == 2 then
				xlib.addToAnimQueue( "pnlSlide", { panel=xgui.anchor, startx=xgui.x, starty=xgui.y, endx=xgui.x, endy=-490, setvisible=false } )
				xlib.addToAnimQueue( function() xgui.anchor:SetAlpha(0) end )
			elseif xgui.settings.animOuttype == 3 then
				xlib.addToAnimQueue( "pnlSlide", { panel=xgui.anchor, startx=xgui.x, starty=xgui.y, endx=-610, endy=xgui.y, setvisible=false } )
				xlib.addToAnimQueue( function() xgui.anchor:SetAlpha(0) end )
			elseif xgui.settings.animOuttype == 4 then
				xlib.addToAnimQueue( "pnlSlide", { panel=xgui.anchor, startx=xgui.x, starty=xgui.y, endx=xgui.x, endy=ScrH(), setvisible=false } )
				xlib.addToAnimQueue( function() xgui.anchor:SetAlpha(0) end )
			elseif xgui.settings.animOuttype == 5 then
				xlib.addToAnimQueue( "pnlSlide", { panel=xgui.anchor, startx=xgui.x, starty=xgui.y, endx=ScrW(), endy=xgui.y, setvisible=false } )
				xlib.addToAnimQueue( function() xgui.anchor:SetAlpha(0) end )
			else
				xlib.addToAnimQueue( function() xgui.anchor:SetPos( xgui.x, xgui.y ) end )
				xlib.addToAnimQueue( "pnlFade", { panelOut=xgui.anchor } )
			end
			xlib.animQueue_start()
		end

		function xgui.SetPos( pos, xoff, yoff, ignoreanim ) --Sets the position of XGUI based on "pos", and checks to make sure that with whatever offset and pos combination, XGUI does not go off the screen.
			pos = tonumber( pos )
			xoff = tonumber( xoff )
			yoff = tonumber( yoff )
			if not xoff then xoff = 0 end
			if not yoff then yoff = 0 end
			if not pos then pos = 5 end
			if pos == 1 or pos == 4 or pos == 7 then --Left side of the screen
				if xoff < -10 then
					xoff = -10
				elseif xoff > ScrW()-610 then
					xoff = ScrW()-610
				end
				xgui.x = 10+xoff
			elseif pos == 3 or pos == 6 or pos == 9 then --Right side of the screen
				if xoff < -ScrW()+610 then
					xoff = -ScrW()+610
				elseif xoff > 10 then
					xoff = 10
				end
				xgui.x = ScrW()-610+xoff
			else --Center
				if xoff < -ScrW()/2+300 then
					xoff = -ScrW()/2+300
				elseif xoff > ScrW()/2-300 then
					xoff = ScrW()/2-300
				end
				xgui.x = ScrW()/2-300+xoff
			end

			if pos == 1 or pos == 2 or pos == 3 then --Bottom of the screen
				if yoff < -ScrH()+430 then
					yoff = -ScrH()+430
				elseif yoff > 30 then
					yoff = 30
				end
				xgui.y = ScrH()-430+yoff
			elseif pos == 7 or pos == 8 or pos == 9 then --Top of the screen
				if yoff < -10 then
					yoff = -10
				elseif yoff > ScrH()-410 then
					yoff = ScrH()-410
				end
				xgui.y = yoff+10
			else --Center
				if yoff < -ScrH()/2+210 then
					yoff = -ScrH()/2+210
				elseif yoff > ScrH()/2-190 then
					yoff = ScrH()/2-190
				end
				xgui.y = ScrH()/2-210+yoff
			end
			if ignoreanim then
				xgui.anchor:SetPos( xgui.x, xgui.y )
			else
				local curx, cury = xgui.anchor:GetPos()
				xlib.addToAnimQueue( "pnlSlide", { panel=xgui.anchor, startx=curx, starty=cury, endx=xgui.x, endy=xgui.y } )
				xlib.animQueue_start()
			end
		end
		xgui.SetPos( xgui.settings.xguipos.pos, xgui.settings.xguipos.xoff, xgui.settings.xguipos.yoff )

		function xgui.base:SetActiveTab( active, ignoreAnim )
			if ( self.m_pActiveTab == active ) then return end
			if ( self.m_pActiveTab ) then
				if not ignoreAnim then
					xlib.addToAnimQueue( "pnlFade", { panelOut=self.m_pActiveTab:GetPanel(), panelIn=active:GetPanel() } )
				else
					--Run this when module permissions have changed.
					xlib.addToAnimQueue( "pnlFade", { panelOut=nil, panelIn=active:GetPanel() }, 0 )
				end
				xlib.animQueue_start()
			end
			self.m_pActiveTab = active
			self:InvalidateLayout()
		end

		--Progress bar
		xgui.chunkbox = xlib.makeprogressbar{ x=420, w=180, h=20, visible=false, skin=xgui.settings.skin, parent=xgui.anchor }
		function xgui.chunkbox:Progress( datatype )
			self.value = self.value + 1
			self:SetFraction( self.value / self.max )
			self.Label:SetText( "Getting data: " .. datatype .. " - " .. string.format("%.2f", (self.value / self.max) * 100) .. "%" )
			if self.value == self.max then
				xgui.expectingdata = nil
				self.Label:SetText( "Waiting for clientside processing..." )
				xgui.queueFunctionCall( xgui.chunkbox.SetVisible, "chunkbox", xgui.chunkbox, false )
				RunConsoleCommand( "_xgui", "dataComplete" )
			end
		end
	end

	------------------------
	--XGUI QueueFunctionCall
	------------------------
	--This is essentially a straight copy of Megiddo's queueFunctionCall; Since XGUI tends to use it quite a lot, I decided to seperate it to prevent delays in ULib's stuff
	--I also now get to add a method of flushing the queue based on a tag in the event that new data needs to be updated.
	local stack = {}
	local function onThink()

		local num = #stack
		if num > 0 then
			for i=1,3 do --Run 3 lines per frame
				if stack[1] ~= nil then
					local b, e = pcall( stack[ 1 ].fn, unpack( stack[ 1 ], 1, stack[ 1 ].n ) )
					if not b then
						ErrorNoHalt( "XGUI queue error: " .. tostring( e ) .. "\n" )
					end
				end
			table.remove( stack, 1 ) -- Remove the first inserted item. This is FIFO
			end
		else
			hook.Remove( "Think", "XGUIQueueThink" )
		end
	end

	function xgui.queueFunctionCall( fn, tag, ... )
		if type( fn ) ~= "function" then
			error( "queueFunctionCall received a bad function", 2 )
			return
		end

		table.insert( stack, { fn=fn, tag=tag, n=select( "#", ... ), ... } )
		hook.Add( "Think", "XGUIQueueThink", onThink, HOOK_MONITOR_HIGH )
	end

	function xgui.flushQueue( tag )
		local removeIndecies = {}
		for i, fncall in ipairs( stack ) do
			if fncall.tag == tag then
				table.insert( removeIndecies, i )
			end
		end
		for i=#removeIndecies,1,-1 do --Remove the queue functions backwards to prevent desynchronization of pairs
			table.remove( stack, removeIndecies[i] )
		end
	end


	-------------------
	--ULIB XGUI helpers
	-------------------
	--Helper function to parse access tag for a particular argument
	function ulx.getTagArgNum( tag, argnum )
		return tag and ULib.splitArgs( tag, "<", ">" )[argnum]
	end

	--Load control interpretations for ULib argument types
	function ULib.cmds.BaseArg.x_getcontrol( arg, argnum, parent )
		return xlib.makelabel{ label="Not Supported", parent=parent }
	end

	function ULib.cmds.NumArg.x_getcontrol( arg, argnum, parent )
		local access, tag = LocalPlayer():query( arg.cmd )
		local restrictions = {}
		ULib.cmds.NumArg.processRestrictions( restrictions, arg, ulx.getTagArgNum( tag, argnum ) )

		if table.HasValue( arg, ULib.cmds.allowTimeString ) then
			local min = restrictions.min or 0
			local max = restrictions.max or 10 * 60 * 24 * 365 --default slider max 10 years

			local outPanel = xlib.makepanel{ h=40, parent=parent }
			xlib.makelabel{ x=5, y=3, label="Ban Length:", parent=outPanel }
			outPanel.interval = xlib.makecombobox{ x=90, w=75, parent=outPanel }
			outPanel.val = xlib.makeslider{ w=165, y=20, label="<--->", min=min, max=max, value=min, decimal=0, parent=outPanel }

			local divisor = {}
			local sensiblemax = {}
			if min == 0 then outPanel.interval:AddChoice( "Permanent" ) table.insert( divisor, 1 ) table.insert( sensiblemax, 0 ) end
			if max >= 1 and min <= 60*24 then outPanel.interval:AddChoice( "Minutes" ) table.insert( divisor, 1 ) table.insert( sensiblemax, 60*24 ) end
			if max >= 60 and min <= 60*24*7 then outPanel.interval:AddChoice( "Hours" ) table.insert( divisor, 60 ) table.insert( sensiblemax, 24*7 ) end
			if max >= ( 60*24 ) and min <= 60*24*120 then outPanel.interval:AddChoice( "Days" ) table.insert( divisor, 60*24 ) table.insert( sensiblemax, 120 ) end
			if max >= ( 60*24*7 ) and min <= 60*24*7*52 then outPanel.interval:AddChoice( "Weeks" ) table.insert( divisor, 60*24*7 ) table.insert( sensiblemax, 52 ) end
			if max >= ( 60*24*365 ) then outPanel.interval:AddChoice( "Years" ) table.insert( divisor, 60*24*365 ) table.insert( sensiblemax, 10 ) end

			outPanel.interval.OnSelect = function( self, index, value, data )
				outPanel.val:SetDisabled( value == "Permanent" )
				outPanel.val.maxvalue = math.min( max / divisor[index], sensiblemax[index] )
				outPanel.val.minvalue = math.max( min / divisor[index], 0 )
				outPanel.val:SetMax( outPanel.val.maxvalue )
				outPanel.val:SetMin( outPanel.val.minvalue )
				outPanel.val:SetValue( math.Clamp( tonumber( outPanel.val:GetValue() ), outPanel.val.minvalue, outPanel.val.maxvalue ) )
			end

			function outPanel.val:ValueChanged( val )
				val = math.Clamp( tonumber( val ), self.minvalue or 0, self.maxvalue or 0 )
				self.Slider:SetSlideX( self.Scratch:GetFraction( val ) )
				if ( self.TextArea != vgui.GetKeyboardFocus() ) then
					self.TextArea:SetValue( self.Scratch:GetTextValue() )
				end
				self:OnValueChanged( val )
			end

			if #outPanel.interval.Choices ~= 0 then
				outPanel.interval:ChooseOptionID( 1 )
			end

			outPanel.GetValue = function( self )
				local val, char = self:GetRawValue()
				return val .. char
			end
			outPanel.GetRawValue = function( self )
				local char = string.lower( self.interval:GetValue():sub(1,1) )
				if char == "m" or char == "p" or tonumber( self.val:GetValue() ) == 0 then char = "" end
				return self.val:GetValue(), char
			end
			outPanel.GetMinutes = function( self )
				local btime, char = self:GetRawValue()
				if char == "h" then btime = btime * 60
				elseif char == "d" then btime = btime * 1440
				elseif char == "w" then btime = btime * 10080
				elseif char == "y" then btime = btime * 525600 end
				return btime
			end
			outPanel.TextArea = outPanel.val.TextArea
			return outPanel
		else
			local defvalue = arg.min
			if table.HasValue( arg, ULib.cmds.optional ) then defvalue = arg.default end
			if not defvalue then defvalue = 0 end --No default was set for this command, so we'll use 0.

			local maxvalue = restrictions.max
			local minvalue = restrictions.min or 0
			if maxvalue == nil then
				if defvalue > 100 then
					maxvalue = defvalue
				else
					maxvalue = 100
				end
			end

			local decimal = 0
			if not table.HasValue( arg, ULib.cmds.round ) then
				local minMaxDelta = maxvalue - minvalue
				if minMaxDelta < 5 then
					decimal = 2
				elseif minMaxDelta <= 10 then
					decimal = 1
				end
			end

			local outPanel = xlib.makepanel{ h=35, parent=parent }
			xlib.makelabel{ label=arg.hint or "NumArg", parent=outPanel }
			outPanel.val = xlib.makeslider{ y=15, w=165, min=minvalue, max=maxvalue, value=defvalue, decimal=decimal, label="<--->", parent=outPanel }
			outPanel.GetValue = function( self ) return outPanel.val.GetValue( outPanel.val ) end
			outPanel.TextArea = outPanel.val.TextArea
			return outPanel
		end
	end

	function ULib.cmds.NumArg.getTime( arg )
		if arg == nil or arg == "" then return nil, nil end

		if arg == 0 or tonumber( arg ) == 0 then
			return "Permanent", 0
		end

		local charPriority = { "y", "w", "d", "h" }
		local charMap = { "Years", "Weeks", "Days", "Hours" }
		local divisor = { 60 * 24 * 365, 60 * 24 * 7, 60 * 24, 60 }
		for i, v in ipairs( charPriority ) do
			if arg:find( v, 1, true ) then
				if not charMap[ i ] or not divisor [ i ] or not ULib.stringTimeToMinutes( arg ) then return nil, nil end
				local val = ULib.stringTimeToMinutes( arg ) / divisor[ i ]
				if val == 0 then return "Permanent", 0 end
				return charMap[ i ], val
			end
		end

		return "Minutes", ULib.stringTimeToMinutes( arg )
	end


	function ULib.cmds.StringArg.x_getcontrol( arg, argnum, parent )
		local access, tag = LocalPlayer():query( arg.cmd )
		local restrictions = {}
		ULib.cmds.StringArg.processRestrictions( restrictions, arg, ulx.getTagArgNum( tag, argnum ) )

		local is_restricted_to_completes = table.HasValue( arg, ULib.cmds.restrictToCompletes ) -- Program-level restriction (IE, ulx map)
			or restrictions.playerLevelRestriction -- The player's tag specifies only certain strings

		if is_restricted_to_completes then
			return xlib.makecombobox{ text=arg.hint or "StringArg", choices=restrictions.restrictedCompletes, parent=parent }
		elseif restrictions.restrictedCompletes and table.Count( restrictions.restrictedCompletes ) > 0 then
			-- This is where there needs to be both a drop down AND an input box
			local outPanel = xlib.makecombobox{ text=arg.hint, choices=restrictions.restrictedCompletes, enableinput=true, selectall=true, parent=parent }
			outPanel.OnEnter = function( self )
				self:GetParent():OnEnter()
			end
			return outPanel
		else
			return xlib.maketextbox{ text=arg.hint or "StringArg", selectall=true, parent=parent }
		end
	end

	function ULib.cmds.PlayerArg.x_getcontrol( arg, argnum, parent )
		local access, tag = LocalPlayer():query( arg.cmd )
		local restrictions = {}
		ULib.cmds.PlayerArg.processRestrictions( restrictions, LocalPlayer(), arg, ulx.getTagArgNum( tag, argnum ) )

		local outPanel = xlib.makecombobox{ text=arg.hint, parent=parent }
		local targets = restrictions.restrictedTargets
		if targets == false then -- No one allowed
			targets = {}
		elseif targets == nil then -- Everyone allowed
			targets = player.GetAll()
		end

		for _, ply in ipairs( targets ) do
			outPanel:AddChoice( ply:Nick() )
		end
		return outPanel
	end

	function ULib.cmds.CallingPlayerArg.x_getcontrol( arg, argnum, parent )
		return xlib.makelabel{ label=arg.hint or "CallingPlayer", parent=parent }
	end

	function ULib.cmds.BoolArg.x_getcontrol( arg, argnum, parent )
		local access, tag = LocalPlayer():query( arg.cmd )
		local restrictions = {}
		ULib.cmds.BoolArg.processRestrictions( restrictions, arg, ulx.getTagArgNum( tag, argnum ) )

		local outPanel = xlib.makecheckbox{ label=arg.hint or "BoolArg", value=restrictions.restrictedTo, parent=parent }
		if restrictions.restrictedTo ~= nil then outPanel:SetDisabled( true ) end
		outPanel.GetValue = function( self )
			return self:GetChecked() and 1 or 0
		end
		return outPanel
	end
end