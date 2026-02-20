---@class Location
---@field id integer
---@field name string
---@field ref string

-- TODO: This will eventually be merged with the apworld's location list
---@type Location[]
local research = {
    {
        id = 0x0101,
        name = "Research - Tier 1 Keypad Hacker",
        ref = "recipe_keypadhacker",
    },
    {
        id = 0x0102,
        name = "Research - Energy Brick",
        ref = "recipe_brick_power",
    }
}

return {
    research = research
}
