local AP = require("lua-apclientpp")
local utils = require("utils")
local ModVersion = require("mod-version")

local gameName = "Abiotic Factor"
local itemsHandling = 7 -- full remote
local messageFormat = AP.RenderFormat.TEXT
--The Archipelago version we're supporting
local clientVersion = { 0, 6, 6 }

local this = {}

---@class AbioticAPClient
---@field slot string | nil
---@field password string | nil
---@field apclientpp APClient | nil
---@field isDisconnected boolean
---@field OnAPMessage function | nil
local AbioticAPClient = {}
AbioticAPClient.__index = AbioticAPClient

---@param data { [string]: any }
---@param _ { [string]: any }
function AbioticAPClient:OnPrintJSON(data, _)
    local apMessage = self.apclientpp:render_json(data, messageFormat)
    LogInfo("[ChatWindow]", apMessage)
    if self.OnAPMessage then
        self.OnAPMessage(apMessage)
    end
end

function AbioticAPClient:OnSocketConnected()
    LogInfo("Socket connected")
end

function AbioticAPClient:OnSocketError(msg)
    LogInfo("Socket error: " .. msg)
end

function AbioticAPClient:OnSocketDisconnected()
    LogInfo("Socket disconnected")
end

---@param slotData { [string]: any }
function AbioticAPClient:OnSlotConnected(slotData)
    LogInfo("Slot connected")
end

---@param dataPackage { [string]: any }
function AbioticAPClient:OnDataPackageChanged(dataPackage)
    LogInfo("Data package changed. Showing output of dataPackage.games")
    utils.DumpTable(dataPackage.games)
end

function AbioticAPClient:OnItemsRecieved(items)
    print("Items received:")
    for _, item in ipairs(items) do
        print(item.item)
    end
end

function AbioticAPClient:OnRoomInfo()
    LogInfo("Room info")
    self.apclientpp:ConnectSlot(self.slot, self.password, itemsHandling, {}, clientVersion)
end

---@param locationId integer
function AbioticAPClient:SendLocationFound(locationId)
    if self.apclientpp then
        self.apclientpp:LocationChecks({ locationId })
    end
end

function AbioticAPClient:Disconnect()
    self.isDisconnected = true
    self.apclientpp = nil
    collectgarbage("collect")
    LogInfo("AP Client disconnected")
end

function AbioticAPClient:StartLoop()
    --16ms is roughly 60 times per second
    LoopAsync(16, function()
        if self.apclientpp then
            self.apclientpp:poll()
        end

        --This will loop forever until self.isDisconnected is true
        return self.isDisconnected
    end)
end

function this.Connect(server, slot, password)
    ---@class AbioticAPClient
    local client = setmetatable({}, AbioticAPClient)
    client.slot = slot
    client.password = password
    local uuid = ""
    LogInfo("Connecting to", server)
    local apclientpp = AP(uuid, gameName, server);
    apclientpp:set_print_json_handler(
        function(data, command) client:OnPrintJSON(data, command) end
    )
    apclientpp:set_socket_connected_handler(function() client:OnSocketConnected() end)
    apclientpp:set_socket_error_handler(function(msg) client:OnSocketError(msg) end)
    apclientpp:set_socket_disconnected_handler(function() client:OnSocketDisconnected() end)
    apclientpp:set_room_info_handler(function() client:OnRoomInfo() end)
    apclientpp:set_slot_connected_handler(function(slotData) client:OnSlotConnected(slotData) end)
    apclientpp:set_data_package_changed_handler(
        function(dataPackage) client:OnDataPackageChanged(dataPackage) end
    )
    apclientpp:set_items_received_handler(function(items) client:OnItemsRecieved(items) end)

    client:StartLoop()

    client.apclientpp = apclientpp

    return client
end

return this
