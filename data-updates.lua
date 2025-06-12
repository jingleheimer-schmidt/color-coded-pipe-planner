
local constants = require("__color-coded-pipes__.scripts.constants")
local pipe_colors = constants.pipe_colors
local base_entities = constants.base_entities

local filter_items = {}
for _, entity_data in pairs(base_entities) do
    local entity_name = entity_data.name
    local pipes, pipe_to_grounds, storage_tanks, pumps = data.raw["pipe"], data.raw["pipe-to-ground"], data.raw["storage-tank"], data.raw["pump"]
    if pipes[entity_name] or pipe_to_grounds[entity_name] or storage_tanks[entity_name] or pumps[entity_name] then
        table.insert(filter_items, entity_name)
    end
    for color_name, _ in pairs(pipe_colors) do
        local prototype_name = color_name .. "-color-coded-" .. entity_name
        if pipes[prototype_name] or pipe_to_grounds[prototype_name] or storage_tanks[prototype_name] or pumps[prototype_name] then
            table.insert(filter_items, prototype_name)
        end
    end
end

local entity_filters = {} ---@type string[]
local alt_entity_filters = {} ---@type string[]
local reverse_entity_filters = {} ---@type string[]
local alt_reverse_entity_filters = {} ---@type string[]

for _, name in pairs(filter_items) do
    table.insert(entity_filters, name)
    table.insert(alt_entity_filters, name)
    table.insert(reverse_entity_filters, name)
    table.insert(alt_reverse_entity_filters, name)
end

local pipe_painting_planner = table.deepcopy(data.raw["selection-tool"]["selection-tool"])
pipe_painting_planner.name = "pipe-painting-planner"

pipe_painting_planner.select.entity_filters = entity_filters
pipe_painting_planner.select.mode = { "friend", "upgrade", }

pipe_painting_planner.alt_select.entity_filters = alt_entity_filters
pipe_painting_planner.alt_select.mode = { "friend", "cancel-upgrade", }

pipe_painting_planner.reverse_select = table.deepcopy(pipe_painting_planner.select)
pipe_painting_planner.reverse_select.entity_filters = reverse_entity_filters
pipe_painting_planner.reverse_select.mode = { "friend", "upgrade", }

pipe_painting_planner.alt_reverse_select = table.deepcopy(pipe_painting_planner.alt_select)
pipe_painting_planner.alt_reverse_select.entity_filters = alt_reverse_entity_filters
pipe_painting_planner.alt_reverse_select.mode = { "friend", "cancel-upgrade", }

pipe_painting_planner.flags = {
    "not-stackable",
    "spawnable",
    -- "only-in-cursor",
    "mod-openable",
}
pipe_painting_planner.icon = "__color-coded-pipe-planner__/graphics/selection-tool-icon/selection-tool-icon.png"
pipe_painting_planner.order = "c[automated-construction]-p[pipe-painting-planner]"
pipe_painting_planner.subgroup = data.raw["upgrade-item"]["upgrade-planner"].subgroup
-- pipe_painting_planner.icons = {
--     {
--         icon = pipe_painting_planner.icon,
--         icon_size = pipe_painting_planner.icon_size,
--         icon_mipmaps = pipe_painting_planner.icon_mipmaps,
--         tint = { r = 0.8, g = 0.5, b = 0.2, a = 1.0 }
--     }
-- }

data:extend { pipe_painting_planner }

local pipe_painting_shortcut = table.deepcopy(data.raw["shortcut"]["give-upgrade-planner"])
pipe_painting_shortcut.name = "give-pipe-painting-shortcut"
pipe_painting_shortcut.item_to_spawn = "pipe-painting-planner"
pipe_painting_shortcut.localised_name = { "shortcut-name.give-pipe-painting-shortcut" }
pipe_painting_shortcut.localised_description = { "shortcut-description.give-pipe-painting-shortcut" }
pipe_painting_shortcut.associated_control_input = "pipe-painting-custom-input"
pipe_painting_shortcut.order = "b[blueprints]-p[pipe-painting-planner]"
pipe_painting_shortcut.style = "default"
pipe_painting_shortcut.icon = "__color-coded-pipe-planner__/graphics/selection-planner-shortcut/pipe-painting-planner-x32-white.png"
pipe_painting_shortcut.icon_size = 32
pipe_painting_shortcut.small_icon = "__color-coded-pipe-planner__/graphics/selection-planner-shortcut/pipe-painting-planner-x24-white.png"
pipe_painting_shortcut.small_icon_size = 24
-- pipe_painting_shortcut.disabled_small_icon.filename = "__color-coded-pipe-planner__/graphics/selection-planner-shortcut/pipe-painting-planner-x24.png"

data:extend { pipe_painting_shortcut }

local pipe_painting_custom_input = {
    type = "custom-input",
    name = "pipe-painting-custom-input",
    key_sequence = "ALT + P",
    action = "spawn-item",
    item_to_spawn = "pipe-painting-planner",
}
data:extend { pipe_painting_custom_input }
