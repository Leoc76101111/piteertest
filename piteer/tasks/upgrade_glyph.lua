local plugin_label = 'piteer' -- change to your plugin name

local utils = require "core.utils"
local explorerlite = require "core.explorerlite"
local settings = require 'core.settings'
local tracker = require "core.tracker"
local gui = require "gui"

local upgrade_state = {
    INIT = "INIT",
    TELEPORTING = "TELEPORTING",
    MOVING_TO_NPC = "MOVING_TO_NPC",
    INTERACTING_WITH_NPC = "INTERACTING_WITH_NPC",
    UPGRADING_GLYPH = "UPGRADING_GLYPH",
    FINISHED = "FINISHED",
}

local blacklist = {}
local last_attempted_glyph = nil
local failed_count = 0

local task = {
    name = 'Upgrade Glyph', -- change to your choice of task name
    current_state = upgrade_state.INIT,
    last_interaction_time = nil,
}

local function get_npc()
    local actors = actors_manager:get_all_actors()
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name == "Gizmo_Paragon_Glyph_Upgrade" then
            -- console.print("Glyph upgrade location found: " .. name)
            return actor
        end
    end
    --console.print("No NPC found")
    return nil
end

local function init_upgrade()
    task.current_state = upgrade_state.MOVING_TO_NPC
    blacklist = {}
    failed_count = 0
end
local function move_to_npc()
    local npc = get_npc()
    if npc then
        explorerlite:set_custom_target(npc:get_position())
        explorerlite:move_to_target()
        if utils.distance_to(npc) < 2 then
            -- console.print("Reached npc")
            task.current_state = upgrade_state.INTERACTING_WITH_NPC
        end
    end
end

local function interact_npc()
    local npc = get_npc()
    if npc then
        local current_time = get_time_since_inject()
        interact_vendor(npc)
        if task.last_interaction_time == nil then
            task.last_interaction_time = get_time_since_inject()
        end
        if current_time - task.last_interaction_time >= 2 then
            task.current_state = upgrade_state.UPGRADING_GLYPH
        end
    end
end

local function should_upgrade(glyph)
    if last_attempted_glyph ~= nil and
        last_attempted_glyph.glyph_name_hash == glyph.glyph_name_hash and
        last_attempted_glyph:get_level() == glyph:get_level()
    then
        if failed_count < 10 then
            failed_count = failed_count + 1
        else
            blacklist[glyph.glyph_name_hash] = true
            failed_count = 0
        end
    else
        failed_count = 0
    end
    -- rounding upgrade chance to the nearest %
    local upgrade_chance = math.floor((glyph:get_upgrade_chance() + 0.005) * 100)
    if glyph:can_upgrade() and
        upgrade_chance >= settings.upgrade_threshold and
        (settings.upgrade_legendary_toggle or glyph:get_level() ~= 45) and
        blacklist[glyph.glyph_name_hash] == nil
    then
        return true
    end
    return false
end

local function npc_glyph_upgrade()
    local current_time = get_time_since_inject()
    if current_time - task.last_interaction_time >= 2 then
        local glyphs = get_glyphs()
        if settings.upgrade_mode == gui.upgrade_modes_enum.HIGHEST then
            -- the order is already in highest to lowest
            for i = 1, glyphs:size() do
                local current_glyph = glyphs:get(i)
                if should_upgrade(current_glyph) then
                    console.print('Upgrading ' .. tostring(current_glyph.glyph_name_hash))
                    last_attempted_glyph = current_glyph
                    upgrade_glyph(current_glyph)
                    task.last_interaction_time = get_time_since_inject()
                    return
                end
            end
        elseif settings.upgrade_mode == gui.upgrade_modes_enum.LOWEST then
            local lowest_glyph = nil
            for i = 1, glyphs:size() do
                local current_glyph = glyphs:get(i)
                if should_upgrade(current_glyph) and
                    (lowest_glyph == nil or lowest_glyph:get_level() >= current_glyph:get_level())
                then
                    lowest_glyph = current_glyph
                end
            end
            if lowest_glyph ~= nil then
                console.print('Upgrading ' .. tostring(lowest_glyph.glyph_name_hash))
                last_attempted_glyph = lowest_glyph
                upgrade_glyph(lowest_glyph)
                task.last_interaction_time = get_time_since_inject()
                return
            end
        end
        -- nothing to upgrade 
        task.current_state = upgrade_state.FINISHED
    end
end

local function finish_upgrade()
    task.current_state = upgrade_state.INIT
    tracker:set_boss_task_running(false)
    blacklist = {}
    failed_count = 0
end

function task.shouldExecute()
    if not settings.upgrade_toggle then return false end
    local npc = get_npc()
    if npc then
        tracker:set_boss_task_running(true)
        local glyphs = get_glyphs()
        for i = 1, glyphs:size() do
            if glyphs:get(i):can_upgrade() then return true end
        end
        return not (glyphs:size() > 0 and task.current_state == upgrade_state.INIT)
    end
    return false
end

function task.Execute()
    local npc = get_npc()
    if task.current_state == upgrade_state.INIT then
        init_upgrade()
    elseif npc and utils.distance_to(npc) > 2 and task.current_state ~= upgrade_state.MOVING_TO_NPC then
        init_upgrade()
    elseif task.current_state == upgrade_state.MOVING_TO_NPC then
        move_to_npc()
    elseif task.current_state == upgrade_state.INTERACTING_WITH_NPC then
        interact_npc()
    elseif task.current_state == upgrade_state.UPGRADING_GLYPH then
        npc_glyph_upgrade()
    elseif task.current_state == upgrade_state.FINISHED then
        finish_upgrade()
    end
end

return task