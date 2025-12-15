local utils = require "core.utils"
local enums = require "data.enums"
local explorerlite = require "core.explorerlite"
local settings = require "core.settings"
local tracker = require "core.tracker"
local gui = require "gui"

local town_stash = {
    name = "Town Stash",
    current_state = "INIT",
    last_stash_interaction_time = 0,
    last_stash_check_time = 0,
    max_retries = 50,
    current_retries = 0,
    vendor_open_time = nil,
    last_stash_move_time = nil,
    is_running = true,
    next_run_time = 0,
}

function town_stash.check_inventory_has_items()
    local local_player = get_local_player()
    if not local_player then 
        console.print("No local player found")
        return false 
    end

    local qualifying_items = 0
    local inventory_items = local_player:get_inventory_items()
    
    for _, inventory_item in pairs(inventory_items) do
        if inventory_item and not inventory_item:is_locked() then
            local display_name = inventory_item:get_display_name()
            local item_id = inventory_item:get_sno_id()
            local greater_affix_count = utils.get_greater_affix_count(display_name)
            local is_uber = utils.is_uber_item(item_id)

            if is_uber or greater_affix_count >= settings.greater_affix_threshold then
                qualifying_items = qualifying_items + 1
            end
        end
    end

    return qualifying_items > 0
end

function town_stash.stash_items()
    local local_player = get_local_player()
    if not local_player then 
        console.print("No local player found")
        return 
    end

    local inventory_items = local_player:get_inventory_items()
    for _, inventory_item in pairs(inventory_items) do
        if inventory_item and not inventory_item:is_locked() then
            local display_name = inventory_item:get_display_name()
            local item_id = inventory_item:get_sno_id()
            local greater_affix_count = utils.get_greater_affix_count(display_name)
            local is_uber = utils.is_uber_item(item_id)

            if is_uber or greater_affix_count >= settings.greater_affix_threshold then
                console.print("Moving item to stash: " .. display_name .. 
                    (is_uber and " (Uber Item)" or " (Greater Affixes: " .. greater_affix_count .. ")"))
                loot_manager.move_item_to_stash(inventory_item)
                return
            end
        end
    end
end

function town_stash.shouldExecute()
    if settings.use_alfred and PLUGIN_alfred_the_butler then return false end
    return utils.player_in_zone("Scos_Cerrigar") 
        and town_stash.check_inventory_has_items()
        and settings.loot_modes == gui.loot_modes_enum.STASH
end

function town_stash.Execute()
    local current_time = get_time_since_inject()
    
    -- Check if we're still in cooldown
    if current_time < town_stash.next_run_time then
        console.print(string.format("Stash on cooldown for %.1f more seconds", 
            town_stash.next_run_time - current_time))
        return
    end

    console.print("Executing Town Stash Task")
    local stash = utils.get_stash()
    
    if not stash then
        console.print("No stash found")
        explorerlite:set_custom_target(enums.positions.stash_position)
        explorerlite:move_to_target()
        return
    end

    explorerlite:set_custom_target(stash:get_position())
    explorerlite:move_to_target()

    if utils.distance_to(stash) < 2 then
        interact_vendor(stash)
        town_stash.stash_items()
        town_stash.next_run_time = current_time + 0.5
    end
end

return town_stash