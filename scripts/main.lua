local UEHelpers = require("UEHelpers")
local AFUtils = require("AFUtils.AFUtils")
local AFUtilsDebug = require("AFUtils.AFUtilsDebug")
local BaseUtils = require("BaseUtils")
local utils = require("utils")

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

RegisterKeyBind(Key.F2, function()
    -- AFUtils:GetGameInstance():ForceSave()
    -- LogInfo("World saved")
    utils.UnlockDoorAtCrosshair()
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

-- Prevent doors from being unlocked unless permitted.
RegisterHook("Function /Game/Blueprints/Doors/SimpleDoor_ParentBP.SimpleDoor_ParentBP_C:IsDoorLocked",
    ---@param selfParam RemoteUnrealParam
    ---@param toiletLockedParam RemoteUnrealParam
    ---@param oneWayLockedParam RemoteUnrealParam
    function(selfParam, toiletLockedParam, oneWayLockedParam)
        LogInfo("IsDoorLocked")
        local door = selfParam:get() ---@cast door ASimpleDoor_ParentBP_C
        if door.OneWayDoor then
            LogInfo("Forcing door lock to true")
            oneWayLockedParam:set(true)
        end
    end)

--Prevent recipes from being learned unless permitted
RegisterHook(
    "/Game/Blueprints/Characters/Abiotic_CharacterProgressionComponent.Abiotic_CharacterProgressionComponent_C:AddPendingRecipesToUnlock",
    ---@param selfParam RemoteUnrealParam
    ---@param recipeRowNameParam RemoteUnrealParam
    function(selfParam, recipeRowNameParam)
        ---@type FName
        local name = recipeRowNameParam:get()
        LogInfo("[AddPendingRecipesToUnlock] Blocked recipe " .. name:ToString())
        ---@type UAbiotic_CharacterProgressionComponent_C
        local progressionComponent = selfParam:get()
        progressionComponent.PendingRecipesToUnlock = {}
    end
)
LogInfo("Mod loading done")
