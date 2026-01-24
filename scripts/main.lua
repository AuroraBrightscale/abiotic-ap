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
    -- ---@type FVector
    -- local location = {}
    -- ---@type FRotator
    -- local rotation = {}
    -- AFUtils:GetMyPlayer():Local_GetPointAtCrosshair(location, rotation, nil)
    -- if location then
    --     local doors = FindAllOf("SimpleDoor_ParentBP_C") ---@cast doors ASimpleDoor_ParentBP_C[]
    --     ---@type ASimpleDoor_ParentBP_C
    --     local foundDoor
    --     ---@type ASimpleDoor_ParentBP_C
    --     for i, d in pairs(doors) do
    --         ---@type ASimpleDoor_ParentBP_C
    --         local door = d
    --         local position = door:K2_GetActorLocation()
    --         if math.abs(position.X - location.X) < 200 and
    --             math.abs(position.Y - location.Y) < 200 and
    --             math.abs(position.Z - location.Z) < 200 then
    --             print("Found a door!", i, position)
    --             foundDoor = door
    --             foundDoor.DoorState = 3
    --             break
    --         end
    --     end
    --     if not foundDoor then
    --         print("Didn't find a door")
    --     end
    -- else
    --     print("No hit")
    -- end
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

RegisterHook("Function /Game/Blueprints/Widgets/HUD/W_HUD_QuestObjective.W_HUD_QuestObjective_C:UpdateCurrentQuest",
    ---@param selfParam RemoteUnrealParam<UW_HUD_QuestObjective_C>
    ---@param newQuestParam RemoteUnrealParam<UScriptStruct>
    ---@param waypointModeParam RemoteUnrealParam<E_WaypointMode>
    function(selfParam, newQuestParam, waypointModeParam)
        local newQuest = newQuestParam:get() ---@cast newQuest UScriptStruct
        -- local questDt = FindFirstOf("/Game/Blueprints/DataTables/DT_Quests.DT_Quests") ---@cast questDt UDataTable
        -- if questDt then
        LogInfo("New quest recieved:")
        LogInfo(newQuest)
        newQuest:GetClass():ForEachProperty(
        ---@param prop Property
            function(prop)
                LogInfo(prop:GetFName():ToString())
            end)
        LogInfo("End property list")
        if newQuest then
            for k, v in pairs(newQuest) do
                LogInfo(k, v)
            end
        end
        -- else
        --     LogWarn("Cannot find quest data table")
        -- end
    end)

RegisterHook("Function /Game/Blueprints/Doors/SimpleDoor_ParentBP.SimpleDoor_ParentBP_C:TryOpenOrUnlockDoor",
    ---@param selfParam RemoteUnrealParam<ASimpleDoor_ParentBP_C>
    ---@param characterToTestParam RemoteUnrealParam<AActor>
    ---@param doorKickParam RemoteUnrealParam<boolean>
    ---@param forceDoorParam RemoteUnrealParam<boolean>
    ---@param forceDoorStateParam RemoteUnrealParam<E_DoorStates>
    function(selfParam, characterToTestParam, doorKickParam, forceDoorParam, forceDoorStateParam)
        local door = selfParam:get() ---@cast door ASimpleDoor_ParentBP_C
        if door.OneWayDoor then
            LogInfo("Forcing door lock to true for door " .. door:GetFName():ToString())
            door.OneWayDoor_HasBeenUnlocked = false
            door.DoorState = 0
        end
    end
)

-- Prevent doors from being unlocked unless permitted.
-- RegisterHook("Function /Game/Blueprints/Doors/SimpleDoor_ParentBP.SimpleDoor_ParentBP_C:IsDoorLocked",
--     ---@param selfParam RemoteUnrealParam
--     ---@param toiletLockedParam RemoteUnrealParam
--     ---@param oneWayLockedParam RemoteUnrealParam
--     function(selfParam, toiletLockedParam, oneWayLockedParam)
--         -- print(selfParam)
--         local door = selfParam:get() ---@cast door ASimpleDoor_ParentBP_C
--         -- print(door)
--         --FIXME This is either crashing or not working
--         if door.OneWayDoor then
--             -- LogInfo("Locked", oneWayLockedParam:get())
--             -- if oneWayLockedParam.IsValid then
--             LogInfo("Forcing door lock to true")
--             -- ExecuteInGameThread(function()
--             door.OneWayDoor_HasBeenUnlocked = false
--             -- oneWayLockedParam:set(true)
--             -- end)
--             -- else
--             -- LogInfo("Parameter isn't valid!")
--             -- end
--             -- selfParam:set(nil)
--             -- door = nil
--         end
--     end)

---@param door ASimpleDoor_ParentBP_C
NotifyOnNewObject("SimpleDoor_ParentBP_C", function(door)
    print("Door created:", door:GetFName():ToString())
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
