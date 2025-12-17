local plugin_label = 'piteer' -- change to your plugin name

local utils = require "core.utils"
local enums = require "data.enums"
local explorerlite = require "core.explorerlite"
local settings = require 'core.settings'
local tracker = require "core.tracker"
local gui = require "gui"

local function get_plugin_root_path()
    local plugin_root = string.gmatch(package.path, '.*?\\?')()
    plugin_root = plugin_root:gsub('?','')
    return plugin_root
end

local function get_filename()
    local filename = get_plugin_root_path()
    filename = filename .. 'data\\d4assistant\\timestamp.txt'
    return filename
end

local task = {
    name = 'D4 Assistant Trigger' -- change to your choice of task name
}

function task.shouldExecute()
    local npc = utils.get_object_by_name(enums.misc.gizmo_paragon_glyph_upgrade)
    if npc then
        local filename = get_filename()
        local file, err = io.open(filename,'r')
        if not file then
            return true
        end
        io.input(file)
        local data = io.read("*a")
        local timestamp = tonumber(data)
        io.close(file)
        if type(timestamp) ~= "number" or timestamp + 60 < tonumber(os.time(os.date('!*t'))) then
            console.print(timestamp)
            return true
        end
    end
    return false
end

function task.Execute()
    local filename = get_filename()
    local file, err = io.open(filename,'w')
    if not file then
        return
    end
    io.output(file)
    io.write(os.time(os.date('!*t')))
    io.close(file)
end

return task