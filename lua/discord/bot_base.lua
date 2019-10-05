local META = prototype.CreateTemplate("discord_bot")

function META:Send(data)
	self.socket:SendMessage(data)
end

function META:CreateWebsocket(opcodes, friendly_name, on_close)
	local name2opcode = {}
	local opcode2name = {}

	for i, v in ipairs(opcodes) do
		name2opcode[v] = i
	end

	for i, v in ipairs(opcodes) do
		opcode2name[i] = v
	end

	local socket = sockets.CreateWebsocketClient()

	function socket:SendMessage(data)
		if data.opcode then
			data.op = name2opcode[data.opcode]
			if not data.op then error("invalid opcode " .. data.opcode) end
			data.opcode = nil
		end
		self:Send(serializer.Encode("json", data), 1)
	end

	for k, v in pairs(opcodes) do
		socket["Send" .. v] = function(self, data)

			self:SendMessage({
				op = k,
				d = data,
			})
		end
	end

	function socket:OnReceive(message, err, partial)
		local data = serializer.Decode("json", message)

		data.opcode = opcode2name[data.op]
		data.op = nil

		if data.opcode == "Hello" then
			self:SendHeartbeat(os.clock())
			local id = tostring(self)
			event.Timer(id, (data.d.heartbeat_interval/1000) * 0.75, function()
				if not self:IsValid() then
					event.RemoveTimer(id)
					return
				end

				self:SendHeartbeat(os.clock())
			end)
		end

		if data.opcode then
			--llog(friendly_name .. " received opcode: " .. data.opcode)
			--table.print(data)
		elseif data.t and data.t ~= "PRESENCE_UPDATE" and data.t ~= "GUILD_CREATE" then
			--llog(friendly_name .. " received event: " .. data.t)
			--table.print(data)
		end

		self:OnEvent(data)
    end

	function socket.OnClose(reason, code)
		event.RemoveTimer(socket)
        socket:Remove()

        if on_close then
            on_close(string.format("closing discord socket: %s (%s)\n", reason, code))
        end
	end

	function socket:OnEvent(data) end

	return socket
end

function META:Initialize()
	self.api.GET("gateway/bot"):Then(function(data)

		local socket = self:CreateWebsocket({
			[0] = "Dispatch", -- dispatches an event
			[1] = "Heartbeat", -- used for ping checking
			[2] = "Identify", -- used for client handshake
			[3] = "StatusUpdate", -- used to update the client status
			[4] = "VoiceStateUpdate", -- used to join/move/leave voice channels
			[5] = "VoiceServerPing", -- used for voice ping checking
			[6] = "Resume", -- used to resume a closed connection
			[7] = "Reconnect", -- used to tell clients to reconnect to the gateway
			[8] = "RequestGuildMembers", -- used to request guild members
			[9] = "InvalidSession", -- used to notify client they have an invalid session id
			[10] = "Hello", -- sent immediately after connecting, contains heartbeat and server debug information
			[11] = "HeartbackACK", -- sent immediately following a client heartbeat that was received
        }, "base", function(reason) self:Close(reason) end)

		self.socket = socket

		socket:Connect(data.url .. "/?v=6", "wss")

		socket:SendIdentify({
			token = self.token,
			properties = {
				["$os"] = jit.os,
				["$browser"] = "goluwa",
				["$device"] = "goluwa",
				["$referrer"] = "",
				["$referring_domain"] = "",
			},
			compress = false,
			large_threshold = 100,
			shard = {0,1},
		})

		function socket.OnEvent(_, data)
			self:OnEvent(data)
		end
	end):Catch(function(reason, code)
		self:OnClose(reason, code or -1)
	end)
end

function META:Close(reason)
    self:OnClose(reason)
    self:Remove()
end

function META:OnClose(reason)
    llog(reason)
end

function META:OnRemove()
	self.socket:Remove()
end

META:Register()

function DiscordBot(token)
	local self = META:CreateObject()
	self.token = "Bot " .. token

	self.api = http.CreateAPI("https://discordapp.com/api/", function(data)
		return {
			Authorization = self.token,
			["Content-Type"] = data.body and "application/json" or nil,
		}
	end)

	self:Initialize()

	return self
end