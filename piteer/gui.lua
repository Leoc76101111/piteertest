local gui = {}
local plugin_label = "piteer v3.4a"

local function create_checkbox(key)
    return checkbox:new(false, get_hash(plugin_label .. "_" .. key))
end

gui.loot_modes_options = {
    "Nothing",  -- will get stuck
    "Stash",    -- nothing for now, will get stuck, but in future can be added
}

gui.loot_modes_enum = {
    NOTHING = 0,
    STASH = 1,
}

gui.gamble_categories = { "Quarterstaff","Cap", "Whispering Key", "Tunic", "Gloves", "Boots", "Pants", "Amulet", "Ring", "Polearm", "Glaive"}

gui.elements = {
    main_tree = tree_node:new(0),
    main_toggle = create_checkbox("main_toggle"),
    settings_tree = tree_node:new(1),
    path_settings_tree = tree_node:new(2),
    melee_logic = create_checkbox("melee_logic"),
    elite_only_toggle = create_checkbox("elite_only"),
    pit_level_slider = slider_int:new(1, 150, 1, 1984),
    loot_modes = combo_box:new(0, get_hash("piteer_loot_modes")),
    path_angle_slider = slider_int:new(0, 36, 0, get_hash("path_angle_slider")), -- 10 is a default value
    reset_time_slider = slider_int:new(60, 900, 600, get_hash("reset_time_slider")), -- New slider for reset time in seconds
    exit_pit_toggle = create_checkbox("exit_pit_toggle"),
    explorer_grid_size_slider = slider_int:new(10, 20, 15, get_hash("explorer_grid_size_slider")),
    gamble_category = combo_box:new(0, get_hash("piteer_gamble_category")),
    greater_affix_slider = slider_int:new(0, 3, 1, get_hash("greater_affix_slider")),
    gamble_toggle = create_checkbox("gamble_toggle"),
}

function gui.render()
    if not gui.elements.main_tree:push("Piteer V3.5") then return end

    gui.elements.main_toggle:render("Enable", "Enable the bot")
    
    if gui.elements.settings_tree:push("Settings") then
        gui.elements.elite_only_toggle:render("Elite Only", "Do we only want to seek out elites in the Pit?")
        gui.elements.pit_level_slider:render("Pit Level", "Which Pit level do you want to enter?")
        gui.elements.loot_modes:render("Keep Items", gui.loot_modes_options, "Do you want to stash items or keep in inventory?")
        gui.elements.reset_time_slider:render("Failed Run Threshold (seconds)", "Set the time in seconds for failed run time for resetting")
        gui.elements.exit_pit_toggle:render("Enable Exit Pit", "Toggle Exit Pit task on/off")
        gui.elements.gamble_toggle:render("Enable Gambling", "Toggle gambling on/off")
        gui.elements.gamble_category:render("Gamble Category", gui.gamble_categories, "Select the item category to gamble")
        gui.elements.greater_affix_slider:render("Keep Greater Affix Count ", "Set the number of greater affixes to Keep (0-3)")
        -- Path Settings subtree (moved to bottom)
        if gui.elements.path_settings_tree:push("Path Settings") then
            gui.elements.path_angle_slider:render("Path Angle", "Adjust the angle for path filtering (0-36 degrees)")
            gui.elements.explorer_grid_size_slider:render("Explorer Grid Size", "Adjust the grid size for exploration (1.0-2.0)")
            gui.elements.path_settings_tree:pop()
        end
        
        gui.elements.settings_tree:pop()
    end

    gui.elements.main_tree:pop()
end

return gui
