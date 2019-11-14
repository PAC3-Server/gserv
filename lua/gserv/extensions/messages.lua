local gserv = ... or _G.gserv

function gserv.WriteData(id, str)
    local path = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/data/gserv/gserv2gmod.txt"

	local prev = fs.Read(path) or ""
	fs.Write(path, prev .. str .. "¥$£@DELIMITER@£$¥")
end

function gserv.ReadData(id)
    local path = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/data/gserv/gmod2gserv.txt"

	local data = fs.Read(path)
	fs.Write(path, "")

	if data and data ~= "" then
		for _, chunk in ipairs(data:split("¥$£@DELIMITER@£$¥")) do
			if chunk ~= "" then
				event.Call("GServMessage", chunk)
			end
		end
	end
end

gserv.AddGLua("messages", [[
    function gserv.WriteData(str)
        file.Append("gserv/gmod2gserv.txt", str .. "¥$£@DELIMITER@£$¥")
    end

    local path = "gserv/gserv2gmod.txt"

    function gserv.ReadData()
        local data = file.Read(path, "DATA")
        file.Write(path, "")

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
            local time = file.Time("gserv/gserv2gmod.txt", "DATA")
            if time ~= last_time then
                gserv.ReadData()
                last_time = time
            end
        end)
    end
]])

event.AddListener("GServStart", "gserv_messages", function(id, gmod_dir, config)
    local last_time
    event.AddListener("Update", "gserv_messages_" .. id, function()
        local time = vfs.GetLastModified(gmod_dir .. "data/gserv/gmod2gserv.txt")
        if time ~= last_time then

            local data = fs.Read(gmod_dir .. "data/gserv/gmod2gserv.txt")
            fs.Write(gmod_dir .. "data/gserv/gmod2gserv.txt", "")

            if data and data ~= "" then
                for _, chunk in ipairs(data:split("¥$£@DELIMITER@£$¥")) do
                    if chunk ~= "" then
                        event.Call("GServMessage", chunk)
                    end
                end
            end

            last_time = time
        end
    end)
end)

event.AddListener("GServStop", "gserv_messages", function(id, gmod_dir)
    event.RemoveListener("gserv_messages_" .. id)
    fs.Remove(gmod_dir .. "data/gserv/gmod2gserv.txt")
end)

if RELOAD then
    gserv.Reload()
end