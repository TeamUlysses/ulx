# ULX
ULX is an admin mod for [Garry's Mod](http://garrysmod.com/).

ULX offers server admins an AMXX-style support. It allows multiple admins with different access levels on the same server.
It has features from basic kick, ban, and slay to fancier commands such as blind, freeze, voting, and more.

Visit our homepage at <http://ulyssesmod.net>.

You can talk to us on our forums at <http://forums.ulyssesmod.net>

## Requirements
ULX requires the latest version of [ULib](https://github.com/TeamUlysses/ulib) to be installed on the server.

## Installation
To install ULX, simply extract the files from the archive to your garrysmod/addons/ folder.
When you've done this, you should have a file structure like this:

`(garrysmod)/addons/ulx/lua/ulib/modules/ulx_init.lua`

`(garrysmod)/addons/ulx/lua/ulx/modules/fun.lua`

etc..

You absolutely, positively have to do a full server restart after installing the files. A simple map change will not cut it!

## Usage
To access the commands and settings in ULX, you can open the GUI with `ulx menu` in console. It is recommended to bind this command to a keyboard key. Additionally, you can use console commands in the form of `ulx (command) (arguments)` or chat commands in the form of `!ulx (command) (arguments)`.

To add users to usergroups, navigate to the "Groups" tab of the GUI and select a group. Then use the "Add" button to add connected players. You can also use the `ulx adduser (user) (group)` command. If you absolutely need to, you can also edit the `data/lib/users.txt` file.

A word about superadmins: Superadmins are considered the highest usergroup. They have access to all the commands in ULX, the ability to override other user's immunity, and are shown usually hidden log messages (IE, shown rcon commands admins are running). Superadmins also have the power to give and revoke access to commands using userallow and userdeny (though they can't use this command on each other).

All commands are preceded by `ulx `. Type `ulx help` in a console without the quotes for help.

**To give yourself a jump start into ULX, simply remember the commands `ulx help` and `ulx menu`.**

Check out the config folder in ulx for some more goodies.

## Credits
ULX is brought to you by..

* Brett "Megiddo" Smith - Contact: <mailto:megiddo@ulyssesmod.net>
* JamminR - Contact: <mailto:jamminr@ulyssesmod.net>
* Stickly Man! - Contact: <mailto:sticklyman@ulyssesmod.net>
* MrPresident - Contact: <mailto:mrpresident@ulyssesmod.net>

Thanks to everyone in #ulysses in irc.gamesurge.net for not giving up on me :)

A big thanks to JamminR for listening to me ramble on and for giving the project fresh insights.

## Changelog
See [the CHANGELOG file](CHANGELOG.md) for release information. To view individual commits, see the [ULX GitHub repository](https://github.com/TeamUlysses/ulx)'s commit list.

## License
This work is licensed under the Creative Commons Attribution-NonCommercial-ShareAlike 3.0 License.
To view a copy of this license, visit http://creativecommons.org/licenses/by-nc-sa/3.0/ or send a letter to
```
Creative Commons
543 Howard Street
5th Floor
San Francisco, California 94105
USA
```
