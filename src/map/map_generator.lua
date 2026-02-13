local class = require('lib.middleclass')
local CombatNode = require('src.map.combat_node')
local EventNode = require('src.map.event_node')
local Edge = require('src.map.edge')
local Floor = require('src.map.floor')
local Map = require('src.map.map')

---@class MapGenerator
---@field _next_node_id number
local MapGenerator = class('MapGenerator')

local SEGMENT_WIDTH = 300
local MAP_HEIGHT = 720
local MAX_EDGE_PER_NODE = 2

function MapGenerator:initialize()
    self._next_node_id = 0
end

---@return number
function MapGenerator:_generate_id()
    self._next_node_id = self._next_node_id + 1
    return self._next_node_id
end

---@param min_val number
---@param max_val number
---@return number
local function rand_int(min_val, max_val)
    return math.random(min_val, max_val)
end

---@param config table
---@return Map
function MapGenerator:generate_map(config)
    self._next_node_id = 0
    local map = Map:new()

    for floor_index = 1, config.floor_count do
        local floor = self:generate_floor(floor_index, config)
        map:add_floor(floor)
    end

    return map
end

---@param floor_index number
---@param config table
---@return Floor
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
        self:_connect_columns_with_limits(floor, current_col, next_col, config)
    end

    return floor
end

---현재 컬럼과 다음 컬럼을 최대 인/아웃 엣지 2개 제약으로 연결한다.
---@param floor Floor
---@param current_col Node[]
---@param next_col Node[]
---@param config table
function MapGenerator:_connect_columns_with_limits(floor, current_col, next_col, config)
    local out_count = {}
    local in_count = {}
    local has_edge = {}

    for i = 1, #current_col do
        out_count[i] = 0
        has_edge[i] = {}
    end

    for j = 1, #next_col do
        in_count[j] = 0
    end

    -- 1) 다음 컬럼의 모든 노드가 최소 1개 인-엣지를 갖도록 보장
    for next_idx = 1, #next_col do
        local candidates = {}
        for current_idx = 1, #current_col do
            if out_count[current_idx] < MAX_EDGE_PER_NODE and not has_edge[current_idx][next_idx] then
                table.insert(candidates, current_idx)
            end
        end

        if #candidates == 0 then
            break
        end

        local chosen_idx = candidates[rand_int(1, #candidates)]
        out_count[chosen_idx] = out_count[chosen_idx] + 1
        in_count[next_idx] = in_count[next_idx] + 1
        has_edge[chosen_idx][next_idx] = true
        floor:add_edge(Edge:new(current_col[chosen_idx], next_col[next_idx]))
    end

    -- 2) 현재 컬럼의 모든 노드가 최소 1개 아웃-엣지를 갖도록 보장
    for current_idx = 1, #current_col do
        if out_count[current_idx] == 0 then
            local candidates = {}
            for next_idx = 1, #next_col do
                if in_count[next_idx] < MAX_EDGE_PER_NODE and not has_edge[current_idx][next_idx] then
                    table.insert(candidates, next_idx)
                end
            end

            if #candidates > 0 then
                local chosen_next_idx = candidates[rand_int(1, #candidates)]
                out_count[current_idx] = out_count[current_idx] + 1
                in_count[chosen_next_idx] = in_count[chosen_next_idx] + 1
                has_edge[current_idx][chosen_next_idx] = true
                floor:add_edge(Edge:new(current_col[current_idx], next_col[chosen_next_idx]))
            end
        end
    end

    -- 3) 설정값 범위 내에서 추가 엣지 생성 (단, 인/아웃 2개 제한 엄수)
    for current_idx = 1, #current_col do
        local from_node = current_col[current_idx]
        local desired_out = rand_int(config.edges_per_node.min, config.edges_per_node.max)
        local target_out = math.min(desired_out, MAX_EDGE_PER_NODE)

        while out_count[current_idx] < target_out do
            local candidates = {}
            for next_idx = 1, #next_col do
                if in_count[next_idx] < MAX_EDGE_PER_NODE and not has_edge[current_idx][next_idx] then
                    table.insert(candidates, next_idx)
                end
            end

            if #candidates == 0 then
                break
            end

            local chosen_next_idx = candidates[rand_int(1, #candidates)]
            out_count[current_idx] = out_count[current_idx] + 1
            in_count[chosen_next_idx] = in_count[chosen_next_idx] + 1
            has_edge[current_idx][chosen_next_idx] = true
            floor:add_edge(Edge:new(from_node, next_col[chosen_next_idx]))
        end
    end
end

return MapGenerator
