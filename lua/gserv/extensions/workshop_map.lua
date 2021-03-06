local gserv = ... or _G.gserv

gserv.AddGLua("workshop_content", [[
    local addons = {}
    local str = file.Read("gserv/workshop_addons.txt", "DATA")
    for _, line in ipairs(str:Split("\n")) do
        local key, val = line:match("^(.-) = (.+)$")
        addons[key] = val
    end

    local map = game.GetMap():lower()

	if addons[map] then
        resource.AddWorkshop(addons[map])
	end
]])

event.AddListener("GServStart", "workshop_content", function(id, gmod_dir, config)
    if not config.addons then return end

    local str = {}

    for key, v in pairs(config.addons) do
        local info = gserv.NormalizeAddonInfo(v)
        if info.type == "workshop" then
            table.insert(str, key .." = " .. info.id)
        end
    end

    fs.Write(gmod_dir .. "data/gserv/workshop_addons.txt", table.concat(str, "\n"))
end)


if RELOAD then
    gserv.Reload()
end