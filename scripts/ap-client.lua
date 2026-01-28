-- coroutine example
-- see sample.lua for a more complete example of the API

local AP = require "lua-apclientpp"


-- global to this mod
local game_name = "Abiotic Factor"
local items_handling = 7           -- full remote
local message_format = AP.RenderFormat.TEXT
local client_version = { 0, 6, 5 } -- optional, defaults to lib version
local ap = nil
local co = nil

-- TODO: user input
local host = "localhost:38281"
local slot = "Aurora-AF"
local password = ""

local this = {}


local function on_socket_connected()
    print("Socket connected")
end

local function on_socket_error(msg)
    print("Socket error: " .. msg)
end

local function on_socket_disconnected()
    print("Socket disconnected")
end

---@param ap APClient
local function on_room_info(ap)
    print("Room info")
    ap:ConnectSlot(slot, password, items_handling, {}, client_version)
end

local function connectLoop(server, slot, password)
    local running = true -- set this to false to kill the coroutine
    -- ...

    local uuid = ""
    ap = AP(uuid, game_name, server);

    ap:set_socket_connected_handler(on_socket_connected)
    ap:set_socket_error_handler(on_socket_error)
    ap:set_socket_disconnected_handler(on_socket_disconnected)
    ap:set_room_info_handler(function() on_room_info(ap) end)
    -- ...

    while running do
        ap:poll()
        coroutine.yield()
    end
end

function this.connect(server, slot, password)
    co = coroutine.create(function() connectLoop(host, slot, password) end)
end

function this.disconnect()
    co = nil
end

LoopAsync(16, function()
    if co then
        coroutine.resume(co);
    end
    return false
end)

return this

-- print("Will run for 10 seconds ...")
-- local t0 = os.clock()
-- while os.clock() - t0 < 10 do
--     local status = coroutine.resume(co)
-- end
-- print("shutting down...");
