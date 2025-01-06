
local color_coded_util = require("__color-coded-pipes__/color-coded-util")
local rgb_colors = color_coded_util.rgb_colors ---@type table<string, Color>

local base_filter_items = {
    "pipe",
    "pipe-to-ground",
    "storage-tank",
    "pump",
}
if mods["pipe_plus"] then
    table.insert(base_filter_items, "pipe-to-ground-2")
    table.insert(base_filter_items, "pipe-to-ground-3")
end
if mods["Flow Control"] then
    table.insert(base_filter_items, "pipe-elbow")
    table.insert(base_filter_items, "pipe-junction")
    table.insert(base_filter_items, "pipe-straight")
end
if mods["StorageTank2_2_0"] then
    table.insert(base_filter_items, "storage-tank2")
end
if mods["zithorian-extra-storage-tanks-port"] then
    table.insert(base_filter_items, "fluid-tank-1x1")
    table.insert(base_filter_items, "fluid-tank-2x2")
    table.insert(base_filter_items, "fluid-tank-3x4")
    table.insert(base_filter_items, "fluid-tank-5x5")
end

local entity_filters = {} ---@type string[]
local alt_entity_filters = {} ---@type string[]
local reverse_entity_filters = {} ---@type string[]
local alt_reverse_entity_filters = {} ---@type string[]

for _, name in pairs(base_filter_items) do
    table.insert(entity_filters, name)
    table.insert(alt_entity_filters, name)
    table.insert(reverse_entity_filters, name)
    table.insert(alt_reverse_entity_filters, name)
end
for color_name, _ in pairs(rgb_colors) do
    local suffixes = {}
    for _, pipe_name in pairs(base_filter_items) do
        table.insert(suffixes, "-color-coded-" .. pipe_name)
    end
    for _, suffix in pairs(suffixes) do
        local full_name = color_name .. suffix
        local pipes, pipe_to_grounds, storage_tanks, pumps = data.raw["pipe"], data.raw["pipe-to-ground"], data.raw["storage-tank"], data.raw["pump"]
        if pipes[full_name] or pipe_to_grounds[full_name] or storage_tanks[full_name] or pumps[full_name] then
            table.insert(entity_filters, full_name)
            table.insert(alt_entity_filters, full_name)
            table.insert(reverse_entity_filters, full_name)
            table.insert(alt_reverse_entity_filters, full_name)
        end
    end
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
