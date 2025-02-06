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
    use_alfred = false,
    alfred_return = false,
    upgrade_toggle = false,
    upgrade_mode = 0,
    upgrade_threshold = 50,
    upgrade_legendary_toggle = false,
}

function settings:update_settings()
    local class = gui.get_character_class()
    settings.enabled = gui.elements.main_toggle:get()
    settings.elites_only = gui.elements.elite_only_toggle:get()
    settings.pit_level = gui.elements.pit_level_slider:get()
    settings.loot_enabled = gui.elements.loot_toggle:get()
    settings.loot_modes = gui.elements.loot_modes:get()
    settings.path_angle = gui.elements.path_angle_slider:get()
    settings.reset_time = gui.elements.reset_time_slider:get()
    settings.exit_pit_enabled = gui.elements.exit_pit_toggle:get()
    settings.explorer_grid_size = gui.elements.explorer_grid_size_slider:get()
    settings.gamble_category = gui.gamble_categories[class][gui.elements.gamble_category[class]:get() + 1]
    settings.greater_affix_threshold = gui.elements.greater_affix_slider:get()
    settings.gamble_enabled = gui.elements.gamble_toggle:get()
    settings.use_alfred = gui.elements.use_alfred:get()
    settings.alfred_return = gui.elements.alfred_return:get()
    settings.upgrade_toggle = gui.elements.upgrade_toggle:get()
    settings.upgrade_mode = gui.elements.upgrade_mode:get()
    settings.upgrade_threshold = gui.elements.upgrade_threshold:get()
    settings.upgrade_legendary_toggle = gui.elements.upgrade_legendary_toggle:get()
end

return settings
