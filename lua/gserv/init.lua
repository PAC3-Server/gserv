local gserv = _G.gserv or {}

gserv.glua = {}
gserv.glua_preloaded = {}

function gserv.AddGLua(key, glua)
	gserv.glua[key] = glua
end

function gserv.RenderGLua()
	local lua = [[
		if not gmod then return end

		file.CreateDir("gserv")

		gserv = {}
	]]

	for k,v in pairs(gserv.glua) do
		lua = "do --" .. k .. "\n" .. lua .. v .. "end\n"
	end

	return lua
end

function gserv.AddPreLoadedGLua(key, glua)
	gserv.glua_preloaded[key] = glua
end

function gserv.RenderPreloadedGLua()
	local lua = ""
	for k,v in pairs(gserv.glua_preloaded) do
		lua = "do --" .. k .. "\n" .. lua .. v .. "\nend\n"
	end
	return lua
end

runfile("extensions/*", gserv)

local function underscore(str)
	return str:lower():gsub("%p", ""):gsub("%s+", "_")
end

function gserv.GetSRCDSDirectory()
    return e.SHARED_FOLDER .. "srcds2/"
end

function gserv.SteamCMD(args)
	return resource.Download("http://media.steampowered.com/client/steamcmd_linux.tar.gz"):Then(function(path)
		local srcds_dir = gserv.GetSRCDSDirectory()

		if not vfs.IsFile(srcds_dir .. "steamcmd.sh") then
			vfs.CopyRecursively(path, "os:" .. srcds_dir)
		end

		local arg_str = {}

		for k,v in pairs(args) do
			local s = "+" .. k
			if v ~= true then
				s = s .. " " .. v
			end
			table.insert(arg_str, s)
		end

		arg_str = table.concat(arg_str, " ")

		llog(arg_str)

		-- todo
		os.execute("chmod +x " .. srcds_dir .. "steamcmd.sh")
		os.execute("chmod +x " .. srcds_dir .. "/linux32/steamcmd")

		repl.OSExecute(srcds_dir .. "steamcmd.sh " .. arg_str)
	end)
end

function gserv.InstallGame(name, username)
	local appid, full_name = steam.GetAppIdFromName(name)

	if not appid then
		error("could not find appid for " .. name, 2)
	end

	local install_dir = gserv.GetSRCDSDirectory() .. "installed/" .. underscore(full_name)

	llog("installing %s (%s) to %s", name, appid, install_dir)

	return gserv.SteamCMD({
		login = username or "anonymous",
		force_install_dir = "\"" .. install_dir .. "\"",
		app_update = appid,
		quit = true,
		validate = true,
	}):Then(function()
		return callback.Resolve(install_dir .. "/", appid, full_name)
	end)
end

function gserv.GetInstalledSourceGames()
	local installed = {}

	local srcds_dir = gserv.GetSRCDSDirectory()
	for _, dir in ipairs(vfs.Find(srcds_dir .. "installed/", true)) do
		local manifest_path = vfs.Find(dir .. "/steamapps/appmanifest_", true)[1]
		if manifest_path then
			local tbl = utility.VDFToTable(vfs.Read(manifest_path))
			if tbl and tbl.AppState then
				table.insert(installed, {
					name = tbl.AppState.name,
					appid = tbl.AppState.appid,
					directory = dir .. "/",
				})
			end
		end
	end

	return installed
end

function gserv.Reload()
	llog("reloading")

	runfile("lua/gserv/extensions/*", gserv)

	for _, id in ipairs(gserv.GetSetupServers()) do
		if gserv.IsRunning(id) then
			gserv.Resume(id)
		end
	end
end

do
	local function install_lua(gmod_dir)
		assert(fs.Write(gmod_dir .. "addons/gserv/lua/autorun/server/gserv.lua", gserv.RenderGLua(), true))

		do			-- override resource.AddFile and resource.AddSingleFile for fastdl
			local lua = assert(fs.Read(gmod_dir .. "lua/includes/util.lua"))

			lua = lua:gsub("%-%-GSERV_INJECT_START.-%-%-GSERV_INJECT_STOP", "")

			lua = lua .. "--GSERV_INJECT_START\n"
			lua = lua .. gserv.RenderPreloadedGLua()
			lua = lua .. "--GSERV_INJECT_STOP"

			assert(fs.Write(gmod_dir .. "lua/includes/util.lua", lua))
		end
	end

	local function build_mount_config(gmod_dir)
		local mountdepots_txt = '"gamedepotsystem"\n'
		mountdepots_txt = mountdepots_txt .. "{\n"

		local mounts_cfg = '"mountcfg"\n'
		mounts_cfg = mounts_cfg .. "{\n"

		for _, data in pairs(gserv.GetInstalledSourceGames()) do
			if data.appid ~= 4020 then
				local name = data.directory:match(".+/(.+)")
				mounts_cfg = mounts_cfg .. "\t\"" .. name .. "\"\t\t" .. "\""..data.directory.."\"\n"
				mountdepots_txt = mountdepots_txt .. "\t\"" .. name .. "\"\t\"1\"\n"
			end
		end

		mounts_cfg = mounts_cfg .. "}"
		mountdepots_txt = mountdepots_txt .. "}"

		assert(fs.Write(gmod_dir .. "cfg/mount.cfg", mounts_cfg))
		assert(fs.Write(gmod_dir .. "cfg/mountdepots.txt", mountdepots_txt))
	end

	local function build_cfg(gmod_dir, config)
		local str = ""
		for k,v in pairs(config.cfg) do
			str = str .. k .. " " .. v .. "\n"
		end
		assert(fs.Write(gmod_dir .. "cfg/gserv.cfg", str))

		-- silence some startup errors
		assert(fs.Write(gmod_dir .. "cfg/server.cfg", "exec gserv.cfg\n"))
		assert(fs.Write(gmod_dir .. "cfg/trusted_keys_base.txt", "trusted_key_list\n{\n}\n"))
		assert(fs.Write(gmod_dir .. "cfg/pure_server_minimal.txt", "whitelist\n{\n}\n"))
		assert(fs.Write(gmod_dir .. "cfg/network.cfg", ""))
	end

	function gserv.InstallGServ(location, config)
		local gmod_dir = location .. "/garrysmod/"

		install_lua(gmod_dir)
		build_cfg(gmod_dir, config)
		build_mount_config(gmod_dir)
	end
end

function gserv.InstallGMod(where)
	return gserv.InstallGame("gmod dedicated server"):Then(function(dir, appid, full_name)
		local location = gserv.GetSRCDSDirectory() .. "gserv/" .. where

		fs.Remove(dir .. "garrysmod/sv.db")

		if not fs.IsFile(location .. "/garrysmod/data/gserv/gserv_installed") then
			llog("copying files from:")
			logn("\t" .. dir)
			logn("\tto")
			logn("\t" .. location)
			assert(fs.CreateDirectory(location, true))
			assert(fs.CopyRecursively(dir, location))
			fs.Write(location .. "/garrysmod/data/gserv/gserv_installed", "", true)
		end

		return callback.Resolve(location)
	end)
end

function gserv.GetSetupServers()
	local out = {}
	local where = gserv.GetSRCDSDirectory() .. "gserv/"
	for i,v in ipairs(fs.GetFiles(where)) do
		if fs.IsDirectory(where .. v) then
			table.insert(out, v)
		end
	end
	return out
end

local function get_workshop_id(str)
	if (str:find("steamcommunity", nil, true) and str:find("id=%d+")) or tonumber(str) then
		return str:match("id=(%d+)") or str
	end
end

function gserv.NormalizeAddonInfo(val)
	local info = {}

	if type(val) == "string" then
		info.type = val:endswith(".git") and "git" or get_workshop_id(val) and "workshop"
		info.url = val
	end

	if info.type == "workshop" then
		info.id = get_workshop_id(info.url)
	end

	return info
end

function gserv.UpdateAddon(id, key, info)
	local dir = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/addons/" .. underscore(key) .. "/"

	local info = gserv.NormalizeAddonInfo(info)

	if info.type == "git" then
		llog(id .. " - updating git repository addon " .. info.url)
		local branch = info.branch or "master"

		if not fs.IsDirectory(dir) then
			repl.OSExecute("git clone -b " .. branch .. " " .. info.url .. " '" .. dir .. "' --depth 1")
		else
			repl.OSExecute("git -C '" .. dir .. "' fetch && git -C '" .. dir .. "' reset --hard origin/" .. branch .. " && git -C '" .. dir .. "' clean -fxd")
		end
		llog(id .. " - done updating " .. info.url)
	elseif info.type == "workshop" then
		llog(id .. " - updating workshop addon " .. info.url)

		steam.DownloadWorkshop(info.id, function(path, workshop_info)
			vfs.CopyRecursively(path, "os:" .. dir)
			--fs.RemoveRecursively(dir)
			llog(id .. " - done updating " .. info.url)
		end)
	end
end


do -- tmux and runtime related
	function gserv.IsRunning(id)
		local f = assert(io.popen("tmux has-session -t gserv_"..underscore(id).."_goluwa 2>&1"))
		local ok = f:read("*all") == ""
		f:close()
		return ok
	end

	gserv.active = {}

	local function start_listening(id, config)
		local gmod_dir = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/"
		gserv.active[id] = config or gserv.active[id]
		event.Call("GServStart", id, gmod_dir, gserv.active[id])
	end

	local function stop_listening(id)
		local gmod_dir = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/"
		event.Call("GServStop", id, gmod_dir, gserv.active[id])
		gserv.active[id] = nil
	end

	function gserv.Resume(id, config)
		if gserv.IsRunning(id) then
			llog(id .. " - resuming server")
			start_listening(id, config)
		end
	end

	local function build_arg_line(config)
		local str = ""

		if config then
			if config.startup then
				for k, v in pairs(config.startup) do
					str = str .. "+" .. k .. " " .. v .. " "
				end
			end

			if config.workshop_collection then
				local collection_id =
					tonumber(config.workshop_collection) or
					config.workshop_collection:match("id=(%d+)") or
					config.workshop_collection
				str = str .. "+host_workshop_collection " .. collection_id  .. " "
			end

			local key = config.workshop_authkey and os.getenv(config.workshop_authkey)

			if key then
				str = str .. "-authkey " .. key .. " "
			end

			if config.port then
				str = str .. "-port " .. config.port .. " "
			end

			if config.launch then
				for k, v in pairs(config.launch) do
					if v == true then
						str = str .. "-" .. k .. " "
					else
						str = str .. "-" .. k .. " " .. v .. " "
					end
				end
			end
		end

		return "-game garrysmod " .. str
	end

	function gserv.Attach(id)
		gserv.ExecuteAsync(id, "echo to detach hold CTRL and press the following keys: *hold CTRL* b b *release CTRL* d")
		repl.OSExecute("unset TMUX; tmux attach -t gserv_"..underscore(id).."_goluwa")
	end

	function gserv.ExecuteAsync(id, cmd)
		os.execute("tmux send-keys -t gserv_"..underscore(id).."_goluwa \"" .. cmd .. "\" C-m")
	end

	function gserv.GetOutput(id)
		local log_path, err = gserv.GetCurrentLogPath(id)
		if not log_path then
			return nil, err
		end

		local str, err = fs.Read(log_path)
		if not str then
			return nil, err
		end

		str = str:gsub("\r", "")

		return str
	end

	function gserv.ExecuteSync(id, str)
		local delimiter = "goluwa_gserv_ExecuteSync_" .. os.clock()
		local prev = gserv.GetOutput(id)

		gserv.ExecuteAsync(id, str)
		gserv.ExecuteAsync(id, "echo " .. delimiter)

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

	function gserv.GetCurrentLogPath(id)
		local log_dir = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/data/gserv/logs/"
		local path, err = fs.Read(log_dir .. "current_log_file.txt")
		if not path then
			return nil, err
		end
		return path
	end

	function gserv.Start(id, config)
		local location = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/"

		if not fs.IsDirectory(location) then
			error(location .. " does not exist", 2)
		end

		gserv.Stop(id)
		gserv.InstallGServ(location, config)

		if
			config and config.startup and config.startup.map and
			not fs.IsFile(location .. "garrysmod/maps/" .. config.startup.map .. ".bsp")
		then
			local dir = location .. "garrysmod/addons/"
			local ok = false
			for _, addon in ipairs(fs.GetFiles(dir)) do
				if fs.IsFile(dir .. addon .. "/maps/" .. config.startup.map .. ".bsp") then
					ok = true
					break
				end
			end

			if not ok then
				error("maps/" .. config.startup.map .. ".bsp does not exist", 2)
			end
		end

		local arg_line = build_arg_line(config)

		if not arg_line:find("authkey") then
			llog(id .. " - workshop auth key not setup")
		end

		local tmux_id = "gserv_"..underscore(id).."_goluwa"

		os.execute("tmux kill-session -t "..tmux_id.." 2>/dev/null")
		os.execute("tmux new-session -d -s "..tmux_id)

		-- create an empty log file for tmux
		local log_dir = location .. "garrysmod/data/gserv/logs/"
		local log_path = log_dir .. os.date("%Y/%m/%d/%H-%M-%S.txt")
		fs.Write(log_path, "", true)
		fs.Write(log_dir .. "current_log_file.txt", log_path)

		os.execute("tmux pipe-pane -o -t "..tmux_id.." 'cat >> " .. log_path .. "'")

		os.execute("chmod +x " .. location .. "srcds_linux")
		os.execute("chmod +x " .. location .. "srcds_run")
		os.execute("tmux send-keys -t "..tmux_id.." \"cd "..location.."\" C-m")

		os.execute("tmux send-keys -t "..tmux_id.." \"./srcds_run " .. arg_line .. "\" C-m")

		start_listening(id, config)
	end

	function gserv.Stop(id)
		local tmux_id = "gserv_"..underscore(id).."_goluwa"
		os.execute("tmux kill-session -t srcds_"..underscore(id).."_goluwa 2>/dev/null")

		stop_listening(id)
	end
end

if RELOAD then
	gserv.Reload()
end

return gserv