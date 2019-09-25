if not system.OSCommandExists("tmux", "tar") then return end

gserv = gserv or {}

gserv.logs = {}
gserv.configs = {}

gserv.default_config = {
	ip = nil,
	port = 27015,

	workshop_authkey = "WORKSHOP_AUTHKEY",
	workshop_collection = nil,

	webhook_port = nil, --27020
	webhook_secret = "WEBHOOK_SECRET",

	startup = {
		maxplayers = 32,
		map = "gm_construct",
	},

	launch = {
		disableluarefresh = "",
	},

	cfg = {
		sv_hibernate_think = 1, -- so pinger can run even if there are no players on the server
	},

	addons = {},
}

local function underscore(str)
	return str:lower():gsub("%p", ""):gsub("%s+", "_")
end

local function get_gmod_dir(id)
	return gserv.GetInstallDir(id) .. "/garrysmod/"
end

local function get_gserv_addon_dir(id)
	return get_gmod_dir(id) .. "addons/gserv/"
end

local srcds_dir = e.SHARED_FOLDER .. "srcds/"

local data_dir = "data/gserv/"

local function save_config(id)
	if not gserv.configs[id] then
		gserv.configs[id] = table.merge(table.copy(gserv.default_config), {id = id})
	end
	serializer.WriteFile("luadata", data_dir .. "configs/" .. underscore(id) .. ".lua", gserv.configs[id])
end

local function load_config(id)
	if not gserv.configs[id] then
		local config = serializer.ReadFile("luadata", data_dir .. "configs/" .. underscore(id) .. ".lua") or {}
		config.id = id
		gserv.configs[id] = table.merge(table.copy(gserv.default_config), config)
		save_config(id)
	end
end

local function check_setup(id)
	local ok, err = gserv.IsSetup(id)
	if not ok then
		error("server is not setup " .. err, 3)
	end
end

local function check_running(id)
	if not gserv.IsRunning(id) then
		error("server is not running", 3)
	end
end

function gserv.Log(id, ...)
	logn("[", id, "] ", ...)
end

function gserv.IsSetup(id)
	if not gserv.GetInstallDir(id) then
		return false, "unable to find installation directory from " .. id
	end

	if not vfs.IsFile(gserv.GetInstallDir(id) .. "/srcds_run") then
		return false, "unable to find " .. gserv.GetInstallDir(id) .. "/srcds_run"
	end

	if not vfs.IsFile(get_gserv_addon_dir(id) .. "lua/autorun/server/gserv.lua") then
		return false, "unable to find " .. get_gserv_addon_dir(id) .. "lua/autorun/server/gserv.lua"
	end

	return true
end

function gserv.WriteData(id, str)
	local prev = vfs.Read(get_gmod_dir(id) .. "data/gserv_data_gserv2gmod.txt") or ""
	vfs.Write(get_gmod_dir(id) .. "data/gserv_data_gserv2gmod.txt", prev .. str .. "¥$£@DELIMITER@£$¥")
end

function gserv.ReadData(id)
	local data = vfs.Read(get_gmod_dir(id) .. "data/gserv_data_gmod2gserv.txt")
	vfs.Write(get_gmod_dir(id) .. "data/gserv_data_gmod2gserv.txt", "")

	if data and data ~= "" then
		for _, chunk in ipairs(data:split("¥$£@DELIMITER@£$¥")) do
			if chunk ~= "" then
				event.Call("GServMessage", chunk)
			end
		end
	end
end

function gserv.SetupLua(id)
	vfs.CreateDirectoriesFromPath("os:" .. get_gserv_addon_dir(id) .. "lua/autorun/server/")

	vfs.Write(get_gserv_addon_dir(id) .. "lua/autorun/server/gserv.lua", [[
		gserv = {}

		function gserv.WriteData(str)
			file.Append("gserv_data_gmod2gserv.txt", str .. "¥$£@DELIMITER@£$¥")
		end

		function gserv.ReadData()
			local data = file.Read("gserv_data_gserv2gmod.txt", "DATA")
			file.Write("gserv_data_gserv2gmod.txt", "")

			if data and data ~= "" then
				for _, chunk in ipairs(data:Split("¥$£@DELIMITER@£$¥")) do
					if chunk ~= "" then
						hook.Run("GServMessage", chunk)
					end
				end
			end
		end

		do
			local last_time
			hook.Add("Think", "gserv_read_data", function()
				if file.Time("gserv_data_gserv2gmod.txt", "DATA") ~= last_time then
					gserv.ReadData()
				end
			end)
		end

		do
			_G.OLD_HTTP = _G.OLD_HTTP or _G.HTTP
			local active = {}

			function HTTP(tbl)
				if tbl and tbl.url and tbl.url:find("discordapp%.com%/api") then
					local uid = tostring(tbl)
					active[uid] = tbl

					local tbl = table.Copy(tbl)
					tbl.type = "HTTP"
					tbl.uid = uid

					tbl.success = nil
					tbl.failed = nil

					gserv.WriteData(util.TableToJSON(tbl))

					return
				end

				return _G.OLD_HTTP(tbl)
			end

			hook.Add("GServMessage", "gserv_http", function(str)
				local data = util.JSONToTable(str)
				if data and data.type == "HTTP" and active[data.uid] then
					if data.success and active[data.uid].success then
						active[data.uid].success(unpack(data.success))
					elseif data.failed and active[data.uid].failed then
						active[data.uid].failed(data.failed)
					end
				end
			end)
		end

		timer.Create("gserv_pinger", 1, 0, function()
			file.Write("gserv_pinger.txt", os.time())
		end)

		local extensions = {
			vmt = {"vtf"},
			mdl = {"vvd", "ani", "dx80.vtx", "dx90.vtx", "sw.vtx", "phy", "jpg"}
		}

		timer.Simple(0.01, function()
			local found = {}

			for path, type in pairs(GSERV_RESOURCE_FILES) do
				if type == "AddFile" then
					local path, ext = path:match("(.+/.-)%.(.+)")
					if extensions[ext] then
						for k, v in pairs(file.Find(path:match("(.+/)") .. "*", "GAME")) do
							for _, ext2 in ipairs(extensions[ext]) do
								if v:EndsWith("." .. ext2) then
									found[path .. "." .. ext2] = true
								end
								break
							end
						end
					end
				end
				if file.Exists(path, "GAME") then
					found[path] = true
				end
			end

			do
				local path = "maps/" .. game.GetMap() .. ".bsp"

				if file.Exists(path, "GAME") then
					found[path] = true
				end
			end

			do
				local path = "maps/" .. game.GetMap() .. ".nav"

				if file.Exists(path, "GAME") then
					found[path] = true
				end
			end

			local txt = ""
			for path in pairs(found) do
				txt = txt .. path .. "\n"
			end
			file.Write("gserv_resource_files.txt", txt)
		end)


	]])

	vfs.Write(get_gmod_dir(id) .. "cfg/server.cfg", "exec gserv.cfg\n")

	-- silence some startup errors
	vfs.Write(get_gmod_dir(id) .. "cfg/trusted_keys_base.txt", "trusted_key_list\n{\n}\n")
	vfs.Write(get_gmod_dir(id) .. "cfg/pure_server_minimal.txt", "whitelist\n{\n}\n")
	vfs.Write(get_gmod_dir(id) .. "cfg/network.cfg", "")

	gserv.BuildMountConfig(id)

	gserv.SetupCommands(id)

	local lua = vfs.Read(get_gmod_dir(id) .. "lua/includes/util.lua")
	if not lua then
		print("unable to find " .. get_gmod_dir(id) .. "lua/includes/util.lua")
		lua = ""
	end

	if not lua:find("GSERV_RESOURCE_FILES") then
		lua = lua .. [[
if SERVER then
GSERV_RESOURCE_FILES = {}
do
	local old = resource.AddFile
	function resource.AddFile(path, ...)
		GSERV_RESOURCE_FILES[path] = "AddFile"
		return old(path, ...)
	end
end
do
	local old = resource.AddSingleFile
	function resource.AddSingleFile(path, ...)
		GSERV_RESOURCE_FILES[path] = "AddSingleFile"
		return old(path, ...)
	end
end
end
]]
		vfs.Write(get_gmod_dir(id) .. "lua/includes/util.lua", lua)
	end
end

function gserv.Setup(id)
	if gserv.IsRunning(id) then error("server is running", 2) end

	if gserv.IsSetup(id) then
		gserv.Log(id, "server is already setup")
	else
		local ok, reason = gserv.IsSetup(id)
		gserv.Log(id, "setting server from the beginning (" .. reason .. ")")

		if vfs.IsFile(data_dir .. "configs/" .. underscore(id) .. ".lua") then
			gserv.Log(id, "found old config, using that as the initial setup")
			local config = serializer.ReadFile("luadata", data_dir .. "configs/" .. underscore(id) .. ".lua") or {}
			config.id = id
			gserv.configs[id] = table.merge(table.copy(gserv.default_config), config)
		end
	end

	save_config(id)

	gserv.InstallGame("gmod dedicated server", nil, function()
		local dir = underscore(id)

		os.execute("cp --verbose -a " .. gserv.GetInstalledGames()[4020] .. "/. " .. srcds_dir .. dir)
		serializer.StoreInFile("luadata", data_dir .. "games.lua", id, srcds_dir .. dir)
		gserv.installed_games = serializer.ReadFile("luadata", data_dir .. "games.lua")

		gserv.SetupLua(id)
	end)
end

commands.Add("gserv setup=string[gserv]", function(id) gserv.Setup(id) end)
commands.Add("gserv update_game=string|number,string|nil", function(name) gserv.UpdateGame(name, dir) end)
commands.Add("gserv install_game=string|number,string|nil,string|nil", function(name, dir, username) gserv.InstallGame(name, dir, nil, username) end)

function gserv.SetupCommands(id)
	commands.Add(id .. " start", function() gserv.Start(id) end)
	commands.Add(id .. " stop", function() gserv.Stop(id) end)
	commands.Add(id .. " kill", function() gserv.Kill(id) end)
	commands.Add(id .. " dump", function() gserv.Dump(id) end)
	commands.Add(id .. " restart=number[30]", function(time) gserv.Restart(id, time) end)
	commands.Add(id .. " reboot", function() gserv.Reboot(id) end)

	commands.Add(id .. " add_addon=string,string|nil,string|nil", function(url, override, branch) gserv.AddAddon(id, url, override, branch) gserv.UpdateAddon(id, url) end)
	commands.Add(id .. " remove_addon=string", function(url) gserv.RemoveAddon(id, url) end)
	commands.Add(id .. " update_addon=string", function(url) gserv.UpdateAddon(id, url) end)
	commands.Add(id .. " update_addons", function() gserv.UpdateAddons(id) end)
	commands.Add(id .. " scan_addons", function() gserv.ScanAddons(id) end)

	commands.Add(id .. " setup_info", function() check_setup(id) table.print(gserv.configs[id]) end)
	commands.Add(id .. " reload_config", function() check_setup(id) gserv.ReloadConfig(id) end)

	commands.Add(id .. " set_startup_param=string,string", function(key, val) gserv.SetStartupParameter(id, key, val) end)
	commands.Add(id .. " set_launch_param=string,string|nil", function(key, val) gserv.SetLaunchParameter(id, key, val) end)
	commands.Add(id .. " remove_launch_param=string,string|nil", function(key, val) gserv.RemoveLaunchParameter(id, key) end)
	commands.Add(id .. " set_config_param=string,string|nil", function(key, val) gserv.SetConfigParameter(id, key, val) end)

	commands.Add(id .. " run=string_rest", function(str) logn(gserv.ExecuteSync(id, str)) end)
	commands.Add(id .. " lua=string_rest", function(code) logn(gserv.RunLua(id, code)) end)
	commands.Add(id .. " attach", function() gserv.Attach(id) end)
	commands.Add(id .. " show", function() gserv.Attach(id) end)
end

function gserv.UpdateGame(id)
	gserv.InstallGame("gmod dedicated server", nil, function(appid)
		if appid == 4020 then
			os.execute("cp -a -rf " .. gserv.GetInstalledGames()[4020] .. "/. " .. srcds_dir .. underscore(id))
		end
	end)
end

function gserv.InstallGame(name, dir, callback, username)
	local appid, full_name = steam.GetAppIdFromName(name)
	if not appid and tonumber(name) then
		appid = tonumber(name)
	end

	if not appid then
		error("could not find " .. name, 2)
	end

	username = username or "anonymous"

	-- create the srcds directory in goluwa/data/srcds
	vfs.CreateDirectory("os:" .. srcds_dir)

	-- download steamcmd
	resource.Download("http://media.steampowered.com/client/steamcmd_linux.tar.gz"):Then(function(path)

		-- if steamcmd.sh does not exist then we need to extract it
		if not vfs.IsFile(srcds_dir .. "steamcmd.sh") then
			os.execute("tar -xvzf " .. vfs.GetAbsolutePath(path) .. " -C " .. srcds_dir)
		end

		local dir_name = dir or underscore(full_name)

		llog("installing ", name, " (", appid, ")", " to ", srcds_dir .. dir_name)

		serializer.StoreInFile("luadata", data_dir .. "games.lua", appid, srcds_dir .. dir_name)
		gserv.installed_games = serializer.ReadFile("luadata", data_dir .. "games.lua")
		repl.OSExecute(srcds_dir .. "steamcmd.sh +login " .. username .. " +force_install_dir \"" .. srcds_dir .. dir_name .. "\" +app_update " .. appid .. " +quit")

		llog("done")
		if callback then callback(appid) end
	end)
end

function gserv.GetInstallDir(id)
	return gserv.GetInstalledGames()[id]
end

function gserv.GetInstalledGames()
	return gserv.installed_games
end

function gserv.BuildMountConfig(id)

	local mountdepots_txt = '"gamedepotsystem"\n'
	mountdepots_txt = mountdepots_txt .. "{\n"

	local mounts_cfg = '"mountcfg"\n'
	mounts_cfg = mounts_cfg .. "{\n"

	for appid, dir in pairs(gserv.GetInstalledGames()) do
		if type(appid) == "number" and appid ~= 4020 then
			for _, dir in ipairs(vfs.Find(dir .. "/", true)) do
				local gameinfo = vfs.IsFile(dir .. "/gameinfo.txt")
				if gameinfo then
					local name = dir:match(".+/(.+)")

					mounts_cfg = mounts_cfg .. "\t\"" .. name .. "\"\t\t" .. "\""..dir.."\"\n"
					mountdepots_txt = mountdepots_txt .. "\t\"" .. name .. "\"\t\"1\"\n"
				end
			end
		end
	end

	mounts_cfg = mounts_cfg .. "}"
	mountdepots_txt = mountdepots_txt .. "}"

	vfs.Write(get_gmod_dir(id) .. "cfg/mount.cfg", mounts_cfg)
	vfs.Write(get_gmod_dir(id) .. "cfg/mountdepots.txt", mountdepots_txt)
end

function gserv.ReloadConfig(id)
	local old = gserv.configs[id]

	gserv.configs[id] = nil
	load_config(id)
	gserv.BuildConfig(id)
end

do
	function gserv.SetConfigParameter(id, key, val)
		load_config(id)
		gserv.configs[id].cfg[key] = val
		save_config(id)

		gserv.BuildConfig(id)

		if gserv.IsRunning(id) and val then
			gserv.Execute(id, key .. " " .. val)
		end
	end

	function gserv.GetConfigParameter(id, key)
		load_config(id)
		return gserv.configs[id].cfg[key]
	end

	function gserv.BuildConfig(id)
		check_setup(id)

		-- write the cfg file
		local str = ""
		for k,v in pairs(gserv.configs[id].cfg) do
			str = str .. k .. " " .. v .. "\n"
		end
		vfs.Write(get_gmod_dir(id) .. "cfg/gserv.cfg", str)
	end
end

do
	function gserv.SetStartupParameter(id, key, val)
		load_config(id)

		gserv.configs[id].startup[key] = val

		save_config(id)
	end

	function gserv.GetStartupParameter(id, key)
		load_config(id)

		return gserv.configs[id].startup[key]
	end

	function gserv.SetLaunchParameter(id, key, val)
		load_config(id)

		gserv.configs[id].launch[key] = val or ""

		save_config(id)
	end

	function gserv.RemoveLaunchParameter(id, key)
		load_config(id)

		gserv.configs[id].launch[key] = nil

		save_config(id)
	end

	function gserv.GetLaunchParameter(id, key)
		load_config(id)

		return gserv.configs[id].launch[key]
	end
end

do -- addons
	function gserv.UpdateAddons(id)
		check_setup(id)

		for url, info in pairs(gserv.GetAddons(id)) do
			gserv.UpdateAddon(id, url)
		end
	end

	function gserv.UpdateAddon(id, url)
		check_setup(id)

		local info = gserv.GetAddon(id, url)

		if not info then
			error("no such addon: " .. url)
		end

		if info.type == "git" then
			gserv.Log(id, "updating git repository addon ", info.url)
			local dir = get_gmod_dir(id) .. "addons/" .. info.name
			local branch = info.branch or "master"

			if not vfs.IsDirectory(dir) then
				repl.OSExecute("git clone -b " .. branch .. " " .. info.url .. " '" .. dir .. "' --depth 1")
			else
				repl.OSExecute("git -C '" .. dir .. "' fetch && git -C '" .. dir .. "' reset --hard origin/" .. branch .. " && git -C '" .. dir .. "' clean -f -d")
			end
			gserv.Log(id, "done updating ", info.url)
		elseif info.type == "workshop" then
			gserv.Log(id, "updating workshop addon ", info.url)
			steam.DownloadWorkshop(info.id, function(path, workshop_info)
				local name = info.name

				-- if the name is just the id make it more readable
				if info.id == name then
					info.name = vfs.ReplaceIllegalPathSymbols(workshop_info.publishedfiledetails[1].title, true) .. "_" .. name
					save_config(id)
				end

				vfs.Write(get_gmod_dir(id) .. "addons/" .. name .. ".gma", path)

				repl.OSExecute(gserv.GetInstallDir(id) .. "/bin/gmad_linux extract -file " .. get_gmod_dir(id) .. "addons/" .. name ..".gma -out " .. get_gmod_dir(id) .. "addons/" .. name)

				vfs.Delete(get_gmod_dir(id) .. "addons/" .. name .. ".gma")

				gserv.Log(id, "done updating ", info.url)
			end)
		end
	end

	function gserv.AddAddon(id, url, name_override, branch)
		load_config(id)

		local key = url
		local info

		if url:find("github.com", nil, true) and not url:endswith(".git") then
			url = url .. ".git"
		end

		if url:endswith(".git") then
			info = {
				type = "git",
				name = name_override or url:match(".+/(.+)%.git"):lower(),
				branch = branch or "master",
			}
		elseif url:find("steamcommunity") and url:find("id=%d+") or tonumber(url) then
			info = {
				id = url:match("id=(%d+)") or url,
				type = "workshop",
				name = name_override or url:match("id=(%d+)") or url,
			}
		else
			error("could not determine addon type from: " .. url, 2)
		end

		info.key = key
		info.url = url

		gserv.configs[id].addons[key] = info

		save_config(id)

		gserv.Log(id, "added addon")
		table.print(info)

		return info
	end

	function gserv.RemoveAddon(id, url)
		check_setup(id)
		load_config(id)

		local info = gserv.GetAddon(id, url)

		if not info then
			error("no such addon: " .. url)
		end

		local path = get_gmod_dir(id) .. "addons/" .. info.name

		local dir

		if vfs.IsDirectory(path) then
			dir = path
		elseif info.id then
			local found = vfs.Find(get_gmod_dir(id) .. "addons/" .. info.id, true)
			if #found == 1 and vfs.IsDirectory(found[1]) then
				dir = found[1]
			end
		end

		if not dir then
			gserv.Log(id, "could not find the addon directory")
		end

		if dir then
			local ok = false

			if info.type == "git" then
				local cfg = vfs.Read(dir .. "/.git/config")
				local url = cfg:match("%[remote \"origin\"%]%s+url = (.-)\n")

				if url == info.key then
					ok = true
				else
					gserv.Log(id, "not deleting directory because remote origin is different (not owned by gserv?)")
				end
			end

			if ok then
				os.execute("rm -rf '" .. dir .. "'")
			end
		end

		-- LEGACY
		if not info.key then
			for k,v in pairs(gserv.configs[id].addons) do
				if v == info then
					gserv.configs[id].addons[k] = nil
					break
				end
			end
		end

		gserv.configs[id].addons[info.key] = nil

		save_config(id)

		gserv.Log(id, "removed addon")
		table.print(info)
	end

	function gserv.GetAddon(id, url)
		load_config(id)

		local info = gserv.configs[id].addons[url]

		if not info then
			for _, info in pairs(gserv.GetAddons(id)) do
				if info.name:lower() == url:lower() then
					return info
				end
			end
		end

		return info
	end

	function gserv.GetAddons(id)
		load_config(id)

		return gserv.configs[id].addons
	end

	function gserv.ScanAddons(id)
		gserv.Log(id, "looking for new git addons .. ")
		local found = 0
		for _, dir in ipairs(vfs.Find(get_gmod_dir(id) .. "addons/", true)) do
			if vfs.IsFile(dir .. "/.git/config") then
				local cfg = vfs.Read(dir .. "/.git/config")
				local url = cfg:match("%[remote \"origin\"%]%s+url = (.-)\n")
				if not gserv.GetAddon(id, url) then
					local name = url:match(".+/(.+)"):lower()

					for k, v in pairs(gserv.GetAddons(id)) do
						if v.name == name then
							error("there is already an addon with the name " .. name .. " remove it with '" .. id .. " remove_addon " .. v.key .. "' and run this command again")
						end
					end

					gserv.AddAddon(id, url)

					found = found + 1
				end
			end
		end
		if found == 0 then
			gserv.Log(id, "found no new git addons to add")
		end
	end
end

do
	function gserv.IsRunning(id)
		local f = assert(io.popen("tmux has-session -t srcds_"..underscore(id).."_goluwa 2>&1"))
		local ok = f:read("*all") == ""
		f:close()
		return ok
	end

	local function fastdl(from, to)
		vfs.CreateDirectory("os:" .. to:match("(.+/)"))
		os.executeasync("ln " .. from .. " " .. to .. " 2>/dev/null")
		os.executeasync("bzip2 --best -c " .. from .. " > " .. to .. ".bz2" .. " 2>/dev/null")
	end

	local function start_listening(id)
		event.Timer("gserv_listener_" .. underscore(id), 1, 0, function()
			local time = vfs.Read(get_gmod_dir(id) .. "data/gserv_pinger.txt")

			if time then
				time = tonumber(time)
				local diff = os.difftime(os.time(), time)
				if diff > 1 then
					gserv.Log(id, "server hasn't responded for more than ", diff ," seconds")
					if diff > 60 then
						gserv.Reboot(id)
					end
				end
			end

			local paths = serializer.ReadFile("newline", get_gmod_dir(id) .. "data/gserv_resource_files.txt")
			if paths then
				gserv.Log(id, "updating fastdl folder")
				vfs.CreateDirectory("os:" .. get_gmod_dir(id) .. "fastdl/")
				for _, path in ipairs(paths) do
					if path:startswith("maps/") then
						if vfs.IsFile(get_gmod_dir(id) .. "/" .. path) then
							fastdl(get_gmod_dir(id) .. "/" .. path, get_gmod_dir(id) .. "fastdl/" .. path)
						end
					end
					for _, dir in ipairs(vfs.Find(get_gmod_dir(id) .. "addons/", true)) do
						if vfs.IsFile(dir .. "/" .. path) then
							fastdl(dir .. "/" .. path, get_gmod_dir(id) .. "fastdl/" .. path)
							break
						end
					end
				end
				vfs.Delete(get_gmod_dir(id) .. "data/gserv_resource_files.txt")
			end
		end)

		do
			local last_time
			event.AddListener("Update", "gserv_message_" .. underscore(id), function()
				local time = vfs.GetLastModified(get_gmod_dir(id) .. "data/gserv_data_gmod2gserv.txt")
				if time ~= last_time then
					gserv.ReadData(id)
					last_time = time
				end
			end)
		end

		if gserv.configs[id].webhook_port then
			sockets.StartWebhookServer(gserv.configs[id].webhook_port, os.getenv(gserv.configs[id].webhook_secret), function(...) event.Call("GservWebhook", id, ...) end)
		end
	end

	local function stop_listening(id)
		vfs.Delete(get_gmod_dir(id) .. "data/gserv_pinger.txt")
		vfs.Delete(get_gmod_dir(id) .. "data/gserv_resource_files.txt")

		event.RemoveTimer("gserv_listener_" .. underscore(id))

		if gserv.configs[id].webhook_port then
			sockets.StopWebhookServer(gserv.configs[id].webhook_port)
		end
	end

	function gserv.Resume(id)
		if gserv.IsRunning(id) then
			gserv.Log(id, "resuming server")

			start_listening(id)
		end
	end

	function gserv.Start(id)
		check_setup(id)

		if gserv.IsRunning(id) then error("server is running", 2) end

		load_config(id)

		gserv.Log(id, "starting gmod server")

		stop_listening(id)

		os.execute("tmux kill-session -t srcds_"..underscore(id).."_goluwa 2>/dev/null")
		os.execute("tmux new-session -d -s srcds_"..underscore(id).."_goluwa")

		gserv.logs[id] = "gserv/logs/" .. os.date("%Y/%m/%d/%H-%M-%S.txt")
		vfs.Write("data/" .. gserv.logs[id], "")
		serializer.WriteFile("luadata", data_dir .. underscore(id) .. "_server_state", {id = id, log_path = gserv.logs[id]})
		os.execute("tmux pipe-pane -o -t srcds_"..underscore(id).."_goluwa 'cat >> " .. R("data/" .. gserv.logs[id]) .. "'")

		gserv.BuildConfig(id)
		gserv.SetupLua(id)

		local str = ""
		for k, v in pairs(gserv.configs[id].startup) do
			str = str .. "+" .. k .. " " .. v .. " "
		end

		if gserv.configs[id].workshop_collection then
			local collection_id = tonumber(gserv.configs[id].workshop_collection) or gserv.configs[id].workshop_collection:match("id=(%d+)") or gserv.configs[id].workshop_collection
			str = str .. "+host_workshop_collection " .. collection_id  .. " "
		end

		local key = gserv.configs[id].workshop_authkey and os.getenv(gserv.configs[id].workshop_authkey)

		if key then
			str = str .. "-authkey " .. key .. " "
		else
			gserv.Log(id, "workshop auth key not setup")
		end


		str = str .. "-port " .. gserv.configs[id].port .. " "

		for k, v in pairs(gserv.configs[id].launch) do
			str = str .. "-" .. k .. " " .. v .. " "
		end

		os.execute("tmux send-keys -t srcds_"..underscore(id).."_goluwa \"sh '" .. gserv.GetInstallDir(id) .. "/srcds_run' -game garrysmod " .. str .. "\" C-m")

		start_listening(id)
	end

	function gserv.Kill(id)
		vfs.Delete(data_dir .. underscore(id) .. "_server_state")
		stop_listening(id)

		gserv.Log(id, "killing gmod server")
		os.execute("tmux kill-session -t srcds_"..underscore(id).."_goluwa 2>/dev/null")
	end

	function gserv.Reboot(id)
		if gserv.IsRunning(id) then
			gserv.Kill(id)
		end
		gserv.Start(id)
	end

end

function gserv.GetOutput(id)
	check_running(id)

	local str = assert(vfs.Read(gserv.logs[id]))
	str = str:gsub("\r", "")

	return str
end

function gserv.Dump(id)
	check_running(id)
	repl.NoColors(true)
	logn(gserv.GetOutput(id))
	repl.NoColors(false)
end

function gserv.Execute(id, line)
	check_running(id)

	os.execute("tmux send-keys -t srcds_"..underscore(id).."_goluwa \"" .. line .. "\" C-m")
end

function gserv.ExecuteSync(id, str)
	local delimiter = "goluwa_gserv_ExecuteSync_" .. os.clock()
	local prev = gserv.GetOutput(id)

	gserv.Execute(id, str)
	gserv.Execute(id, "echo " .. delimiter)

	local end_line = "echo "..delimiter.."\n"..delimiter.." \n"
	local current

	local timeout = os.clock() + 1

	repeat
		if timeout < os.clock() then
			error("Waiting for output took more than 1 second.\nUse gserv show to dump all output.")
		end

		current = gserv.GetOutput(id)
	until current:endswith(end_line)

	local res = current:sub(#prev + #str + 1):sub(2, -#end_line - 2)

	-- gserv run print(1) will print the echo line twice so do this just in case for cleaner output
	res = res:replace("echo "..delimiter .. "\n", "")

	return res
end

function gserv.Stop(id)
	check_running(id)

	gserv.Execute(id, "exit")

	event.Delay(1, function()
		gserv.Kill(id)
	end)
end

function gserv.RunLua(id, line)
	check_running(id)

	return gserv.ExecuteSync(id, "lua_run " .. line)
end

-- this is really stupid but idk what else to do at the moment
function gserv.GetLuaOutput(id, line)
	check_running(id)

	local id = tostring({})
	gserv.RunLua(id, "file.Write('gserv_capture_output.txt', '" .. id .."' .. tostring((function()"..line.."end)()), 'DATA')")
	while true do
		local str = vfs.Read(get_gmod_dir() .. data_dir .. "capture_output.txt")
		if str and str:startswith(id) then
			return str:sub(#id + 1)
		end
	end
end

function gserv.GetMap(id)
	check_running(id)

	gserv.ExecuteSync(id, "lua_run print(game.GetMap())")
end

function gserv.Attach(id)
	check_running(id)
	gserv.Execute(id, "echo to detach hold CTRL and press the following keys: *hold CTRL* b b *release CTRL* d")
	repl.OSExecute("unset TMUX; tmux attach -t srcds_"..underscore(id).."_goluwa")
end

function gserv.Restart(id, time)
	check_running(id)

	time = time or 0
	gserv.Log(id, "restarting server in ", time, " seconds")
	gserv.RunLua(id, "if aowl then RunConsoleCommand('aowl', 'restart', '"..time.."') else timer.Simple("..time..", function() RunConsoleCommand('changelevel', game.GetMap()) end) end")
end

for _, path in ipairs(vfs.Find("lua/gserv/configs/", true)) do
	local config = runfile(path)
	gserv.configs[config.id] = config
	gserv.SetupCommands(config.id)

	gserv.Log(config.id, "loaded config from " .. path)
end

for _, path in ipairs(vfs.Find(data_dir .. "configs/", true)) do
	local config = serializer.ReadFile("luadata", path)
	if config and config.id and not gserv.configs[config.id] then
		gserv.configs[config.id] = config
		gserv.SetupCommands(config.id)
	end
end

if not CLI then
	gserv.installed_games = gserv.installed_games or serializer.ReadFile("luadata", data_dir .. "games.lua") or {}

	for _, path in ipairs(vfs.Find(data_dir, true)) do
		if path:endswith("_server_state") then
			local data = serializer.ReadFile("luadata", path)
			gserv.Resume(data.id)
			gserv.logs[data.id] = data.log_path
		end
	end
end

if GMOD or CAPSADMIN then
	event.AddListener("GservWebhook", "update_addons", function(id, tbl)
		if tbl.repository and tbl.repository.html_url then
			local url = tbl.repository.html_url .. ".git"
			local info = gserv.GetAddon(id, url)
			if info then
				gserv.UpdateAddon(id, url)
				vfs.Write(get_gmod_dir(id) .. "data/server_want_restart.txt", info.name)
			else
				gserv.Log(id, "received webhook for ", url, " but addon does not exist")
			end
		else
			gserv.Log(id, "bad payload?")
		end
	end)

	event.AddListener("GServMessage", "gmod_HTTP_goluwa", function(data)
		local ok, data = pcall(serializer.Decode, "json", data)
		if ok and data then
			if data.type == "HTTP" then
				data.headers = data.headers or {}
				data.headers["Content-Type"] = data.headers["Content-Type"] or "text/plain; charset=utf-8"

				sockets.Request({
					url = data.url,
					callback = function(data_)
						data.success = {data_.code, data_.body, data_.header}
						gserv.WriteData("gmod", serializer.Encode("json", data))
					end,
					error_callback = function(msg)
						data.failed = msg
						gserv.WriteData("gmod", serializer.Encode("json", data))
					end,
					method = (data.method or "get"):upper(),
					header = data.headers,
					post_data = data.body or data.parameters,
				})
			end
		end
	end)

	do
		local id = "gmod"

		if FASTDL then
			FASTDL:Remove()
			FASTDL = nil
		end

		if not FASTDL then
			local server = sockets.TCPServer()
			server:Host("*", 5000)
			FASTDL = server
		end

		gserv.SetConfigParameter("gmod", "sv_loadingurl", "\"http://threekelv.in:2080/loadingscreen/\"")
		gserv.SetConfigParameter("gmod", "sv_downloadurl", "\"http://threekelv.in:2080/downloadurl/\"")

		function FASTDL:OnClientConnected(client)
			function client:OnReceiveChunk(str)
				local url = str:match("GET %/(%S+) HTTP/1%.")
				local ip, port = client.socket:get_name()

				if url ~= "favicon.ico" then
					llog("%s:%s wants to request %s", ip, port, url)
				end

				if url:startswith("downloadurl/") then
					url = url:sub(#"downloadurl/" + 1)

					if vfs.IsFile("os:" .. get_gmod_dir(id) .. "fastdl/" .. url) then
						local raw = vfs.Read("os:" .. get_gmod_dir(id) .. "fastdl/" .. url)
						local data = {
							"HTTP/1.1 200 OK",
							"Content-Type: application/octet-stream",
							"Content-Length: " .. #raw,
							"Last-Modified: Tue, 17 Sep 2019 09:17:41 GMT",
							"Connection: keep-alive",
							"ETag: 5d80a4b5-1c4bd8a",
							"Accept-Ranges: bytes",
						}

						client:Send(table.concat(data, "\r\n").."\r\n\r\n")
						client:Send(raw)
					else
						llog("%s:%s unable to find %s", ip, port, "os:" .. get_gmod_dir(id) .. "fastdl/" .. url)
					end
				elseif url:startswith("loadingscreen") and gserv.configs[id].screenshots then
					local raw = [[
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
				for i,v in ipairs(gserv.configs[id].screenshots) do
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
					]]
					local data = {
						"HTTP/1.1 200 OK",
						"Content-Length: " .. #raw,
						"Last-Modified: Tue, 17 Sep 2019 09:17:41 GMT",
						"Connection: keep-alive",
						"Content-Type: text/html",
						"ETag: 5d80a4b5-1c4bd8a",
					}

					client:Send(table.concat(data, "\r\n").."\r\n\r\n")
					client:Send(raw)
				end
			end
		end
	end

	if RELOAD then
		gserv.SetupLua("gmod")
		gserv.RunLua("gmod", "print(include('autorun/server/gserv.lua'), '!!!')")
	end
end
