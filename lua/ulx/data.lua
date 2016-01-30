-- This file populates the data folder. We can't just ship these files, because Steam Workshop disallows that.

local files = {}

files["adverts.txt"] =
[[; Here's where you put advertisements
;
; Whether an advertisement is a center advertisement (csay) or text box advertisement (tsay) is determined by
; whether or not the "time_on_screen" key is present. If it is present, it's a csay.
;
; The 'time' argument inside a center advertisement and the number following a chat advertisement are the
; time it takes between each showing of this advertisement in seconds. Set it to 300 and the advertisement
; will show every five minutes.
;
; If you want to make it so that one advertisement is shown and then will always be followed by another,
; put them in a table. For example, if you add the following to the bottom of the file, A will always show
; first followed by B.
; "my_group"
; {
;     {
;         "text" "Advertisement A"
;         "time" "200"
;     }
;     {
;         "text" "Advertisement B"
;         "time" "300"
;     }
; }

{
	"text" "You're playing on %host%, enjoy your stay!"
	"red" "100"
	"green" "255"
	"blue" "200"
	"time_on_screen" "10"
	"time" "300"
}
{
	"text" "This server is running ULX Admin Mod %ulx_version% by Team Ulysses from ulyssesmod.net"
	"time" "635"
}
]]

files["banmessage.txt"] = [[
; Possible variables here are as follows:
; {{BANNED_BY}} - The person (and steamid) who initiated the ban
; {{BAN_START}} - The date/time of the ban, in the server's time zone
; {{REASON}} - The ban reason
; {{TIME_LEFT}} - The time left in the ban
; {{STEAMID}} - The banned player's Steam ID (excluding non-number characters)
; {{STEAMID64}} - The banned player's 64-bit Steam ID
; The two steam ID vairables are useful for constructing URLs for appealing bans
-------===== [ BANNED ] =====-------

---= Reason =---
{{REASON}}

---= Time Left =---
{{TIME_LEFT}}
]]


files["banreasons.txt"] =
[[; This file is used to store default reasons for kicking and banning users.
; These reasons show up in console autocomplete and in XGUI dropdowns.
Spammer
Crashed server
Minge
Griefer
Foul language
Disobeying the rules
]]

files["config.txt"] =
[[;Any of the settings in here can be added to the per-map or per-gamemode configs.
;To add per-map and per-gamemode configs, create data/ulx/maps/<mapname>/config.txt
;and data/ulx/gamemodes/<gamemodename>/config.txt files. This can also be done for
;All other configuration files (adverts.txt, downloads.txt, gimps.txt, votemaps.txt)
;All configurations add to each other except gimps and votemaps, which takes the most
;specific config only.
;Any line starting with a ';' is a comment!

ulx showMotd 2 ; MOTD mode
; MOTD modes:
; 0 - OFF No MOTD shown
; 1 - FILE Show the players the contents of the file from the 'motdfile' cvar
; 2 - GENERATOR Uses the MOTD generator to create a MOTD for the player (use XGUI for this)
; 3 - URL Show the player the URL specified by the 'motdurl' cvar
; In a URL, you can use %curmap% and %steamid% in the URL to have it automagically parsed for you (eg, server.com/?map=%curmap%&id=%steamid%).
ulx motdfile ulx_motd.txt ; The MOTD to show, if using a file. Put this file in the root of the garry's mod directory.
ulx motdurl ulyssesmod.net ; The MOTD to show, if using a URL.


ulx chattime 0 ; Players can only chat every x seconds (anti-spam). 0 to disable
ulx meChatEnabled 1 ; Allow players to use '/me' in chat. 0 = Disabled, 1 = Sandbox only (Default), 2 = Enabled


; This is what the players will see when they join, set it to "" to disable.
; You can use %host% and %curmap% in your text and have it automagically parsed for you
ulx welcomemessage "Welcome to %host%! We're playing %curmap%."


ulx logFile 1 ; Log to file (Can still echo if off). This is a global setting, nothing will be logged to file with this off.
ulx logEvents 1 ; Log events (player connect, disconnect, death)
ulx logChat 1 ; Log player chat
ulx logSpawns 1 ; Log when players spawn objects (props, effects, etc)
ulx logSpawnsEcho 1 ; Echo spawns to players in server. -1 = Off, 0 = Dedicated console only, 1 = Admins only, 2 = All players. (Echoes to console)
ulx logJoinLeaveEcho 1 ; Echo players leaves and joins to admins in the server (useful for banning minges)
ulx logDir "ulx_logs" ; The log dir under garrysmod/data
ulx logEcho 1 ; Echo mode
; Echo modes:
; 0 - OFF No output to any players when an admin command is used
; 1 - ANONYMOUS Output to players without access to see who used the command (admins by default) similar to "(Someone) slapped Bob with 0 damage"
; 2 - FULL Output to players similar to "Foo slapped Bob with 0 damage"

ulx logEchoColors 1 ; Whether or not echoed commands in chat are colored
ulx logEchoColorDefault "151 211 255" ; The default text color (RGB)
ulx logEchoColorConsole "0 0 0" ; The color that Console gets when using actions
ulx logEchoColorSelf "75 0 130" ; The color for yourself in echoes
ulx logEchoColorEveryone "0 128 128" ; The color to use when everyone is targeted in echoes
ulx logEchoColorPlayerAsGroup 1 ; Whether or not to use group colors for players. If false, it uses the color below.
ulx logEchoColorPlayer "255 255 0" ; The color to use for players when ulx logEchoColorPlayerAsGroup is set to 0.
ulx logEchoColorMisc "0 255 0" ; The color for anything else in echoes

ulx rslotsMode 0
ulx rslots 2
ulx rslotsVisible 1 ; When this is 0, sv_visiblemaxplayers will be set to maxplayers - slots_currently_reserved
;Modes:
;0 - Off
;1 - Keep # of slots reserved for admins, admins fill slots.
;2 - Keep # of slots reserved for admins, admins don't fill slots, they'll be freed when a player leaves.
;3 - Always keep 1 slot open for admins, kick the user with the shortest connection time if an admin joins.

;Difference between 1 and 2:
;I realize it's a bit confusing, so here's an example.
;On mode 1--
;	You have maxplayers set to 10, rslots set to 2, and there are currently 8 non-admins connected.
;	If a non-admin tries to join, they'll be kicked to keep the reserved slots open. Two admins join
;	and fill the two reserved slots. When non-admins leave, the two admins will still be filling the
;	two reserved slots, so another regular player can join and fill the server up again without being
;	kicked by the slots system

;On mode 2--
;	Same setup as mode 1, you have the two admins in the server and the server is full. Now, when a
;	non-admin leaves the server, reserved slots will pick up the slot again as reserved. If a regular
;	player tries to join and fill the server again, even though there are two admins connected, it will
;	kick the regular player to keep the slot open

;So, the basic difference between these two is mode 1 will subtract currently connected admins from the slot
;pool, while mode 2 while always be attempting to reclaim slots if it doesn't currently have enough when
;players leave no matter how many admins are connected.

;rslotsVisible:
;	If you set this variable to 0, ULX will automatically change sv_visiblemaxplayers for you so that if
;	there are no regular player slots available in your server, it will appear that the server is full.
;	The major downside to this is that admins can't connect to the server using the "find server" dialog
;	when it appears full. Instead, they have to go to console and use the command "connect <ip>".
;	NOTE THIS DOES NOT CHANGE YOUR MAXPLAYERS VARIABLE, ONLY HOW MANY MAXPLAYERS IT _LOOKS_ LIKE YOUR
;	SERVER HAS. YOU CAN NEVER, EVER HAVE MORE PLAYERS IN YOUR SERVER THAN THE MAXPLAYERS VARIABLE.



ulx votemapEnabled 1 ; Enable/Disable the entire votemap command
ulx votemapMintime 10 ; Time after map change before votes count.
ulx votemapWaittime 5 ; Time before a user must wait before they can change their vote.
ulx votemapSuccessratio 0.4 ; Ratio of (votes for map)/(total players) needed to change map. (Rounds up)
ulx votemapMinvotes 3 ; Number of minimum votes needed to change map (Prevents llamas). This supercedes the above convar on small servers.
ulx votemapVetotime 30 ; Time in seconds an admin has after a successful votemap to veto the vote. Set to 0 to disable.
ulx votemapMapmode 1 ; 1 = Use all maps but what's specified in votemaps.txt, 2 = Use only the maps specified in votemaps.txt.

ulx voteEcho 0 ; 1 = Echo what every player votes (this does not apply to votemap). 0 = Don't echo

ulx votemap2Successratio 0.5 ; Ratio of (votes for map)/(total players) needed to change map. (Rounds up)
ulx votemap2Minvotes 3 ; Number of minimum votes needed to change map (Pevents llamas). This supercedes the above convar on small servers.

ulx votekickSuccessratio 0.6 ; Ratio of (votes for kick)/(total players) needed to kick player. (Rounds up)
ulx votekickMinvotes 2 ; Number of minimum votes needed to kick player (Pevents llamas). This supercedes the above convar on small servers.

ulx votebanSuccessratio 0.7 ; Ratio of (votes for ban)/(total players) needed to ban player. (Rounds up)
ulx votebanMinvotes 3 ; Number of minimum votes needed to ban player (Pevents llamas). This supercedes the above convar on small servers.
]]

files["downloads.txt"] =
[[; You can add forced downloads here. Add as many as you want, one file or
; folder per line. You can also add these to your map- or game-specific files.
; You can add a folder to add all files inside that folder recursively.
; Any line starting with ';' is a comment and WILL NOT be processed!!!
; Examples:
;sound/cheeseman.mp3 <-- Adds the file 'cheeseman.mp3' under the sound folder
;sound/my_music <-- Adds all files within the my_music folder, inside the sound folder
]]

files["gimps.txt"] =
[[; Add gimp says in this file, one per line.
; Any line starting with a ';' is a comment
I'm a llama.
How do you fly?
baaaaaaaaaah.
Llama power!
Llamas are the coolest!
What's that gun to move stuff?
I'm a soulless approximation of a cheese danish!
Hold up guys, I'm watching The Powerpuff Girls.
Not yet, I'm being attacked by an... OH CRAP!
]]

files["sbox_limits.txt"] =
[[;The number by each cvar indicates the maximum value for the slider in XGUI.
|Sandbox
sbox_maxballoons 100
sbox_maxbuttons 200
sbox_maxdynamite 75
sbox_maxeffects 200
sbox_maxemitters 100
sbox_maxhoverballs 200
sbox_maxlamps 50
sbox_maxlights 50
sbox_maxnpcs 50
sbox_maxprops 1000
sbox_maxragdolls 50
sbox_maxsents 1024
sbox_maxspawners 50
sbox_maxthrusters 200
sbox_maxturrets 50
sbox_maxvehicles 50
sbox_maxwheels 200
|Other
sbox_maxdoors 100
sbox_maxhoverboards 10
sbox_maxkeypads 100
sbox_maxwire_keypads 100
sbox_maxpylons 100
|Wire
sbox_maxwire_addressbuss 100
sbox_maxwire_adv_emarkers 50
sbox_maxwire_adv_inputs 100
sbox_maxwire_buttons 100
sbox_maxwire_cameracontrollers 100
sbox_maxwire_cd_disks 100
sbox_maxwire_cd_locks 100
sbox_maxwire_cd_rays 100
sbox_maxwire_clutchs 10
sbox_maxwire_colorers 100
sbox_maxwire_consolescreens 100
sbox_maxwire_cpus 10
sbox_maxwire_damage_detectors 50
sbox_maxwire_data_satellitedishs 100
sbox_maxwire_data_stores 100
sbox_maxwire_data_transferers 100
sbox_maxwire_dataplugs 100
sbox_maxwire_dataports 100
sbox_maxwire_datarates 100
sbox_maxwire_datasockets 100
sbox_maxwire_deployers 5
sbox_maxwire_detonators 100
sbox_maxwire_dhdds 100
sbox_maxwire_digitalscreens 100
sbox_maxwire_dual_inputs 100
sbox_maxwire_dynamic_buttons 100
sbox_maxwire_egps 10
sbox_maxwire_emarkers 30
sbox_maxwire_exit_points 10
sbox_maxwire_explosives 50
sbox_maxwire_expressions 100
sbox_maxwire_extbuss 100
sbox_maxwire_eyepods 15
sbox_maxwire_forcers 100
sbox_maxwire_freezers 50
sbox_maxwire_fx_emitters 100
sbox_maxwire_gate_angles 30
sbox_maxwire_gate_arithmetics 30
sbox_maxwire_gate_arrays 30
sbox_maxwire_gate_bitwises 30
sbox_maxwire_gate_comparisons 30
sbox_maxwire_gate_entitys 30
sbox_maxwire_gate_logics 30
sbox_maxwire_gate_memorys 30
sbox_maxwire_gate_rangers 30
sbox_maxwire_gate_selections 30
sbox_maxwire_gate_strings 30
sbox_maxwire_gate_times 30
sbox_maxwire_gate_trigs 30
sbox_maxwire_gate_vectors 30
sbox_maxwire_gates 30
sbox_maxwire_gimbals 10
sbox_maxwire_gpss 50
sbox_maxwire_gpus 10
sbox_maxwire_grabbers 100
sbox_maxwire_graphics_tablets 100
sbox_maxwire_gyroscopes 50
sbox_maxwire_hdds 100
sbox_maxwire_holoemitters 50
sbox_maxwire_hologrids 100
sbox_maxwire_hoverballs 30
sbox_maxwire_hoverdrivecontrolers 5
sbox_maxwire_hudindicators 100
sbox_maxwire_hydraulics 16
sbox_maxwire_igniters 100
sbox_maxwire_indicators 100
sbox_maxwire_inputs 100
sbox_maxwire_keyboards 100
sbox_maxwire_keypads 50
sbox_maxwire_lamps 50
sbox_maxwire_las_receivers 100
sbox_maxwire_latchs 15
sbox_maxwire_levers 50
sbox_maxwire_lights 10
sbox_maxwire_locators 30
sbox_maxwire_motors 50
sbox_maxwire_nailers 100
sbox_maxwire_numpads 100
sbox_maxwire_oscilloscopes 100
sbox_maxwire_outputs 50
sbox_maxwire_pixels 100
sbox_maxwire_plugs 100
sbox_maxwire_pods 100
sbox_maxwire_radios 100
sbox_maxwire_rangers 50
sbox_maxwire_relays 100
sbox_maxwire_screens 100
sbox_maxwire_sensors 100
sbox_maxwire_simple_explosives 100
sbox_maxwire_sockets 100
sbox_maxwire_soundemitters 50
sbox_maxwire_spawners 50
sbox_maxwire_speedometers 50
sbox_maxwire_spus 10
sbox_maxwire_target_finders 100
sbox_maxwire_textreceivers 50
sbox_maxwire_textscreens 100
sbox_maxwire_thrusters 50
sbox_maxwire_trails 100
sbox_maxwire_turrets 100
sbox_maxwire_twoway_radios 100
sbox_maxwire_users 100
sbox_maxwire_values 100
sbox_maxwire_vectorthrusters 50
sbox_maxwire_vehicles 100
sbox_maxwire_watersensors 100
sbox_maxwire_waypoints 30
sbox_maxwire_weights 100
sbox_maxwire_wheels 30
]]

files["votemaps.txt"] =
[[; List of maps that are either included in the votemap command or excluded from it
; Make sure to set votemapMapmode in config.txt to what you want.
background01
background02
background03
background04
background05
background06
background07
credits
intro
test_hardware
test_speakers
]]

files["motd.txt"] =
[[; These settings describe the default configuration and text to be shown on the MOTD. This only applies if ulx showMotd is set to 1.
; All style configuration is set, and the values must be valid CSS.
; Under info, you may have as many sections as you like. Valid types include "text", "ordered_list", "list".
; Special type "mods" will automatically list workshop and regular addons in an unordered list.
; Special type "admins" will automatically list all users within the groups specified in contents.
; For an example of all of these items, please see the default file generated in ulx\lua\data.lua

"info"
{
	"description" "Welcome to our server. Enjoy your stay!"
	{
		"title" "About This Server"
		"type" "text"
		"contents"
		{
			"This server is running ULX."
			"To edit this default MOTD, open XGUI->Settings->Server->ULX MOTD, or edit data\ulx\motd.txt."
		}
	}
	{
		"title" "Rules"
		"type" "ordered_list"
		"contents"
		{
			"DON'T MESS WITH OTHER PLAYERS' STUFF. If they want help, they'll ask!"
			"Don't spam."
			"Have fun."
		}
	}
	{
		"title" "Reporting Rulebreakers"
		"type" "list"
		"contents"
		{
			"Contact an available admin on this server and let them know."
			"Use @ before typing a chat message to send it to admins."
			"If no admin is available, note the players name and the current time, then let an admin know as soon as they are available."
		}
	}
	{
		"title" "Installed Addons"
		"type" "mods"
	}
	{
		"title" "Our Admins"
		"type" "admins"
		"contents"
		{
			"superadmin"
			"admin"
		}
	}
}
"style"
{
	"borders"
	{
		"border_color" "#000000"
		"border_thickness" "2px"
	}
	"colors"
	{
		"background_color" "#dddddd"
		"header_color" "#82a0c8"
		"header_text_color" "#ffffff"
		"section_text_color" "#000000"
		"text_color" "#000000"
	}
	"fonts"
	{
		"server_name"
		{
			"family" "Impact"
			"size" "32px"
			"weight" "normal"
		}
		"subtitle"
		{
			"family" "Impact"
			"size" "20px"
			"weight" "normal"
		}
		"section_title"
		{
			"family" "Impact"
			"size" "26px"
			"weight" "normal"
		}
		"regular"
		{
			"family" "Tahoma"
			"size" "12px"
			"weight" "normal"
		}
	}
}
]]

ULib.fileCreateDir( "data/ulx" ) -- This is ignored if the folder already exists
for filename, content in pairs( files ) do
	local filepath = "data/ulx/" .. filename
	if not ULib.fileExists( filepath, true ) then
		ULib.fileWrite( filepath, content )
	end
end
files = nil -- Cleanup
