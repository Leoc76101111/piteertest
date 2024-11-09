local gui = require "gui"
local settings = {
    enabled = false,
    elites_only = false,
    pit_level = 1,
    loot_enabled = true, -- Default to true
    path_angle = 0,
    reset_time = 1, -- Default to 1
    exit_pit_enabled = true, -- Default to true
    explorer_grid_size = 10,
    gamble_category = "Cap",
    greater_affix_threshold = 1,
    gamble_enabled = false,
}

function settings:update_settings()
    settings.enabled = gui.elements.main_toggle:get()
    settings.elites_only = gui.elements.elite_only_toggle:get()
    settings.pit_level = gui.elements.pit_level_slider:get()
    settings.loot_enabled = gui.elements.loot_toggle:get()
    settings.loot_modes = gui.elements.loot_modes:get()
    settings.path_angle = gui.elements.path_angle_slider:get()
    settings.reset_time = gui.elements.reset_time_slider:get()
    settings.exit_pit_enabled = gui.elements.exit_pit_toggle:get()
    settings.explorer_grid_size = gui.elements.explorer_grid_size_slider:get()
    settings.gamble_category = gui.gamble_categories[gui.elements.gamble_category:get() + 1]
    settings.greater_affix_threshold = gui.elements.greater_affix_slider:get()
    settings.gamble_enabled = gui.elements.gamble_toggle:get()
end

return settings
