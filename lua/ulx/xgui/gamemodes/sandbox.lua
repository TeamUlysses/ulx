--Sandbox settings module for ULX GUI -- by Stickly Man!
--Defines sbox cvar limits and sandbox specific settings for the sandbox gamemode.

xgui.prepareDataType( "sboxlimits" )
local sbox_settings = xlib.makepanel{ parent=xgui.null }

xlib.makecheckbox{ x=10, y=10, label="Enable Noclip", repconvar="rep_sbox_noclip", parent=sbox_settings }
xlib.makecheckbox{ x=10, y=30, label="Enable Godmode", repconvar="rep_sbox_godmode", parent=sbox_settings }
xlib.makecheckbox{ x=10, y=50, label="Enable PvP Damage", repconvar="rep_sbox_playershurtplayers", parent=sbox_settings }
xlib.makecheckbox{ x=10, y=70, label="Spawn With Weapons", repconvar="rep_sbox_weapons", parent=sbox_settings }
xlib.makecheckbox{ x=10, y=90, label="Limited Physgun", repconvar="rep_physgun_limited", parent=sbox_settings }

xlib.makecheckbox{ x=10, y=130, label="Persist Props", repconvar="rep_sbox_persist", parent=sbox_settings }
xlib.makecheckbox{ x=10, y=150, label="Bone Manip. Misc", repconvar="rep_sbox_bonemanip_misc", parent=sbox_settings }
xlib.makecheckbox{ x=10, y=170, label="Bone Manip. NPC", repconvar="rep_sbox_bonemanip_npc", parent=sbox_settings }
xlib.makecheckbox{ x=10, y=190, label="Bone Manip. Player", repconvar="rep_sbox_bonemanip_player", parent=sbox_settings }

xlib.makelabel{ x=5, y=247, w=140, wordwrap=true, label="NOTE: The non-ulx cvars configurable in XGUI are provided for easy access only and DO NOT SAVE when the server is shut down or crashes.", parent=sbox_settings }
sbox_settings.plist = xlib.makelistlayout{ x=140, y=5, h=322, w=440, spacing=1, padding=2, parent=sbox_settings }

function sbox_settings.processLimits()
	sbox_settings.plist:Clear()
	for g, limits in ipairs( xgui.data.sboxlimits ) do
		if #limits > 0 then
			local panel = xlib.makepanel{ h=5+math.ceil( #limits/2 )*25 }
			local i=0
			for _, cvar in ipairs( limits ) do
				local cvardata = string.Explode( " ", cvar ) --Split the cvarname and max slider value number
				xgui.queueFunctionCall( xlib.makeslider, "sboxlimits", { x=10+(i%2*205), y=5+math.floor(i/2)*25, w=200, label="Max " .. cvardata[1]:sub(9), min=0, max=cvardata[2], repconvar="rep_"..cvardata[1], parent=panel, fixclip=true } )
				i = i + 1
			end
			sbox_settings.plist:Add( xlib.makecat{ label=limits.title .. " (" .. #limits .. " limit" .. ((#limits > 1) and "s" or "") .. ")", contents=panel, expanded=( g==1 ) } )
		end
	end
end
sbox_settings.processLimits()

xgui.hookEvent( "sboxlimits", "process", sbox_settings.processLimits, "sandboxProcessLimits" )
xgui.addSettingModule( "Sandbox", sbox_settings, "icon16/box.png", "xgui_gmsettings" )
