--Sandbox settings module for ULX GUI -- by Stickly Man!
--Defines sbox cvar limits and sandbox specific settings for the sandbox gamemode.

xgui.prepareDataType( "sboxlimits" )
local sbox_settings = xlib.makepanel{ parent=xgui.null }

local sidepanel = xlib.makescrollpanel{ x=5, y=5, w=160, h=322, spacing=4, parent=sbox_settings }
xlib.makecheckbox{ dock=TOP, dockmargin={0,0,0,0}, label="Give weapons on spawn", convar=xlib.ifListenHost("sbox_weapons"), repconvar=xlib.ifNotListenHost("rep_sbox_weapons"), parent=sidepanel }
xlib.makecheckbox{ dock=TOP, dockmargin={0,5,0,0}, label="Players have god mode", convar=xlib.ifListenHost("sbox_godmode"), repconvar=xlib.ifNotListenHost("rep_sbox_godmode"), parent=sidepanel }

xlib.makecheckbox{ dock=TOP, dockmargin={0,20,0,0}, label="Allow PvP", convar=xlib.ifListenHost("sbox_playershurtplayers"), repconvar=xlib.ifNotListenHost("rep_sbox_playershurtplayers"), parent=sidepanel }
xlib.makecheckbox{ dock=TOP, dockmargin={0,5,0,0}, label="Allow noclip", convar=xlib.ifListenHost("sbox_noclip"), repconvar=xlib.ifNotListenHost("rep_sbox_noclip"), parent=sidepanel }
xlib.makecheckbox{ dock=TOP, dockmargin={0,5,0,0}, label="Bone manip. NPCs", convar=xlib.ifListenHost("sbox_bonemanip_npc"), repconvar=xlib.ifNotListenHost("rep_sbox_bonemanip_npc"), parent=sidepanel }
xlib.makecheckbox{ dock=TOP, dockmargin={0,5,0,0}, label="Bone manip. players", convar=xlib.ifListenHost("sbox_bonemanip_player"), repconvar=xlib.ifNotListenHost("rep_sbox_bonemanip_player"), parent=sidepanel }
xlib.makecheckbox{ dock=TOP, dockmargin={0,5,0,0}, label="Bone manip. everything", convar=xlib.ifListenHost("sbox_bonemanip_misc"), repconvar=xlib.ifNotListenHost("rep_sbox_bonemanip_misc"), parent=sidepanel }

xlib.makecheckbox{ dock=TOP, dockmargin={0,20,0,0}, label="Limited physgun", convar=xlib.ifListenHost("physgun_limited"), repconvar=xlib.ifNotListenHost("rep_physgun_limited"), parent=sidepanel }
xlib.makelabel{ dock=TOP, dockmargin={0,5,0,0}, label="Max beam range", parent=sidepanel }
xlib.makeslider{ dock=TOP, dockmargin={0,2,5,0}, label="<--->", w=125, min=128, max=8192, convar=xlib.ifListenHost("physgun_maxrange"), repconvar=xlib.ifNotListenHost("rep_physgun_maxrange"), parent=sidepanel, fixclip=true }
xlib.makelabel{ dock=TOP, dockmargin={0,5,0,0}, label="Teleport Distance", parent=sidepanel }
xlib.makeslider{ dock=TOP, dockmargin={0,2,5,0}, label="<--->", w=125, min=0, max=10000, convar=xlib.ifListenHost("physgun_teleportDistance"), repconvar=xlib.ifNotListenHost("rep_physgun_teleportDistance"), parent=sidepanel, fixclip=true  }
xlib.makelabel{ dock=TOP, dockmargin={0,5,0,0}, label="Max Prop Speed", parent=sidepanel }
xlib.makeslider{ dock=TOP, dockmargin={0,2,5,0}, label="<--->", w=125, min=0, max=10000, convar=xlib.ifListenHost("physgun_maxSpeed"), repconvar=xlib.ifNotListenHost("rep_physgun_maxSpeed"), parent=sidepanel, fixclip=true }
xlib.makelabel{ dock=TOP, dockmargin={0,5,0,0}, label="Max Angular Speed", parent=sidepanel }
xlib.makeslider{ dock=TOP, dockmargin={0,2,5,0}, label="<--->", w=125, min=0, max=10000, convar=xlib.ifListenHost("physgun_maxAngular"), repconvar=xlib.ifNotListenHost("rep_physgun_maxAngular"), parent=sidepanel, fixclip=true }
xlib.makelabel{ dock=TOP, dockmargin={0,5,0,0}, label="Time To Arrive", parent=sidepanel }
xlib.makeslider{ dock=TOP, dockmargin={0,2,5,0}, label="<--->", w=125, min=0, max=2, decimal=2, convar=xlib.ifListenHost("physgun_timeToArrive"), repconvar=xlib.ifNotListenHost("rep_physgun_timeToArrive"), parent=sidepanel, fixclip=true }
xlib.makelabel{ dock=TOP, dockmargin={0,5,0,0}, label="Time To Arrive (Ragdolls)", parent=sidepanel }
xlib.makeslider{ dock=TOP, dockmargin={0,2,5,0}, label="<--->", w=125, min=0, max=2, decimal=2, convar=xlib.ifListenHost("physgun_timeToArriveRagdoll"), repconvar=xlib.ifNotListenHost("rep_physgun_timeToArriveRagdoll"), parent=sidepanel, fixclip=true }

xlib.makelabel{ dock=TOP, dockmargin={0,20,0,0}, w=138, label="Persistence file:", parent=sidepanel }
xlib.maketextbox{ h=25, dock=TOP, dockmargin={0,5,5,0}, label="Persist Props", convar=xlib.ifListenHost("sbox_persist"), repconvar=xlib.ifNotListenHost("rep_sbox_persist"), parent=sidepanel }

xlib.makelabel{ dock=TOP, dockmargin={0,20,0,0}, w=138, wordwrap=true, label="NOTE: Sandbox settings are provided for convience and are not saved after the server restarts or crashes.", parent=sidepanel }

sbox_settings.plist = xlib.makelistlayout{ x=170, y=5, h=322, w=410, spacing=1, padding=2, parent=sbox_settings }

function sbox_settings.processLimits()
	sbox_settings.plist:Clear()
	for g, limits in ipairs( xgui.data.sboxlimits ) do
		if #limits > 0 then
			local panel = xlib.makepanel{ dockpadding={ 0,0,0,5 } }
			local i=0
			for _, cvar in ipairs( limits ) do
				local cvardata = string.Explode( " ", cvar ) --Split the cvarname and max slider value number
				xgui.queueFunctionCall( xlib.makelabel, "sboxlimits", { x=10+(i%2*195), y=5+math.floor(i/2)*40, w=185, label="Max " .. cvardata[1]:sub(9), parent=panel } )
				xgui.queueFunctionCall( xlib.makeslider, "sboxlimits", { x=10+(i%2*195), y=20+math.floor(i/2)*40, w=185, label="<--->", min=0, max=cvardata[2], convar=xlib.ifListenHost(cvardata[1]), repconvar=xlib.ifNotListenHost("rep_"..cvardata[1]), parent=panel, fixclip=true } )
				i = i + 1
			end
			sbox_settings.plist:Add( xlib.makecat{ label=limits.title .. " (" .. #limits .. " limit" .. ((#limits > 1) and "s" or "") .. ")", contents=panel, expanded=( g==1 ) } )
		end
	end
end
sbox_settings.processLimits()

xgui.hookEvent( "sboxlimits", "process", sbox_settings.processLimits, "sandboxProcessLimits" )
xgui.addSettingModule( "Sandbox", sbox_settings, "icon16/box.png", "xgui_gmsettings" )
