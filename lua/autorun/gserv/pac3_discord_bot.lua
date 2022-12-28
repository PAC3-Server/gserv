if not DISCORD_BOT then
	--DISCORD_BOT:Remove()
	local token = vfs.Read("temp/discord_bot_token")
	if not token then
		wlog("temp/discord_bot_token is missing, can't start discord bot")
		return
	end
	logn("starting discord bot")
	token = token:trim()
	assert(#token == 70, "invalid token length")
	DISCORD_BOT = DiscordBot(token:trim())
end

local server_id = "260866188962168832"
local channel_id = "568745482407641099"
local ADMIN_ROLE = "260932947140411412"
local chatsounds_channel = "570392695248388097"

local function restart()
	if DISCORD_BOT and DISCORD_BOT:IsValid() then
		DISCORD_BOT:Remove()
		DISCORD_BOT = nil
	end

	timer.Delay(1, function()
		runfile("lua/autorun/gserv/pac3_discord_bot.lua")
	end)
end

local function start_voicechat(self)
	chatsounds.Initialize()

	local ffi = require("ffi")
	local CHANNELS = 2
	local SAMPLE_RATE = 48000 -- Hz
	local FRAME_DURATION = 20 -- ms
	local COMPLEXITY = 5

	local MIN_BITRATE = 8000 -- bps
	local MAX_BITRATE = 128000 -- bps
	local MIN_COMPLEXITY = 0
	local MAX_COMPLEXITY = 10

	local MAX_SEQUENCE = 0xFFFF
	local MAX_TIMESTAMP = 0xFFFFFFFF

	local PADDING = string.rep('\0', 12)

	local sodium = require("sodium")
	local opus = require("opus")

	self.key = sodium.key(self.secret_key)

	local encoder = opus.Encoder(SAMPLE_RATE, CHANNELS)

	encoder:set(opus.SET_COMPLEXITY_REQUEST, COMPLEXITY)
	encoder:set(opus.SET_BITRATE_REQUEST, 64000)

	local frame_size = SAMPLE_RATE * FRAME_DURATION / 1000
	local pcm_len = frame_size * CHANNELS
	local elapsed = 0
	local start = system.GetElapsedTime()

	self.sample = 0
	self.time = 0

	local header = ffi.new([[
		struct {
			uint16_t magic;
			uint16_t sample;
			uint32_t time;
			uint32_t ssrc;
		}
	]])

	header.magic = utility.SwapEndian(0x8078, 2)

	local speaking

	local function is_speaking(pcm, pcm_len)
		for i = 0, pcm_len-1 do
			if pcm[i] <= -5 or pcm[i] >= 5 then
				return true
			end
		end

		return false
	end

	event.AddListener("Update", "noise_voice", function()

		local pcm, pcm_len = audio.ReadLoopbackOutput(frame_size * 2)

		if is_speaking(pcm, pcm_len) then
			if not speaking then
				self:SendSpeaking({
					speaking = true,
					delay = 0,
					ssrc = self.ssrc,
				})
				speaking = true
			end
		else
			if speaking then
				self:SendSpeaking({
					speaking = false,
					delay = 0.5,
					ssrc = self.ssrc,
				})
				speaking = false
			end
		end

		if not speaking then return end

		local data, len = encoder:encode(pcm, pcm_len, pcm_len * 2)

		if not data then
			print('could not encode audio data')
			event.RemoveListener("Update", "noise_voice")
			return
		end

		local s, t = self.sample, self.time

		header.sample = utility.SwapEndian(s, 2)
		header.time = utility.SwapEndian(t, 4)
		header.ssrc = utility.SwapEndian(self.ssrc, 4)

		local header = ffi.string(header, ffi.sizeof(header))

		s = s + 1
		t = t + pcm_len

		self.sample = s > MAX_SEQUENCE and 0 or s
		self.time = t > MAX_TIMESTAMP and 0 or t

		local encrypted, encrypted_len = sodium.encrypt(data, len, header .. PADDING, self.key)

		if not encrypted then
			print('could not encrypt audio data')
			event.RemoveListener("Update", "noise_voice")
			return
		end

		local packet = header .. ffi.string(encrypted, encrypted_len)
		self.udp:Send(packet, self.ip, self.port)

	--	elapsed = elapsed + FRAME_DURATION/1000
	--	local delay = elapsed - (system.GetTime() - start)
	--	event.Delay(delay, encode)
	end)
	--encode()
end


local ffi = require("ffi")
local freeimage = require("freeimage")

function DISCORD_BOT:Say2(channel, msg)
	local discord_message = msg:starts_with("__DISCORD_MESSAGE__")
	if discord_message then
		msg = msg:sub(#"__DISCORD_MESSAGE__" + 1)
	end

	local i = 0

	local function send(str)
		event.Delay(i, function()
			if discord_message then
				self:Say(channel, str)
			else
				self:Say(channel, "```lua\n"..str.."\n```")
			end
		end)
	end

	local chunk = ""
	for _, line in ipairs(msg:split("\n")) do
		if #chunk > 1950 then
			send(chunk)
			chunk = ""
			i = i + 1
		else
			chunk = chunk .. line .. "\n"
		end
	end

	if chunk ~= "" then
		send(chunk)
	end
end

function DISCORD_BOT:SendImage(pixels, w,h, channel)
	local image = {
		buffer = pixels,
		width = w,
		height = h,
		format = "rgba",
	}

	local png_data = freeimage.ImageToBuffer(image, "png")

	vfs.Write("test.png", png_data)

	local files = {}

	table.insert(files, {
		name = "payload_json",
		type = "application/json",
		data = serializer.Encode("json", {
			file = {
				image = {
					url = "attachment://test.png",
					width = image.width,
					height = image.height,
				},
			},
			--content = "sending " .. utility.FormatFileSize(#png_data) .. " image\n" .. serializer.Encode("luadata", image),
		}),
	})

	table.insert(files, {
		name = "test",
		type = "application/octet-stream",
		filename = "test.png",
		data = png_data,
	})

	self.api.POST("channels/"..channel.."/messages", {
		files = files,
	}):Then(print)
end

function DISCORD_BOT:Say(channel, what)
	print(channel, what)
	self.api.POST("channels/"..channel.."/messages", {
		body = {
			content = what:sub(0, 1999),
		},
	}):Then(function() end)
end

function DISCORD_BOT:OnEvent(data)
	if data.t == "VOICE_SERVER_UPDATE" then
		self.voice_server = data
	elseif data.t == "VOICE_STATE_UPDATE" then
		self.voice_state = data
	end

	if self.voice_server and self.voice_state then
		if not self.voice_socket then
			local socket = self:CreateWebsocket({
				[0] = "Identify", --	client	begin a voice websocket connection
				[1] = "SelectProtocol", --	client	select the voice protocol
				[2] = "Ready", --	server	complete the websocket handshake
				[3] = "Heartbeat", --	client	keep the websocket connection alive
				[4] = "SessionDescription", --	server	describe the session
				[5] = "Speaking", --	client and server	indicate which users are speaking
				[6] = "HeartbeatACK", --	server	sent immediately following a received client heartbeat
				[7] = "Resume", --	client	resume a connection
				[8] = "Hello", --	server	the continuous interval in milliseconds after which the client should send a heartbeat
				[9] = "Resumed", --	server	acknowledge Resume
				[13] = "ClientDisconnect", --	server	a client has disconnected from the voice channel
			}, "voice", restart)

			self.voice_socket = socket

			local voice_server = self.voice_server
			local voice_state = self.voice_state

			local host, port = unpack(self.voice_server.d.endpoint:split(":"))
			socket:Connect("wss://" .. host .. "/?v=3")
			socket:SendIdentify({
				server_id = voice_server.d.guild_id,
				user_id = voice_state.d.user_id,
				session_id = voice_state.d.session_id,
				token = voice_server.d.token,
			})

			local bot = self

			function socket:OnEvent(data)
				if data.opcode == "Ready" then
					self.ssrc = data.d.ssrc
					self.key = "?"
					self.ip = data.d.ip
					self.port = data.d.port

					local udp = sockets.UDPServer()

					llog("connecting to voice chat " .. data.d.ip .. ":" .. data.d.port)

					udp:SetAddress(data.d.ip, data.d.port)

					function udp.OnReceiveChunk(_, chunk, address)
						local buf = utility.CreateBuffer(chunk)
						buf:Advance(4)
						local ip = buf:ReadString()
						buf:SetPosition(buf:GetSize()-2)
						local port = buf:ReadUInt16_T()

						self:SendSelectProtocol({
							protocol = "udp",
							data = {
								address = ip,
								port = port,
								mode = "xsalsa20_poly1305"
							}
						})

						llog("our voice chat address is " .. address:get_ip() .. ":" .. address:get_port())
					end

					udp:Send(string.rep("\0", 70))

					local udp = sockets.UDPClient()
					udp:SetAddress(data.d.ip, data.d.port)
					self.udp = udp
				end

				if data.opcode == "SessionDescription" then
					self.secret_key = data.d.secret_key

					--start_voicechat(self)
					bot:Say(chatsounds_channel, "win2000 startup")
				end
			end
		end
	end

	if data.t == "READY" then
		--self.api.GET("guilds/"..server_id.."/roles"):Then(table.print)

		--[[self.api.POST("channels/260911858133762048/messages", {
			body = {
				content = "hello"
			}
		}):Then(table.print)

		self.api.GET(http.query("channels/260911858133762048/messages", {limit = 10})):Then(function(messages)
			table.print(messages)
			for k,v in pairs(messages) do
				print(v.author.username, v.content)
			end
		end)
		]]

		self.socket:SendVoiceStateUpdate({
			guild_id = server_id,
			channel_id = channel_id,
			self_mute = false,
			self_deaf = false
		})

		--[[self:Query("GET /guilds/"..server_id.."/members", function(data)
			table.print(data)
		end, {limit = 10})]]
	else
		if (data.t == "MESSAGE_CREATE" or data.t == "MESSAGE_UPDATE") and data.d.content then
			local ok, err = pcall(function()

				if data.d.channel_id == chatsounds_channel then
					chatsounds.Say(data.d.content)
				end

                local cmd, rest = data.d.content:match("^!(%S+)%s(.+)")

				if not rest then
					cmd = data.d.content:match("^!(%S+)")
				end

                if data.d.member and list.has_value(data.d.member.roles, ADMIN_ROLE) and data.d.content:starts_with("!") then

					do
						local captured = ""
						event.AddListener("ReplPrint", "capture", function(str)
							captured = captured .. str
						end)

						commands.RunString(data.d.content)

						timer.Delay(0, function()
							self:Say2(data.d.channel_id, captured)
							event.RemoveListener("ReplPrint", "capture")
						end)
					end

                    do return end

					if cmd == "l" and rest then
						local func, err = loadstring(rest)
						if func then
                            local ok, err = pcall(func)
                            if not ok then
                                print(err)
                                self:Say(data.d.channel_id, err)
							end
                        else
                            print(err)
                            self:Say(data.d.channel_id, err)
                        end
					elseif cmd == "avatar" then
						self.api.PATCH("users/@me", {
							body = {
								username = "goluwa",
								avatar = "data:image/png;base64," .. crypto.Base64Encode(vfs.Read("/home/caps/Documents/Untitled.png"))
							},
							--avatar = "data:image/png;base64,iVBORw0KGgoAAAANSUhEUgAAABAAAAAQCAYAAAAf8/9hAAAAVUlEQVR42mNgGAXYwSOB/ySJo4PMDRb/STYcGeg58/zHZzheC9BtACl2KVL5j2w4PgvgBqyB2kJYAw7biNaE7ncMjUheArkqH8k7JLmIZO+QpWFoAgAY9DgM7ldwswAAAABJRU5ErkJggg==",
						}):Then(print)
					elseif cmd == "screenshot" then
						local w,h = render.GetWidth(), render.GetHeight()
						local pixels = ffi.new("uint8_t[?]", (w*h*4))
						require("opengl").ReadPixels(0,0,w,h,"GL_BGRA", "GL_UNSIGNED_BYTE", pixels)

						self:SendImage(pixels, w, h, data.d.channel_id)
					elseif cmd == "glsl" and rest then
						local fb = render.CreateFrameBuffer()
						fb:SetSize(Vec2()+128)

						local tex = render.CreateTexture("2d")
						tex:SetSize(Vec2(128, 128))
						tex:SetInternalFormat("rgba8")
						tex:SetupStorage()
						tex:Clear()
						print(rest)
						tex:Shade(rest)
						local image = tex:Download()

						self:SendImage(ffi.cast("uint8_t *", image.buffer), image.width, image.height, data.d.channel_id)
					end
				end

				if cmd == "ac" and rest then
					self:Say(data.d.channel_id, table.concat(autocomplete.Query("chatsounds", rest), "\n"))
				end
			end)

			if not ok then
				logn(err)
				self:Say(data.d.channel_id, err)
			end
		end
		--table.print(data)
	end
end

function DISCORD_BOT:OnClose(reason)
    llog(reason)
    restart()
end