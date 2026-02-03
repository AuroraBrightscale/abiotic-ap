local this = {}

local AFUtils = require("AFUtils.AFUtils")

---Dumps the table values of the given table
---@param tbl table The table to dump
function this.DumpTable(tbl, prefix)
    for k, v in pairs(tbl) do
        if type(v) == "table" then
            this.DumpTable(v, k .. ".")
        else
            if prefix then
                print(prefix .. k, v)
            else
                print(k, v)
            end
        end
    end
end

---Splits a string with a single character delimiter.
---From https://stackoverflow.com/questions/1426954/split-string-in-lua
---@param inputstr string
---@param sep string | nil
---@return string[]
function this.SplitString(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t = {}
    for str in string.gmatch(inputstr, "([^" .. sep .. "]+)") do
        table.insert(t, str)
    end
    return t
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
