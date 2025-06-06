local MinHeap = {}
MinHeap.__index = MinHeap

function MinHeap.new(compare)
    --console.print("Creating new MinHeap.")
    return setmetatable({heap = {}, compare = compare or function(a, b) return a < b end}, MinHeap)
end

function MinHeap:push(value)
    --console.print("Pushing value into MinHeap.")
    table.insert(self.heap, value)
    self:siftUp(#self.heap)
end

function MinHeap:pop()
    --console.print("Popping value from MinHeap.")
    local root = self.heap[1]
    self.heap[1] = self.heap[#self.heap]
    table.remove(self.heap)
    self:siftDown(1)
    return root
end

function MinHeap:peek()
    --console.print("Peeking value from MinHeap.")
    return self.heap[1]
end

function MinHeap:empty()
    --console.print("Checking if MinHeap is empty.")
    return #self.heap == 0
end

function MinHeap:siftUp(index)
    --console.print("Sifting up in MinHeap.")
    local parent = math.floor(index / 2)
    while index > 1 and self.compare(self.heap[index], self.heap[parent]) do
        self.heap[index], self.heap[parent] = self.heap[parent], self.heap[index]
        index = parent
        parent = math.floor(index / 2)
    end
end

function MinHeap:siftDown(index)
    --console.print("Sifting down in MinHeap.")
    local size = #self.heap
    while true do
        local smallest = index
        local left = 2 * index
        local right = 2 * index + 1
        if left <= size and self.compare(self.heap[left], self.heap[smallest]) then
            smallest = left
        end
        if right <= size and self.compare(self.heap[right], self.heap[smallest]) then
            smallest = right
        end
        if smallest == index then break end
        self.heap[index], self.heap[smallest] = self.heap[smallest], self.heap[index]
        index = smallest
    end
end

function MinHeap:contains(value)
    --console.print("Checking if MinHeap contains value.")
    for _, v in ipairs(self.heap) do
        if v == value then return true end
    end
    return false
end

local utils = require "core.utils"
local enums = require "data.enums"
local settings = require "core.settings"
local tracker = require "core.tracker"
local gui = require "gui"

-- Add this function near the top with other utility functions
local function get_grid_size()
    return gui.elements.explorer_grid_size_slider:get() / 10
end

local explorer = {
    enabled = false,
    is_task_running = false, --added to prevent boss dead pathing 
    start_location_reached = false  -- New flag
}
local explored_areas = {}
local target_position = nil
local exploration_radius = 16
local explored_buffer = 2
local max_target_distance = 60
local target_distance_states = {60, 90, 100, 125}
local target_distance_index = 1
local unstuck_target_distance = 15 -- Maximum distance for an unstuck target
local stuck_threshold = 4      -- Seconds before the character is considered "stuck"
local last_position = nil
local last_move_time = 0
local last_explored_targets = {}
local max_last_targets = 50

-- Replace the rectangular explored_area_bounds with a table of explored circles
local explored_circles = {}

-- Add these new variables at the top of the file
local last_circle_position = nil
local last_circle_time = 0
local min_distance_between_circles = 0.5  -- Distance in units
local min_time_between_circles = 0.5  -- Minimum time in seconds between circle creations

-- Function to check and print pit start time and time spent in pitre
local function check_pit_time()
    --console.print("Checking pit start time...")  -- Add this line for debugging
    if tracker.pit_start_time > 0 then
        local time_spent_in_pit = get_time_since_inject() - tracker.pit_start_time
    else
        --console.print("Pit start time is not set or is zero.")  -- Add this line for debugging
    end
end

local function check_and_reset_dungeons()
    --console.print("Executing check_and_reset_dungeons") -- Debug print
    if tracker.pit_start_time > 0 then
        local time_spent_in_pit = get_time_since_inject() - tracker.pit_start_time
        local reset_time_threshold = settings.reset_time
        if time_spent_in_pit > reset_time_threshold then
            console.print("Time spent in pit is greater than " .. reset_time_threshold .. " seconds. Resetting all dungeons.")
            reset_all_dungeons()
        end
    end
end

-- A* pathfinding variables
local current_path = {}
local path_index = 1

-- Explorationsmodus
local exploration_mode = "unexplored" -- "unexplored" oder "explored"

-- Richtung für den "explored" Modus
local exploration_direction = { x = 10, y = 0 } -- Initiale Richtung (kann angepasst werden)

-- Neue Variable für die letzte Bewegungsrichtung
local last_movement_direction = nil

--ai fix for kill monsters path
function explorer:clear_path_and_target()
    --console.print("Clearing path and target.")
    target_position = nil
    current_path = {}
    path_index = 1
end

-- Replace/update the calculate_distance function
local function calculate_distance(pos1, pos2)
    -- Case 1: pos2 is a game object with get_position method
    if type(pos2.get_position) == "function" then
        return pos1:dist_to_ignore_z(pos2:get_position())
    end
    
    -- Case 2: pos2 is a vector object
    if type(pos2.x) == "function" then
        return pos1:dist_to_ignore_z(pos2)
    end
    
    -- Case 3: pos2 is our stored position table
    if type(pos2.x) == "number" then
        return pos1:dist_to_ignore_z(vec3:new(pos2.x, pos2.y, pos2.z))
    end
    
    -- If we get here, we don't know how to handle the input
    console.print("Warning: Unknown position type in calculate_distance")
    return 0
end

--ai fix for start location spamming 
function explorer:check_start_location_reached()
    if not tracker.start_location_reached then
        local start_location = utils.get_start_location_0()
        if start_location then
            local player_pos = get_player_position()
            local start_pos = start_location:get_position()
            local middle_start_pos = vec3:new(
                start_pos:x() - 10,
                start_pos:y() - 10 ,
                start_pos:z()
            )

            if calculate_distance(player_pos, middle_start_pos) < 0.1 then  -- Adjust this distance as needed
                tracker.start_location_reached = true
                console.print("Start location reached")
            end
        end
    end
end

-- Add this variable near the top with other state variables
local last_start_location_check = 0

function explorer:set_start_location_target()
    local current_time = get_time_since_inject()
    
    -- Only check every 5 seconds
    if current_time - last_start_location_check < 0.5 then
        return false
    end
    
    last_start_location_check = current_time

    if self.is_task_running or self.current_task == "Kill Monsters" or tracker.start_location_reached then
        return false
    end

    local start_location = utils.get_start_location_0()
    if start_location then
        local middle_start_location = vec3:new(
            start_location:get_position():x() - 10,
            start_location:get_position():y() - 10,
            start_location:get_position():z()
        )
        console.print("Setting target to start location: " .. start_location:get_skin_name())
        self:set_custom_target(middle_start_location)
        return true
    else
        return false
    end
end

--ai fix for stairs
local function set_height_of_valid_position(point)
    --console.print("Setting height of valid position.")
    return utility.set_height_of_valid_position(point)
end

local function get_grid_key(point)
    return math.floor(point:x() / get_grid_size()) .. "," ..
           math.floor(point:y() / get_grid_size()) .. "," ..
           math.floor(point:z() / get_grid_size())
end

-- Update the mark_area_as_explored function
local function mark_area_as_explored(center, radius)
    console.print(string.format("Checking if area can be marked as explored: Center (%.2f, %.2f, %.2f), Radius: %.2f", center:x(), center:y(), center:z(), radius))
    
    -- Check distance from existing circles
    for _, circle in ipairs(explored_circles) do
        local distance = calculate_distance(center, circle.center)
        if distance < 8 then
            console.print("Area too close to existing explored circle. Skipping.")
            return
        end
    end
    
    -- If we've reached here, the new circle is at least 5 units away from all existing circles
    table.insert(explored_circles, {center = center, radius = radius, visited = false, targeted = false})
    console.print(string.format("Area marked as explored. Total explored circles: %d", #explored_circles))
end

-- Update the is_point_in_explored_area function
local function is_point_in_explored_area(point)
    --console.print(string.format("Checking if point (%.2f, %.2f, %.2f) is in explored area", point:x(), point:y(), point:z()))
    for _, circle in ipairs(explored_circles) do
        local distance = calculate_distance(point, circle.center)
        if distance <= circle.radius then
            --console.print("Point is in explored area")
            return true
        end
    end
    --console.print("Point is not in explored area")
    return false
end

-- Add a new function to find the nearest unexplored point
local function find_nearest_unexplored_point(start_point, max_distance)
    local player_pos = get_player_position()
    local check_radius = max_distance or max_target_distance
    local nearest_point = nil
    local nearest_distance = math.huge

    for x = -check_radius, check_radius, get_grid_size() do
        for y = -check_radius, check_radius, get_grid_size() do
            local point = vec3:new(
                start_point:x() + x,
                start_point:y() + y,
                start_point:z()
            )
            point = set_height_of_valid_position(point)

            if utility.is_point_walkeable(point) and not is_point_in_explored_area(point) then
                local distance = calculate_distance(player_pos, point)
                if distance < nearest_distance then
                    nearest_point = point
                    nearest_distance = distance
                end
            end
        end
    end

    return nearest_point
end

local function check_walkable_area()
    --console.print("Checking walkable area")
    if os.time() % 5 ~= 0 then return end  -- Only run every 5 seconds

    local player_pos = get_player_position()
    local check_radius = 5 -- Überprüfungsradius in Metern

    console.print(string.format("Player position: (%.2f, %.2f, %.2f)", player_pos:x(), player_pos:y(), player_pos:z()))
    mark_area_as_explored(player_pos, exploration_radius)

    for x = -check_radius, check_radius, get_grid_size() do
        for y = -check_radius, check_radius, get_grid_size() do
            for z = -check_radius, check_radius, get_grid_size() do -- Inclui z no loop
                local point = vec3:new(
                    player_pos:x() + x,
                    player_pos:y() + y,
                    player_pos:z() + z
                )
                print("Checking point:", point:x(), point:y(), point:z()) -- Debug print
                point = set_height_of_valid_position(point)

                if utility.is_point_walkeable(point) then
                    if is_point_in_explored_area(point) then
                        --graphics.text_3d("Explored", point, 15, color_white(128))
                    else
                        --graphics.text_3d("unexplored", point, 15, color_green(255))
                    end
                end
            end
        end
    end
end

-- Update the find_distant_explored_circle function
local function find_distant_explored_circle()
    console.print("Finding distant explored circle")
    local player_pos = get_player_position()
    local valid_circles = {}
    
    for i, circle in ipairs(explored_circles) do
        if not circle.visited and not circle.targeted then
            local distance = calculate_distance(player_pos, circle.center)
            if distance >= 10 and distance <= 50 then
                table.insert(valid_circles, {circle = circle, distance = distance, index = i})
            end
        end
    end
    
    if #valid_circles > 0 then
        table.sort(valid_circles, function(a, b) return a.distance > b.distance end)
        local selected_circle = valid_circles[1].circle
        selected_circle.targeted = true
        console.print(string.format("Selected circle #%d at (%.2f, %.2f, %.2f), distance: %.2f",
            valid_circles[1].index, selected_circle.center:x(), selected_circle.center:y(), selected_circle.center:z(), valid_circles[1].distance))
        return selected_circle
    end

    console.print("No valid circles found, resetting exploration")
    explorer.reset_exploration()
    return nil
end

-- Update the find_explored_direction_target function
local function find_explored_direction_target()
    console.print("Finding explored direction target")
    local player_pos = get_player_position()
    
    -- First, try to find an unexplored point near the player
    local nearby_unexplored = find_nearest_unexplored_point(player_pos, exploration_radius * 2)
    if nearby_unexplored then
        console.print("Found nearby unexplored point. Switching to unexplored mode.")
        exploration_mode = "unexplored"
        return nearby_unexplored
    end
    
    -- If no nearby unexplored point, find a distant explored circle
    local distant_circle = find_distant_explored_circle()
    if distant_circle then
        console.print("Moving towards the center of a distant explored circle")
        return distant_circle.center
    end
    
    console.print("No valid explored targets found. Resetting exploration.")
    explorer.reset_exploration()
    return nil
end

-- Update the reset_exploration function
function explorer.reset_exploration()
    console.print("Resetting exploration")
    for _, circle in ipairs(explored_circles) do
        circle.visited = false
        circle.targeted = false
    end
    explorer.clear_explored_circles()
    last_position = nil
    last_move_time = 0
    current_path = {}
    path_index = 1
    exploration_mode = "unexplored"
    last_movement_direction = nil

    console.print("Exploration reset. All areas marked as unexplored.")
end

local function is_near_wall(point)
    --console.print("Checking if point is near wall.")
    local wall_check_distance = 2 -- Abstand zur Überprüfung von Wänden
    local directions = {
        { x = 1, y = 0 }, { x = -1, y = 0 }, { x = 0, y = 1 }, { x = 0, y = -1 },
        { x = 1, y = 1 }, { x = 1, y = -1 }, { x = -1, y = 1 }, { x = -1, y = -1 }
    }

    for _, dir in ipairs(directions) do
        local check_point = vec3:new(
            point:x() + dir.x * wall_check_distance,
            point:y() + dir.y * wall_check_distance,
            point:z()
        )
        check_point = set_height_of_valid_position(check_point)
        if not utility.is_point_walkeable(check_point) then
            return true
        end
    end
    return false
end

local function find_central_unexplored_target()
    --console.print("Finding central unexplored target.")
    local player_pos = get_player_position()
    local check_radius = max_target_distance
    local unexplored_points = {}

    -- Collect unexplored points
    for x = -check_radius, check_radius, get_grid_size() do
        for y = -check_radius, check_radius, get_grid_size() do
            local point = vec3:new(
                player_pos:x() + x,
                player_pos:y() + y,
                player_pos:z()
            )

            point = set_height_of_valid_position(point)

            if utility.is_point_walkeable(point) and not is_point_in_explored_area(point) then
                table.insert(unexplored_points, point)
            end
        end
    end

    if #unexplored_points == 0 then
        return nil
    end

    -- Use a grid-based clustering approach
    local grid = {}
    for _, point in ipairs(unexplored_points) do
        local grid_key = get_grid_key(point)
        if not grid[grid_key] then
            grid[grid_key] = { points = {}, count = 0 }
        end
        table.insert(grid[grid_key].points, point)
        grid[grid_key].count = grid[grid_key].count + 1
    end

    -- Find the grid cell with the most unexplored points
    local largest_cluster = nil
    local max_count = 0
    for _, cell in pairs(grid) do
        if cell.count > max_count then
            largest_cluster = cell.points
            max_count = cell.count
        end
    end

    if not largest_cluster then
        return nil
    end

    -- Calculate the center of the largest cluster
    local sum_x, sum_y = 0, 0
    for _, point in ipairs(largest_cluster) do
        sum_x = sum_x + point:x()
        sum_y = sum_y + point:y()
    end
    local center_x = sum_x / #largest_cluster
    local center_y = sum_y / #largest_cluster
    local center = vec3:new(center_x, center_y, player_pos:z())
    center = set_height_of_valid_position(center)

    -- Sort points in the largest cluster by distance to the center
    table.sort(largest_cluster, function(a, b)
        return calculate_distance(a, center) < calculate_distance(b, center)
    end)

    return largest_cluster[1]
end

local function find_random_explored_target()
    --console.print("Finding random explored target.")
    local player_pos = get_player_position()
    local check_radius = max_target_distance
    local explored_points = {}

    for x = -check_radius, check_radius, get_grid_size() do
        for y = -check_radius, check_radius, get_grid_size() do
            local point = vec3:new(
                player_pos:x() + x,
                player_pos:y() + y,
                player_pos:z()
            )
            point = set_height_of_valid_position(point)
            local grid_key = get_grid_key(point)
            if utility.is_point_walkeable(point) and explored_areas[grid_key] and not is_near_wall(point) then
                table.insert(explored_points, point)
            end
        end
    end

    if #explored_points == 0 then   
        return nil
    end

    return explored_points[math.random(#explored_points)]
end

function vec3.__add(v1, v2)
    --console.print("Adding two vectors.")
    return vec3:new(v1:x() + v2:x(), v1:y() + v2:y(), v1:z() + v2:z())
end

local function is_in_last_targets(point)
    --console.print("Checking if point is in last targets.")
    for _, target in ipairs(last_explored_targets) do
        if calculate_distance(point, target) < get_grid_size() * 2 then
            return true
        end
    end
    return false
end

local function add_to_last_targets(point)
   --console.print("Adding point to last targets.")
    table.insert(last_explored_targets, 1, point)
    if #last_explored_targets > max_last_targets then
        table.remove(last_explored_targets)
    end
end

local function find_unstuck_target()
    --console.print("Finding unstuck target.")
    local player_pos = get_player_position()
    local valid_targets = {}

    for x = -unstuck_target_distance, unstuck_target_distance, get_grid_size() do
        for y = -unstuck_target_distance, unstuck_target_distance, get_grid_size() do
            local point = vec3:new(
                player_pos:x() + x,
                player_pos:y() + y,
                player_pos:z()
            )
            point = set_height_of_valid_position(point)

            local distance = calculate_distance(player_pos, point)
            if utility.is_point_walkeable(point) and distance >= 2 and distance <= unstuck_target_distance then
                table.insert(valid_targets, point)
            end
        end
    end

    if #valid_targets > 0 then
        return valid_targets[math.random(#valid_targets)]
    end

    return nil
end



local function find_target(include_explored)
    --console.print("Finding target.")
    last_movement_direction = nil -- Reset the last movement direction

    if include_explored then
        return find_unstuck_target()
    else
        if exploration_mode == "unexplored" then
            local unexplored_target = find_central_unexplored_target()
            if unexplored_target then
                return unexplored_target
            else
                exploration_mode = "explored"
                --console.print("No unexplored areas found. Switching to explored mode.")
                last_explored_targets = {} -- Reset last targets when switching modes
            end
        end

        if exploration_mode == "explored" then
            local explored_target = find_explored_direction_target()
            if explored_target then
                return explored_target
            else
                --console.print("No valid explored targets found. Attempting to move to furthest explored circle.")
                local furthest_circle = find_distant_explored_circle()
                if furthest_circle then
                    return furthest_circle.center
                else
                    --console.print("No explored circles found. Resetting exploration.")
                    --explorer.reset_exploration()
                    exploration_mode = "unexplored"
                    return find_central_unexplored_target()
                end
            end
        end
    end

    return nil
end

-- A* pathfinding functions
local function heuristic(a, b)
    --console.print("Calculating heuristic.")
    return calculate_distance(a, b)
end

local function get_neighbors(point)
    --console.print("Getting neighbors of point.")
    local neighbors = {}
    local directions = {
        { x = 1, y = 0 }, { x = -1, y = 0 }, { x = 0, y = 1 }, { x = 0, y = -1 },
        { x = 1, y = 1 }, { x = 1, y = -1 }, { x = -1, y = 1 }, { x = -1, y = -1 }
    }
    for _, dir in ipairs(directions) do
        local neighbor = vec3:new(
            point:x() + dir.x * get_grid_size(),
            point:y() + dir.y * get_grid_size(),
            point:z()
        )
        neighbor = set_height_of_valid_position(neighbor)
        if utility.is_point_walkeable(neighbor) then
            if not last_movement_direction or
                (dir.x ~= -last_movement_direction.x or dir.y ~= -last_movement_direction.y) then
                table.insert(neighbors, neighbor)
            end
        end
    end

    if #neighbors == 0 and last_movement_direction then
        local back_direction = vec3:new(
            point:x() - last_movement_direction.x * get_grid_size(),
            point:y() - last_movement_direction.y * get_grid_size(),
            point:z()
        )
        back_direction = set_height_of_valid_position(back_direction)
        if utility.is_point_walkeable(back_direction) then
            table.insert(neighbors, back_direction)
        end
    end

    return neighbors
end

local function reconstruct_path(came_from, current)
    local path = { current }
    while came_from[get_grid_key(current)] do
        current = came_from[get_grid_key(current)]
        table.insert(path, 1, current)
    end

    -- Filter points with a less aggressive approach
    local filtered_path = { path[1] }
    for i = 2, #path - 1 do
        local prev = path[i - 1]
        local curr = path[i]
        local next = path[i + 1]

        local dir1 = { x = curr:x() - prev:x(), y = curr:y() - prev:y() }
        local dir2 = { x = next:x() - curr:x(), y = next:y() - curr:y() }

        -- Calculate the angle between directions
        local dot_product = dir1.x * dir2.x + dir1.y * dir2.y
        local magnitude1 = math.sqrt(dir1.x^2 + dir1.y^2)
        local magnitude2 = math.sqrt(dir2.x^2 + dir2.y^2)
        local angle = math.acos(dot_product / (magnitude1 * magnitude2))

        -- Use the angle from settings, converting degrees to radians
        local angle_threshold = math.rad(settings.path_angle)

        -- Keep points if the angle is greater than the threshold from settings
        if angle > angle_threshold then
            table.insert(filtered_path, curr)
        end
    end
    table.insert(filtered_path, path[#path])

    return filtered_path
end

local function a_star(start, goal)
    --console.print("Starting A* pathfinding.")
    local closed_set = {}
    local came_from = {}
    local g_score = { [get_grid_key(start)] = 0 }
    local f_score = { [get_grid_key(start)] = heuristic(start, goal) }
    local iterations = 0

    local open_set = MinHeap.new(function(a, b)
        return f_score[get_grid_key(a)] < f_score[get_grid_key(b)] -- Does that work?
    end)
    open_set:push(start)

    while not open_set:empty() do
        iterations = iterations + 1
        if iterations > 666 then
            --console.print("Max iterations reached, aborting!")
            break
        end

        local current = open_set:pop()
        if calculate_distance(current, goal) < get_grid_size() then
            max_target_distance = target_distance_states[1]
            target_distance_index = 1
            return reconstruct_path(came_from, current)
        end

        closed_set[get_grid_key(current)] = true

        for _, neighbor in ipairs(get_neighbors(current)) do
            if not closed_set[get_grid_key(neighbor)] then
                local tentative_g_score = g_score[get_grid_key(current)] + calculate_distance(current, neighbor)

                if not g_score[get_grid_key(neighbor)] or tentative_g_score < g_score[get_grid_key(neighbor)] then
                    came_from[get_grid_key(neighbor)] = current
                    g_score[get_grid_key(neighbor)] = tentative_g_score
                    f_score[get_grid_key(neighbor)] = g_score[get_grid_key(neighbor)] + heuristic(neighbor, goal)

                    if not open_set:contains(neighbor) then
                        open_set:push(neighbor)
                    end
                end
            end
        end
    end

    if target_distance_index < #target_distance_states then
        target_distance_index = target_distance_index + 1
        max_target_distance = target_distance_states[target_distance_index]
        --console.print("No path found. Reducing max target distance to " .. max_target_distance)
    else
        --console.print("No path found even after reducing max target distance.")
    end

    return nil
end

local last_a_star_call = 0.0
local path_recalculation_interval = 0.5 -- Recalculate path every 2 seconds
local last_path_recalculation = 0.0

local function is_enemies_nearby()
    local player_pos = get_player_position()
    local enemies = actors_manager.get_enemy_npcs()
    local enemies_nearby = false
    for _, enemy in ipairs(enemies) do
        if calculate_distance(player_pos, enemy:get_position()) < 2 then
            enemies_nearby = true
        end
    end
    return enemies_nearby
end

-- Update the move_to_target function
local function move_to_target()
    --console.print("Moving to target")
    if tracker:is_boss_task_running() or explorer.is_task_running then
        return  -- Do not set a path if the boss task is running
    end

    if target_position then
        local player_pos = get_player_position()
        if calculate_distance(player_pos, target_position) > 500 then
            console.print("Target too far, finding new target")
            target_position = find_target(false)
            current_path = {}
            path_index = 1
            return
        end

        if not current_path then
            current_path = {}
        end

        if #current_path == 0 or path_index > #current_path then
            console.print("Calculating new path to target")
            local current_core_time = get_time_since_inject()
            path_index = 1
            current_path = a_star(player_pos, target_position)
            last_a_star_call = current_core_time

            if not current_path then
                console.print("No path found to target. Finding new target.")
                target_position = find_target(false)
                current_path = {}  -- Initialize to empty table instead of nil
                return
            end
        end

        local current_time = get_time_since_inject()
        if current_time - last_path_recalculation > path_recalculation_interval then
            console.print("Recalculating path")
            local player_pos = get_player_position()
            local new_path = a_star(player_pos, target_position)
            if new_path then  -- Only update if we got a valid path
                current_path = new_path
                path_index = 1
            end
            last_path_recalculation = current_time
        end

        if current_path and current_path[path_index] then
            local next_point = current_path[path_index]
            if next_point and not next_point:is_zero() then
                if settings.movement_spell_in_explorer and not is_enemies_nearby() then
                    explorer:movement_spell_to_target(target_position)
                end
                local new_player_pos = get_player_position()
                if calculate_distance(player_pos, new_player_pos) == 0 then
                    pathfinder.request_move(next_point)
                end
            end

            if next_point and next_point.x and not next_point:is_zero() and calculate_distance(player_pos, next_point) < get_grid_size() then
                local direction = {
                    x = next_point:x() - player_pos:x(),
                    y = next_point:y() - player_pos:y()
                }
                last_movement_direction = direction
                path_index = path_index + 1
            end
        end

        if calculate_distance(player_pos, target_position) < 3 then
            console.print("Reached target position")
            mark_area_as_explored(player_pos, exploration_radius)
            if current_circle_target then
                current_circle_target.visited = true
                console.print("Marked current circle as visited")
            end
            current_circle_target = nil
            target_position = nil
            current_path = {}
            path_index = 1

            -- Check for nearby unexplored points when in explored mode
            if exploration_mode == "explored" then
                console.print("In explored mode, checking for nearby unexplored points")
                local nearby_unexplored_point = find_nearest_unexplored_point(player_pos, exploration_radius)
                if nearby_unexplored_point then
                    exploration_mode = "unexplored"
                    target_position = nearby_unexplored_point
                    console.print("Found nearby unexplored area. Switching back to unexplored mode.")
                    last_explored_targets = {}
                    current_path = nil
                    path_index = 1
                else
                    console.print("No nearby unexplored points, finding new explored target")
                    target_position = find_explored_direction_target()
                end
            else
                console.print("Finding new target")
                target_position = find_target(false)
            end
        end
    else
        console.print("No target position, finding new target")
        target_position = find_target(false)
    end
end


local function check_if_stuck()
    --console.print("Checking if character is stuck.")
    local current_pos = get_player_position()
    local current_time = os.time()

    if last_position and calculate_distance(current_pos, last_position) < 0.1 then
        if current_time - last_move_time > stuck_threshold then
            return true
        end
    else
        last_move_time = current_time
    end

    last_position = current_pos

    return false
end

explorer.check_if_stuck = check_if_stuck

function explorer:set_custom_target(target)
    --console.print("Setting custom target.")
    target_position = target
end

function explorer:movement_spell_to_target(target)
    local local_player = get_local_player()
    if not local_player then return end

    local movement_spell_id = {}

    if settings.use_evade_as_movement_spell then
        table.insert(movement_spell_id, 337031) -- General Evade
    end

    if settings.use_teleport then
        table.insert(movement_spell_id, 288106) -- Sorceror Teleport
    end

    if settings.use_teleport_enchanted then
        table.insert(movement_spell_id, 959728) -- Sorceror Teleport Enchanted
    end

    if settings.use_dash then
        table.insert(movement_spell_id, 358761) -- Rogue Dash
    end

    if settings.use_shadow_step then
        table.insert(movement_spell_id, 355606) -- Rogue Shadow Step
    end

    if settings.use_the_hunter then
        table.insert(movement_spell_id, 1663206) -- Spiritborn The Hunter
    end

    if settings.use_soar then
        table.insert(movement_spell_id, 1871821) -- Spiritborn Soar
    end

    if settings.use_rushing_claw then
        table.insert(movement_spell_id, 1871761) -- Spiritborn Rushing Claw
    end

    if settings.use_leap then
        table.insert(movement_spell_id, 196545) -- Barbarian Leap
    end

    -- Check if the dash spell is off cooldown and ready to cast
    for _, spell_id in ipairs(movement_spell_id) do
        if local_player:is_spell_ready(spell_id) then
            -- Cast the dash spell towards the target's position
            local success = cast_spell.position(spell_id, target, 3.0) -- A little delay or else rogue goes turbo in dashing
            if success then
                --console.print("Successfully used movement spell to target.")
            else
                --console.print("Failed to use movement spell.")
            end
        else
            --console.print("Movement spell on cooldown.")
        end
    end
end

-- Expose the move_to_target function
function explorer:move_to_target()
    move_to_target()
end

-- Update the draw_explored_area_bounds function
local function draw_explored_area_bounds()
    for _, circle in ipairs(explored_circles) do
        graphics.circle_3d(circle.center, circle.radius, color_orange(255))
    end
end

local last_call_time = 0.0
local is_player_in_pit = false

-- Move this function definition up, before on_update
local function check_and_create_circle()
    local current_time = get_time_since_inject()
    local player_pos = get_player_position()
    
    console.print(string.format("Current player position: (%.2f, %.2f, %.2f)", 
        player_pos:x(), player_pos:y(), player_pos:z()))
    
    if last_circle_position then
        console.print(string.format("Last circle position: (%.2f, %.2f, %.2f)", 
            last_circle_position.x, last_circle_position.y, last_circle_position.z))
        local distance = calculate_distance(player_pos, last_circle_position)
        local time_diff = current_time - last_circle_time
        console.print(string.format("Distance from last circle: %.2f, Time since last circle: %.2f seconds", 
            distance, time_diff))
    else
        console.print("No previous circle created yet")
    end
    
    if not last_circle_position or 
       (calculate_distance(player_pos, last_circle_position) >= min_distance_between_circles and
        current_time - last_circle_time >= min_time_between_circles) then
        
        console.print("Creating new circle")
        mark_area_as_explored(player_pos, exploration_radius)
        console.print(string.format("Total explored circles: %d", #explored_circles))
        
        last_circle_position = {
            x = player_pos:x(), 
            y = player_pos:y(), 
            z = player_pos:z()
        }
        last_circle_time = current_time
    else
        console.print("Not enough distance or time has passed to create a new circle")
    end
end

on_update(function()
    if not settings.enabled then
        return
    end

    if tracker:is_boss_task_running() or explorer.current_task == "Stupid Ladder" then
        return -- Don't run explorer logic if the boss task or stupid ladder is running
    end

    local world = world.get_current_world()
    if world then
        local world_name = world:get_name()
        if world_name:match("Sanctuary") or world_name:match("Limbo") then
            return
        end
    end

    local current_core_time = get_time_since_inject()
    if current_core_time - last_call_time > 0.85 then
        last_call_time = current_core_time
        is_player_in_pit = (utils.player_in_zone("EGD_MSWK_World_02") or utils.player_in_zone("EGD_MSWK_World_01")) and settings.enabled
        if not is_player_in_pit then
            return
        end

        --console.print("Calling check_walkable_area")
        check_walkable_area()
        check_and_create_circle()
        
        local is_stuck = check_if_stuck()
        if is_stuck then
            --console.print("Character was stuck. Finding new target and attempting revive")
            target_position = find_target(true)
            target_position = set_height_of_valid_position(target_position)
            last_move_time = os.time()
            current_path = {}
            path_index = 1

            local local_player = get_local_player()
            if local_player and local_player:is_dead() then
                revive_at_checkpoint()
            else
                -- Attempt to use a movement spell to the new target
                explorer:movement_spell_to_target(target_position)
            end
        end
    end

    if current_core_time - last_call_time > 0.15 then
        explorer:check_start_location_reached()

        if not explorer.start_location_reached and explorer:set_start_location_target() then
            explorer:move_to_target()
        else
            -- Regular exploration logic
            explorer:move_to_target()
        end
    end

    check_pit_time()
    check_and_reset_dungeons() 
end)

on_render(function()
    if not settings.enabled then
        return
    end

    -- dont slide frames here so drawings feel smooth
    if target_position then
        if target_position.x then
            graphics.text_3d("TARGET_1", target_position, 20, color_red(255))
        else
            if target_position and target_position:get_position() then
                graphics.text_3d("TARGET_2", target_position:get_position(), 20, color_orange(255))
            end
        end
    end

    if current_path then
        for i, point in ipairs(current_path) do
            local color = (i == path_index) and color_green(255) or color_yellow(255)
            graphics.text_3d("PATH_1", point, 15, color)
        end
    end

    graphics.text_2d("Mode: " .. exploration_mode, vec2:new(10, 10), 20, color_white(255))

    -- Add this line to draw the explored area bounds
    draw_explored_area_bounds()
end)


-- Add this new function near other helper functions
local function calculate_distance(pos1, pos2)
    local x1 = type(pos1.x) == "function" and pos1:x() or pos1.x
    local y1 = type(pos1.y) == "function" and pos1:y() or pos1.y
    local z1 = type(pos1.z) == "function" and pos1:z() or pos1.z
    
    local x2 = type(pos2.x) == "function" and pos2:x() or pos2.x
    local y2 = type(pos2.y) == "function" and pos2:y() or pos2.y
    local z2 = type(pos2.z) == "function" and pos2:z() or pos2.z
    
    return math.sqrt((x1 - x2)^2 + (y1 - y2)^2 + (z1 - z2)^2)
end

-- Update the check_and_create_circle function
local function check_and_create_circle()
    local current_time = get_time_since_inject()
    local player_pos = get_player_position()
    
    console.print(string.format("Current player position: (%.2f, %.2f, %.2f)", 
        player_pos:x(), player_pos:y(), player_pos:z()))
    
    if last_circle_position then
        console.print(string.format("Last circle position: (%.2f, %.2f, %.2f)", 
            last_circle_position.x, last_circle_position.y, last_circle_position.z))
        local distance = calculate_distance(player_pos, last_circle_position)
        local time_diff = current_time - last_circle_time
        console.print(string.format("Distance from last circle: %.2f, Time since last circle: %.2f seconds", 
            distance, time_diff))
    else
        console.print("No previous circle created yet")
    end
    
    if not last_circle_position or 
       (calculate_distance(player_pos, last_circle_position) >= min_distance_between_circles and
        current_time - last_circle_time >= min_time_between_circles) then
        
        console.print("Creating new circle")
        mark_area_as_explored(player_pos, exploration_radius)
        console.print(string.format("Total explored circles: %d", #explored_circles))
        
        last_circle_position = {
            x = player_pos:x(), 
            y = player_pos:y(), 
            z = player_pos:z()
        }
        last_circle_time = current_time
    else
        console.print("Not enough distance or time has passed to create a new circle")
    end
end


-- This function should be called in your main update loop
function explorer:update()
    -- ... other update logic ...
    
    check_and_create_circle()
    
    -- ... rest of the update logic ...
end


function explorer.clear_explored_circles()
    explored_circles = {}
    console.print("Cleared all explored circles")
end

return explorer
