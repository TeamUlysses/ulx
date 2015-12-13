ulx.motdmenu_exists = true

local isUrl
local url

function ulx.showMotdMenu( steamid )
	local window = vgui.Create( "DFrame" )
	if ScrW() > 640 then -- Make it larger if we can.
		window:SetSize( ScrW()*0.9, ScrH()*0.9 )
	else
		window:SetSize( 640, 480 )
	end
	window:Center()
	window:SetTitle( "ULX MOTD" )
	window:SetVisible( true )
	window:MakePopup()

	local html = vgui.Create( "DHTML", window )
	--html:SetAllowLua( true ) -- Too much of a security risk for us to enable. Feel free to uncomment if you know what you're doing.

	local button = vgui.Create( "DButton", window )
	button:SetText( "Close" )
	button.DoClick = function() window:Close() end
	button:SetSize( 100, 40 )
	button:SetPos( (window:GetWide() - button:GetWide()) / 2, window:GetTall() - button:GetTall() - 10 )

	html:SetSize( window:GetWide() - 20, window:GetTall() - button:GetTall() - 50 )
	html:SetPos( 10, 30 )
	if not isUrl then
		html:SetHTML( ulx.generateMotdHTML() or "" )
	else
		url = string.gsub( url, "%%curmap%%", game.GetMap() )
		url = string.gsub( url, "%%steamid%%", steamid )
		html:OpenURL( url )
	end
end

function ulx.rcvMotd( isUrl_, data )
	isUrl = isUrl_
	if not isUrl then
		ulx.motdSettings = data
	else
		if data:find( "://", 1, true ) then
			url = data
		else
			url = "http://" .. data
		end
	end
end

local template_header = [[
<html>
	<head>
		<style>
			body {
				padding: 0;
				margin: 0;
				height: 100%;
				font-family: {{style.fonts.regular.family}};
				font-size: {{style.fonts.regular.size}};
				font-weight: {{style.fonts.regular.weight}};
				color: {{style.colors.text_color}};
				background-color: {{style.colors.background_color}};
			}
			h1 {
				font-family: {{style.fonts.server_name.family}};
				font-size: {{style.fonts.server_name.size}};
				font-weight: {{style.fonts.server_name.weight}};
			}
			h2 {
				font-family: {{style.fonts.section_title.family}};
				font-size: {{style.fonts.section_title.size}};
				font-weight: {{style.fonts.section_title.weight}};
				color: {{style.colors.section_text_color}};
			}
			h3 {
				font-family: {{style.fonts.subtitle.family}};
				font-size: {{style.fonts.subtitle.size}};
				font-weight: {{style.fonts.subtitle.weight}};
			}
			p {
				padding-left: 20px;
			}
			ul, ol {
				padding-left: 40px;
			}
			.container {
				min-height: 100%;
				position: relative;
			}
			.header, .footer {
				width: 100%;
				text-align: center;
				background-color: {{style.colors.header_color}};
				color: {{style.colors.header_text_color}};
			}
			.header {
				padding: 20px 0;
				border-bottom: {{style.borders.border_thickness}} solid {{style.borders.border_color}};
			}
			.footer {
				position:absolute;
				bottom:0;
				border-top: {{style.borders.border_thickness}} solid {{style.borders.border_color}};
				height: 68px;
			}
			.page {
				width: 90%;
				margin: 0px auto;
				padding: 10px;
				text-align: left;
				padding-bottom: 68px;
			}
			.section {
				margin-bottom: 32px;
			}
		</style>
	</head>
	<body>
		<div class="container">
			<div class="header">
				<h1>%hostname%</h1>
				<h3>{{info.description}}</h3>
			</div>
			<div class="page">
]]

local template_section = [[
				<div class="section">
					<h2>%title%</h2>
					%content%
				</div>
]]

local template_section_p = [[
					<p>
						%items%
					</p>
]]

local template_section_ol = [[
					<ol>
						%items%
					</ol>
]]

local template_section_ul = [[
					<ul>
						%items%
					</ul>
]]

local template_item_li = [[
						<li>%content%</li>
]]

local template_item_br = [[
						%content%</br>
]]

local template_item_addon = [[
						<li><b>%title%</b> by %author%</li>
]]

local template_item_workshop = [[
						<li><b>%title%</b> - <a href="http://steamcommunity.com/sharedfiles/filedetails/?id=%workshop_id%">View on Workshop</a></li>
]]

local template_footer = [[
			</div>
			<div class="footer">
				<h3>Powered by ULX</h3>
			</div>
		</div>
	</body>
</html>
]]

local function escape(str)
	return (str:gsub("<", "&lt;"):gsub(">", "&gt;")) -- Wrapped in parenthesis so we ignore other return vals
end

local function renderItemTemplate(items, template)
	local output = ""
	for i=1, #items do
		output = output .. string.gsub( template, "%%content%%", escape(items[i] or ""))
	end
	return output
end

local function renderMods()
	local output = ""
	for a=1, #ulx.motdSettings.addons do
		local addon = ulx.motdSettings.addons[a]
		if addon.workshop_id then
			local item = string.gsub( template_item_workshop, "%%title%%", escape(addon.title) )
			output = output .. string.gsub( item, "%%workshop_id%%", escape(addon.workshop_id or "") )
		else
			local item = string.gsub( template_item_addon, "%%title%%", escape(addon.title or "") )
			output = output .. string.gsub( item, "%%author%%", escape(addon.author or "") )
		end
	end

	return output
end

function ulx.generateMotdHTML()
	local header = string.gsub( template_header, "%%hostname%%", escape(GetHostName() or "") )
	header = string.gsub( header, "{{(.-)}}", function(a) return escape(ULib.findVar("ulx.motdSettings." .. a) or "") end )

	local body = ""

	for i=1, #ulx.motdSettings.info do
		local data = ulx.motdSettings.info[i]
		local content = ""

		if data.type == "text" then
			content = string.gsub( template_section_p, "%%items%%", renderItemTemplate(data.contents, template_item_br) )

		elseif data.type == "ordered_list" then
			content = string.gsub( template_section_ol, "%%items%%", renderItemTemplate(data.contents, template_item_li) )

		elseif data.type == "list" then
			content = string.gsub( template_section_ul, "%%items%%", renderItemTemplate(data.contents, template_item_li) )

		elseif data.type == "mods" then
			content = string.gsub( template_section_ul, "%%items%%", renderMods() )

		elseif data.type == "admins" then
			local users = {}
			for g=1, #data.contents do
				local group = data.contents[g]
				for u=1, #ulx.motdSettings.admins[group] do
					table.insert( users, ulx.motdSettings.admins[group][u] )
				end
			end
			table.sort( users )
			content = string.gsub( template_section_ul, "%%items%%", renderItemTemplate(users, template_item_li) )
		end

		local section = string.gsub( template_section, "%%title%%", escape(data.title or "") )
		body = body .. string.gsub( section, "%%content%%", content )
	end

	return string.format( "%s%s%s", header, body, template_footer )
end
