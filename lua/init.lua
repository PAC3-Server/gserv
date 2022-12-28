if CLI then return end

local gserv = runfile("lua/gserv/init.lua")
_G.gserv = gserv

runfile("lua/discord/bot_base.lua")

vfs.AutorunAddons("gserv/")

