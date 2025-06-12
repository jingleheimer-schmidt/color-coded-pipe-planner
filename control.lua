
local painting = require("__color-coded-pipes__.scripts.painting")
local paint_pipe = painting.paint_pipe
local unpaint_pipe = painting.unpaint_pipe

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
