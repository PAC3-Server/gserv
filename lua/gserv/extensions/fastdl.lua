local gserv = ... or _G.gserv

gserv.AddPreLoadedGLua("fastdl", [[
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
]])

gserv.AddGLua("fastdl", [[
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
        file.Write("gserv/resource_files.txt", txt)
    end)
]])

-- this will create a fastdl folder in garrysmod/fastdl which is supposed to be served by a webserver

event.AddListener("GServStart", "gserv_fastdl", function(id, gmod_dir, config)

    event.Timer("gserv_fastdl_" .. id, 1, 0, function()
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

                if fs.IsFile(path) then
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

    event.RemoveTimer("gserv_fastdl_" .. id)
    fs.Remove(gmod_dir .. "data/gserv/resource_files.txt")
end)

if RELOAD then
    gserv.Reload()
end