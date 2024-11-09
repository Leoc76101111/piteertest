local utils = require "core.utils"
local enums = require "data.enums"

local function is_loading_or_limbo()
    local current_world = world.get_current_world()
    if not current_world then
        return true
    end
    local world_name = current_world:get_name()
    return world_name:find("Limbo") ~= nil or world_name:find("Loading") ~= nil
end

local move_to_cerrigar = {
    name = "Move to Cerrigar",
}

-- Task should execute function (without self)
function move_to_cerrigar.shouldExecute()
    return not (utils.player_in_zone("Scos_Cerrigar") or utils.player_in_zone("EGD_MSWK_World_02") or utils.player_in_zone("EGD_MSWK_World_01")) and not is_loading_or_limbo()
end

-- Task execute function (without self)
function move_to_cerrigar.Execute()
    console.print("Executing Move to Cerrigar task")
    -- Teleport to the Cerrigar waypoint
    teleport_to_waypoint(enums.waypoints.CERRIGAR)
end

return move_to_cerrigar