local gserv = ... or _G.gserv

gserv.AddGLua("discord_cloudflare_workaround", [[
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
]])

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

if RELOAD then
    gserv.Reload()
end
