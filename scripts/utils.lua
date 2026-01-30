local this = {}

local AFUtils = require("AFUtils.AFUtils")

---Dumps the table values of the given table
---@param tbl table The table to dump
function this.DumpTable(tbl)
    for k, v in pairs(tbl) do
        print(k, v)
    end
end

---Unlocks the simple door that the crosshair is pointing at
function this.UnlockDoorAtCrosshair()
    local location = {}
    local rotation = {}
    AFUtils:GetMyPlayer():Local_GetPointAtCrosshair(location, rotation, nil)
    if location then
        local doors = FindAllOf("SimpleDoor_ParentBP_C") ---@cast doors ASimpleDoor_ParentBP_C[]
        ---@type ASimpleDoor_ParentBP_C
        local foundDoor
        ---@type ASimpleDoor_ParentBP_C
        for i, d in pairs(doors) do
            ---@type ASimpleDoor_ParentBP_C
            local door = d
            local position = door:K2_GetActorLocation()
            if math.abs(position.X - location.X) < 200 and
                math.abs(position.Y - location.Y) < 200 and
                math.abs(position.Z - location.Z) < 200 then
                print("Found a door!", i, position)
                foundDoor = door
                foundDoor:UnlockViaButton(true)
                break
            end
        end
        if not foundDoor then
            print("Didn't find a door")
        end
    else
        print("No hit")
    end
end

return this
