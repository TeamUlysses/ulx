# ULX
ULX is an admin mod for [Garry's Mod](http://garrysmod.com/).

ULX offers server admins an AMXX-style support. It allows multiple admins with different access levels on the same server.
It features commands from basic kick, ban, and slay to fancier commands such as blind, freeze, voting, and more.

Visit our homepage at http://ulyssesmod.net.

You can talk to us on our forums at http://forums.ulyssesmod.net.

## Requirements
ULX requires the latest version of [ULib](https://github.com/TeamUlysses/ulib) to be installed on the server.

## Installation

### Workshop
ULX's workshop ID is `557962280`. You can subscribe to ULX via Workshop [here](http://steamcommunity.com/sharedfiles/filedetails/?id=557962280).
Don't forget you'll also need ULib, whose workshop ID is `557962238` and can be found [here](http://steamcommunity.com/sharedfiles/filedetails/?id=557962238).

### Classic
To install ULX, simply extract the files from the downloaded archive to your garrysmod/addons/ folder.
When you've done this, you should have a file structure like this:

`(garrysmod)/addons/ulx/lua/ulib/modules/ulx_init.lua`

`(garrysmod)/addons/ulx/lua/ulx/modules/fun.lua`

You absolutely, positively have to do a full server restart after installing the files. A simple map change will not cut it!

## Usage
**To give yourself a jump start into ULX, simply remember the commands `ulx help` and `ulx menu`.**

To access the commands and settings in ULX, you can open the GUI with `ulx menu` in console. It is recommended to bind this command to a keyboard key. Additionally, you can use console commands in the form of `ulx (command) (arguments)` or chat commands in the form of `!(command) (arguments)`.

To add users to usergroups, navigate to the "Groups" tab of the GUI and select a group. Then use the "Add" button to add connected players. You can also use the `ulx adduser (user) (group)` command. If you absolutely need to, you can also edit the `data/lib/users.txt` file.

A word about superadmins: Superadmins are considered the highest usergroup. They have access to all the commands in ULX, the ability to override other user's immunity, and are shown log messages which are hidden from other players (EG, they are shown rcon commands admins are running). Superadmins also have the power to give and revoke access to commands using userallow and userdeny.

All commands are preceded by `ulx `. Type `ulx help` in a console without the quotes for help.

Check out the config folder in ulx for some more goodies.

## Credits
ULX is brought to you by..

* Brett "Megiddo" Smith - Contact: <mailto:megiddo@ulyssesmod.net>
* JamminR - Contact: <mailto:jamminr@ulyssesmod.net>
* Stickly Man! - Contact: <mailto:sticklyman@ulyssesmod.net>
* MrPresident - Contact: <mailto:mrpresident@ulyssesmod.net>

A big thanks to JamminR for listening to the rest of the team (especially Megiddo) ramble on, never giving up on us, and for giving the project fresh insights.

## Changelog
See the [CHANGELOG](CHANGELOG.md) file for information regarding changes between releases.
