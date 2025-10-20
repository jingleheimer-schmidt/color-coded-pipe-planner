
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
    local planner_modes = {
        ["best-guess"] = "rainbow",
        ["perfect-match"] = "fluid"
    }
    planner_mode = planner_modes[planner_mode] or "rainbow"
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
        if entity.valid and entity.to_be_upgraded() then
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

---@param player LuaPlayer
local function update_planner_gui_data(player)
    local planner_gui = player.gui.screen["color-coded-pipes-planner-frame"]
    if not planner_gui then return end
    local settings_table = planner_gui["color-coded-pipes-planner-settings-frame"]["color-coded-pipes-planner-settings-table"]
    if not settings_table then return end
    local bots_reset_button = settings_table["color-coded-pipe-planner-bots-required-label-flow"]["color-coded-pipe-planner-bots-required-reset-button"]
    local bots_checkbox = settings_table["color-coded-pipe-planner-bots-required-checkbox"]
    local mode_reset_button = settings_table["color-coded-pipe-planner-mode-label-flow"]["color-coded-pipe-planner-mode-reset-button"]
    local mode_dropdown = settings_table["color-coded-pipe-planner-mode-dropdown"]
    if not (bots_reset_button and bots_checkbox and mode_reset_button and mode_dropdown) then return end
    local mod_settings = player.mod_settings
    local bots_required = mod_settings["color-coded-pipe-planner-bots-required"].value --[[@as boolean]]
    local planner_mode = mod_settings["color-coded-pipe-planner-mode"].value --[[@as string]]
    local default_bots_value = settings.player_default["color-coded-pipe-planner-bots-required"].value --[[@as boolean]]
    local default_mode_value = settings.player_default["color-coded-pipe-planner-mode"].value --[[@as string]]
    bots_checkbox.state = bots_required
    mode_dropdown.selected_index = (planner_mode == "best-guess" and 1) or (planner_mode == "perfect-match" and 2) or 1
    bots_reset_button.enabled = (bots_required ~= default_bots_value)
    bots_reset_button.sprite = bots_reset_button.enabled and "utility/reset" or "utility/reset_white"
    mode_reset_button.enabled = (planner_mode ~= default_mode_value)
    mode_reset_button.sprite = mode_reset_button.enabled and "utility/reset" or "utility/reset_white"
end

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
    if name == "color-coded-pipe-planner-bots-required-reset-button" then
        local default_value = settings.player_default["color-coded-pipe-planner-bots-required"].value --[[@as boolean]]
        player.mod_settings["color-coded-pipe-planner-bots-required"] = { value = default_value }
    end
    if name == "color-coded-pipe-planner-bots-required-checkbox" then
        local state = element.state --[[@as boolean]]
        player.mod_settings["color-coded-pipe-planner-bots-required"] = { value = state }
    end
    if name == "color-coded-pipe-planner-mode-reset-button" then
        local default_value = settings.player_default["color-coded-pipe-planner-mode"].value --[[@as string]]
        player.mod_settings["color-coded-pipe-planner-mode"] = { value = default_value }
    end
    if name == "color-coded-pipe-planner-mode-dropdown" then
        local index = element.selected_index --[[@as uint]]
        local modes = {
            [1] = "best-guess",
            [2] = "perfect-match"
        }
        local mode = modes[index] or "best-guess"
        player.mod_settings["color-coded-pipe-planner-mode"] = { value = mode }
    end
    update_planner_gui_data(player)
end

script.on_event(defines.events.on_gui_click, on_gui_click)

---@param event EventData.on_gui_selection_state_changed
local function on_gui_selection_state_changed(event)
    local element = event.element
    local name = element.name
    if name == "color-coded-pipe-planner-mode-dropdown" then
        local player = game.get_player(event.player_index)
        if not (player and player.valid) then return end
        local index = element.selected_index --[[@as uint]]
        local modes = {
            [1] = "best-guess",
            [2] = "perfect-match"
        }
        local mode = modes[index] or "best-guess"
        player.mod_settings["color-coded-pipe-planner-mode"] = { value = mode }
        update_planner_gui_data(player)
    end
end

script.on_event(defines.events.on_gui_selection_state_changed, on_gui_selection_state_changed)

---@param event EventData.on_mod_item_opened
local function on_mod_item_opened(event)
    local player = game.get_player(event.player_index)
    if not player then return end
    local item = event.item.name
    if item ~= "pipe-painting-planner" then return end
    if player.gui.screen["color-coded-pipes-planner-frame"] then
        player.gui.screen["color-coded-pipes-planner-frame"].destroy()
    end
    local frame = player.gui.screen.add {
        type = "frame",
        name = "color-coded-pipes-planner-frame",
        caption = { "item-name.pipe-painting-planner" },
        direction = "vertical",
    }
    frame.auto_center = true
    local settings_frame = frame.add {
        type = "frame",
        name = "color-coded-pipes-planner-settings-frame",
        -- caption = { "color-pipes-gui.planner-settings" },
        style = "inside_shallow_frame_with_padding"
    }
    local button_flow = frame.add {
        type = "flow",
        name = "color-coded-pipes-planner-button-frame",
        style = "dialog_buttons_horizontal_flow",
    }
    button_flow.style.horizontally_stretchable = true
    button_flow.style.horizontal_align = "center"
    button_flow.add {
        type = "button",
        -- sprite = "utility/close_black",
        -- hovered_sprite = "utility/close_white",
        name = "color-coded-pipes-planner-close-button",
        caption = { "color-pipes-gui.close-planner-button" },
        tooltip = { "gui.close-instruction" },
        style = "back_button",
    }
    local button_graggable_space = button_flow.add {
        type = "empty-widget",
        style = "draggable_space_header",
    }
    button_graggable_space.style.horizontally_stretchable = true
    button_flow.add {
        type = "button",
        -- sprite = "utility/trash",
        -- hovered_sprite = "utility/trash_white",
        name = "color-coded-pipes-planner-delete-button",
        caption = { "color-pipes-gui.delete-planner-button" },
        tooltip = { "color-pipes-gui.delete-planner-button" },
        style = "red_confirm_button",
    }
    -- Build a two-column table for settings: [label+info] | [control]
    local settings_table = settings_frame.add {
        type = "table",
        name = "color-coded-pipes-planner-settings-table",
        column_count = 2,
        draw_horizontal_lines = false,
        draw_vertical_lines = false,
    }
    -- Tweak spacing/alignment so controls sit to the right
    settings_table.style.horizontal_spacing = 12
    settings_table.style.column_alignments[2] = "right"

    -- Row 1: Require Construction Bots [i] | [checkbox]
    local bots_label_flow = settings_table.add { type = "flow", name = "color-coded-pipe-planner-bots-required-label-flow", direction = "horizontal" }
    bots_label_flow.add {
        type = "sprite-button",
        style = "mini_tool_button_red",
        name = "color-coded-pipe-planner-bots-required-reset-button",
        sprite = "utility/reset",
        -- tooltip = { "gui.reset-instruction" },
    }
    bots_label_flow.add {
        type = "label",
        caption = { "", { "mod-setting-name.color-coded-pipe-planner-bots-required" }, " [img=info]" },
        tooltip = { "mod-setting-description.color-coded-pipe-planner-bots-required" },
    }
    settings_table.add {
        type = "checkbox",
        name = "color-coded-pipe-planner-bots-required-checkbox",
        state = player.mod_settings["color-coded-pipe-planner-bots-required"].value --[[@as boolean]]
    }

    -- Row 2: Color Matching Mode [i] | [dropdown]
    local mode_label_flow = settings_table.add { type = "flow", name = "color-coded-pipe-planner-mode-label-flow", direction = "horizontal" }
    mode_label_flow.add {
        type = "sprite-button",
        style = "mini_tool_button_red",
        name = "color-coded-pipe-planner-mode-reset-button",
        sprite = "utility/reset"
    }
    mode_label_flow.add {
        type = "label",
        caption = { "", { "mod-setting-name.color-coded-pipe-planner-mode" }, " [img=info]" },
        tooltip = { "mod-setting-description.color-coded-pipe-planner-mode" },
    }
    settings_table.add {
        type = "drop-down",
        name = "color-coded-pipe-planner-mode-dropdown",
        items = {
            { "string-mod-setting.color-coded-pipe-planner-mode-best-guess" },
            { "string-mod-setting.color-coded-pipe-planner-mode-perfect-match" },
        },
    }
    player.opened = frame
    update_planner_gui_data(player)
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
