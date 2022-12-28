--os.execute("./goluwa build luajit")
--os.execute("./goluwa build libressl")
--os.execute("./goluwa build openal")
--os.execute("./goluwa build libsndfile")
--os.execute("./goluwa build libarchive")
-- ./goluwa --cli --l "runfile('lua/run_docker.lua')"
-- ./goluwa --cli --l "runfile('lua/build_docker_runtime.lua')"

assert(system.OSCommandExists("id"), "id command must exist")

local user_id = io.popen("id -u"):read("*l")
local group_id = io.popen("id -g"):read("*l")
local user_name = io.popen("id -u --name"):read("*l")

local docker_file = ffibuild.GetDefaultDockerHeader() .. [[
    EXPOSE 27015/udp
    EXPOSE 27015/tcp
    EXPOSE 5000/tcp

    RUN apt-get install git wget tmux lib32gcc-s1 lib32stdc++6 -y

    RUN useradd -ms /bin/bash gserv
    USER gserv
    WORKDIR /home/gserv

    COPY --chown=gserv core core
    COPY --chown=gserv framework framework
    COPY --chown=gserv engine engine
    COPY --chown=gserv game game
    COPY --chown=gserv gserv gserv
    
    COPY --chown=gserv goluwa goluwa

    RUN touch core/bin/linux_x64/keep_local_binaries
    RUN touch framework/bin/linux_x64/keep_local_binaries

    ENV USER=gserv
    ENV GOLUWA_AUDIO_DEVICE=loopback

    ENTRYPOINT [ "./goluwa" ]
]]

local temp_file = os.tmpname()
fs.Write(temp_file, docker_file)

os.execute("docker build -t goluwa-srcds -f "..temp_file.." .")