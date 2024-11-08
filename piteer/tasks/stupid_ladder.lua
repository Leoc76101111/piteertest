local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"
local tracker = require "core.tracker"

local function vec3_to_string(vec)
    if vec then
        return string.format("(%.2f, %.2f, %.2f)", vec:x(), vec:y(), vec:z())
    else
        return "nil"
    end
end

local function find_traversal_actor()
    local actors = actors_manager:get_all_actors()
    local player_pos = get_player_position()
    for _, actor in pairs(actors) do
        local name = actor:get_skin_name()
        if name:match("[Tt]raversal") then
            local actor_pos = actor:get_position()
            if math.abs(actor_pos:z() - player_pos:z()) <= 5 then
                return actor
            end
        end
    end
    return nil
end

local function find_nearest_walkable_position(pos, radius)
    local nearest_pos = nil
    local nearest_dist = math.huge
    local player_pos = get_player_position()

    for x = -radius, radius, 0.5 do
        for y = -radius, radius, 0.5 do
            local test_pos = vec3:new(
                pos:x() + x,
                pos:y() + y,
                pos:z()
            )
            test_pos = utility.set_height_of_valid_position(test_pos)
            
            if utility.is_point_walkeable(test_pos) then
                local dist = test_pos:dist_to_ignore_z(pos)
                if dist < nearest_dist then
                    nearest_dist = dist
                    nearest_pos = test_pos
                end
            end
        end
    end
    
    return nearest_pos
end

local task = {
    name = "Stupid Ladder",
    shouldExecute = function()
        local traversal_actor = find_traversal_actor()
        if traversal_actor ~= nil then
            -- console.print("Traversal actor found: " .. traversal_actor:get_skin_name())
            return not tracker.traversal_controller_reached
        end
        return false
    end,
    Execute = function()
        -- console.print("Executing Stupid Ladder task")
        explorer.current_task = "Stupid Ladder"
        explorer.is_task_running = false
        explorer:clear_path_and_target()

        local traversal_actor = find_traversal_actor()
        if not traversal_actor then
            -- console.print("Error: Traversal actor not found")
            explorer.current_task = nil
            explorer.is_task_running = false
            return
        end

        local actor_pos = traversal_actor:get_position()
        local player_pos = get_player_position()
        local distance = utils.distance_to(actor_pos)
        
        -- console.print("Actor position: " .. vec3_to_string(actor_pos))
        -- console.print("Distance to actor: " .. tostring(distance))

        if distance < 2 then
            pathfinder.force_move_raw(actor_pos)
            -- console.print("Close to traversal actor. Using actual Z height.")
        else
            local target_pos = vec3:new(actor_pos:x(), actor_pos:y(), player_pos:z())
            
            if not utility.is_point_walkeable(target_pos) then
                -- console.print("Target position not walkable, finding nearest walkable position...")
                local walkable_pos = find_nearest_walkable_position(target_pos, 5)
                if walkable_pos then
                    target_pos = walkable_pos
                    -- console.print("Found walkable position: " .. vec3_to_string(walkable_pos))
                else
                    -- console.print("Warning: Could not find walkable position near target")
                end
            end
            
            -- console.print("Far from actor. Using explorer pathing.")
            explorer:clear_path_and_target()
            explorer:set_custom_target(target_pos)
            explorer:move_to_target()
        end

        if distance < 1 then
            -- console.print("Within interaction range. Interacting...")
            interact_object(traversal_actor)
            tracker.traversal_controller_reached = true
        end

        explorer.current_task = nil
        explorer.is_task_running = false
    end
}

return task
