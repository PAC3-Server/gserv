
event.AddListener("GServStart", "gserv_webhooks", function(id, gmod_dir, config)
    if config and config.webhook_port then
        gserv.webhook_servers = gserv.webhook_servers or {}
        gserv.webhook_servers[id] = config.webhook_port
        sockets.StartWebhookServer(config.webhook_port, os.getenv(config.webhook_secret), function(...)
            event.Call("GservWebhook", id, ...)
        end)
    end
end)

event.AddListener("GServStop", "gserv_webhooks", function(id, gmod_dir)
    if gserv.webhook_servers and gserv.webhook_servers[id] then
        sockets.StopWebhookServer(gserv.webhook_servers[id])
    end
end)

if RELOAD then
    gserv.Reload()
end