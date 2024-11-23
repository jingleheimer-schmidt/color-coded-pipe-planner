
local fluid_to_color_map = require("fluid_to_color_map")

---@param entity LuaEntity
---@return boolean
local function entity_is_crafting_machine(entity)
    local type = entity.type
    local crafting_machine_types = {
        ["assembling-machine"] = true,
        ["furnace"] = true,
        ["rocket-silo"] = true,
    }
    return crafting_machine_types[type]
end

---@param entity LuaEntity
---@return string
local function get_fluid_name(entity)
    local fluid_name = ""
    local fluidbox = entity.fluidbox
    if fluidbox and fluidbox.valid then
        for index = 1, #fluidbox do
            local contents = fluidbox.get_fluid_segment_contents(index)
            if contents and next(contents) then
                local amount = 0
                for name, count in pairs(contents) do
                    if count > amount then
                        amount = count
                        fluid_name = name
                    end
                end
                break
            end
        end
    end
    return fluid_name
end

---@param player LuaPlayer
---@param pipe LuaEntity
---@param bots_required boolean
---@param planner_mode string
local function paint_pipe(player, pipe, bots_required, planner_mode)
    if not pipe.valid then return end
    local fluid_name = get_fluid_name(pipe)
    local pipe_name = pipe.name
    local prefix = ((planner_mode == "perfect-match") and fluid_name) or fluid_to_color_map[fluid_name] or fluid_name
    local start_index, end_index = pipe_name:find(prefix .. "-color-coded-", 1, true)
    local pipe_color_needs_update = not (start_index and end_index)
    if pipe_color_needs_update then start_index, end_index = pipe_name:find("-color-coded-", 1, true) end
    local unpainted_pipe_name = pipe_color_needs_update and pipe_name:sub((end_index or 0) + 1) or pipe_name
    if fluid_name and fluid_name ~= "" and pipe_color_needs_update then
        local name = prefix .. "-color-coded-" .. unpainted_pipe_name
        local force = pipe.force
        local direction = pipe.direction
        if bots_required then
            pipe.order_upgrade {
                force = force,
                target = name,
                player = player,
                direction = direction
            }
        else
            local surface = pipe.surface
            local position = pipe.position
            if surface.can_fast_replace {
                    name = name,
                    position = position,
                    direction = direction,
                    force = force,
                } then
                local entity = player.surface.create_entity {
                    name = name,
                    position = position,
                    force = force,
                    direction = direction,
                    fluidbox = pipe.fluidbox,
                    fast_replace = true,
                    spill = false,
                    player = nil,
                }
                entity.last_user = player
            end
        end
    end
end

---@param player LuaPlayer
---@param pipe LuaEntity
---@param bots_required boolean
local function unpaint_pipe(player, pipe, bots_required)
    if not pipe.valid then return end
    local start_index, end_index = pipe.name:find("-color-coded-", 1, true)
    if start_index and end_index then
        local force = pipe.force
        local direction = pipe.direction
        local target_name = pipe.name:sub(end_index + 1)
        if bots_required then
            pipe.order_upgrade {
                force = force,
                target = target_name,
                player = player,
                direction = direction,
            }
        else
            local surface = pipe.surface
            local position = pipe.position
            if surface.can_fast_replace {
                    name = target_name,
                    position = position,
                    direction = direction,
                    force = force,
                } then
                local entity = player.surface.create_entity {
                    name = target_name,
                    position = position,
                    force = force,
                    direction = direction,
                    fluidbox = pipe.fluidbox,
                    fast_replace = true,
                    spill = false,
                    player = nil,
                }
                entity.last_user = player
            end
        end
    end
end

---@param event EventData.on_player_selected_area
local function on_player_selected_area(event)
    if event.item ~= "pipe-painting-planner" then return end
    local player = game.get_player(event.player_index)
    if not player then return end
    local bots_required = player.mod_settings["color-coded-pipe-planner-bots-required"].value --[[@as boolean]]
    local planner_mode = player.mod_settings["color-coded-pipe-planner-mode"].value --[[@as string]]
    for _, entity in pairs(event.entities) do
        if entity.valid then
            paint_pipe(player, entity, bots_required, planner_mode)
        end
    end
end

---@param event EventData.on_player_reverse_selected_area
local function on_player_alt_selected_area(event)
    if event.item ~= "pipe-painting-planner" then return end
    local player = game.get_player(event.player_index)
    if not player then return end
    local force = player.force
    for _, entity in pairs(event.entities) do
        if not entity.valid then
        elseif entity.to_be_upgraded() then
            entity.cancel_upgrade(force, player)
        end
    end
end

---@param event EventData.on_player_reverse_selected_area
local function on_player_reverse_selected_area(event)
    if event.item ~= "pipe-painting-planner" then return end
    local player = game.get_player(event.player_index)
    if not player then return end
    local bots_required = player.mod_settings["color-coded-pipe-planner-bots-required"].value --[[@as boolean]]
    for _, entity in pairs(event.entities) do
        if entity.valid then
            unpaint_pipe(player, entity, bots_required)
        end
    end
end

---@param event EventData.on_player_alt_reverse_selected_area
local function on_player_alt_reverse_selected_area(event)
    if event.item ~= "pipe-painting-planner" then return end
    local player = game.get_player(event.player_index)
    if not player then return end
    local force = player.force
    for _, entity in pairs(event.entities) do
        if entity.valid and entity.to_be_upgraded() then
            entity.cancel_upgrade(force, player)
        end
    end
end

-- selection mode notes:
-- select is left-click + drag
-- alt_select is shift-left-click + drag
-- reverse_select is right-click + drag
-- alt_reverse_select is shift-right-click + drag

script.on_event(defines.events.on_player_selected_area, on_player_selected_area)
script.on_event(defines.events.on_player_alt_selected_area, on_player_alt_selected_area)
script.on_event(defines.events.on_player_reverse_selected_area, on_player_reverse_selected_area)
script.on_event(defines.events.on_player_alt_reverse_selected_area, on_player_alt_reverse_selected_area)

---@param event EventData.on_gui_click
local function on_gui_click(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local element = event.element
    if not element.valid then return end
    local name = element.name
    if not name then return end
    if name == "color-coded-pipes-planner-delete-button" then
        local inventory = player.get_main_inventory()
        if inventory and inventory.valid then
            local count = inventory.get_item_count("pipe-painting-planner")
            if count > 0 then
                inventory.remove { name = "pipe-painting-planner", count = 1 }
            end
        end
        player.gui.screen["color-coded-pipes-planner-frame"].destroy()
        player.opened = player
    end
    if name == "color-coded-pipes-planner-close-button" then
        player.gui.screen["color-coded-pipes-planner-frame"].destroy()
        player.opened = player
    end
end

script.on_event(defines.events.on_gui_click, on_gui_click)

---@param event EventData.on_mod_item_opened
local function on_mod_item_opened(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local item = event.item
    if not item == "pipe-painting-planner" then return end
    if player.gui.screen["color-coded-pipes-planner-frame"] then
        player.gui.screen["color-coded-pipes-planner-frame"].destroy()
    end
    local frame = player.gui.screen.add {
        type = "frame",
        name = "color-coded-pipes-planner-frame",
        caption = { "item-name.pipe-painting-planner" },
    }
    frame.auto_center = true
    frame.add {
        type = "button",
        -- sprite = "utility/close_black",
        -- hovered_sprite = "utility/close_white",
        name = "color-coded-pipes-planner-close-button",
        caption = { "color-pipes-gui.close-planner-button" },
        tooltip = { "gui.close-instruction" },
        style = "back_button",
    }
    frame.add {
        type = "button",
        -- sprite = "utility/trash",
        -- hovered_sprite = "utility/trash_white",
        name = "color-coded-pipes-planner-delete-button",
        caption = { "color-pipes-gui.delete-planner-button" },
        tooltip = { "color-pipes-gui.delete-planner-button" },
        style = "red_confirm_button",
    }
    player.opened = frame
end

script.on_event(defines.events.on_mod_item_opened, on_mod_item_opened)

---@param event EventData.on_gui_closed
local function on_gui_closed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local screen = player.gui.screen
    if screen["color-coded-pipes-planner-frame"] then
        screen["color-coded-pipes-planner-frame"].destroy()
        player.opened = player
    end
end

script.on_event(defines.events.on_gui_closed, on_gui_closed)
