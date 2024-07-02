
-- data:extend{
--     {
--         type = "bool-setting",
--         name = "color-coded-pipes-planner-tooltip",
--         setting_type = "runtime-per-user",
--         default_value = false,
--         order = "a",
--         hidden = true,
--     }
-- }

local bots_required = {
    type = "bool-setting",
    name = "color-coded-pipe-planner-bots-required",
    setting_type = "runtime-per-user",
    default_value = true,
    order = "a",
}

local planner_mode = {
    type = "string-setting",
    name = "color-coded-pipe-planner-mode",
    setting_type = "runtime-per-user",
    default_value = "best-guess",
    allowed_values = { "best-guess", "perfect-match" },
    order = "b",
}

data:extend {
    bots_required,
    planner_mode,
}
