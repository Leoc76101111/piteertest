local utils = require "core.utils"
local enums = require "data.enums"
local explorer = require "core.explorer"
local tracker = require "core.tracker"

local interaction_time = 0

local function vec3_to_string(vec)
    if vec then
        return string.format("(%.2f, %.2f, %.2f)", vec:x(), vec:y(), vec:z())
    else
        return "nil"
    end
end

local task = {
    name = "Stupid Ladder",
    shouldExecute = function()
        local traversal_controller = utils.get_object_by_name(enums.misc.traversal_controller)
        local should_execute = traversal_controller ~= nil and not tracker.traversal_controller_reached
        --console.print("Stupid Ladder should execute: " .. tostring(should_execute))
        return should_execute
    end,
    Execute = function()
        console.print("Executing Stupid Ladder task")
        explorer.current_task = "Stupid Ladder"
        explorer.is_task_running = true
        explorer:clear_path_and_target()

        local traversal_controller = utils.get_closest_object_by_name(enums.misc.traversal_controller)
        
        if traversal_controller then
            local controller_pos = traversal_controller:get_position()
            console.print("Controller position: " .. vec3_to_string(controller_pos))
            
            local target_pos = vec3:new(controller_pos:x(), controller_pos:y(), 0)
            console.print("Updated controller position: " .. vec3_to_string(target_pos))

            local distance = utils.distance_to(target_pos)
            console.print("Distance to controller: " .. tostring(distance))

            if distance < 3 then
                console.print("Close to traversal controller. Interacting...")
                interact_object(traversal_controller)
                tracker.traversal_controller_reached = true
            else
                pathfinder.force_move_raw(target_pos)
                return
            end
        else
            console.print("Error: Traversal controller not found")
        end

        explorer.current_task = nil
        explorer.is_task_running = false
    end
}

return task
