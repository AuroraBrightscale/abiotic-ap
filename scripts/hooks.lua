local utils = require("utils")
local afUtils = require("AFUtils.AFUtils")
local locations = require("locations")

---@type [string, integer, integer][]
local hooks = {}

local this = {}

---Called when the player quits the game.
---@type fun() | nil
this.OnQuitGame = nil

---Called when a check should be sent.
---@type fun(id: integer) | nil
this.OnLocationCheck = nil

--- Registers a hook using the same UE4SS RegisterHook signature, but collects the hook's IDs to
--- unregister when the player quits the game.
---@param name string
---@param fn fun(self: UObject, ...)
---@return integer preId
---@return integer postId
function SafeRegisterHook(name, fn)
    local preId, postId = RegisterHook(name, fn)
    table.insert(hooks, { name, preId, postId })
    return preId, postId
end

--Report out current quest when changed
SafeRegisterHook("Function /Game/Blueprints/Widgets/HUD/W_HUD_QuestObjective.W_HUD_QuestObjective_C:UpdateCurrentQuest",
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


--These simple doors are always unlocked no matter what
local always_unlocked = {
    "SimpleDoor_ParentBP_C /Game/Maps/Facility_Office1.Facility_Office1:PersistentLevel.SimpleDoor_ParentBP_C_9",
    "SimpleDoor_ParentBP_C /Game/Maps/Facility_Office1.Facility_Office1:PersistentLevel.SimpleDoor_ParentBP_C_5"
}

--Prevent doors from being unlocked unless permitted
SafeRegisterHook("Function /Game/Blueprints/Doors/SimpleDoor_ParentBP.SimpleDoor_ParentBP_C:TryOpenOrUnlockDoor",
    ---@param selfParam RemoteUnrealParam<ASimpleDoor_ParentBP_C>
    ---@param characterToTestParam RemoteUnrealParam<AActor>
    ---@param doorKickParam RemoteUnrealParam<boolean>
    ---@param forceDoorParam RemoteUnrealParam<boolean>
    ---@param forceDoorStateParam RemoteUnrealParam<E_DoorStates>
    function(selfParam, characterToTestParam, doorKickParam, forceDoorParam, forceDoorStateParam)
        local door = selfParam:get() ---@cast door ASimpleDoor_ParentBP_C
        if door.OneWayDoor and not utils.ArrayContains(always_unlocked, door:GetFullName()) then
            LogInfo("Forcing door lock to true for door " .. door:GetFullName())
            afUtils.DisplayWarningMessage(
                "This door is currently locked. But someone else may have found something...",
                AFUtils.CriticalityLevels.Yellow
            )
            door.OneWayDoor_HasBeenUnlocked = false
            door.DoorState = 0 --Keep the door shut
        end
    end)


--A list of recipe names that are learned via checks
local checkRecipes = {
    "recipe_brick_power"
}

SafeRegisterHook(
    "/Game/Blueprints/Meta/Abiotic_Survival_GameMode.Abiotic_Survival_GameMode_C:ApplyAllWorldSaveData",
    ---@param selfParam RemoteUnrealParam<AAbiotic_Survival_GameMode_C>
    ---@param levelParam RemoteUnrealParam<FString>
    ---@param iterationParam RemoteUnrealParam<integer>
    ---@param doAllIterations RemoteUnrealParam<boolean>
    ---@param saveParam RemoteUnrealParam<UAbiotic_WorldSave_C>
    ---@param levelObjectParam RemoteUnrealParam<UObject>
    ---@param persistentParam RemoteUnrealParam<boolean>
    function(
        selfParam,
        levelParam,
        iterationParam,
        doAllIterations,
        saveParam,
        levelObjectParam,
        persistentParam
    )
        ---Seed initialization: Open the cafeteria section and set the first quest to report to
        ---the security officer
        if levelParam:get():ToString() == "Facility_Office1" then
            --Destroy the cafeteria door
            local damagetype = FindFirstOf("/Game/Blueprints/DamageTypes/DamageType_Blunt")
            ---@cast damagetype UDamageType_Blunt_C
            local facility1 = FindFirstOf("Facility_Office1_C")
            ---@cast facility1 AFacility_Office1_C
            if facility1 and facility1:IsValid() and damagetype then
                facility1.Destructible_CafeteriaDoor_C_1_ExecuteUbergraph_Facility_Office1_RefProperty:TryApplyDamage(
                    1000,
                    damagetype
                )
                LogDebug("Cafeteria door to lobby opened")
            else
                LogDebug("Could not find cafeteria door to lobby")
            end

            --Open the midway cafeteria doors
            for i, doorName in ipairs({ "SimpleDoor_ParentBP_C_9", "SimpleDoor_ParentBP_C_5" }) do
                local door = StaticFindObject(
                    "/Game/Maps/Facility_Office1.Facility_Office1:PersistentLevel." .. doorName
                )
                ---@cast door ASimpleDoor_ParentBP_C
                if door and door:IsValid() then
                    door:UnlockViaButton(true)
                    LogDebug("Opened cafeteria midway door " .. i)
                else
                    LogDebug("Could not find cafeteria midway door " .. i)
                end
            end

            --Set the quest to the proper first one if necessary.
            local beforehand_quests = { "None", "quest_cafeteriadoor" }
            local currentQuest = AFUtils.GetSurvivalGameState().CurrentQuest.RowName:ToString()
            if utils.ArrayContains(beforehand_quests, currentQuest) then
                AFUtils.GetSurvivalGameState().CurrentQuest = {
                    ---@diagnostic disable-next-line: assign-type-mismatch
                    DataTablePath = "/Script/Engine.DataTable'/Game/Blueprints/DataTables/DT_Quests.DT_Quests'",
                    RowName = FName("quest_findofficer")
                }
                AFUtils.GetSurvivalGameState():OnRep_CurrentQuest()
            end
        end
    end
)

SafeRegisterHook(
    "/Game/Blueprints/Widgets/Inventory/W_Research_RecipeGuesser.W_Research_RecipeGuesser_C:CorrectRecipe?",
    ---@param selfParam RemoteUnrealParam
    ---@param correctParam RemoteUnrealParam
    function(selfParam, correctParam)
        local _self = selfParam:get() ---@type UW_Research_RecipeGuesser_C
        local correct = correctParam:get() ---@type boolean
        local itemName = _self.CurrentRecipe:ToString()
        local checkSearch = utils.Search(locations.research, "ref", itemName)
        local checkData = utils.FirstOrNil(checkSearch)

        if correct and checkData then
            LogDebug("Blocking AP restricted research: ", checkData.ref)
            correctParam:set(false)
            for _, slot in ipairs({
                _self.ReceivingSlot0,
                _self.ReceivingSlot1,
                _self.ReceivingSlot2,
                _self.ReceivingSlot3,
            }) do
                slot:ResetSlotToEmpty()
                slot.CorrectTrim:SetVisibility(2) --ESlateVisibility.Hidden
            end
            if this.OnLocationCheck then
                this.OnLocationCheck(checkData.id)
            end
            afUtils.DisplayWarningMessage(
                "You can't learn this yet. But someone else may have found something...",
                AFUtils.CriticalityLevels.Yellow
            )
        else
            LogDebug("Not blocking research (Not AP block or incorrect recipe)", itemName)
        end
    end
)

--Dump name of any learned recipe
SafeRegisterHook(
    "/Game/Blueprints/Characters/Abiotic_CharacterProgressionComponent.Abiotic_CharacterProgressionComponent_C:AddPendingRecipesToUnlock",
    ---@param selfParam RemoteUnrealParam
    ---@param recipeRowNameParam RemoteUnrealParam
    function(selfParam, recipeRowNameParam)
        ---@type FName
        local name = recipeRowNameParam:get()
        LogDebug("[AddPendingRecipesToUnlock] Learned recipe " .. name:ToString())
    end
)

--Prevent recipes from being learned unless permitted
-- RegisterHook(
--     "/Game/Blueprints/Characters/Abiotic_CharacterProgressionComponent.Abiotic_CharacterProgressionComponent_C:AddPendingRecipesToUnlock",
--     ---@param selfParam RemoteUnrealParam
--     ---@param recipeRowNameParam RemoteUnrealParam
--     function(selfParam, recipeRowNameParam)
--         ---@type FName
--         local name = recipeRowNameParam:get()
--         LogDebug("[AddPendingRecipesToUnlock] Blocked recipe " .. name:ToString())
--         ---@type UAbiotic_CharacterProgressionComponent_C
--         local progressionComponent = selfParam:get()
--         progressionComponent.PendingRecipesToUnlock = {}
--     end
-- )

--Prevent trams from being moved unless permitted
SafeRegisterHook("Function /Game/Blueprints/Tram/TramSystem_Station.TramSystem_Station_C:IsStationLocked",
    ---@param selfParam RemoteUnrealParam<ATramSystem_Station_C>
    ---@param lockedParam RemoteUnrealParam<boolean>
    function(selfParam, lockedParam)
        local self = selfParam:get()
        LogInfo("Tram station lock check for", self.StationName:ToString(), lockedParam:get())
        lockedParam:set(true)
    end)

--We're quitting now. Clean up hooks.
SafeRegisterHook("/Game/Blueprints/Widgets/MenuSystem/W_EscapeMenu_Main.W_EscapeMenu_Main_C:Quit_Quit",
    function()
        LogInfo("Exiting game")
        for _, ids in ipairs(hooks) do
            UnregisterHook(ids[1], ids[2], ids[3])
        end

        if this.OnQuitGame then
            this.OnQuitGame()
        end
    end)

return this
