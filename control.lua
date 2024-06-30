
---@param entity LuaEntity
---@return string
local function get_fluid_name(entity)
    local fluid_name = ""
    local fluidbox = entity.fluidbox
    if fluidbox and fluidbox.valid then
        for index = 1, #fluidbox do
            local contents = fluidbox.get_fluid_system_contents(index)
            if contents then
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
local function paint_pipe(player, pipe)
    if not pipe.valid then return end
    local fluid_name = get_fluid_name(pipe)
    local pipe_type = pipe.type
    local already_painted = pipe.name == fluid_name .. "-" .. pipe_type
    if fluid_name and not (fluid_name == "") and not already_painted then
        if player.mod_settings["color-coded-pipe-planner-bots-required"].value then
            pipe.order_upgrade{
                force = pipe.force,
                target = fluid_name .. "-" .. pipe_type,
                player = player,
                direction = pipe.direction
            }
        else
            local entity = player.surface.create_entity{
                name = fluid_name .. "-" .. pipe_type,
                position = pipe.position,
                force = pipe.force,
                direction = pipe.direction,
                fluidbox = pipe.fluidbox,
                fast_replace = true,
                spill = false,
                player = nil,
            }
            entity.last_user = player
        end
    end
end

---@param player LuaPlayer
---@param pipe LuaEntity
local function unpaint_pipe(player, pipe)
    if not pipe.valid then return end
    local pipe_type = pipe.type
    local already_unpainted = pipe.name == pipe_type
    if not already_unpainted then
        if player.mod_settings["color-coded-pipe-planner-bots-required"].value then
            pipe.order_upgrade{
                force = pipe.force,
                target = pipe_type,
                player = player,
                direction = pipe.direction
            }
        else
            local entity = player.surface.create_entity{
                name = pipe_type,
                position = pipe.position,
                force = pipe.force,
                direction = pipe.direction,
                fluidbox = pipe.fluidbox,
                fast_replace = true,
                spill = false,
                player = nil,
            }
            entity.last_user = player
        end
    end
end

---@param event EventData.on_player_selected_area
local function on_player_selected_area(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local item = event.item
    if item ~= "pipe-painting-planner" then return end
    for _, entity in pairs(event.entities) do
        if entity.valid then
            paint_pipe(player, entity)
        end
    end
end

---@param event EventData.on_player_reverse_selected_area
local function on_player_alt_selected_area(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local item = event.item
    if not item == "pipe-painting-planner" then return end
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
    local player = game.get_player(event.player_index)
    if not player then return end
    local item = event.item
    if not item == "pipe-painting-planner" then return end
    for _, entity in pairs(event.entities) do
        if entity.valid then
            unpaint_pipe(player, entity)
        end
    end
end

---@param event EventData.on_player_alt_reverse_selected_area
local function on_player_alt_reverse_selected_area(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local item = event.item
    if not item == "pipe-painting-planner" then return end
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


---@param event EventData.on_player_cursor_stack_changed
local function on_player_cursor_stack_changed(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local ids = rendering.get_all_ids("color-coded-pipes")
    for _, id in pairs(ids) do
        if rendering.is_valid(id) then
            local players = rendering.get_players(id) or {}
            for _, renderid_player in pairs(players) do
                if renderid_player.index == player.index then
                    rendering.destroy(id)
                end
            end
        end
    end
    local item = player.cursor_stack
    if not item then return end
    if not item.valid_for_read then return end
    if not (item.name == "pipe-painting-planner") then return end
    global.planner_message_shown = global.planner_message_shown or {}
    global.planner_message_shown[player.index] = global.planner_message_shown[player.index] or 0
    if (global.planner_message_shown[player.index] == 0) then
        local mod_setting = player.mod_settings["color-coded-pipes-planner-tooltip"]
        mod_setting.value = true
        player.mod_settings["color-coded-pipes-planner-tooltip"] = mod_setting
    elseif (global.planner_message_shown[player.index] == 3) then
        local mod_setting = player.mod_settings["color-coded-pipes-planner-tooltip"]
        mod_setting.value = false
        player.mod_settings["color-coded-pipes-planner-tooltip"] = mod_setting
        player.print{"selection-tool-floating-text.tooltip-disabled"}
    end
    global.planner_message_shown[player.index] = global.planner_message_shown[player.index] + 1
    local show_tooltip = player.mod_settings["color-coded-pipes-planner-tooltip"].value
    if not show_tooltip then return end
    local position = player.position
    for i = 0, 8 do
        rendering.draw_text{
            text = { "selection-tool-floating-text.line-" .. i },
            surface = player.surface,
            target = { position.x - 4, position.y + i * 0.5 },
            use_rich_text = true,
            color = { r = 1, g = 1, b = 1 },
            players = { player },
        }
    end
end

-- script.on_event(defines.events.on_player_cursor_stack_changed, on_player_cursor_stack_changed)

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
                inventory.remove{name = "pipe-painting-planner", count = 1}
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
    local frame = player.gui.screen.add{
        type = "frame",
        name = "color-coded-pipes-planner-frame",
        caption = {"item-name.pipe-painting-planner"},
    }
    frame.auto_center = true
    frame.add{
        type = "button",
        -- sprite = "utility/close_black",
        -- hovered_sprite = "utility/close_white",
        name = "color-coded-pipes-planner-close-button",
        caption = {"color-pipes-gui.close-planner-button"},
        tooltip = {"gui.close-instruction"},
        style = "back_button",
    }
    frame.add{
        type = "button",
        -- sprite = "utility/trash",
        -- hovered_sprite = "utility/trash_white",
        name = "color-coded-pipes-planner-delete-button",
        caption = {"color-pipes-gui.delete-planner-button"},
        tooltip = {"color-pipes-gui.delete-planner-button"},
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

-- ---@param event EventData.on_mod_item_opened
-- local function delete_pipe_painting_planner(event)
--     local player = game.get_player(event.player_index)
--     if not player then return end
--     local item = event.item
--     if not (item.name == "pipe-painting-planner") then return end
--     local inventory = player.get_main_inventory()
--     if inventory and inventory.valid then
--         local count = inventory.get_item_count("pipe-painting-planner")
--         if count > 0 then
--             inventory.remove{name = "pipe-painting-planner", count = 1}
--         end
--     end
--     player.opened = player.get_main_inventory()
-- end

-- -- script.on_event("delete-pipe-painting-planner", delete_pipe_painting_planner)
-- script.on_event(defines.events.on_mod_item_opened, delete_pipe_painting_planner)