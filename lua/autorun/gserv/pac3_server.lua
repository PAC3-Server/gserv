local id = "gmod"

local config = {
	port = 27015,
	webserver_port = 5000,
	--webhook_port = 27020,
	--webhook_secret = "WEBHOOK_SECRET",
	workshop_authkey = "WORKSHOP_AUTHKEY",
	cfg = {
		sv_downloadurl = "\"http://threekelv.in:2080/downloadurl/\"",
	sv_loadingurl = "\"http://threekelv.in:2080/loadingscreen/\"",
		sv_hibernate_think = 1,
	},
	launch = {
		disableluarefresh = true,
	},
	startup = {
		map = "gm_bluehills_test3",
		maxplayers = 32,
	},
	screenshots = {
		"http://images.akamai.steamusercontent.com/ugc/97230215092227696/455104144247EA98BFAAA35B9274B08A17D570AB/",
		"http://images.akamai.steamusercontent.com/ugc/97229161714264905/F0FA90A9FB5910755BC46B49E613EE11A178AED7/",
		"http://images.akamai.steamusercontent.com/ugc/97228916908030276/AECB6D7E066B64426014E7A0BF4EE1AB9C681873/",
		"http://images.akamai.steamusercontent.com/ugc/91600752837319807/791BEE339F2B67A8D91D62D75F6BCC8680613BD8/",
		"http://images.akamai.steamusercontent.com/ugc/91599028254452016/B8B75CEDAA5EFB58195A1E6DC2C1DFDF44150DC7/",
		"https://steamuserimages-a.akamaihd.net/ugc/97230430500821067/13FEB065EE962E8A6B29BCAC6129FD8F4966FD8F/",
		"https://steamuserimages-a.akamaihd.net/ugc/97230430496415661/3C97D1849AE9F0D0BCC4EF4138A50195C4ED103C/",
		"https://steamuserimages-a.akamaihd.net/ugc/97230215092230276/1FE0D1F3C66C55CFEF84C78755D74B9B263B8FAF/",
		"https://steamuserimages-a.akamaihd.net/ugc/97229161714257807/18A0BACEB1BD94B44F4476BFCA6A92D8CAB28007/",
		"https://steamuserimages-a.akamaihd.net/ugc/97229161698792932/DEB524E482F574409BC7D7F2579B14BD05F9EAE8/",
		"https://steamuserimages-a.akamaihd.net/ugc/97229161714263160/CA771D4326457274174F8983CE3662D93D3403FF/",
		"https://steamuserimages-a.akamaihd.net/ugc/97229161698791256/B379F4CFDCCBCCE1EA684B5B4655B28A52777E9A/",
		"https://steamuserimages-a.akamaihd.net/ugc/97228916908030748/03C22F8F4A4FE3B3B619107150957967C51037C8/",
		"https://steamuserimages-a.akamaihd.net/ugc/97228916908029967/E8D599CEEBF3E6E606E8866D30E38034B2524252/",
		"https://steamuserimages-a.akamaihd.net/ugc/97228916907916701/09232615E4C0727A0126E913A29B1AA74722D09F/",
		"https://steamuserimages-a.akamaihd.net/ugc/97228916908022718/8F9B27111F3A95F29401FD8B8AEB6075FBCC083F/",
		"https://steamuserimages-a.akamaihd.net/ugc/97228527778365157/A9E59F85FB114A06F1089C2C55D8CF3D6AEF9E48/",
		"https://steamuserimages-a.akamaihd.net/ugc/97228527786942844/223F7B7AC6A305EB27233E73B659641DACB8DE29/",
		"https://steamuserimages-a.akamaihd.net/ugc/97228358436128892/645534E237A954C75519CA6E03142379766FF86F/",
		"https://steamuserimages-a.akamaihd.net/ugc/97228358436126615/5B491DC58B37B03DA9CBAEEB31620CCE36E27A9E/",
		"https://steamuserimages-a.akamaihd.net/ugc/97228358436114353/C1B1A41F9ECD5B3AA3D2A4AD7AABA70DA3768254/",
		"https://steamuserimages-a.akamaihd.net/ugc/97228358436112614/17DA9CF333AD4D28240AAA1288206D0A3F181E2C/",
		"https://steamuserimages-a.akamaihd.net/ugc/612794559809260304/C421A9B7CF78E32C03219AF8839AAAB09A83573D/",
		"https://steamuserimages-a.akamaihd.net/ugc/616176504162672221/297C2ABD226FCBBD8048C85FF9556ED41D0F022C/",
		"https://steamuserimages-a.akamaihd.net/ugc/597038027888276522/54A14DCFAEE534DD0DD0D50C5F8E12D4C7D68313/",
		"https://steamuserimages-a.akamaihd.net/ugc/612794559817667935/1FCE2B6D8FE9769C6BE036E462B325E4A36473DE/",
		"https://steamuserimages-a.akamaihd.net/ugc/612792385985920798/3941F843C632BB33963A292EAF8105486F330C0B/",
		"https://steamuserimages-a.akamaihd.net/ugc/612792385939765742/D9F0750DFA45D6374B4D724E207C4B3B1E0405F0/",
		"https://steamuserimages-a.akamaihd.net/ugc/616167640800093820/4C03BBE420810265A561D0B6AEF112AAC35B603C/",
		"https://steamuserimages-a.akamaihd.net/ugc/885254803422979463/DA2F25E4FD1995D178CCD9C911F9FF4640AE4FA3/",
		"https://steamuserimages-a.akamaihd.net/ugc/902138687653856475/DEE8A1C5CAE6DBA34BC61479757CD4B40E5E3146/",
		"https://steamuserimages-a.akamaihd.net/ugc/1101419084299998276/4FCAD1612192FCDE4DA50D09FB42EFD30C88AF4B/",
		"https://steamuserimages-a.akamaihd.net/ugc/1101417743046773832/C650C5027AD8243CB619729BEEBA68D6A6AD634F/",
		"https://steamuserimages-a.akamaihd.net/ugc/1117172369057112289/3E0D8E00C81393B026CE6C35095495B186FB194C/",
		"https://steamuserimages-a.akamaihd.net/ugc/1119423428174595077/94FF36387C3DA89B94B8465A1F95EF00A008D9C0/",
		"https://steamuserimages-a.akamaihd.net/ugc/1081139558301025615/AAF7CCA3FC04290369E021709B63C89CD331EB81/",
		"https://steamuserimages-a.akamaihd.net/ugc/1081137251474225812/84D661A95BD2BC3CF7C65F65B22AF617A3EC39DC/",
		"https://steamuserimages-a.akamaihd.net/ugc/1081137251492890743/0B556507570C8328E384A8DAD8DBE714DBA7AEAA/",
		"https://steamuserimages-a.akamaihd.net/ugc/1081135668698861985/5AECF40BD8B029C7EF479255D9036EB7F91C554F/",
		"https://steamuserimages-a.akamaihd.net/ugc/1081135668698870169/BC8307AA69C7B08F1D8BE619FF1D1AE21EB6ADD6/",
		"https://steamuserimages-a.akamaihd.net/ugc/1083386834462186322/FA240A7B28C11C43FCF47C4B3F4D4FBD14D401EC/",
		"https://steamuserimages-a.akamaihd.net/ugc/1083386834461739704/D5ECCB986335965342B2EF4B57D748E0F4609ED5/",
		"https://steamuserimages-a.akamaihd.net/ugc/1117162757625949215/9364184A2FCEE03DF780045E0BE3234F78DADA44/",
		"https://steamuserimages-a.akamaihd.net/ugc/1117162757625896014/2980BEB5125618421291B1C70E6ED7CF0D7AEDBC/",
		"https://steamuserimages-a.akamaihd.net/ugc/1117162757621563267/8EF48561651A065630397540DBDD4040FAF1AF8F/",
		"https://steamuserimages-a.akamaihd.net/ugc/1117161388836100046/3941397714DFC419F2E1EF0F80E6BAC46FBEAA29/",
		"https://steamuserimages-a.akamaihd.net/ugc/1118286662450502199/4EC49A544DFC86ADBFCAAFD3FB7AF07EA00A5B89/",
		"https://steamuserimages-a.akamaihd.net/ugc/1117159397298034969/50BF5C7239673A13A16CC2C32BA7EE61B34DA806/",
		"https://steamuserimages-a.akamaihd.net/ugc/1117158766048747007/41303081DB7C8CF047E8131B2401061CE1EE98E7/",
		"https://steamuserimages-a.akamaihd.net/ugc/1117158766007350447/AE26D0B2BAFE70CFEB4E1FE2F238DACA27F25150/",
		"https://steamuserimages-a.akamaihd.net/ugc/1118284034492070995/988554CE8363A6BEB45CE5453A7DBE8C3AE4A80A/",
		"https://steamuserimages-a.akamaihd.net/ugc/1099142547226737497/63850DE5DA1A41932B145267F13BDD581B8A5056/",
		"https://steamuserimages-a.akamaihd.net/ugc/1099142547226686008/18BA76D393B32D12B011705257EB970C52D6919A/",
		"https://steamuserimages-a.akamaihd.net/ugc/1099141251737665460/2B266AA8F0AE5B1BCE17EF78D31E2E9556271D85/",
		"https://steamuserimages-a.akamaihd.net/ugc/1099141251740225974/2D0D9F76F2ACEAEAA8114BE47501B1A1E4528C20/",
		"https://steamuserimages-a.akamaihd.net/ugc/1136291596828147048/881864B53DF977C46982A0D1F22AC7BDD9E3D83F/",
		"https://steamuserimages-a.akamaihd.net/ugc/1135164915844144485/BA7F007479B6B38EBC6C713CC1D9F6F3F7AA02CB/",
		"https://steamuserimages-a.akamaihd.net/ugc/1135163718326272324/10CC361453C2BBEBAE99C26D262FFC4E35D605A9/",
		"https://steamuserimages-a.akamaihd.net/ugc/1136287903723128040/996F947CDB74A5BF74CE5851B90F34CCA0B4E3BA/",
		"https://steamuserimages-a.akamaihd.net/ugc/1137411731740330911/04E39BD9234F2F0EB9F5805D37FAD9130450B1AE/",
		"https://steamuserimages-a.akamaihd.net/ugc/1136285104850872809/C118B53D481AC8EA7991C81F4E91D6BD871702C0/",
		"https://steamuserimages-a.akamaihd.net/ugc/1136285104850864904/DC054CFFB3EE7EE1147F9C39DA7F16B5F952D08D/",
		"https://steamuserimages-a.akamaihd.net/ugc/1136285104850772520/582D339EB0409C8FDA309B3940D85EAA2ADB31A0/",
		"https://steamuserimages-a.akamaihd.net/ugc/925927727228359320/848A08D5DE11EF955FBE0045DACABAD19BE58124/",
	},
	addons = {
		pac3 = {
			type = "git",
			branch = "develop",
			url = "https://github.com/CapsAdmin/pac3.git",
		},
		serverassets = "https://github.com/PAC3-Server/ServerAssets.git",
		workshop_addons = "https://github.com/PAC3-Server/workshop-addons.git",
		garrysmod = "https://github.com/PAC3-Server/garrysmod.git",
		notagain = "https://github.com/PAC3-Server/notagain.git",
		gm_http_discordrelay = "https://github.com/PAC3-Server/gm-http-discordrelay.git",

		gm_mediaplayer = "https://github.com/samuelmaddock/gm-mediaplayer.git",
		wire_extras = "https://github.com/wiremod/wire-extras.git",
		vj_base = "https://github.com/DrVrej/VJ-Base.git",
		sit_anywhere = "https://github.com/Xerasin/Sit-Anywhere.git",
		epoe = "https://github.com/Metastruct/EPOE.git",
		wire = "https://github.com/wiremod/wire.git",
		advdupe3 = "https://github.com/wiremod/advdupe2.git",
		
		gmodvr = "https://steamcommunity.com/sharedfiles/filedetails/?id=1678408548",

		-- workshop addons
		--maps
		gm_excess_construct = "https://steamcommunity.com/sharedfiles/filedetails/?id=174651081",
		gm_excess_islands = "https://steamcommunity.com/sharedfiles/filedetails/?id=115250988",
		gm_bluehills_test3 = "https://steamcommunity.com/sharedfiles/filedetails/?id=243902601",
		rp_chromeliner_v1 = "https://steamcommunity.com/sharedfiles/filedetails/?id=1898270711",
		gm_bigcity = "https://steamcommunity.com/sharedfiles/filedetails/?id=105982362",
		gm_excess_waters = "https://steamcommunity.com/sharedfiles/filedetails/?id=158910762",
		["gm_aquablocks!"] = "https://steamcommunity.com/sharedfiles/filedetails/?id=154093078",
		supersize_room = "https://steamcommunity.com/sharedfiles/filedetails/?id=104793138",
		rp_feudal = "https://steamcommunity.com/sharedfiles/filedetails/?id=1112581984",

		rt_camera = "https://steamcommunity.com/sharedfiles/filedetails/?id=106944414",

		sprops_workshop_edition = "https://steamcommunity.com/sharedfiles/filedetails/?id=173482196",
		playable_piano_fork = "http://steamcommunity.com/sharedfiles/filedetails/?id=741857902",


		explosive_entities = "https://steamcommunity.com/sharedfiles/filedetails/?id=129638197",
		wowozela = "https://steamcommunity.com/sharedfiles/filedetails/?id=108170491",
		propeller_engine = "https://steamcommunity.com/sharedfiles/filedetails/?id=108168963",
		vuvuzela = "https://steamcommunity.com/sharedfiles/filedetails/?id=109624491",
		mediaplayer = "https://steamcommunity.com/sharedfiles/filedetails/?id=546392647",
		precision_tool = "https://steamcommunity.com/sharedfiles/filedetails/?id=104482086",

		css_swep_pack = "https://steamcommunity.com/sharedfiles/filedetails/?id=108720350",

		physical_parent = "https://steamcommunity.com/sharedfiles/filedetails/?id=1328566021",
		smart_freezer = "http://steamcommunity.com/sharedfiles/filedetails/?id=107388767",
		improved_polyweld = "http://steamcommunity.com/sharedfiles/filedetails/?id=344795193",
		total_mass_tool = "http://steamcommunity.com/sharedfiles/filedetails/?id=129425927",
		smart_painter = "http://steamcommunity.com/sharedfiles/filedetails/?id=126566296",
		fin = "http://steamcommunity.com/sharedfiles/filedetails/?id=165509582",
		wing = "http://steamcommunity.com/sharedfiles/filedetails/?id=117908563",
		seat_weaponizer = "https://steamcommunity.com/sharedfiles/filedetails/?id=601411453",
		damage_in_seats = "https://steamcommunity.com/sharedfiles/filedetails/?id=428278317",
		unbreakable_tool = "https://steamcommunity.com/sharedfiles/filedetails/?id=111158387",
		smartsnap = "https://steamcommunity.com/sharedfiles/filedetails/?id=104815552",
		multi_parent_tool = "https://steamcommunity.com/sharedfiles/filedetails/?id=111929524",
		gesture_menu_commands = "https://steamcommunity.com/sharedfiles/filedetails/?id=145939873",
		precision_alignment = "https://steamcommunity.com/sharedfiles/filedetails/?id=457478322",
		smart_weld = "https://steamcommunity.com/sharedfiles/filedetails/?id=131586620",
		official_precision_tool = "https://steamcommunity.com/sharedfiles/filedetails/?id=104482086",
		make_spherical = "https://steamcommunity.com/sharedfiles/filedetails/?id=136318146",
		sub_material_tool = "https://steamcommunity.com/sharedfiles/filedetails/?id=405793043",
		smartnsap = "https://steamcommunity.com/sharedfiles/filedetails/?id=104815552",
		nocollide_everything = "https://steamcommunity.com/sharedfiles/filedetails/?id=105955548",
		doors = "https://steamcommunity.com/sharedfiles/filedetails/?id=499280258",
		unbreakable_tool = "https://steamcommunity.com/sharedfiles/filedetails/?id=111158387",
		weight_stool = "https://steamcommunity.com/sharedfiles/filedetails/?id=104480013",
		more_materials_stool = "https://steamcommunity.com/sharedfiles/filedetails/?id=105841291",
		improved_stacker = "https://github.com/Mista-Tea/improved-stacker.git",
		ragdoll_mover = "https://steamcommunity.com/sharedfiles/filedetails/?id=104575630",
	},
}

local gmod_dir = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/"

event.AddListener("GservWebhook", "update_addons", function(id, tbl)
	if tbl.repository and tbl.repository.html_url then
		local url = tbl.repository.html_url .. ".git"

		for name, info in pairs(config.addons) do
			local addon_url = type(info) == "table" and info.url or info

			if url:lower() == addon_url:lower() then
				llog(id .. " - received webhook to update " .. name .. " - " .. addon_url)
				gserv.UpdateAddon(id, name, info)
				-- relies on https://github.com/PAC3-Server/notagain/blob/master/lua/notagain/pac_server/autorun/server/auto_restart.lua
				vfs.Write(gmod_dir .. "data/server_want_restart.txt", name)
				return
			end
		end

		llog(id .. " - received webhook for " .. url .. " but addon does not exist")
	else
		llog(id .. " - bad payload?")
	end
end)

event.AddListener("GServStart", "gmod_webserver", function(id, gmod_dir, config)
	if not config.webserver_port then
		return
	end

	if GMOD_WEBSERVER then
		GMOD_WEBSERVER:Remove()
	end

	local server = sockets.HTTPServer()
	server.debug = true
	server:Host("*", config.webserver_port)
	GMOD_WEBSERVER = server

	function GMOD_WEBSERVER:Reply(client, header, body)
		body = body or ""
		table.insert(header, "Content-Length: " .. #body)
		client:Send(table.concat(header, "\r\n").."\r\n\r\n" .. body)
	end

	local allowed = {
		webhook = true,
		loadingscreen = true,
		downloadurl = true
	}

	local function client_path(client)
		local path = client.http.path:sub(2)
		if path:endswith("/") then
			path = path:sub(1, -2)
		end

		return path
	end

	local last

	function GMOD_WEBSERVER:OnReceiveResponse(client, method, path)
		local path = client_path(client):split("/")[1]

		if not allowed[path] then
			self:Reply(client, {
				"HTTP/1.1 404 Not found",
			})
			return false
		end
	end

	local secret = os.getenv("WEBHOOK_SECRET")

	function GMOD_WEBSERVER:OnReceiveBody(client)
		local path = client_path(client)

		if path == "webhook" then
			local tbl = sockets.HandleWebhookRequest(
				client,
				client.http.body,
				client.http.header["content-type"],
				secret,
				client.http.header["x-hub-signature"]
			)
			event.Call("GservWebhook", "gmod", tbl, client)
		end
	end

	function GMOD_WEBSERVER:OnReceiveHeader(client, headers)
		local path = client_path(client)

		if path:startswith("downloadurl") then
			local url = path:sub(#"downloadurl/" + 1)

			if fs.IsFile(gmod_dir .. "fastdl/" .. url) then
				GMOD_WEBSERVER:Reply(client, {
					"HTTP/1.1 200 OK",
					"Connection: keep-alive",
				}, fs.Read(gmod_dir .. "fastdl/" .. url))
			else
				llog("%s:%s unable to find %s", ip, port, "fastdl/" .. url)

				GMOD_WEBSERVER:Reply(client, {
					"HTTP/1.1 404 Not Found",
					"Connection: close",
				})
			end
		elseif path == "loadingscreen" and config.screenshots then
			GMOD_WEBSERVER:Reply(client, {
				"HTTP/1.1 200 OK",
				"Connection: close",
				"Content-Type: text/html",
			}, [[
				<!DOCTYPE html>
				<html>
				<style>
				body {
					background-color: black;
					background-size: cover;
					overflow: hidden;
					transition: background 1s ease-in 200ms;
				}
				</style>
				<script>
				let urls = [
					]]..(function() local str = {}
					for i,v in ipairs(config.screenshots) do
						table.insert(str, "\"" .. v .. "\"")
					end
					return table.concat(str, ",\n")
					end)()..[[
				]

				let cb = () => {
					let i = Math.floor(Math.random() * urls.length);
					document.getElementsByTagName("body")[0].style.backgroundImage = "url(" + urls[i] + ")"
				}
				setInterval(cb, 5000)
				cb()
				</script>

				<head></head>
				<body></body>

				</html>
			]])
		end
	end
end)

event.AddListener("GServStop", "gmod_webserver", function(id, gmod_dir)
	if GMOD_WEBSERVER then
		GMOD_WEBSERVER:Remove()
		GMOD_WEBSERVER = nil
	end
end)

local function setup(force_reinstall)
	gserv.InstallGMod(id, force_reinstall):Then(function(location)
		gserv.InstallGServ(location, config)
		--gserv.InstallGame("Counter-Strike: Source Dedicated Server")
		--gserv.InstallGame("Team Fortress 2 Dedicated Server")

		for key, info in pairs(config.addons) do
			gserv.UpdateAddon(id, key, info)
		end
	end)
end

local function remove_unknown_addons()
	local temp = {gserv = true}
	for k,v in pairs(config.addons) do
		temp[gserv.UnderscoreFileName(k)] = true
	end

	for _, name in ipairs(gserv.GetActiveAddons(id)) do
		if not temp[name] then
			logn("removing unknown addon " .. name)
			fs.RemoveRecursively(gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/addons/" .. name)
		end
	end
end

commands.Add(id .. " update_addons", function()
	for key, info in pairs(config.addons) do
		gserv.UpdateAddon(id, key, info)
	end
end)

commands.Add(id .. " setup", function()
	setup()
end)

commands.Add(id .. " update", function()
	setup(true)
end)

commands.Add(id .. " list_addons", function()
	local remaining = {}

	for key, info in pairs(config.addons) do
		remaining[gserv.UnderscoreFileName(key)] = {info = gserv.NormalizeAddonInfo(info), name = key}
	end

	-- discord
	log("__DISCORD_MESSAGE__")

	for _, name in ipairs(gserv.GetActiveAddons(id)) do
		local info = remaining[name]
		if info then
			if info.info.type == "workshop" then
				logn(info.name, " - ", "<https://steamcommunity.com/sharedfiles/filedetails/?id=" .. info.info.id .. ">" )
			elseif info.info.type == "git" then
				logn(info.name, " - ", "<" .. info.info.url .. ">")
			end
			remaining[name] = nil
		end
	end

	for name, info in pairs(remaining) do
		if info.info.type == "workshop" then
			logn(info.name, " - ", "<https://steamcommunity.com/sharedfiles/filedetails/?id=" .. info.info.id .. ">", " ** NOT INSTALLED ** ")
		elseif info.info.type == "git" then
			logn(info.name, " - ", "<" .. info.info.url .. ">", " ** NOT INSTALLED ** ")
		end
	end
end)

commands.Add(id .. " start", function()
	gserv.Start(id, config)
end)

commands.Add(id .. " stop", function()
	gserv.Stop(id)
end)

commands.Add(id .. " kill", function()
	gserv.Stop(id)
end)

commands.Add(id .. " dump", function()
	repl.NoColors(true)
	logn(gserv.GetOutput(id))
	repl.NoColors(false)
end)

commands.Add(id .. " restart=number[30]", function(time)
	gserv.ExecuteSync(id .. "", "aowl restart " .. time)
end)

commands.Add(id .. " status", function(code)
	logn(gserv.ExecuteSync(id, "status"))
end)

commands.Add(id .. " reboot", function()
	if gserv.IsRunning(id) then
		gserv.Stop(id)
	end
	gserv.Start(id, config)
end)

commands.Add(id .. " run=string_rest", function(str)
	logn(gserv.ExecuteSync(id, str))
end)
commands.Add(id .. " lua=string_rest", function(code)
	logn(gserv.ExecuteSync(id, "lua_run " .. code))
end)

commands.Add(id .. " attach", function()
	gserv.Attach(id)
end)

commands.Add(id .. " show", function()
	gserv.Attach(id)
end)


logn("starting " .. id)

local gmod_dir = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/"

if gserv.IsRunning(id) then
	gserv.InstallGServ(gmod_dir, config)
	gserv.Resume(id, config)
	return
else
	if not gserv.IsInstalled(4000) then
		setup()
	end

	remove_unknown_addons()

	gserv.InstallGServ(gmod_dir, config)
	gserv.Start(id, config)
end
