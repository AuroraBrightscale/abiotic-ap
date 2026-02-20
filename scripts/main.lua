local UEHelpers = require("UEHelpers")
local AFUtils = require("AFUtils.AFUtils")
local APClient = require("ap-client")
local _ModVersion = require("mod-version")
local utils = require("utils")

DebugMode = true
ModName = "abiotic-ap"
ModVersion = _ModVersion

LogInfo("Mod loaded. Rawrrawr.\n")

---@type FVector
local lastLocation = nil

---@type AbioticAPClient | nil
local apClient = nil

---Dumps the player's current location
function ReadPlayerLocation()
    local FirstPlayerController = UEHelpers:GetPlayerController()
    local Pawn = FirstPlayerController.Pawn
    local Location = Pawn:K2_GetActorLocation()
    LogInfo(string.format("Player location: {X=%.3f, Y=%.3f, Z=%.3f}\n", Location.X, Location.Y, Location.Z))
    if lastLocation then
        LogInfo(string.format("Player moved: {delta_X=%.3f, delta_Y=%.3f, delta_Z=%.3f}\n",
            Location.X - lastLocation.X,
            Location.Y - lastLocation.Y,
            Location.Z - lastLocation.Z)
        )
    end
    lastLocation = Location
end

function OnQuitGame()
    if apClient and not apClient.isDisconnected then
        ExecuteAsync(function() if apClient then apClient:Disconnect() end end)
    else
        collectgarbage("collect")
    end
end

---@param id integer
function OnLocationCheck(id)
    if apClient then
        ExecuteAsync(function()
            apClient:SendLocationFound(id)
        end)
    end
end

--main block

-- Hook bootstrap.
-- TODO Find a way to do this without a delay. Delay is needed for the objects to initialize on game boot
ExecuteWithDelay(600, function()
    local hooks = require("hooks")
    hooks.OnQuitGame = OnQuitGame
    hooks.OnLocationCheck = OnLocationCheck
    LogInfo("Registered game hooks")
end)



--Debug keybind to do...stuff.
RegisterKeyBind(Key.F2, function()
    ExecuteAsync(function()
        local obj = StaticFindObject(
            "/Game/Blueprints/DataTables/DT_Recipes.DT_Recipes"
        )
        if obj ~= nil then
            ---@cast obj UDataTable
            obj:ForEachRow(function(name, data)
                LogDebug(name)
                -- utils.DumpTable(data)
                -- if data ~= nil then
                --     data:ForEachProperty(function(prop)
                --         LogDebug("\t" ..
                --             prop:GetFName():ToString() .. " : " .. obj:GetPropertyValue(prop:GetFName():ToString()))
                --     end)
                -- end
            end)
        else
            LogInfo("Not found")
        end
    end)
end)

--Print actor debug information for actor within 50cm of crosshair point
RegisterKeyBind(Key.F5, {}, function()
    local location = {}
    local rotation = {}
    AFUtils:GetMyPlayer():Local_GetPointAtCrosshair(location, rotation, nil)
    if location then
        local actors = FindAllOf("Actor") ---@cast actors AActor[]
        ---@type AActor
        local foundActor
        ---@type AActor
        for i, d in pairs(actors) do
            ---@type AActor
            local actor = d
            local position = actor:K2_GetActorLocation()
            if math.abs(position.X - location.X) < 50 and
                math.abs(position.Y - location.Y) < 50 and
                math.abs(position.Z - location.Z) < 50 then
                foundActor = actor
                LogInfo(actor:GetFullName())
            end
        end
        if not foundActor then
            LogInfo("Didn't find an actor")
        end
    else
        LogInfo("No hit")
    end
end)

RegisterConsoleCommandHandler("ap", function(command, parts, ar)
    if #parts == 0 then
        AFUtils.DisplayTextChatMessage("Usage: ap <subcommand> <args>")
        return true
    end
    ---@type string
    local apCommand = parts[1]
    if apCommand:lower() == "learn" then
        if #parts == 2 then
            AFUtils.GetMyCharacterProgressionComponent():Server_TryUnlockRecipe(FName(parts[2]))
        else
            AFUtils.DisplayTextChatMessage("Usage: ap learn <recipe>")
        end
    elseif apCommand:lower() == "connect" then
        ExecuteAsync(function()
            --Defaults
            local hostAndPort = "localhost:38281" -- default AP localhost port
            local slotName    = "Player1"         -- default name in AP yamls
            local password    = ""                -- Rooms by default don't have a password
            if #parts >= 2 then
                hostAndPort = parts[2]
            end
            if #parts >= 3 then
                slotName = parts[3]
            end
            if #parts == 4 then
                password = parts[4]
            end
            AFUtils.DisplayTextChatMessage("Connecting to " .. hostAndPort .. ", slot name " .. slotName, "[AP]")
            apClient = APClient.Connect(hostAndPort, slotName, password)
            ---@param message string
            apClient.OnAPMessage = function(message)
                AFUtils.DisplayTextChatMessage(message, "[AP]")
            end
        end)
    elseif apCommand:lower() == "disconnect" then
        ExecuteAsync(function() if apClient then apClient:Disconnect() end end)
        AFUtils.DisplayTextChatMessage("Disconnected", "[AP]")
    elseif apCommand:lower() == "loc" then
        local success = false
        if #parts == 2 then
            local num = tonumber(parts[2])
            if num then
                ExecuteAsync(function()
                    if apClient then
                        apClient:SendLocationFound(num)
                    end
                end)
                success = true
            end
        end
        if not success then
            AFUtils.DisplayTextChatMessage("Usage: ap loc <loc_id>")
        end
    end
    return true
end)

LogInfo("Mod loading done")
