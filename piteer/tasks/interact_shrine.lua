local plugin_label = 'piteer' -- change to your plugin name

local utils = require "core.utils"
local settings = require 'core.settings'
local enums = require "data.enums"
local explorer = require "core.explorer"

local status_enum = {
    INIT = "INIT",
    MOVING_TO_NPC = "MOVING_TO_NPC",
    INTERACTING_WITH_NPC = "INTERACTING_WITH_NPC"
}
local task = {
    name = 'interact_shrine', -- change to your choice of task name
    status = status_enum.INIT
}
local function getInteractableShrine()
    local actors = actors_manager:get_ally_actors()
    for _, actor in pairs(actors) do
        if actor:is_interactable() then
            local actor_name = actor:get_skin_name()
            for _,shrine_name in pairs(enums.shrines) do
                if actor_name == shrine_name then
                    return actor
                end
            end
        end
    end
    return nil
end
local function init_interact()
    task.current_state = status_enum.MOVING_TO_NPC
end

local function move_to_npc(npc)
    if npc then
        explorer:set_custom_target(npc:get_position())
        explorer:move_to_target()
        if utils.distance_to(npc) < 2 then
            -- console.print("Reached npc")
            task.current_state = status_enum.INTERACTING_WITH_NPC
        end
    end
end
local function interact_npc(npc)
    if npc then
        interact_object(npc)
        task.current_state = status_enum.INIT
    end
end

function task.shouldExecute()
    local local_player = get_local_player();
    local is_player_in_pit = (utils.player_in_zone("EGD_MSWK_World_02") or utils.player_in_zone("EGD_MSWK_World_01"))
    if settings.interact_shrine and is_player_in_pit and local_player then
        return getInteractableShrine() ~= nil
    end
    return false
end

function task.Execute()
    local npc = getInteractableShrine()
    if task.current_state == status_enum.INIT then
        init_interact()
    elseif npc and utils.distance_to(npc) > 2 and task.current_state ~= status_enum.MOVING_TO_NPC then
        init_interact()
    elseif task.current_state == status_enum.MOVING_TO_NPC then
        move_to_npc(npc)
    elseif task.current_state == status_enum.INTERACTING_WITH_NPC then
        interact_npc(npc)
    end
end

return task