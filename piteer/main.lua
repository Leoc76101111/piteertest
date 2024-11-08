-- if true then return end

local gui          = require "gui"
local task_manager = require "core.task_manager"
local settings     = require "core.settings"

local local_player, player_position

local function update_locals()
    local_player = get_local_player()
    player_position = local_player and local_player:get_position()
end

local function main_pulse()
    settings:update_settings()
    if not local_player or not settings.enabled then return end
    if orbwalker.get_orb_mode() ~= 3 then
        orbwalker.set_clear_toggle(true);
        orbwalker.set_block_movement(true);
    end
    task_manager.execute_tasks()
end

local function render_pulse()
    if not local_player or not settings.enabled then return end
    local current_task = task_manager.get_current_task()
    if current_task then
        local px, py, pz = player_position:x(), player_position:y(), player_position:z()
        local draw_pos = vec3:new(px, py - 2, pz + 3)
        graphics.text_3d("Current Task: " .. current_task.name, draw_pos, 14, color_white(255))
    end
end

-- Set Global access for other plugins
PitPlugin = {
    enable = function ()
        gui.elements.main_toggle:set(true)
    end,
    disable = function ()
        gui.elements.main_toggle:set(false)
    end,
}

on_update(function()
    update_locals()
    main_pulse()
end)

on_render_menu(gui.render)
on_render(render_pulse)
