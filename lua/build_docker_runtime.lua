--os.execute("./goluwa build luajit")
--os.execute("./goluwa build libressl")
--os.execute("./goluwa build openal")
--os.execute("./goluwa build libsndfile")
--os.execute("./goluwa build libarchive")
-- ./goluwa --cli --l "runfile('lua/run_docker.lua')"
-- ./goluwa --cli --l "runfile('lua/build_docker_runtime.lua')"

local docker_file = ffibuild.GetDefaultDockerHeader() .. [[
    EXPOSE 27015/udp
    EXPOSE 27015/tcp
    EXPOSE 5000/tcp

    RUN apt-get install git wget tmux lib32gcc-s1 lib32stdc++6 libopus0 libsodium23 -y

    workdir /goluwa

    COPY core core
    COPY framework framework
    COPY engine engine
    COPY game game
    COPY gserv gserv

    COPY goluwa goluwa

    RUN cp /lib/x86_64-linux-gnu/libsodium.so.23 framework/bin/linux_x64/libsodium.so
    RUN cp /lib/x86_64-linux-gnu/libopus.so.0 framework/bin/linux_x64/libopus.so

    RUN touch core/bin/linux_x64/keep_local_binaries
    RUN touch framework/bin/linux_x64/keep_local_binaries

    ENTRYPOINT [ "./goluwa" ]
]]

local temp_file = os.tmpname()
fs.Write(temp_file, docker_file)

os.execute("docker build -t goluwa-srcds -f "..temp_file.." .")