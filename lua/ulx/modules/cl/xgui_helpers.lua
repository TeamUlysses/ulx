--xgui_helpers -- by Stickly Man!
--A set of generic functions to help with various XGUI-related things.

local function xgui_helpers()
	---------------
	--Derma Helpers
	---------------
	--A quick function to get the value of a DMultiChoice (I like consistency)
	function DMultiChoice:GetValue()
		return self.TextEntry:GetValue()
	end
	
	function DCheckBoxLabel:GetValue()
		return self:GetChecked()
	end

	--Clears all of the tabs in a DPropertySheet, parents removed panels to xgui.null.
	function DPropertySheet:Clear()
		for _, Sheet in ipairs( self.Items ) do
			Sheet.Panel:SetParent( xgui.null )
			Sheet.Tab:Remove()
		end
		self.m_pActiveTab = nil
		self:SetActiveTab( nil )
		self.tabScroller.Panels = {}
		self.Items = {}
	end
	
	--Clears a DTree.
	function DTree:Clear()
		for item, node in pairs( self.Items ) do
			node:Remove()
			self.Items[item] = nil
		end
		self.m_pSelectedItem = nil
		self:InvalidateLayout()
	end
	
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
		
	-------------------------
	--Custom Animation System
	-------------------------
	--This is a heavily edited version of Garry's derma animation stuff with the following differences:
		--Allows for animation chains (one animation to begin right after the other)
		--Can call functions anywhere during the animation cycle.
		--Reliably calls a start/end function for each animation so the animations always shows/ends properly.
		--Animations can be completely disabled by setting 0 for the animation time.	
	local xlibAnimation = {}
	xlibAnimation.__index = xlibAnimation
	
	function xlib.anim( runFunc, startFunc, endFunc )
		local anim = {}
		anim.runFunc = runFunc
		anim.startFunc = startFunc
		anim.endFunc = endFunc
		setmetatable( anim, xlibAnimation )
		return anim
	end
	
	xlib.animTypes = {}
	xlib.registerAnimType = function( name, runFunc, startFunc, endFunc )
		xlib.animTypes[name] = xlib.anim( runFunc, startFunc, endFunc )
	end
	
	function xlibAnimation:Start( Length, Data )
		self.startFunc( Data )
		if ( Length == 0 ) then
			self.endFunc( Data )
			xlib.animQueue_call()
		else
			self.Length = Length
			self.StartTime = SysTime()
			self.EndTime = SysTime() + Length
			self.Data = Data
			table.insert( xlib.activeAnims, self )
		end
	end
	
	function xlibAnimation:Stop()
		self.runFunc( 1, self.Data )
		self.endFunc( self.Data )
		for i, v in ipairs( xlib.activeAnims ) do
			if v == self then table.remove( xlib.activeAnims, i ) break end
		end
		xlib.animQueue_call()
	end
	
	function xlibAnimation:Run()
		local CurTime = SysTime()
		local delta = (CurTime - self.StartTime) / self.Length
		if ( CurTime > self.EndTime ) then
			self:Stop()
		else
			self.runFunc( delta, self.Data )
		end
	end
	
	--Animation Ticker
	xlib.activeAnims = {}
	xlib.animRun = function()
		for _, v in ipairs( xlib.activeAnims ) do
			v.Run( v )
		end
	end
	hook.Add( "XLIBDoAnimation", "xlib_runAnims", xlib.animRun )
	
	-------------------------
	--Animation chain manager
	-------------------------
	xlib.animQueue = {}
	xlib.animBackupQueue = {}
	
	--This will allow us to make animations run faster when linked together 
	--Makes sure the entire animation length = animationTime (~0.2 sec by default)
	xlib.animStep = 0
	
	--Call this to begin the animation chain
	xlib.animQueue_start = function()
		if xlib.animRunning then --If a new animation is starting while one is running, then we should instantly stop the old one.
			xlib.animQueue_forceStop()
			return --The old animation should be finished now, and the new one should be starting
		end
		xlib.curAnimStep = xlib.animStep
		xlib.animStep = 0
		xlib.animQueue_call()
	end
	
	xlib.animQueue_forceStop = function()
		--This will trigger the currently chained animations to run at 0 seconds.
		xlib.curAnimStep = -1
		if type( xlib.animRunning ) == "table" then xlib.animRunning:Stop() end
	end
	
	xlib.animQueue_call = function()
		if #xlib.animQueue > 0 then
			local func = xlib.animQueue[1]
			table.remove( xlib.animQueue, 1 )
			func()
		else
			xlib.animRunning = nil
			--Check for queues in the backup that haven't been started.
			if #xlib.animBackupQueue > 0 then
				xlib.animQueue = table.Copy( xlib.animBackupQueue )
				xlib.animBackupQueue = {}
				xlib.animQueue_start()
			end
		end
	end	
	
	xlib.addToAnimQueue = function( obj, ... )
		--If there is an animation running, then we need to store the new animation stuff somewhere else temporarily.
		--Also, if ignoreRunning is true, then we'll add the anim to the regular queue regardless of running status.
		local outTable = xlib.animRunning and xlib.animBackupQueue or xlib.animQueue
			
		if type( obj ) == "function" then
			table.insert( outTable, function() xlib.animRunning = true  obj( unpack( arg ) )  xlib.animQueue_call() end )
		elseif type( obj ) == "string" and xlib.animTypes[obj] then
			--arg[1] should be data table, arg[2] should be length
			length = arg[2] or xgui.settings.animTime
			xlib.animStep = xlib.animStep + 1
			table.insert( outTable, function() xlib.animRunning = xlib.animTypes[obj]  xlib.animRunning:Start( ( xlib.curAnimStep ~= -1 and ( length/xlib.curAnimStep ) or 0 ), arg[1] ) end )
		else
			Msg( "Error: XGUI recieved an invalid animation call! TYPE:" .. type( obj ) .. " VALUE:" .. tostring( obj ) .. "\n" )
		end
	end
	
	-------------------------
	--Default Animation Types
	-------------------------
	--Slide animation
	local function slideAnim_run( delta, data )
		--data.panel, data.startx, data.starty, data.endx, data.endy, data.setvisible
		data.panel:SetPos( data.startx+((data.endx-data.startx)*delta), data.starty+((data.endy-data.starty)*delta) )
	end
	
	local function slideAnim_start( data )
		data.panel:SetPos( data.startx, data.starty )
		if data.setvisible == true then
			data.panel:SetVisible( true )
		end
	end
	
	local function slideAnim_end( data )
		data.panel:SetPos( data.endx, data.endy )
		if data.setvisible == false then
			data.panel:SetVisible( false )
		end
	end
	xlib.registerAnimType( "pnlSlide", slideAnim_run, slideAnim_start, slideAnim_end )
	
	--Fade animation
	local function fadeAnim_run( delta, data )
		if data.panelOut then data.panelOut:SetAlpha( 255-(delta*255) ) data.panelOut:SetVisible( true ) end
		if data.panelIn then data.panelIn:SetAlpha( 255 * delta ) data.panelIn:SetVisible( true ) end
	end
	
	local function fadeAnim_start( data )
		if data.panelOut then data.panelOut:SetAlpha( 255 ) data.panelOut:SetVisible( true ) end
		if data.panelIn then data.panelIn:SetAlpha( 0 ) data.panelIn:SetVisible( true ) end
	end
	
	local function fadeAnim_end( data )
		if data.panelOut then data.panelOut:SetVisible( false ) end
		if data.panelIn then data.panelIn:SetAlpha( 255 ) end
	end
	xlib.registerAnimType( "pnlFade", fadeAnim_run, fadeAnim_start, fadeAnim_end )
	

	---------------------------------
	--Code for creating the XGUI base
	---------------------------------
	function x_makeXGUIbase()
		xgui.base = vgui.Create( "DPropertySheet" )
		xgui.anchor = xlib.makeXpanel{ w=600, h=470, x=ScrW()/2-300, y=ScrH()/2-270 }
		xgui.anchor:SetVisible( false )
		xgui.anchor:SetKeyboardInputEnabled( false )
		xgui.anchor.Paint = function() hook.Call( "XLIBDoAnimation" ) end
		xgui.anchor:SetAlpha( 0 )
		xgui.base:SetAlpha( 0 )
		xgui.base:SetParent( xgui.anchor )
		xgui.base:SetPos( 0, 70 )
		xgui.base:SetSize( 600, 400 )

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
				elseif yoff > 10 then
					yoff = 10
				end
				xgui.y = ScrH()-500+yoff
			elseif pos == 7 or pos == 8 or pos == 9 then --Top of the screen
				if yoff < -70 then
					yoff = -70
				elseif yoff > ScrH()-490 then
					yoff = ScrH()-490
				end
				xgui.y = yoff
			elseif pos == 4 or pos == 5 or pos == 6 then --Center
				if yoff < -ScrH()/2+200 then
					yoff = -ScrH()/2+200
				elseif yoff > ScrH()/2-220 then
					yoff = ScrH()/2-220
				end
				xgui.y = ScrH()/2-270+yoff
			else --Someone screwed something up!
				xgui.x = ScrW()/2-300
				xgui.y = ScrH()/2-270
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
		xgui.chunkbox = xlib.makeframe{ label="XGUI is receiving data!", w=200, h=60, x=200, y=5, visible=false, nopopup=true, draggable=false, showclose=false, skin=xgui.settings.skin, parent=xgui.anchor }
		xgui.chunkbox.progress = xlib.makeprogressbar{ x=10, y=30, w=180, h=20, min=0, percent=true, parent=xgui.chunkbox }
		function xgui.chunkbox:Progress( datatype )
			self.progress:SetValue( self.progress:GetValue() + 1 )
			self.progress.Label:SetText( datatype .. " - " .. self.progress.Label:GetValue() )
			if self.progress:GetValue() == self.progress.m_iMax then
				xgui.expectingdata = nil
				self.progress.Label:SetText( "Waiting for clientside processing" )
				xgui.queueFunctionCall( xgui.chunkbox.SetVisible, "chunkbox", xgui.chunkbox, false )
				RunConsoleCommand( "_xgui", "dataComplete" )
			end
			self.progress:PerformLayout()
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
		hook.Add( "Think", "XGUIQueueThink", onThink, -20 )
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
	function ULib.cmds.BaseArg.x_getcontrol( arg, argnum )
		return xlib.makelabel{ label="Not Supported" }
	end
	
	function ULib.cmds.NumArg.x_getcontrol( arg, argnum )
		local access, tag = LocalPlayer():query( arg.cmd )
		local restrictions = {}
		ULib.cmds.NumArg.processRestrictions( restrictions, arg, ulx.getTagArgNum( tag, argnum ) )
		
		local defvalue = arg.min
		if table.HasValue( arg, ULib.cmds.optional ) then defvalue = arg.default end
		if not defvalue then defvalue = 0 end --No default was set for this command, so we'll use 0.
		
		local maxvalue = restrictions.max
		if restrictions.max == nil and defvalue > 100 then maxvalue = defvalue end
		
		return xlib.makeslider{ min=restrictions.min, max=maxvalue, value=defvalue, label=arg.hint or "NumArg" }
	end
	
	function ULib.cmds.StringArg.x_getcontrol( arg, argnum )
		local access, tag = LocalPlayer():query( arg.cmd )
		local restrictions = {}
		ULib.cmds.StringArg.processRestrictions( restrictions, arg, ulx.getTagArgNum( tag, argnum ) )
		
		local is_restricted_to_completes = table.HasValue( arg, ULib.cmds.restrictToCompletes ) -- Program-level restriction (IE, ulx map)
			or restrictions.playerLevelRestriction -- The player's tag specifies only certain strings	
		
		if is_restricted_to_completes then
			xgui_temp = xlib.makemultichoice{ text=arg.hint or "StringArg" }
			for _, v in ipairs( restrictions.restrictedCompletes ) do
				xgui_temp:AddChoice( v )
			end
			return xgui_temp
		elseif restrictions.restrictedCompletes then
			-- This is where there needs to be both a drop down AND an input box
			local temp = xlib.makemultichoice{ text=arg.hint, choices=restrictions.restrictedCompletes, enableinput=true, selectall=true }
			temp.TextEntry.OnEnter = function( self )
				self:GetParent():OnEnter()
			end
			return temp
		else
			return xlib.maketextbox{ text=arg.hint or "StringArg", selectall=true }
		end
	end
	
	function ULib.cmds.PlayerArg.x_getcontrol( arg, argnum )
		local access, tag = LocalPlayer():query( arg.cmd )
		local restrictions = {}
		ULib.cmds.PlayerArg.processRestrictions( restrictions, LocalPlayer(), arg, ulx.getTagArgNum( tag, argnum ) )
		
		xgui_temp = xlib.makemultichoice{ text=arg.hint }
		local targets = restrictions.restrictedTargets
		if targets == false then -- No one allowed
			targets = {}
		elseif targets == nil then -- Everyone allowed
			targets = player.GetAll()
		end
		
		for _, ply in ipairs( targets ) do
			xgui_temp:AddChoice( ply:Nick() )
		end
		return xgui_temp
	end
	
	function ULib.cmds.CallingPlayerArg.x_getcontrol( arg, argnum )
		return xlib.makelabel{ label=arg.hint or "CallingPlayer" }
	end
	
	function ULib.cmds.BoolArg.x_getcontrol( arg, argnum )
		-- There are actually not any restrictions possible on a boolarg...
		local xgui_temp = xlib.makecheckbox{ label=arg.hint or "BoolArg" }
		xgui_temp.GetValue = function( self )
			return self:GetChecked() and 1 or 0
		end
		return xgui_temp
	end
end

hook.Add( "ULibLocalPlayerReady", "InitXguiHelpers", xgui_helpers, -15 )