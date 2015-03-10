Title: ULib Readme

*ULib v2.52 (released 03/09/15)*

ULib is a developer library for GMod 10 (<http://garrysmod.com/>).

ULib provides such features as universal physics, user access lists, and much, much more!

Visit our homepage at <http://ulyssesmod.net/>.

You can talk to us on our forums at <http://forums.ulyssesmod.net/>.

Group: Author

ULib is brought to you by..

* Brett "Megiddo" Smith - Contact: <megiddo@ulyssesmod.net>
* JamminR - Contact: <jamminr@ulyssesmod.net>
* Stickly Man! - Contact: <sticklyman@ulyssesmod.net>

Group: Requirements

ULib requires a working copy of the latest garrysmod, and that's it!

Group: Installation

To install ULib, simply extract the files from the archive to your garrysmod/addons folder.
When you've done this, you should have a file structure like this--
<garrysmod>/addons/ulib/lua/ULib/init.lua
<garrysmod>/addons/ulib/lua/ULib/server/util.lua
<garrysmod>/addons/ulib/lua/autorun/ulib_init.lua
<garrysmod>/addons/ulib/data/ULib/users.txt
etc..

Please note that installation is the same on dedicated servers.

You absolutely, positively have to do a full server restart after installing the files. A simple map
change will not cut it!

Group: Usage

Server admins do not "use" ULib, they simply enjoy the benefits it has to offer.
After installing ULib correctly, scripts that take advantage of ULib will take care of the rest.
Rest easy!

Group: Changelog
v2.52 - *(03/09/15)*
	* [ADD] Admin parameter to ULib.unban for overriding purposes (Thanks for the idea, MStruntze).
	* [ADD] A list of players is presented when a target string for getUser matches more than one player (Thanks, RhapsodySL).
	* [FIX] ULib.ucl.registerAccess not allowing an access tag to be registered to no groups.
	* [FIX] Several incorrect file I/O calls (Thanks, Q4-Bi).
	* [FIX] Hook priority being messed up for parent hook when hooks are called recursively (Thanks, NoBrainCZ).
	* [FIX] Some fiddly-bits with group case-sensitivity (Thanks, BryanFlannery).
	* [CHANGE] hook.Run to match Garry's changes.
	* [CHANGE] ULib.HOOK_LOCALPLAYERREADY is now called on InitPostEntity instead of OnEntCreate.

v2.51 - *(08/30/13)*
	* [FIX] ULib.ucl.userAllow not working on disconnected players (Thanks, JackYack13).
	* [FIX] Issue with setting groups with capitals in the group name (Thanks, FPtje!).
	* [FIX] Calling SetUserGroup not passing on information to clients (Thanks, Bo98).
	* [FIX] Garry's File I/O bugs by wrapping all his I/O.
	* [FIX] A user group lower casing that no longer belonged in the code (Thanks, iamalexer).
	* [FIX] Some issues with casing in ULib commands (Thanks, TheSpy7).
	* [FIX] Invalid time restrictions throwing an error (Thanks, Scratch).
	* [FIX] A problem with targeting in single player (Effected XGUI. Thanks, bender180).
	* [FIX] A problem with self-target restrictions breaking commands under certain conditions (Thanks, iSnipeu).
	* [FIX] A bug with being able to update replicated variables after running a listen server and then joining another server.
	* [REMOVED] Temp garry-patch for reading from the data directory that appears to be fixed now.

v2.50 - *(01/27/13)*
	* [ADD] ULib.pcallError -- Does what global PCallError used to do before it was removed.
	* [ADD] Shows reasons to kicked person upon kick or ban (Thanks FPtje!).
	* [ADD] Operator to target only a specific group, ignoring inheritance ('#').
	* [ADD] Operator to target a specific id ('$').
	* [ADD] ULib.namedQueueFunctionCall to allow scripts to create their own queues separate of the main one.
	* [ADD] The ability to have aliased chat commands.
	* [FIX] The usual assortment of garry breakages.
	* [FIX] Changed away from our custom implementation of datastream to use Garry's new net library.
	* [FIX] Error with returning from invisibility when the player has no weapons (Thanks HellFox).
	* [FIX] "ULibCommandCalled" hook not being called on chat commands (Thanks Adult).
	* [CHANGE] Replicated cvars aren't actually relying on source replication anymore since Garry broke it (but they function the same).
	* [CHANGE] Lots of changes to match GM13.
	* [CHANGE] NumArg now allows for time string format.
	* [CHANGE] Hook library to match garry's. hook.isInHook was removed, no longer able to support with garry's changes.

v2.42 - *(01/01/12)*
	* [FIX] Garry breakages.

v2.41 - *(09/22/11)*
	* [ADD] ULib.ucl.getUserRegisteredID.
	* [ADD] ULib.stringTimeToSeconds (Thanks lavacano201014).
	* [FIX] Now properly kicks users who are banned while joining (Thanks Willdy).

v2.40 - *(05/13/11)*
	* [ADD] ULib.tsayColor and Ulib.tsayError
	* [ADD] Replicated cvars. Nearly a direct port from the UPS implementation, with a few improvements.
	* [ADD] queueFunctionCall, ported from UPS.
	* [ADD] Player:GetUserGroup().
	* [ADD] Player:CheckGroup(), ability to check if a user in a group via inheritance.
	* [ADD] ULib.getPlyByUID().
	* [ADD] ULib.clientRPC(), send massive amounts of data to a client with ease.
	* [ADD] Upgrade script.
	* [ADD] hook.getCurrentHooks(), returns all currently processing hooks.
	* [ADD] hook.isInHook( name ), returns if you're in the specified hook or not.
	* [ADD] ULib.splitPort(), ULib.isValidSteamID(), ULib.isValidIP().
	* [ADD] ULib.backupFile().
	* [ADD] ULib.throwBadArg(), useful for argument checking.
	* [ADD] ULib.checkArg(), useful for argument checking.
	* [ADD] ULib.getPicker(), returns a user directly in front of another user.
	* [ADD] Utilities for table inheritance.
	* [ADD] New 'translation' command system that acts as a wrapper between a user and lua.
	* [ADD] New (and very different) command system.
	* [ADD] Lots of new hooks.
	* [ADD] Support for gatekeeper in ULib.kick.
	* [ADD] Our own optimized version of datastream, since garry's implementation is always broken.
	* [ADD] ULib.getAllReadyPlayers(), useful for sending usermessages to everyone.
	* [ADD] Basic spam detection system for ULib commands.
	* [FIX] ULib.filesInDir, was completely broken.
	* [FIX] The usual assortment of garry breakages.
	* [FIX] Some case-sensitive issues with the ULib add-command functions.
	* [FIX] Attempting to delete misc_registered.txt when it didn't exist.
	* [FIX] ULib.splitArgs now really properly handles escaped quotes and now unescapes them.
	* [FIX] Concommands created by ULib removing empty args.
	* [FIX] Overflowing command buffer when executing large config files.
	* [FIX] Optimized various functions to support up to 4000 bans (at least!).
	* [FIX] Bug where reloading ban information when a temp ban had less than a minute left made the ban permanent.
	* [FIX] Bug where ULib was reading in bad characters from source bans (Thanks edk141).
	* [CHANGE] Chat hooks are now a high priority due to other aggressive admin mods overriding ULX.
	* [CHANGE] Rewrote UCL entirely. The upgrade script should take care of bringing over old data into the new system.
	* [CHANGE] Added the ability to have access tags for each access string. These allow the accesses to have customizable behavior.
	* [CHANGE] Access tags now have comments attached to them (for the "what is it?" among us).
	* [CHANGE] Added lots of keywords (and keyword negation!) to ULib.getUsers and ULib.getUser.
	* [CHANGE] Invisible gets rid of shadows now.
	* [CHANGE] Garry's hook table spec is now more closely followed. (Thanks aVoN!)
	* [CHANGE] Moved the hook changes to the shared portion so clients can use the enhanced hooks as well.
	* [CHANGE] Updated the hooks file to match garry's recent changes. Also increased efficiency in hooks (faster than garry's!)
	* [CHANGE] Slaps now do a view punch as well.
	* [CHANGE] Allow nil access on ULib.addSayCommand so that you can create a command you always have access to.
	* [CHANGE] ULib.ucl.query always returns true when a nil access string is passed in.
	* [REMOVE] Ability to have passwords in UCL, don't think it worked anymore and it was never really used.
	* [REMOVE] Immunity no longer exists, since the new UCL has a much better method of doing the same thing.
	* [REMOVE] Some hooks due to garry breakage.
	* [REMOVE] Chat sounds on tsay, engine no longer makes sounds so neither should tsay.

v2.30 - *(06/20/09)*
	* [FIX] Umsgs being sent too early in certain circumstances.
	* [FIX] Some issues garry introduced in the Jan09 update regarding player initialization.
	* [FIX] ParseKeyValues not unescaping backslashes.
	* [CHANGE] Rewrote splitArgs and parseKeyValues.
	* [CHANGE] misc_registered.txt now self-destructs on missing or empty groups.txt.
	* [CHANGE] All gamemode.Call refs to hook.Call, thanks aVoN!
	* [CHANGE] SetUserGroup now REMOVES any other groups and sets an exclusive group. Sorry about this, but this is for the better.

v2.21 - *(06/08/08)*
	* [ADD] Support for client/server-side only modules.
	* [FIX] Bug in ULib.tsay that would incorrectly print to console if the target player was disconnecting.
	* [FIX] Makes sure that prop protectors don't take ownership of props using physgun reload while a prop is unmovable.
	* [CHANGE] ULib.getUsers now returns multiple users on an asterisk "*" when enable_keywords is true. "<ALL>" can still be used. (Thanks Kyzer)


v2.20 - *(01/26/08)*
	* [ADD] ULib now has three shiny new hooks to let you know about client initialization and a new hook to signal a player name change.
	* [FIX] A possible bug in the physics helpers.
	* [CHANGE] Various things to bring ULib into new engine compatibility.
	* [CHANGE] Removed all timers dealing with initialization and now rely on flags from the client. This makes the ULib initialization much more dependable.
	* [CHANGE] Converted all calls from ULib.consoleCommand( "exec ..." ) to ULib.execFile() to avoid running into the block on "exec" without our module.
	* [REMOVE] Removing the module for now, might re-appear in the next version


v2.10 - *(09/23/07)*
	* [ADD] New hook library. Completely backwards compatible, but can now do priorities. (Server-side only)
	* [ADD] ULib.parseKeyValues, ULib.makeKeyValues
	* [ADD] ULib.getSpawnInfo, ULib.Spawn - Enhanced Spawn... will replace original health/armor when called if getSpawnInfo called first.
	* [ADD] READDED hexing system to get around garry's ConCommand() blocks. So much is now blocked that it's interferring with normal ULX operations.
	* [ADD] Our server module again. This time with only console-executing abilities. This is because garry has blocked much of what we need. Source is included.
	* [ADD] Custom ban list to store temp bans and additional ban info. Permanent bans are still stored in banned_user.cfg, and the two lists are synchronized.
	* [FIX] Can now query players from client side.
	* [FIX] An exploit in DisallowDelete() that allowed players to still remove the props
	* [FIX] Various initialization functions trying to access a disconnected player
	* [FIX] ULib.csay() sending umsgs to invalid players.
	* [FIX] UCL by clantag not working.
	* [CHANGE] Big changes in ucl.query() and concommand functions. Probably won't be backwards compatible.
	* [CHANGE] UCL now uses our new keyvalues functions. It should be backwards compatible with your old data, but we make no promises. If you're having trouble with it, try starting from scratch.
	* [CHANGE] ULib.tsay has a wait parameter to send on next frame
	* [CHANGE] subconcommands are now case insensitive
	* [CHANGE] Csay's now have fade.
	* [CHANGE] DisallowSpawning() now implements SpawnObject. For example, people can't sit and precache props while in the ulx jail.
	* [CHANGE] Say commands are now case insensitive and default to needing a space between command and arg (can flag to use old behavior though)
	* [CHANGE] ULib.ban, and ULib.kickban now accept additional information and pass data to ULib.addBan.
	* [CHANGE] Immunity is now an access string instead of a group
	* [CHANGE] Overcoming immunity is no longer bound to superadmins
	* [CHANGE] Increased performance of UCL.
	* [REMOVED] The vgui panels, derma is the vgui of choice now.

v2.05 - *(06/19/07)*
	* [ADD] ply:SetUserGroup() -- Thanks aVoN!
	* [ADD] ply:DisallowVehicles( bool )
	* [FIX] A timer error in UCL, was messing up scoreboard sometimes.
	* [FIX] Security hole where exploiters could gain superadmin access
	* [CHANGE] You can assign allow/denies to the default user group, "user" now. (IE, allow guests to slap)
	* [CHANGE] DisallowSpawning now disallows tools that can spawn things.
	* [REMOVED] Old settings/users.txt stuff, handled by SetUserGroup now

v2.04 - *(05/05/07)*
	* [ADD] ULib.isSandbox
	* [ADD] Player/ent hooks DisallowMoving, DisallowDeleting, DisallowSpawning, DisallowNoclip
	* [ADD] Some vgui libs (URoundButton, URoundMenu)
	* [FIX] Double printing in console.
	* [CHANGE] Implemented garry's "proper" way of including c-side files.
	* [CHANGE] Implemented client side UCL
	* [CHANGE] Now in addon format
	* [CHANGE] Slapping noclipped players will take them out of noclip to prevent them flying very far out of the world
	* [CHANGE] Improved the umsg send/receive functions
	* [REMOVED] Hexing system to get around garry's ConCommand() blocks. Very little is blocked now.
	* [REMOVED] Dll, MOTD functionality is handled by ULX now.

v2.03 - *(01/10/07)*
	* [ADD] ULib module, has functions for motd, concommands, and downloading files. SOURCE CODE!
	* [FIX] Player slap after dead problem.

v2.02 - *(01/07/07)*
	* [ADD] New system for giving files to clients. Strips comments and puts them in a separate folder.
	* [FIX] Autocompletes aren't handled so hackishly now. This should fix some occasional errors.
	* [FIX] Lots of general fixes.

v2.01 - *(01/02/07)*
	* [FIX] Importing from garry's default user file.
	* [FIX] All users receiving "you do not have access" message.

v2.0 - *(01/01/07)*
	* Initial version for GM10

Group: Developers

To all developers, I sincerely hope you enjoy what ULib has to offer!
If you have any suggestions, comments, or complaints, please tell us at <http://forums.ulyssesmod.net/>.

If you want an overview of what's in ULib, please visit the documentation at <http://ulyssesmod.net/docs/>.
If you find any bugs, you can report them at <https://github.com/Nayruden/Ulysses/issues>.

All ULib's functions are kept in the table "ULib" to prevent conflicts.

Revisions are kept in the function/variable documentation. If you don't see revisions listed, it hasn't changed since v2.0

If you write a script taking advantage of ULib, stick the init script inside ULib/modules. ULib will load your script after
ULib loads, and will send it to and load it on clients as well.

Some important quirks developers should know about --
* autocomplete - You have to define the autocomplete on the client, so if you pass a string for autocomplete to ULib.concommand,
it will assume you mean a client function. There's also a delay in the sending of these to the client.

Group: Credits

Thanks to JamminR, who is always there to offer help and advice to those who need it.

Group: License

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to
Creative Commons
543 Howard Street
5th Floor
San Francisco, California 94105
USA
