-- Written by Team Ulysses, http://ulyssesmod.net/
module( "Uclip", package.seeall )
if not CLIENT then return end

-- This function checks the protector to see if ownership has changed from what we think it is. Notifies player for c-side prediction too.	
function updateOwnership( ply, ent )
	if noProtection then return end -- No point on going on	
	if not ent.Uclip then ent.Uclip = {} end -- Initialize table
end

-- Here's where the server notifies us of a new passable state. We need this for c-side prediction
function rcvOwnershipUpdate( um )
	local ent = um:ReadEntity()
	if not ent or not ent:IsValid() then return end
	
	updateOwnership( LocalPlayer(), ent ) -- So it sets up the table if we don't have it already
	local owns = um:ReadBool()
	if owns == false then -- More convienent to store as nil, takes less memory!
		owns = nil
	end
	
	ent.Uclip[ LocalPlayer() ] = owns
end
usermessage.Hook( "UclipOwnershipUpdate", rcvOwnershipUpdate )

function rcvNoProtection( um )
	noProtection = true
end
usermessage.Hook( "UclipNoProtection", rcvNoProtection )