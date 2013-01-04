--[[
	Title: Player

	Has useful player-related functions.
]]

--[[
	Function: getPicker

	Gets the player directly in front of the specified player

	Parameters:

		ply - The player to look for another player in front of.
		radius - *(Optional, defaults to 30)* How narrow to make our checks for players in front of us.

	Returns:

		The player most directly in front of us if one exists with the given constraints, otherwise nil.

	Revisions:

		v2.40 - Initial.
]]
function ULib.getPicker( ply, radius )
	radius = radius or 30

	local trace = util.GetPlayerTrace( ply )
	local trace_results = util.TraceLine( trace )

	if not trace_results.Entity:IsValid() or not trace_results.Entity:IsPlayer() then
		-- Try finding a best choice
		local best_choice
		local best_choice_diff
		local pos = ply:GetPos()
		local ang = ply:GetAimVector():Angle()
		local players = player.GetAll()
		for _, player in ipairs( players ) do
			if player ~= ply then
				local vec_diff = player:GetPos() - Vector( 0, 0, 16 ) - pos
				local newang = vec_diff:Angle()
				local diff = math.abs( math.NormalizeAngle( newang.pitch - ang.pitch ) ) + math.abs( math.NormalizeAngle( newang.yaw - ang.yaw ) )
				if not best_choice_diff or diff < best_choice_diff then
					best_choice_diff = diff
					best_choice = player
				end
			end
		end

		if not best_choice or best_choice_diff > radius then
			return -- Give up
		else
			return best_choice
		end
	else
		return trace_results.Entity
	end
end


--[[
	Function: getUsers

	Finds users matching an identifier.

	Parameters:

		target - A string of what you'd like to target. Accepts a comma separated list.
		enable_keywords - *(Optional, defaults to false)* If true, the keywords "*" for all players, "^" for self,
			"@" for picker (person in front of you), "#<group>" for those inside a specific group, 
			and "%<group>" for users inside a group (counting inheritance) will be activated.
			Any of these can be negated with "!" before it. IE, "!^" targets everyone but yourself.
		ply - *(Optional)* Player needing getUsers, this is necessary for some of the keywords.

	Returns:

		A table of players (false and message if none found).

	Revisions:

		v2.40 - Rewrite, added more keywords, removed immunity.
		v2.50 - Added "#" keyword, removed special exception for "%user" (replaced by "#user").
]]
function ULib.getUsers( target, enable_keywords, ply )
	local players = player.GetAll()
	target = target:lower()

	-- First, do a full name match in case someone's trying to exploit our target system
	for _, player in ipairs( players ) do
		if target == player:Nick():lower() then
			return { player }
		end
	end

	-- Okay, now onto the show!
	local targetPlys = {}
	local pieces = ULib.explode( ",", target )
	for _, piece in ipairs( pieces ) do
		piece = piece:Trim()
		if piece ~= "" then
			local safe = ULib.makePatternSafe( piece )
			local keywordMatch = false
			if enable_keywords then
				local tmpTargets = {}
				local negate = false
				if piece:sub( 1, 1 ) == "!" and piece:len() > 1 then
					negate = true
					piece = piece:sub( 2 )
				end

				if piece == "*" then -- All!
					table.Add( tmpTargets, players )
				elseif piece == "^" then -- Self!
					if ply then
						table.insert( tmpTargets, ply )
					end
				elseif piece == "@" then
					if ply and ply:IsValid() then
						local player = ULib.getPicker( ply )
						if player then
							table.insert( tmpTargets, player )
						end
					end
				elseif piece:sub( 1, 1 ) == "#" and ULib.ucl.groups[ piece:sub( 2 ) ] then
					local group = piece:sub( 2 )
					for _, player in ipairs( players ) do
						if player:GetUserGroup() == group then
							table.insert( tmpTargets, player )
						end
					end
				elseif piece:sub( 1, 1 ) == "%" and ULib.ucl.groups[ piece:sub( 2 ) ] then
					local group = piece:sub( 2 )
					for _, player in ipairs( players ) do
						if player:CheckGroup( group ) then
							table.insert( tmpTargets, player )
						end
					end
				end

				if negate then
					for _, player in ipairs( players ) do
						if not table.HasValue( tmpTargets, player ) then
							keywordMatch = true
							table.insert( targetPlys, player )
						end
					end
				else
					if #tmpTargets > 0 then
						keywordMatch = true
						table.Add( targetPlys, tmpTargets )
					end
				end
			end

			if not keywordMatch then
				for _, player in ipairs( players ) do
					if player:Nick():lower():find( piece, 1, true ) then -- No patterns
						table.insert( targetPlys, player )
					end
				end
			end
		end
	end

	-- Now remove duplicates
	local finalTable = {}
	for _, player in ipairs( targetPlys ) do
		if not table.HasValue( finalTable, player ) then
			table.insert( finalTable, player )
		end
	end

	if #finalTable < 1 then
		return false, "No target found or target has immunity!"
	end

	return finalTable
end


--[[
	Function: getUser

	Finds a user matching an identifier.

	Parameters:

		target - A string of the user you'd like to target. IE, a partial player name.
		enable_keywords - *(Optional, defaults to false)* If true, the keywords "^" for self and "@" for picker (person in
			front of you) will be activated.
		ply - *(Optional)* Player needing getUsers, this is necessary to use keywords.

	Returns:

		The resulting player target, false and message if no user found.

	Revisions:

		v2.40 - Rewrite, added keywords, removed immunity.
]]
function ULib.getUser( target, enable_keywords, ply )
	local players = player.GetAll()
	target = target:lower()

	-- First, do a full name match in case someone's trying to exploit our target system
	for _, player in ipairs( players ) do
		if target == player:Nick():lower() then
			return player
		end
	end

	if enable_keywords then
		if target == "^" then
			return ply
		elseif target == "@" then
			local player = ULib.getPicker( ply )
			if not player then
				return false, "No player found in the picker"
			else
				return player
			end
		end
	end

	local plyMatch
	for _, player in ipairs( players ) do
		if player:Nick():lower():find( target, 1, true ) then -- No patterns
			if plyMatch then -- Already have one
				return false, "Found multiple targets! Please choose a better string for the target. (IE, the whole name)"
			end
			plyMatch = player
		end
	end

	if not plyMatch then
		return false, "No target found or target has immunity!"
	end

	return plyMatch
end

