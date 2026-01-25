local UEHelpers = require("UEHelpers")
local AFUtils = require("AFUtils.AFUtils")
local AFUtilsDebug = require("AFUtils.AFUtilsDebug")
local BaseUtils = require("BaseUtils")
local utils = require("utils")
local AP = require("lua-apclientpp")

DebugMode = true
ModName = "abiotic-ap"
ModVersion = "0.0.0"

LogInfo("Mod loaded. Rawrrawr.\n")

---@type FVector
local lastLocation = nil

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

--main block

-- Hook bootstrap.
-- TODO Find a way to do this without a delay. Delay is needed for the objects to initialize on game boot
local worldLoaded = false
ExecuteWithDelay(500, function()
    if not worldLoaded then
        require("hooks")
        LogInfo("Registered game hooks")
        worldLoaded = true
    end
end)

--Debug keybind to do...stuff.
RegisterKeyBind(Key.F2, function()

end)

--Print actor debug information for actor within 50cm of crosshair point
RegisterKeyBind(Key.F5, {}, function()
    ---@type FVector
    local location = {}
    ---@type FRotator
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
    end
    return true
end)


LogInfo("Mod loading done")
