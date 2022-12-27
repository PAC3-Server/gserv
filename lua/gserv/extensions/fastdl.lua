local gserv = ... or _G.gserv

gserv.AddPreLoadedGLua("fastdl", [[
    if SERVER then
        do
            local extensions = {
                vmt = {"vtf"},
                mdl = {"vvd", "ani", "dx80.vtx", "dx90.vtx", "sw.vtx", "phy", "jpg"}
            }

            local old = resource.AddFile
            function resource.AddFile(path, ...)
                path = path:lower()

                do
                    local path, ext = path:match("(.+/.-)%.(.+)")
                    local name = path:match(".+/(.+)")
                    if extensions[ext] then
                        local dir = path:match("(.+/)")
                        for k, v in pairs(file.Find(dir .. "*", "GAME")) do
                            for _, ext2 in ipairs(extensions[ext]) do
                                if v == name .. "." .. ext2 then
                                    resource.AddSingleFile(dir .. v)
                                end
                            end
                        end
                    end
                end
            end
        end
        do
            GSERV_RESOURCE_FILES = {}
            local done = {}
            local old = resource.AddSingleFile
            function resource.AddSingleFile(path, ...)
                path = path:lower()
                if not done[path] then
                    table.insert(GSERV_RESOURCE_FILES, path)
                    done[path] = true
                end
                return old(path, ...)
            end
        end
    end
]])

gserv.AddGLua("fastdl", [[
    timer.Simple(0.01, function()
        local found = {}

        PrintTable(GSERV_RESOURCE_FILES)

        for _, path in ipairs(GSERV_RESOURCE_FILES) do
            if file.Exists(path, "GAME") then
                found[path] = true
            end
        end

        do
            local path = "maps/" .. game.GetMap():lower() .. ".bsp"

            if file.Exists(path, "GAME") then
                found[path] = true
            end
        end

        do
            local path = "maps/" .. game.GetMap():lower() .. ".nav"

            if file.Exists(path, "GAME") then
                found[path] = true
            end
        end

        local txt = ""
        for path in pairs(found) do
            txt = txt .. path .. "\n"
        end
        file.Write("gserv/resource_files.txt", txt)
    end)
]])

-- this will create a fastdl folder in garrysmod/fastdl which is supposed to be served by a webserver

event.AddListener("GServStart", "gserv_fastdl", function(id, gmod_dir, config)

    timer.Repeat("gserv_fastdl_" .. id, 1, 0, function()
        local paths = serializer.ReadFile("newline", gmod_dir .. "data/gserv/resource_files.txt")

        if paths then
            llog(id .. " - updating fastdl folder")
            fs.CreateDirectory(gmod_dir .. "fastdl/")

            local function fastdl(from, to)
                from = gmod_dir .. from
                to = gmod_dir .. "fastdl/" .. to
                fs.CreateDirectory(to:match("(.+/)"), true)
                os.executeasync("ln " .. from .. " " .. to .. " 2>/dev/null")
                os.executeasync("bzip2 --best -c " .. from .. " > " .. to .. ".bz2" .. " 2>/dev/null")
            end

            for _, path in ipairs(paths) do
                local ok = false

                if fs.IsFile(gmod_dir .. path) then
                    fastdl(path, path)
                    ok = true
                end

                for _, addon in ipairs(fs.GetFiles(gmod_dir .. "addons/")) do
                    if fs.IsFile(gmod_dir.. "addons/" .. addon .. "/" .. path) then
                        fastdl("addons/" .. addon .. "/" .. path, path)
                        ok = true
                        break
                    end
                end

                if not ok then
                    llog(id .. " - unable to find " .. path)
                end
            end

            fs.Remove(gmod_dir .. "data/gserv/resource_files.txt")
        end
    end)
end)

event.AddListener("GServStop", "gserv_fastdl", function(id)
    local gmod_dir = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/"

    timer.RemoveTimer("gserv_fastdl_" .. id)
    fs.Remove(gmod_dir .. "data/gserv/resource_files.txt")
end)

if RELOAD then
    gserv.Reload()
end