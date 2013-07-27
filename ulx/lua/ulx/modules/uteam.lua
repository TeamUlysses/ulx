local next_team_index
local starting_team_index = 21
ulx.teams = {}
local team_by_name = {}

local function sortTeams( team_a, team_b )
	if team_a.order then
		if team_a.order ~= team_b.order then
			return not team_b.order or team_a.order < team_b.order
		end
	elseif team_b.order then
		return false -- Ordered always comes before non-ordered
	end

	return team_a.name < team_b.name
end

local function sendDataTo( ply )
	ULib.clientRPC( ply, "ulx.populateClTeams", ulx.teams )
end

local function assignTeam( ply )
	local team = ULib.ucl.groups[ ply:GetUserGroup() ].team
	if team then
		local team_data = team_by_name[ team.name ]
		ULib.queueFunctionCall( function()
			if not ply:IsValid() then return end -- In case they drop quickly
			ply:SetTeam( team_data.index )
			if team_data.model then
				ply:SetModel( team_data.model )
			end
			for key, value in pairs( team_data ) do
				local candidate_function = ply[ "Set" .. key:sub( 1, 1 ):upper() .. key:sub( 2 ) ]
				if type( value ) == "number" and type( candidate_function ) == "function" then
					candidate_function( ply, value )
				end
			end
		end )
	elseif ply:Team() >= starting_team_index and ply:Team() < next_team_index then
		ULib.queueFunctionCall( ply.SetTeam, ply, 1001 ) -- Unassigned
	end
end

function ulx.saveTeams()
	-- First clear the teams
	for group_name, group_data in pairs( ULib.ucl.groups ) do
		group_data.team = nil
	end

	local to_remove = {}
	for i=1, #ulx.teams do
		local teamdata = table.Copy( ulx.teams[ i ] ) -- Copy since we'll be removing data as we go
		if not teamdata.groups or #teamdata.groups == 0 then
			table.insert( to_remove, 1, i )
		else
			local groupdata = {}
			local groups = teamdata.groups
			teamdata.groups = nil
			if teamdata.color then
				groupdata.color_red = teamdata.color.r
				groupdata.color_green = teamdata.color.g
				groupdata.color_blue = teamdata.color.b
				teamdata.color = nil
			end
			table.Merge( groupdata, teamdata )
			ULib.ucl.groups[ groups[ 1 ] ].team = groupdata
			for i = 2, #groups do
				ULib.ucl.groups[ groups[ i ] ].team = {
					name = teamdata.name,
					order = teamdata.order
				}
			end
		end
	end

	for i=1, #to_remove do
		table.remove( ulx.teams, to_remove[ i ] )
	end

	ULib.ucl.saveGroups()
end

function ulx.refreshTeams()
	if not ULib.isSandbox() then
		return
	end

	next_team_index = starting_team_index
	ulx.teams = {}
	team_by_name = {}

	for group_name, group_data in pairs( ULib.ucl.groups ) do
		if group_data.team then
			local team_name = group_data.team.name or ("Team" .. tostring( next_team_index ))
			group_data.team.name = team_name
			local team_color
			if group_data.team.color_red or group_data.team.color_green or group_data.team.color_blue then
				team_color = Color( tonumber( group_data.team.color_red ) or 255, tonumber( group_data.team.color_green ) or 255, tonumber( group_data.team.color_blue ) or 255 )
			end
			local team_model
			if group_data.team.model then
				team_model = group_data.team.model
				if not ULib.fileExists( team_model ) then
					team_model = player_manager.TranslatePlayerModel( team_model )
				end
			end
			local new_team = {
				name = team_name,
				color = team_color,
				model = team_model,
			}
			for key, value in pairs( group_data.team ) do
				if key ~= "model" and key ~= "name" and not key:find( "color" ) then
					new_team[ key ] = tonumber( value )
				end
			end
			if team_by_name[ team_name ] then
				table.insert( team_by_name[ team_name ].groups, group_name )
				table.Merge( team_by_name[ team_name ], new_team )
			else
				-- Make sure there's a color
				new_team.color = new_team.color or Color( 255, 255, 255, 255 )
				new_team.groups = { group_name }
				table.insert( ulx.teams, new_team )
				team_by_name[ team_name ] = new_team
			end
		end
	end

	table.sort( ulx.teams, sortTeams )
	for i=1, #ulx.teams do
		local team_data = ulx.teams[ i ]
		team.SetUp( next_team_index, team_data.name, team_data.color )
		team_data.index = next_team_index
		next_team_index = next_team_index + 1
	end

	local plys = player.GetAll()
	for i=1, #plys do
		local ply = plys[ i ]
		sendDataTo( ply )
		assignTeam( ply )
	end

	hook.Add( "PlayerInitialSpawn", "UTeamInitialSpawn", sendDataTo, -20 )
	hook.Add( "PlayerSpawn", "UTeamSpawnAuth", assignTeam, -20 )
	hook.Add( "UCLAuthed", "UTeamAuth", assignTeam, -20 )
end
hook.Add( "Initialize", "UTeamInitialize", ulx.refreshTeams, -20 )
