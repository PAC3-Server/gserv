local gserv = ... or _G.gserv

function gserv.WriteData(id, str)
    local gmod_dir = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/"

	local prev = fs.Read(gmod_dir .. "data/gserv/gserv2gmod.txt") or ""
	fs.Write(gmod_dir .. "data/gserv/gserv2gmod.txt", prev .. str .. "¥$£@DELIMITER@£$¥")
end

function gserv.ReadData(id)
    local gmod_dir = gserv.GetSRCDSDirectory() .. "gserv/" .. id .. "/garrysmod/"
	local data = fs.Read(gmod_dir .. "data/gserv/gmod2gserv.txt")
	fs.Write(gmod_dir .. "data/gserv/gmod2gserv.txt", "")

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

    function gserv.ReadData()
        local data = file.Read("gserv/gserv2gmod.txt", "DATA")
        file.Write("gserv/gserv2gmod.txt", "")

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
            if file.Time("gserv/gserv2gmod.txt", "DATA") ~= last_time then
                gserv.ReadData()
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