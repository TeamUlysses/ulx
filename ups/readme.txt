Title: UPS Readme

*UPS v1.00 (released 00/00/00)*

UPS is an prop protection mod for GMod (<http://garrysmod.com/>).

Visit our homepage at <http://ulyssesmod.net/>.

You can talk to us on our forums at <http://forums.ulyssesmod.net/>.

Group: Author

UPS is brought to you by..

* Brett "Megiddo" Smith - Contact: <megiddo@ulyssesmod.net>

Group: Requirements

UPS requires the latest ULib to be installed on the server. You can get ULib from <http://ulyssesmod.net>.

Group: Installation

To install UPS, simply extract the files from the archive to your garrysmod/addons folder.
When you've done this, you should have a file structure like this--
<garrysmod root>/addons/UPS/info.txt
<garrysmod root>/addons/UPS/lua/autorun/client/ups_preinit.lua
etc..

Note that installation for dedicated servers is EXACTLY the same!

You absolutely, positively have to do a full server restart after installing the files. A simple map
change will not cut it!

Group: Usage

After you've restarted your server, if you are an admin, the UPS control panel will appear under utilities in the spawn menu. You should also see owner info on props when you're looking at props with the physgun or toolgun equipped.

Group: Changelog
v1.00 - *(00/00/00)*
	* [FIX] Fixes for garry breakages.

v0.96 - *(07/05/11)*
	* [ADD] Global disables.
	* [ADD] Our own cvar saving to get away from Garry's terrible version. Now saves changes instantly.
	* [FIX] Restored saving functionality for player disables (not sure when this got broken, sorry. Thanks AtomicSpark).
	* [CHANGE] Moved replicated cvar stuff to ULib and improved it a bit.
	* [CHANGE] Won't show HUD while in vehicle anymore.
	* [CHANGE] Saved data is under data/ups now.
	* [CHANGE] UPS won't load in single player.

v0.95 - *(06/20/09)*
	* [ADD] Ability to enable and disable world protection.
	* [ADD] Ability to revoke admins' elevated privileges.
	* [FIX] Some problems with data consistency on player initialization.
	* [FIX] Added checks all over to ensure data integrity.
	* [FIX] Rewrote the anti-damage system. Should be able to take just about anything you can throw at it now (npcs, turrets, fire, etc).

v0.90 - *(07/29/08)*
	* Initial.

Group: Credits

A big thanks to JamminR for listening to me ramble on and for giving the project fresh insights. Thanks also to spbogie for helping me think around mental blocks and inspiring ideas.

Group: License

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to
Creative Commons
543 Howard Street
5th Floor
San Francisco, California 94105
USA