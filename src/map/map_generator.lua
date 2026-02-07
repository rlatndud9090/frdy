local class = require('lib.middleclass')
local CombatNode = require('src.map.combat_node')
local EventNode = require('src.map.event_node')
local Edge = require('src.map.edge')
local Floor = require('src.map.floor')
local Map = require('src.map.map')

local MapGenerator = class('MapGenerator')

local SEGMENT_WIDTH = 300
local MAP_HEIGHT = 720

function MapGenerator:initialize()
    self._next_node_id = 0
end

--- Generate a unique node ID
function MapGenerator:_generate_id()
    self._next_node_id = self._next_node_id + 1
    return self._next_node_id
end

--- Random integer in range [min, max] inclusive
local function rand_int(min_val, max_val)
    return math.random(min_val, max_val)
end

--- Generate a complete Map with all floors
---@param config table Map generation config (from default_config.lua)
---@return table Map instance
function MapGenerator:generate_map(config)
    self._next_node_id = 0
    local map = Map:new()

    for floor_index = 1, config.floor_count do
        local floor = self:generate_floor(floor_index, config)
        map:add_floor(floor)
    end

    return map
end

--- Generate a single floor with column-based DAG structure
---@param floor_index integer 1-based floor index
---@param config table Map generation config
---@return table Floor instance
function MapGenerator:generate_floor(floor_index, config)
    local floor = Floor:new(floor_index)
    local num_columns = rand_int(config.columns_per_floor.min, config.columns_per_floor.max)

    -- Build columns as arrays of nodes
    local columns = {}
    for i = 0, num_columns do
        columns[i] = {}
    end

    -- Column 0: single start CombatNode
    local start_pos = {x = 0, y = MAP_HEIGHT / 2}
    local start_node = CombatNode:new(self:_generate_id(), start_pos, floor_index, nil, false)
    table.insert(columns[0], start_node)
    floor:add_node(start_node)

    -- Middle columns (1 to num_columns - 1)
    for col = 1, num_columns - 1 do
        local node_count = rand_int(config.nodes_per_column.min, config.nodes_per_column.max)
        local x = col * SEGMENT_WIDTH

        for row = 1, node_count do
            -- Distribute y positions evenly across MAP_HEIGHT
            local y = (row / (node_count + 1)) * MAP_HEIGHT
            local pos = {x = x, y = y}

            local node
            if math.random() < config.combat_ratio then
                node = CombatNode:new(self:_generate_id(), pos, floor_index, nil, false)
            else
                node = EventNode:new(self:_generate_id(), pos, floor_index, nil)
            end

            table.insert(columns[col], node)
            floor:add_node(node)
        end
    end

    -- Final column: single boss CombatNode
    local boss_x = num_columns * SEGMENT_WIDTH
    local boss_pos = {x = boss_x, y = MAP_HEIGHT / 2}
    local boss_node = CombatNode:new(self:_generate_id(), boss_pos, floor_index, nil, true)
    table.insert(columns[num_columns], boss_node)
    floor:add_node(boss_node)

    -- Edge generation: connect column i -> column i+1
    for col = 0, num_columns - 1 do
        local current_col = columns[col]
        local next_col = columns[col + 1]

        -- Track which nodes in next column have incoming edges
        local has_incoming = {}
        for j = 1, #next_col do
            has_incoming[j] = false
        end

        -- For each node in current column, create 1~3 edges to next column
        for _, from_node in ipairs(current_col) do
            local num_edges = rand_int(config.edges_per_node.min, config.edges_per_node.max)
            -- Clamp to available targets
            num_edges = math.min(num_edges, #next_col)

            -- Pick random unique targets from next column
            local targets = self:_pick_random_indices(#next_col, num_edges)

            for _, target_idx in ipairs(targets) do
                has_incoming[target_idx] = true
                local edge = Edge:new(from_node, next_col[target_idx])
                floor:add_edge(edge)
            end
        end

        -- Ensure no orphan nodes: any node in next_col without incoming edge
        -- gets connected from a random node in current column
        for j = 1, #next_col do
            if not has_incoming[j] then
                local random_from = current_col[rand_int(1, #current_col)]
                local edge = Edge:new(random_from, next_col[j])
                floor:add_edge(edge)
            end
        end
    end

    return floor
end

--- Pick `count` unique random indices from range [1, max]
---@param max integer Upper bound
---@param count integer Number of indices to pick
---@return table Array of unique indices
function MapGenerator:_pick_random_indices(max, count)
    if count >= max then
        -- Return all indices
        local all = {}
        for i = 1, max do
            all[i] = i
        end
        return all
    end

    local selected = {}
    local used = {}

    while #selected < count do
        local idx = rand_int(1, max)
        if not used[idx] then
            used[idx] = true
            table.insert(selected, idx)
        end
    end

    return selected
end

return MapGenerator
