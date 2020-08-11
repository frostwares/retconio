--snes9x
---[[
-- use emu.registerbefore(func) to call a function before each frame (doesn't block the frame)
-- use full snes memory addressing
-- documentation: https://github.com/TASVideos/snes9x-rr/wiki/Lua-Functions

--]] /snes9x

-- ######### --

--bizhawk
--[[
-- Specifically:
-- instead of emu.registerbefore(func), we sit in a tight loop calling emu.frameadvance() which yields to the emulator
-- also, depending on bizhawk core:
-- -- either use memory.usememorydomain("System Bus")
-- -- OR
-- -- adjust incoming addresses to match memory model
-- documentation: http://tasvideos.org/Bizhawk/LuaFunctions.html

--]]

-- ######### --

socket = require("socket.core")
sock = nil
sock_err = nil
sock_data = nil
sock_status = nil
sock_reader = nil
sock_addr = "127.0.0.1"
sock_port = 60000
sock_isConnected = false

ERR_ALREADY_CONNECTED = 1
ERR_SOCKET_ERROR = 2
OK = 0
DISCONNECT = 5

-- ######### --

sock = socket:tcp()
sock_status, sock_err = sock:connect(sock_addr, sock_port)
if sock_status == nil then
    print("No connection...\n")
    print("Please restart to try connecting again.")
    return nil
else
    print("Connected!")
end

sock_isConnected = true

function write_mem (m_address, m_data)
    memory.writebyte(m_address, m_data)
end

function read_mem (m_address, m_length)
    if m_length == 1 then
        return memory.readbyte(m_address)
    else
        ret = ""
        while m_length > 0 do
            ret = ret .. " " .. tostring(memory.readbyte(m_address))
            m_address = m_address + 1
            m_length = m_length - 1
        end
        return ret
    end
end

function display (msg)
    emu.message(msg)
end

function receive (msg)
    if msg ~= nil then
        local t = {}
        local i = 0
        while true do
            i = string.find(msg, "|")
            if i then
                t[#t+1] = msg:sub(0, i-1)
                msg = msg:sub(i+1)
            else
                t[#t+1] = msg
                break
            end
        end

        if (t[1] == "write") then
            -- print("write " .. t[3] .. " to " .. t[2])
            write_mem(tonumber(t[2]), tonumber(t[3]))
            return "bytes written to " .. t[2] .. "\n"
        end
        if (t[1] == "read") then
            -- print("read " .. t[3] .. " bytes from ".. t[2])
            return "bytes read from " .. t[2] .. ": " .. read_mem(tonumber(t[2]), tonumber(t[3])) .. "\n"
        end
        if (t[1] == "display") then
            display(t[2])
            return "displayed\n"
        end
        if (t[1] == "console") then
            print(t[2])
            return "recorded to console\n"
        end
    end
end

function onclose ()
    sock:send("close\n")
    sock:close()
end

function main ()
    sock:settimeout(0)
    local sock_data, sock_status = sock:receive()
    if sock_data ~= nil then
        sock_data = receive(sock_data)
    end
    if sock_status == "closed" then
        sock:close()
        sock_isConnected = false
        return
    end
    if sock_status == 'timeout' then
        return
    end
    if sock_data ~= nil then
        sock:send(sock_data)
    end
end

emu.registerbefore(main)
emu.registerexit(onclose)