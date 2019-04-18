--Settings module v2 for ULX GUI -- by Stickly Man!
--This bit of code is the base for holding the various settings modules.

local settings = xlib.makepanel{ parent=xgui.null }

local autorefreshTab
if xgui.settings_tabs ~= nil then autorefreshTab = xgui.settings_tabs:GetActiveTab() end

xgui.settings_tabs = xlib.makepropertysheet{ x=-5, y=6, w=600, h=368, parent=settings, offloadparent=xgui.null }
function xgui.settings_tabs:SetActiveTab( active, ignoreAnim )
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

local func = xgui.settings_tabs.PerformLayout
xgui.settings_tabs.PerformLayout = function( self )
	func( self )
	self.tabScroller:SetPos( 10, 0 )
	self.tabScroller:SetWide( 555 ) --Make the tabs smaller to accommodate for the X button at the top-right corner.
end

if autorefreshTab ~= nil then
	xgui.settings_tabs:SetActiveTab( autorefreshTab, true )
end

xgui.addModule( "Settings", settings, "icon16/wrench.png" )