--Report out current quest when changed
RegisterHook("Function /Game/Blueprints/Widgets/HUD/W_HUD_QuestObjective.W_HUD_QuestObjective_C:UpdateCurrentQuest",
    ---@param selfParam RemoteUnrealParam<UW_HUD_QuestObjective_C>
    ---@param newQuestParam RemoteUnrealParam<UScriptStruct>
    ---@param waypointModeParam RemoteUnrealParam<E_WaypointMode>
    function(selfParam, newQuestParam, waypointModeParam)
        local self = selfParam:get() ---@cast self UW_HUD_QuestObjective_C
        local questName = self.CurrentQuest.RowName:ToString()
        if questName and questName ~= "None" then
            LogInfo("New quest recieved: ", questName)
        end
    end)

--Prevent doors from being unlocked unless permitted
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

--Prevent trams from being moved unless permitted
RegisterHook("Function /Game/Blueprints/Tram/TramSystem_Station.TramSystem_Station_C:IsStationLocked",
    ---@param selfParam RemoteUnrealParam<ATramSystem_Station_C>
    ---@param lockedParam RemoteUnrealParam<boolean>
    function(selfParam, lockedParam)
        local self = selfParam:get()
        LogInfo("Tram station lock check for", self.StationName:ToString(), lockedParam:get())
        lockedParam:set(true)
    end)
