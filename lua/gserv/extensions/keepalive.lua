local gserv = ... or _G.gserv

gserv.AddGLua("keepalive", [[
    timer.Create("gserv_pinger", 1, 0, function()
        file.Write("gserv/last_ping.txt", os.time())
    end)
]])

event.AddListener("GServStart", "gserv_keepalive", function(id, gmod_dir, config)
    event.Timer("gserv_keepalive_" .. id, 1, 0, function()
        local time = fs.Read(gmod_dir .. "data/gserv/last_ping.txt")

        if time and tonumber(time) then
            time = tonumber(time)

            local diff = os.difftime(os.time(), time)

            if diff > 1 then
                llog(id .. " - server hasn't responded for more than " ..  diff .. " seconds")
                if diff > 60 then
                    if gserv.IsRunning(id) then
                        gserv.Stop(id)
                    end
                    gserv.Start(id, config)
                    fs.Remove(gmod_dir .. "data/gserv/last_ping.txt")
                end
            end
        end
    end)
end)

event.AddListener("GServStop", "gserv_keepalive", function(id, gmod_dir)
    event.RemoveTimer("gserv_keepalive_" .. id)
    fs.Remove(gmod_dir .. "data/gserv/pinger.txt")
end)

if RELOAD then
    gserv.Reload()
end