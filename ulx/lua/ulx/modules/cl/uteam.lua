ulx.teams = {}

function ulx.populateClTeams( teams )
	ulx.teams = teams

	for i=1, #teams do
		local team_data = teams[ i ]
		team.SetUp( team_data.index, team_data.name, team_data.color )
	end
end
