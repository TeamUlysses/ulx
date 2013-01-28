Title: Uclip Readme

*Uclip v1.22 (released 01/27/13)*

Uclip is a noclip alternative. By this we mean it's similar but different in the fact that you can't noclip
through anything but your own props (If you're running a prop protection). So, you can't noclip through the
world or through others' props. Admins can still noclip through everything.

Visit our homepage at <http://ulyssesmod.net/>.

You can talk to us on our forums at <http://forums.ulyssesmod.net/> or on our steam community, ULX <http://steamcommunity.com/groups/ULX>.

Group: Authors

Uclip is brought to you by..

* Brett "Megiddo" Smith - Contact: <megiddo@ulyssesmod.net>
* Ryno-SauruS

Group: Requirements

Uclip has no requirements, but it is recommended you use it with a supported prop protector. Supported protectors are below...
* UPS (recommended!)
* Simple Prop Protection
* FPP
* Anything else that supports CPPI (contact the mod author)

Group: Installation

To install Uclip, simply extract the files from the archive to your garrysmod/addons folder.
When you've done this, you should have a file structure like this--
<garrysmod>/addons/uclip/lua/autorun/sh_uclip.lua
etc..

Please note that installation is the same on dedicated servers.

You absolutely, positively have to do a full server restart after installing the files. A simple map
change will not cut it!

Group: Config

There is minimal config inside sh_uclip.lua but you will need basic knowledge of lua to use it.

Group: Changelog
v1.22 - *(01/27/13)*
	* [FIX] garry breakages

v1.21 - *(06/10/11)*
	* [FIX] Exploit where users could come through the bottom of props by moving slowly.

v1.20 - *(12/12/10)*
	* [ADD] uclip_ignore_admins cvar.
	* [FIX] Added a workaround for garry's broken movement system. This was added by Ryno-SauruS. Give him many thanks!
	* [REMOVE] Hacks for hooking into (now way outdated) prop protectors. CPPI is adequate for our purposes.

v1.13 - *(04/21/08)*
	* [ADD] Support for CPPI

v1.12 - *(12/04/07)*
	* [FIX] +moveup/+movedown exploit

v1.11 - *(12/04/07)*
	* [CHANGE] Wall slide calculation is now much faster
	* [ADD] sbox_noclip 2 will now enables global "regular" noclip

v1.10 - *(08/27/07)*
	* [ADD] Support for EPS and Simple Prop Protection
	* [FIX] Now treats all prop_dynamic's like a wall. This means you won't be able to go through any door made by door mod. (Sorry! Gmod problem forced our hand.)

v1.00 - *(08/08/07)*
	* Initial version

Group: License

This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to
Creative Commons
543 Howard Street
5th Floor
San Francisco, California 94105
USA
