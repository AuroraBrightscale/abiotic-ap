local AP = require("lua-apclientpp")
local utils = require("utils")

-- global to this mod
local gameName = "Abiotic Factor"
local itemsHandling = 7           -- full remote
local messageFormat = AP.RenderFormat.TEXT
local clientVersion = { 0, 0, 0 } -- optional, defaults to lib version
---@type APClient | nil
local ap = nil
---@type thread | nil
local co = nil
---@type boolean
local isDisconnected = false

---@type string
local slot = nil
---@type string
local password = nil

local this = {}



---@param apClient APClient
---@param data { [string]: any }
---@param command { [string]: any }
local function OnPrintJSON(apClient, data, command)
    local apMessage = apClient:render_json(data, messageFormat)
    LogInfo("[AP] " .. apMessage)
    if this.OnAPMessage then
        this.OnAPMessage(apMessage)
    end
end

local function OnSocketConnected()
    LogInfo("Socket connected")
end

local function OnSocketError(msg)
    LogInfo("Socket error: " .. msg)
end

local function OnSocketDisconnected()
    LogInfo("Socket disconnected")
end

---@param slotData { [string]: any }
local function OnSlotConnected(slotData)
    LogInfo("Slot connected")
end

---@param dataPackage { [string]: any }
local function OnDataPackageChanged(dataPackage)
    LogInfo("Data package changed")
    utils.DumpTable(dataPackage)
end

---@param apClient APClient
local function OnRoomInfo(apClient)
    LogInfo("Room info")
    apClient:ConnectSlot(slot, password, itemsHandling, {}, clientVersion)
end

---@param locationId integer
function this.SendLocationFound(locationId)
    if ap then
        ap:LocationChecks({ locationId })
    end
end

---@type function | nil
this.OnAPMessage = nil

function this.Connect(server, slt, pwd)
    slot = slt
    password = pwd
    local uuid = ""
    LogInfo("Connecting to", server)
    ap = AP(uuid, gameName, server);

    ap:set_print_json_handler(function(data, command) OnPrintJSON(ap, data, command) end)
    ap:set_socket_connected_handler(OnSocketConnected)
    ap:set_socket_error_handler(OnSocketError)
    ap:set_socket_disconnected_handler(OnSocketDisconnected)
    ap:set_room_info_handler(function() OnRoomInfo(ap) end)
    ap:set_slot_connected_handler(OnSlotConnected)
    ap:set_data_package_changed_handler(OnDataPackageChanged)

    --16ms is roughly 60 times per second
    LoopAsync(16, function()
        if ap then
            ap:poll()
        end
        return isDisconnected
    end)
end

function this.Disconnect()
    -- co = nil
    isDisconnected = true
    ap = nil
    collectgarbage("collect")
    LogInfo("AP Client disconnected")
end

return this
