Title: ULX Readme

__ULX__
Version 3.61

*ULX v3.61 (released 00/00/00)*

ULX is an admin mod for GMod (<http://garrysmod.com/>).

ULX offers server admins an AMXX-style support. It allows multiple admins with different access levels on the same server.
It has features from basic kick, ban, and slay to fancier commands such as blind, freeze, voting, and more.

Visit our homepage at <http://ulyssesmod.net/>.

You can talk to us on our forums at <http://forums.ulyssesmod.net/>

Group: Author

ULX is brought to you by..

* Brett "Megiddo" Smith - Contact: <megiddo@ulyssesmod.net>
* JamminR - Contact: <jamminr@ulyssesmod.net>
* Stickly Man! - Contact: <sticklyman@ulyssesmod.net>

Group: Requirements

ULX requires the latest ULib to be installed on the server. You can get ULib from the ULX homepage.

Group: Installation

To install ULX, simply extract the files from the archive to your garrysmod/addons folder.
When you've done this, you should have a file structure like this--
<garrysmod>/addons/ulx/lua/ULib/modules/ulx_init.lua
<garrysmod>/addons/ulx/lua/ulx/modules/fun.lua
etc..

Note that installation for dedicated servers is EXACTLY the same!

You absolutely, positively have to do a full server restart after installing the files. A simple map
change will not cut it!

Group: Usage

To use ULX, simply type in whatever command or cvar you want to use. If you're not running a listen server,
or if you want to give access to other users, you must add users.

You can either follow the standard GM10 way of adding users
(http://wiki.garrysmod.com/?title=Player_Groups), or you can add yourself directly to the
data/ULib/users.txt file. DO NOT EDIT THE ULIB FILE UNLESS YOU KNOW WHAT YOU'RE DOING.

A word about superadmins: Superadmins are considered the highest usergroup. They have access to all the
commands in ULX, override other user's immunity, and are shown otherwise hidden log messages (IE, shown
rcon commands admins are running, when they spectate others). Superadmins also have the power to give and
revoke access to commands using userallow and userdeny (though they can't use this command on eachother).

All commands are now preceded by "ulx ". Type "ulx help" in a console without the quotes for help.
This is different from ulx v1 where commands were preceded by "ulx_".

__To give yourself a jump start into ulx, simply remember the commands "ulx help" and "ulx menu". You can
also access the menu by saying "!menu".__

Check out the configs folder in ulx for some more goodies.

Group: Changelog
v3.61 - *(00/00/00)*
	* [FIX] XGUI: Infobar text no longer displaying.
	* [FIX] XGUI: Error caused when closing the fban window after the targeted player has left the server (Thanks nathan736).
	* [FIX] "#" (Pound signs) removing content in ulx asay (Thanks bener180).
	* [CHANGE] Jail models. The jail is slightly bigger and can't be shot through anymore (Thanks Mors-Quaedam).

v3.60 - *(01/27/13)*
	* [ADD] "ulx jailtp" - A combination of tp <player> and jail <player> (Thanks HellFox).
	* [ADD] "ulx resettodefaults" - Resets ULX and ULib config to defaults.
	* [ADD] XGUI: Added ability to edit lower-level restrictions from a higher-level group.
	* [CHANGE] ULX ban now supports restricting of time/string formats.
	* [CHANGE] !teleport chat command is now also aliased as !tp.
	* [CHANGE] XGUI: Utilizes ULib's more robust ID Targeting system.
	* [CHANGE] XGUI: Controls added to utilize time/string formats and restrictions.
	* [CHANGE] XGUI: No longer duplicates ULX replicated cvars (ulx_cl_) due to ULib changes. Uses the regular ulx_ cvars directly.
	* [CHANGE] XGUI: Supports new values for sv_alltalk.
	* [CHANGE] XGUI: A few changes to update look and feel. Matches Derma/GWEN skin colors better in some areas.
	* [CHANGE] XGUI: No longer retrieves sandbox limits from the web. Included with download.
	* [FIX] Garry breakages in GM13.
	* [FIX] An exclusivity bug in "ulx freeze" (Thanks infinitywraith).
	* [FIX] A console bug when trying to ulx teleport another player (Thanks infinitywraith).
	* [FIX] "ulx gimp" not obeying chat anti-spam (Thanks ruok2bu).
	* [FIX] "ulx userdeny" not logging properly in some cases.
	* [FIX] An echo incorrectly going to all users for "ulx votekick" (Thanks JackYack13).
	* [FIX] Module cross-contamination in end.lua (Thanks Pon-3).
	* [FIX] Team vs public chat doing the opposite of what it should for logs and "/me" actions. Wonder how long ago Garry needlessly changed that API without us noticing.
	* [FIX] Promotion bug after using "ulx userallow" on a regular user. (Thanks JackYack13).
	* [FIX] Server crash when jail is placed inside trigger_remove brush. (Thanks HellFox).
	* [FIX] XGUI: Changed startup code to initialize faster, handle strange server load scenarios better.
	* [FIX] XGUI: BoolArgs in the Cmds tab now obey restrictions.

v3.54 - *(04/27/12)*
	* [FIX] XGUI: Hard crash with the os.date function when bans have an extremely long unban time.

v3.53 - *(01/01/12)*
	* [FIX] Garry breakages.

v3.52 - *(09/22/11)*
	* [ADD] Support for "time strings" in ulx ban and ulx banid. EG, "5w4d3h2" would ban for 5 weeks, 4 days, 3 hours, 2 minutes (Thanks lavacano201014).
	* [ADD] XGUI: New customization options-- You can now change XGUI's position and the open/close animations.
	* [ADD] XGUI: Double-click a player on the commands tab to execute the command with the parameters on the right.
	* [ADD] XLIB: Additional layout for xlib.makecolorpicker with alphabar.
	* [FIX] No longer able to make a player invincible by freezing then mauling.
	* [FIX] XGUI: Selected svsetting/clsetting modules no longer close when XGUI modules get reprocessed.
	* [FIX] XGUI: Error caused when a bans unban time was changed, causing the ban to expire.
	* [FIX] XGUI: Adding details to SBans would throw an error on server, wouldn't refresh on clients properly.
	* [FIX] XGUI: Expired bans were not removing themselves from the client lists.
	* [FIX] XGUI: Somehow managed to duplicate the entire bans module code within the same file. X|
	* [FIX] XGUI: Rare error causing votemap settings to not load properly (which was previously fixable after a mapchange)
	* [FIX] XGUI: Non-harmful Lua error occuring during data transfer when running XGUI on a non-sandbox game mode. (Thanks Synergy Connections!)
	* [FIX] XGUI: The button for scrolling through tab names of settings modules (if there were too many) was being obscured by the close button. (Thanks [eVo]Lead4u!)
	* [FIX] XGUI: UTeam information would be lost when changing UTeam settings on non sandbox-derived gamemodes
	* [FIX] XGUI: DNumberWangs on color panels being extra long (due to garry update?)
	* [FIX] XGUI: ULib team data not sent after making changes to teams.
	* [FIX] XGUI: Users in the groups tab were not being updated when a group was removed and users in that group were moved to a new group.
	* [FIX] XGUI: Issue where a group's team wasn't getting unassigned when the unassigned team had no more groups associated with it.
	* [FIX] XGUI: Players' UTeam parameters update properly when their group is changed by addons that call ULib's addUser/removeUser functions directly.
	* [FIX] XGUI: In the groups menu, when selecting a player and clicking "change", the list of groups was not in inherited-based order.
	* [FIX] XGUI: Users table was pointlessly being sent when a groups inheritance was changed.
	* [CHANGE] "ulx gag" uses a slightly more robust method of gagging now.
	* [CHANGE] Using file.Append for logging now that it's available to us.
	* [CHANGE] XGUI: "XGUI module" is now the "Clientside Settings Module", which contains the XGUI settings.
	* [CHANGE] XGUI: Optimized sending of ULib users data-- Only sends the data when it needs to (no longer on UCLChanged), and when changed, only sends the updated info.
	* [CHANGE] XGUI: Optimized client-side processing of users data, how often it updated, and lowered priority of users data processing.
	* [CHANGE] XGUI: Added a data chunksize to users to help alleviate some major lag issues on servers with large users lists.
	* [CHANGE] XGUI: The Groups module shows some useful stuff in the event that it wasn't able to grab data from the server.
	* [CHANGE] XGUI: Modifying UTeam settings is now disabled on non sandbox-derived gamemodes.
	* [CHANGE] XGUI: Serverside xgui.removeData much more more robust.
	* [REMOVE] XGUI: xgui_oldcheck.lua (No longer checks for a pre-svn version of XGUI installed.)

v3.51 - *(05/14/11)*
	* [FIX] XGUI: Votemaps and kick/ban reasons not getting refreshed properly.
	* [FIX] XGUI: Ban menu was incorrectly visible to everyone.

v3.50 - *(05/13/11)*
	* [ADD] Autocomplete to ulx playsound.
	* [ADD] Hook, "ULXLoaded".
	* [ADD] Documentation for new keywords to "ulx help". Keywords for target self, target group, target picker, and negate.
	* [ADD] Ability to specify a URL in "ulx showMotd" to show a URL.
	* [ADD] ulx removeuserid, userallowid, userdenyid.
	* [ADD] Integrated UTeam.
	* [ADD] Colored action echoes.
	* [ADD] ulx logJoinLeaveEchoes to echo player steamid's to admins when players join and leave.
	* [FIX] Problem when ulx votemapMintime or votemapWaittime was more than 59 minutes (Thanks Stickly Man!).
	* [FIX] Improved error checking on "ulx ent" (Thanks Python1320).
	* [FIX] Error when running "ulx whip" from dedicated console (Thanks AtomicSpark).
	* [FIX] Can no longer use "ulx motd" if the server has motd disabled, made it so you can change "ulx showMotd" on-the-fly (Thanks AtomicSpark).
	* [FIX] "ulx groupallow" error when used from outside the server console (Thanks AtomicSpark).
	* [FIX] ULX done loading hook removal on listen servers (Thanks Stickly Man!).
	* [FIX] Fixed "ulx unspectate" not working in DarkRP (Thanks Ayran).
	* [FIX] Fixed "ulx unragdoll" not working in DarkRP (Thanks Ayran).
	* [FIX] Fixed an issue with dying while frozen (Thanks Stickly Man!).
	* [FIX] Can't repeatedly slay someone anymore.
	* [FIX] Can't attempt to ban a bot anymore (Thanks Stickly Man!).
	* [FIX] Asay being printed to console twice if the console used the command.
	* [FIX] Ragdolling a player with the Eli Vance model no longer throws an error (Thanks Insano-Man).
	* [FIX] Admin approval box timing out and not allowing any more votes to be taken (Thanks Rambomst).
	* [FIX] Various garry breakages.
	* [FIX] A bug with ulx whip where a timer would never be removed if the player left during whipping.
	* [FIX] Can no longer ragdoll a dead person (Thanks RiftNinja).
	* [FIX] Jails are much more robust (if you get out, it puts you back, and you can't get physgunned out) (Thanks RiftNinja).
	* [FIX] Can no longer slay frozen players (Thanks RiftNinja).
	* [FIX] Can no longer whip or slap frozen players, and freezing a whipped player stops the whip (Thanks Stickly Man!).
	* [CHANGE] Usermanagement commands, ulx who, and various other functions to better take advantage of the new UCL system
	* [CHANGE] ulx ignite no longer spreads. Spreading messed up UPS protection.
	* [CHANGE] Lots of various accessibility changes for XGUI.
	* [CHANGE] Lowered priority of gimp check, you can now ungimp yourself while gimped.
	* [CHANGE] Replaced cvar implementation for XGUI. Uses replicated cvars now for easy menu access.
	* [CHANGE] Errors now show in red.
	* [CHANGE] "ulx ent" can now be undone using garry's undo system.
	* [CHANGE] Dropped requirement to read usermanagementhelp before using those commands.
	* [CHANGE] Player isn't allowed to suicide while in a lot of the different ulx-states now.
	* [CHANGE] Lots of changes to support new command system.
	* [CHANGE] Moved config system to data folder, separated out some of the configs to separate files.
	* [CHANGE] Shortened maul time considerably.
	* [CHANGE] Added ability to get the return of ulx luarun by using '=', IE "ulx luarun =2+2" (also handles tables!).
	* [CHANGE] Added uid to debuginfo.
	* [CHANGE] tsay and csay now log who used the command.
	* [CHANGE] Can specify '-1' to ulx logSpawnsEcho to disable echoing to dedicated console.
	* [CHANGE] ulx adduser will use your existing id you're currently authed by if it exists, instead of always using steam id.
	* [REMOVE] ulx ghost, I was never happy with it.
	* [REMOVE] Old menus, uses XGUI now.

v3.40 - *(06/20/09)*
	* [ADD] Alltalk to the admin menu
	* [FIX] Umsgs being sent too early in certain circumstances.
	* [FIX] The .ini files not loading properly on listen servers.
	* [FIX] Problems introduced by garry's changes in handling concommands
	* [FIX] Changed ULX_README.TXT file to point to proper instruction link for editing Gmod default users.
	* [FIX] Removed a patch for a garrysmod autocomplete bug that's now fixed.
	* [FIX] Maps not being sent correctly to the client.
	* [FIX] Can't create a vote twice anymore.
	* [FIX] A bug with loading the map list on listen server hosts.
	* [FIX] An unfreeze bug with the ulx jail walls.
	* [FIX] A caps bug with ulx adduserid.
	* [FIX] You can now unragdoll yourself even if a third party addon removes the ragdoll.
	* [FIX] Various formatting issues with ulx ban and ulx banid.
	* [CHANGE] ulx ragdoll and unragdoll now preserve angle and velocity.
	* [CHANGE] motdfile cvar now defaults to ulx_motd.txt. Sick of forcefully overriding other mod's motds. Renamed our motd to match.
	* [CHANGE] ulx slap, whip, hp to further prevent being "stuck in ground".
	* [CHANGE] Menus are derma'tized.
	* [CHANGE] Updated how it handles svn version information.

v3.31 - *(06/08/08)*
	* [ADD] ulx adduserid - Add a user by steam id (ie STEAM_0:1:1234...) (Does not actually verify user validity) (Thanks Mr.President)
	* [FIX] Garry's 1/29/08 update breaking MOTD.
	* [FIX] Links not working on MOTD.
	* [FIX] Bug where you'd be stuck if someone disconnected while you were spectating them.
	* [FIX] TF2 motd showing by default.
	* [FIX] The usual assortment of small fixes not worth mentioning.
	* [CHANGE] Unignite help command changed to be more standardized with other help.
	* [CHANGE] Help indicates that multiple users can now also be command targeted using an asterisk "*". (ULib change added this)
	* [CHANGE] Miscellaneous spelling corrections.
	* [CHANGE] ulx chattime so that if your chat doesn't go through it is not counted towards your time.
	* [CHANGE] Can no longer set hp or armor to less than 0.
	* [REMOVE] ulx mingekick, useless now.

v3.30 - *(01/26/08)*
	* [ADD] ulx strip - Strips player(s) weapons
	* [ADD] ulx armor - Sets player(s) armor
	* [ADD] We now log NPC spawns
	* [ADD] ulx unignite - Unignites individual player, <all> players, or <everything> Any entity/player on fire.
	* [FIX] ulx ban requiring a reason.
	* [FIX] Added some more sanity checks to ulx maul.
	* [FIX] The usual assortment of small fixes not worth mentioning.
	* [FIX] ulx usermanagementhelp erroring out.
	* [FIX] .ini's not loading for listen servers.
	* [FIX] Case sensitivity problem with addgroup and removegroup.
	* [FIX] ulx ent incorrectly requiring at least one flag.
	* [FIX] All command inputs involving numbers should now be sanitized.
	* [FIX] Autocomplete send in a multi-layer authentication environment (probably doesn't affect anyone)
	* [CHANGE] The 0-255 scale for "ulx cloak" has been reversed.
	* [CHANGE] Model paths in logging is now standardized (linux notation, single slashes)
	* [CHANGE] The user initiating a silent logged command still sees the echo, even if they don't have access to see it normally.
	* [CHANGE] Various misc things for new engine compatibility (IE, ulx clientmenu got a major change and other menu changes)
	* [CHANGE] Removed all timers dealing with initialization and now rely on flags from the client. This makes the ULX initialization much more dependable.
	* [CHANGE] Name change watching is now taken care of by ULib.
	* [CHANGE] Converted all calls from ULib.consoleCommand( "exec ..." ) to ULib.execFile() to avoid running into the block on "exec" without our module.


v3.20 - *(09/23/07)*
	* [ADD] ulx send - Allows admin to transport a player to another player (no more goto then bring!)
	* [ADD] ulx maul - Maul a player with fast zombies
	* [ADD] ulx gag - Silence individual player's microphone/sound input on voice enabled servers.
	* [ADD] New module system. It's now easier than ever to add, remove, or change ULX commands!
	* [ADD] ulx.addToMenu(). Use this function if you want a module to add something to any of the ULX menu.
	* [ADD] ulx debuginfo. Use this function to get information to give us when you're asking support questions.
	* [ADD] Votes now have a background behind them.
	* [ADD] ulx voteEcho. A config option to enable echo of votes. Does not apply to votemap.
	* [ADD] Maps menu now has option for gamemode.
	* [ADD] Ban menu to view and remove bans.
	* [ADD] ulx removeruser, addgroup, removegroup, groupallow, groupdeny, usermanagementhelp
	* [FIX] ulx whip - No longer allows multiple whip sessions of an individual player at same time.
	* [FIX] ulx adduser - You no longer have to reconnect to get given access.
	* [FIX] Vastly improved ulx send, goto, and teleport. You should never get stuck in anything ever again.
	* [FIX] Various initialization functions trying to access a disconnected player
	* [FIX] Vastly improved reserved slots
	* [FIX] Can't spawn junk or suicide while frozen now.
	* [FIX] Coming out of spectate keeps god mode (if the player was given god with "ulx god")
	* [FIX] Can't use "ulx hp" to give 100000+ hp anymore (crashes players with default HUD).
	* [FIX] If you're authed twice, you won't get duplicates in autocomplete
	* [FIX] ulx votemapmapmode and votemapaddmap not working
	* [CHANGE] /me <action> can now be used in ulx asay/chat @ admin chat. "@ /me bashes spammer over the head"
	* [CHANGE] Commands that used player:spawn (ragdoll,spectate, more) now return player to health/armor they had previously.
	* [CHANGE] ulx teleport. Can now teleport a player to where you are looking. Logs it if a player is specified.
	* [CHANGE] You can now specify entire directories in ulx addForcedDownload
	* [CHANGE] A few internal changes to the ULX base to compliment the new ULib UCL access string system
	* [CHANGE] ULX echoes come after the command now.
	* [CHANGE] Configs are now under /cfg/* instead of /lua/ulx/configs/*
	* [CHANGE] bring goto and teleport now zero out your velocity after moving you.
	* [CHANGE] bring and goto can now still move you when you would get stuck if you're noclipped.
	* [CHANGE] A hidden echo that is still shown to admins is now clearly labeled as such.
	* [CHANGE] ulx cexec now takes multiple targets. (This was the intended behavior)
	* [CHANGE] Lots of minor tweaks that would take too long to list. ;)
	* [CHANGE] All say commands require spaces after them except the "@" commands. (IE, "!slapbob" no longer slaps bob)
	* [CHANGE] Access to physgun players now uses the access string "ulx physgunplayer"
	* [CHANGE] Access to reserved slots now uses the access string "ulx reservedslots"
	* [CHANGE] Complete rewrite of advert system. You probably won't notice any difference (except hostname fix), but the code is leaner and meaner.
	* [CHANGE] No interval option for ulx whip anymore, too easy to abuse.
	* [CHANGE] Menus now use derma
	* [CHANGE] The ULX configs should now really and truly load after the default configs
	* [CHANGE] Votemap, votekick, voteban now all require the approval of the admin that started the vote if it wins.
	* [CHANGE] Voteban can now receive a parameter for ban time.
	* [CHANGE] ulx map can now receive gamemode for a parameter.
	* [CHANGE] You can now use newlines in adverts.
	* [CHANGE] Dropped requirement of being at least an opper for userallow/deny
	* [CHANGE] ulx who has an updated format that includes custom groups.
	* [CHANGE] ulx help is now categorized. (Reserved slots, teleportation, chat, etc )
	* [CHANGE] ulx thetime can now only be used once every minute (server wide)

v3.11 - *(06/19/07)*
	* [FIX] ulx vote. No longer public, people can't vote more than once, won't continue to hog the binds.
	* [FIX] rslots will now set rslots on dedicated server start
	* [FIX] Bring/goto getting you stuck in player sometimes.
	* [FIX] Can't use vehicles from inside a jail now.
	* [CHANGE] bring and goto now place teleporting player behind target
	* [CHANGE] Upped votemapMinvotes to 3 (was 2).
	* [CHANGE] Player physgun now only works in sandbox, lower admins can't physgun immune admins, freezes player while held.
	* [CHANGE] Unblocked custom groups from ulx adduser.

v3.10 - *(05/05/07)*
	* [ADD] Admins with slap access can move players now.
	* [ADD] Chat anti-spam
	* [ADD] ulx addForcedDownload for configs
	* [ADD] Per-gamemode config folder
	* [ADD] Voting! ulx vote, ulx votemap2, ulx voteban, ulx votekick
	* [ADD] Maps menu
	* [ADD] Lots more features to logging, like object spawn logging.
	* [ADD] Reserved slots
	* [FIX] Lots of minor insignificant bugs
	* [FIX] Jail issues
	* [FIX] Logging player connect on dedicated server issues
	* [FIX] Now takes advantage of fixed umsgs. Fixes rare crash.
	* [FIX] Can now psay immune players
	* [FIX] Minor bugs in logs
	* [CHANGE] Logs will now wrap to new date if server's on past midnight
	* [CHANGE] You can now use the admin menu in gamemodes derived from sandbox.
	* [CHANGE] Cleaned up now obsolete GetTable() calls
	* [CHANGE] Motd is now driven by lua. Much easier to deal with, fixes many problems.
	* [CHANGE] Can now use sv_cheats 1/0 from ulx rcon (dodges block)
	* [CHANGE] ulx lua_run is now ulx luarun to dodge another block
	* [CHANGE] Now in addon format
	* [CHANGE] ulx ignite will now last until you die and can spread.
	* [CHANGE] Global toolmode deny doesn't affect admins.

v3.02 - *(01/10/07)*
	* [CHANGE] Admin menu won't spam console so bad now
	* [FIX] Some more command crossbreeding issues (IE ragdolling jailed player)
	* [FIX] Teleport commands able to put someone in a wall. This is still possible, but much less likely.
	* [ADD] Motd manipulation. Auto-shows on startup and !motd
	* [ADD] toolallow, tooldeny, tooluserallow, tooluserdeny. Works fine, but is EXPERIMENTAL!

v3.01 - *(01/07/07)*
	* [ADD] ulx whip
	* [ADD] ulx adduser
	* [ADD] ulx userallow - Allow users access to commands
	* [ADD] ulx userdeny - Deny users access to commands
	* [ADD] ulx bring - Bring a user to you
	* [ADD] ulx goto - Goto a user
	* [ADD] ulx teleport - Teleport to where you're looking
	* [ADD] IRC-style "/me" command
	* [FIX] You can't use the adminmenu outside sandbox now
	* [FIX] Vastly improved "ulx jail"
	* [FIX] Improved "ulx ragdoll"
	* [FIX] pvp damage checkbox in adminmenu not working.
	* [FIX] Ban button
	* [FIX] Ban not kicking users
	* [FIX] Blinded users being able to see through the camera tool
	* [FIX] Admin menu not showing values on a dedicated server
	* [FIX] Admin menu checkboxes (which are now buttons!)
	* [FIX] Ulx commands much more usable from dedicated server console.
	* [FIX] Dedicated server spam (IsListenServerHost)
	* [FIX] Uncloak works properly now
	* [FIX] Various problems using commands on users in vehicles. (Thanks Jalit)

v3.0  - *(01/01/07)*
	* Initial version for GM10

Group: Credits

Thanks to everyone in #ulysses in irc.gamesurge.net for not giving up on me :)
A big thanks to JamminR for listening to me ramble on and for giving the project fresh insights.

Group: License

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to
Creative Commons
543 Howard Street
5th Floor
San Francisco, California 94105
USA
