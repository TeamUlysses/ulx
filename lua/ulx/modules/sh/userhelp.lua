local help = [[
General User Management Concepts:
User access is driven by ULib's Ulysses Control List (UCL). This list contains users and groups
which in turn contains lists of allowed and denied accesses. The allow and deny lists contain
access strings like "ulx slap" or "ulx phygunplayer" to show what a user and/or group does and does
not have access to. If a user has "ulx slap" in their user allow list or in the allow list of one
of the groups they belong to, they have access to slap. If a user has "ulx slap" in their user deny
list they are DENIED the command, even if they have the command in one of their group's allow
lists. In this way, deny takes precedence over allow.

ULib supports immunity by being able to specify what various users and groups are allowed to
target. This is often used to make it so lower admins cannot target higher admins. EG, by default
admins can't target superadmins, but superadmins can still target admins.


More Advanced Concepts:
Groups have inheritance. You can specify what group they inherit from in the addgroup command. If a
user is in a group that has inheritance, UCL will check all groups connected in the inheritance
chain. Note that groups do not support deny lists for the sake of simplicity. If you feel that a
group needs to be denied something, you should split your groups up instead.

The "user" group applies to everyone who does not otherwise belong in a group. You can use
groupallow on this group just like any other, just remember that everyone is being allowed access.

ULib supports an advanced, highly configurable permission system by using "access tags". Access
tags specify what a user is allowed to pass as arguments to a command. For example, you can make it
so that admins are only allowed to slay users with "killme" somewhere in their name, or you can
give everyone access to the "ulx teleport" command, but only allow them to teleport themselves.

Examples of using access tags are given below in the userallow and groupallow commands. The format
for access tags is as follows. Each argument that is passed to the command can be limited by the
access tag. Each argument being limited must be listed in the same order as in the command,
separated by spaces. If you don't want to limit an argument, use a star ("*"). EG, to limit "ulx
slap" damage to 0 through 10, but still allow it to be used on anyone, use the tag "* 0:10".

User Management Commands:
ulx adduser <user> <group> - Add the specified CONNECTED player to the specified group.
The group MUST exist for this command to succeed. Use operator, admin, superadmin, or see ulx
addgroup. You can only specify one group. See above for explanation on immunity.
Ex 1. ulx adduser "Someguy" superadmin  -- This will add the connected "Someguy" as a superadmin
Ex 2. ulx adduser "Dood" monkey         -- This will add the connected "Dood" to the group monkey
  on the condition that the group exists

ulx removeuser <user> - Remove the specified connected player from the permanent access list.
Ex 1. ulx removeuser "Foo bar"            -- This removes the user "Foo bar"

ulx userallow <user> <access> [<access tag>] - Puts the access on the USER'S ALLOW list, with
  optional access tag (see above)
See above for explanation of allow list vs. deny list, as well as how access strings/tags work.
Ex 1. ulx userallow "Pi" "ulx slap"                 -- This grants the user access to "ulx slap"
Ex 2. ulx userallow "Pi" "ulx slap" "!%admin 0"     -- This grants the user access to "ulx slap"
  -- but they can only slap users lower than an admin, and they can only slap for 0 damage

ulx userdeny <user> <access> [<revoke>] - Removes a player's access. If revoke is true, this simply
  removes the access string from the user's allow/deny lists instead of adding it to the user's
  deny list. See above for an explanation on the deny list.

ulx addgroup <group> [<inherits from>] - Creates a group, optionally inheriting from the specified
  group. See above for explanation on inheritance.

ulx removegroup <group> - Removes a group PERMANENTLY. Also removes the group from all connected
  users and all users who connect in the future. If a user has no group besides this, they will
  become guests. Please be VERY careful with this command!

ulx renamegroup <current group> <new group> - Renames a group

ulx setgroupcantarget <group> [<target string>] - Limits what users a group can target. Pass no
  argument to clear the restriction.
Ex 1. ulx setgroupcantarget user !%admin - Guests cannot target admins or above
Ex 2. ulx setgroupcantarget admin !^ - Admins cannot target themselves

ulx groupallow <group> <access> [<access tag>] - Puts the access on the group's allow list. See
  above on how access strings/tags work.

ulx groupdeny <group> <access> - Removes the group's access.


]]

function ulx.showUserHelp()
	local lines = ULib.explode( "\n", help )
	for _, line in ipairs( lines ) do
		Msg( line .. "\n" )
	end
end
