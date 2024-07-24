local settings = require "core.settings"
local task_manager = {}
local tasks = {}
local current_task = nil
local finished_time = 0

function task_manager.set_finished_time(time)
    finished_time = time
end

function task_manager.get_finished_time()
    return finished_time
end

function task_manager.register_task(task)
    table.insert(tasks, task)
end

local last_call_time = 0.0
local last_check_time = 0.0
local check_interval = 0.01 -- seconds

local function shouldCheckTask()
    local current_time = os.time()
    if current_time - last_check_time >= check_interval then
        last_check_time = current_time
        return true
    end
    return false
end

function task_manager.execute_tasks()
    local auto_play_objective = auto_play.get_objective()
    local should_sell = auto_play_objective == objective.sell
    if should_sell then
        local loot_modes_enum = {
            NOTHING = 0,
            SELL = 1,
            SALVAGE = 2,
            STASH = 3,
        }

        if settings.loot_modes == loot_modes_enum.SALVAGE then
            auto_play.salvage_routine()
        end

        if settings.loot_modes == loot_modes_enum.SELL then
            auto_play.sell_routine()
        end

        return -- stop code here
    end

    local should_repair = auto_play_objective == objective.repair
    if should_repair then
        local world = world.get_current_world()
        if world then
            local world_name = world:get_name()
            if world_name:match("Sanctuary") then
                auto_play.repair_routine()
                return
            end
        end
    end

    local current_core_time = get_time_since_inject()
    if current_core_time - last_call_time < 0.2 then
        return -- quick ej slide frames
    end

    -- last_call_time = current_core_time

    if shouldCheckTask() then
        for _, task in ipairs(tasks) do
            if task.shouldExecute() then
                current_task = task
                task.Execute()
                break -- Execute only one task per pulse
            end
        end
    end

    if not current_task then
        current_task = { name = "Idle" } -- Default state when no task is active
    end
end

function task_manager.get_current_task()
    return current_task or { name = "Idle" }
end

local task_files = { "kill_monsters", "enter_portal", "explore_pit", "open_pit", "finish_pit", "exit_pit" }
for _, file in ipairs(task_files) do
    local task = require("tasks." .. file)
    task_manager.register_task(task)
end

return task_manager