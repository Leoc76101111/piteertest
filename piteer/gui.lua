local gui = {}
local plugin_label = "piteer v3.9"

local function create_checkbox(key)
    return checkbox:new(false, get_hash(plugin_label .. "_" .. key))
end


-- not able to require utils (and settings) because of circular reference
-- so the function lives in gui
function gui.get_character_class()
    local local_player = get_local_player();
    if not local_player then return 'default' end
    local class_id = local_player:get_character_class_id()
    local character_classes = {
        [0] = 'sorcerer',
        [1] = 'barbarian',
        [3] = 'rogue',
        [5] = 'druid',
        [6] = 'necromancer',
        [7] = 'spiritborn'
    }
    if character_classes[class_id] then
        return character_classes[class_id]
    else
        return 'default'
    end
end

gui.loot_modes_options = {
    "Nothing",  -- will get stuck
    "Sell",     -- will sell all and keep going
    "Salvage",  -- will salvage all and keep going
    "Stash",    -- nothing for now, will get stuck, but in future can be added
}

gui.loot_modes_enum = {
    NOTHING = 0,
    SELL = 1,
    SALVAGE = 2,
    STASH = 3,
}
gui.upgrade_modes_enum = {
    HIGHEST = 0,
    LOWEST = 1,
    PRIORITY = 2
}
gui.upgrade_mode = { "Highest to lowest", "Lowest to highest"}

gui.gamble_categories = {
    ['sorcerer'] = {"Cap", "Whispering Key", "Tunic", "Gloves", "Boots", "Pants", "Amulet", "Ring", "Sword", "Mace", "Dagger", "Staff", "Wand", "Focus"},
    ['barbarian'] = {"Cap", "Whispering Key", "Tunic", "Gloves", "Boots", "Pants", "Amulet", "Ring", "Axe", "Sword", "Mace", "Two-Handed Axe", "Two-Handed Sword", "Two-Handed Mace", "Polearm"},
    ['rogue'] = {"Cap", "Whispering Key", "Tunic", "Gloves", "Boots", "Pants", "Amulet", "Ring", "Sword", "Dagger", "Bow", "Crossbow"},
    ['druid'] = {"Cap", "Whispering Key", "Tunic", "Gloves", "Boots", "Pants", "Amulet", "Ring", "Axe", "Sword", "Mace", "Two-Handed Axe", "Two-Handed Mace", "Polearm", "Dagger", "Staff", "Totem"},
    ['necromancer'] = {"Cap", "Whispering Key", "Tunic", "Gloves", "Boots", "Pants", "Amulet", "Ring", "Axe", "Sword", "Mace", "Two-Handed Axe", "Two-Handed Sword", "Scythe", "Two-Handed Mace", "Two-Handed Scythe", "Dagger", "Shield", "Wand", "Focus"},
    ['spiritborn'] = {"Quarterstaff", "Cap", "Whispering Key", "Tunic", "Gloves", "Boots", "Pants", "Amulet", "Ring", "Polearm", "Glaive"},
    ['default'] = {"CLASS NOT LOADED"}
}

gui.elements = {
    main_tree = tree_node:new(0),
    main_toggle = create_checkbox("main_toggle"),
    settings_tree = tree_node:new(1),
    melee_logic = create_checkbox("melee_logic"),
    elite_only_toggle = create_checkbox("elite_only"),
    pit_level = input_text:new(get_hash("piteer_pit_level_unique_id")),
    pit_level_slider = slider_int:new(1, 150, 1, 1984),
    loot_toggle = create_checkbox("loot_toggle"),
    loot_modes = combo_box:new(0, get_hash("piteer_loot_modes")),
    path_angle_slider = slider_int:new(0, 360, 10, get_hash("path_angle_slider")), -- 10 is a default value
    reset_time_slider = slider_int:new(60, 900, 600, get_hash("reset_time_slider")), -- New slider for reset time in seconds
    exit_pit_toggle = create_checkbox("exit_pit_toggle"),
    explorer_grid_size_slider = slider_int:new(10, 20, 15, get_hash("explorer_grid_size_slider")),
    gamble_category = {
        ['sorcerer'] = combo_box:new(0, get_hash("piteer_gamble_sorcerer_category")),
        ['barbarian'] = combo_box:new(0, get_hash("piteer_gamble_barbarian_category")),
        ['rogue'] = combo_box:new(0, get_hash("piteer_gamble_rogue_category")),
        ['druid'] = combo_box:new(0, get_hash("piteer_gamble_druid_category")),
        ['necromancer'] = combo_box:new(0, get_hash("piteer_gamble_necromancer_category")),
        ['spiritborn'] = combo_box:new(0, get_hash("piteer_gamble_spiritborn_category")),
        ['default'] = combo_box:new(0, get_hash("piteer_gamble_default_category")),
    },
    greater_affix_slider = slider_int:new(0, 3, 1, get_hash("greater_affix_slider")),
    gamble_toggle = create_checkbox("gamble_toggle"),
    use_alfred = create_checkbox("use_alfred"),
    alfred_return = create_checkbox("aflred_return"),
    upgrade_toggle = create_checkbox("upgrade_toggle"),
    upgrade_mode = combo_box:new(0, get_hash("piteer_upgrade_mode")),
    upgrade_threshold = slider_int:new(10, 100, 50, get_hash("upgrade_threshold")),
    upgrade_legendary_toggle = create_checkbox("upgrade_legendary_toggle"),
    exit_pit_delay = slider_int:new(10, 300, 10, get_hash("exit_pit_delay")),
}

function gui.render()
    if not gui.elements.main_tree:push("Piteer V3.9") then return end
    local class = gui.get_character_class()

    gui.elements.main_toggle:render("Enable", "Enable the bot")

    if gui.elements.settings_tree:push("Settings") then
        --gui.elements.melee_logic:render("Melee", "Do we need to move into Melee?")
        gui.elements.elite_only_toggle:render("Elite Only", "Do we only want to seek out elites in the Pit?")
        gui.elements.pit_level_slider:render("Pit Level", "Which Pit level do you want to enter?")
        --gui.elements.pit_level:render("Level", "Which level do you want to enter?", false, "", "")
        --gui.elements.loot_toggle:render("Enable Looting", "Toggle looting on/off")        
        if PLUGIN_alfred_the_butler then
            local alfred_status = PLUGIN_alfred_the_butler.get_status()
            if alfred_status.enabled then
                gui.elements.use_alfred:render("Use alfred", "use alfred to manage salvage/sell/stash")
            end
        end
        if not PLUGIN_alfred_the_butler or not gui.elements.use_alfred:get() then
            gui.elements.loot_modes:render("Loot Modes", gui.loot_modes_options, "Nothing and Stash will get you stuck for now")
            gui.elements.greater_affix_slider:render("Greater Affix Threshold", "Set the number of greater affixes to salvage (0-3)")
        else
            gui.elements.alfred_return:render("Return for loot", "return to pit to collect floor loot")
        end

        gui.elements.path_angle_slider:render("Path Angle", "Adjust the angle for path filtering (0-360 degrees)")
        gui.elements.explorer_grid_size_slider:render("Explorer Grid Size", "Adjust the grid size for exploration (1.0-2.0)")

        gui.elements.reset_time_slider:render("Reset Time (seconds)", "Set the time in seconds for resetting all dungeons")
        gui.elements.exit_pit_toggle:render("Enable Exit Pit", "Toggle Exit Pit task on/off")
        if gui.elements.exit_pit_toggle:get() then
            gui.elements.exit_pit_delay:render("Exit delay", "time in seconds to wait before ending pit")
        end
        gui.elements.gamble_category[class]:render("Gamble Category", gui.gamble_categories[class], "Select the item category to gamble")
        gui.elements.gamble_toggle:render("Enable Gambling", "Toggle gambling on/off")
        gui.elements.upgrade_toggle:render("Enable Glyph Upgrade", "Toggle glyph upgrade on/off")
        if gui.elements.upgrade_toggle:get() then
            gui.elements.upgrade_mode:render("Upgrade mode", gui.upgrade_mode, "Select how to upgrade glyphs")
            gui.elements.upgrade_threshold:render("Upgrade threshold", "only upgrade glyph if the %% chance is greater or equal to upgrade threshold")
            gui.elements.upgrade_legendary_toggle:render("Upgrade to legendary glyph", "Disable this to save gem fragments")
        end
        gui.elements.settings_tree:pop()
    end

    gui.elements.main_tree:pop()
end

return gui
