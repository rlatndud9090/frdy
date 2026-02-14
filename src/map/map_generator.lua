local class = require("lib.middleclass")
local CombatNode = require("src.map.combat_node")
local EventNode = require("src.map.event_node")
local Edge = require("src.map.edge")
local Floor = require("src.map.floor")
local Map = require("src.map.map")

---@class MapGenerator
---@field _next_node_id number
local MapGenerator = class("MapGenerator")

local MAP_HEIGHT = 720
local DEFAULT_SEGMENT_WIDTH = 300
local DEFAULT_MAX_EDGE_PER_NODE = 3
local MAX_FLOOR_GENERATION_ATTEMPTS = 20
local MAX_PAIR_CONNECTION_ATTEMPTS = 12

---@return nil
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

---@param value number
---@param min_val number
---@param max_val number
---@return number
local function clamp(value, min_val, max_val)
  if value < min_val then
    return min_val
  end
  if value > max_val then
    return max_val
  end
  return value
end

---@param config table
---@return number
function MapGenerator:_get_max_out_edges(config)
  return config.max_out_edges_per_node or DEFAULT_MAX_EDGE_PER_NODE
end

---@param config table
---@return number
function MapGenerator:_get_max_in_edges(config)
  return config.max_in_edges_per_node or DEFAULT_MAX_EDGE_PER_NODE
end

---@param config table
---@return number
function MapGenerator:_get_segment_width(config)
  return config.segment_width or DEFAULT_SEGMENT_WIDTH
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
  for _ = 1, MAX_FLOOR_GENERATION_ATTEMPTS do
    local floor = Floor:new(floor_index)
    local columns, num_columns = self:_build_columns(floor, floor_index, config)

    local edge_specs = {}
    local regular_success = true
    for col = 0, num_columns - 2 do
      local pair_edges = nil
      for _ = 1, MAX_PAIR_CONNECTION_ATTEMPTS do
        pair_edges = self:_build_regular_pair_edges(columns[col], columns[col + 1], config)
        if pair_edges then
          break
        end
      end

      if not pair_edges then
        regular_success = false
        break
      end

      for _, edge_spec in ipairs(pair_edges) do
        table.insert(edge_specs, edge_spec)
      end
    end

    if regular_success then
      local boss_node = columns[num_columns][1]
      local boss_edges = self:_build_boss_edges(columns[num_columns - 1], boss_node)
      for _, edge_spec in ipairs(boss_edges) do
        table.insert(edge_specs, edge_spec)
      end

      for _, edge_spec in ipairs(edge_specs) do
        floor:add_edge(Edge:new(edge_spec.from_node, edge_spec.to_node))
      end

      local valid = self:_validate_floor_graph(floor, columns, config)
      if valid then
        return floor
      end
    end
  end

  error("Failed to generate a valid floor with current map constraints")
end

---@param floor Floor
---@param floor_index number
---@param config table
---@return table<number, Node[]>, number
function MapGenerator:_build_columns(floor, floor_index, config)
  local num_columns = rand_int(config.columns_per_floor.min, config.columns_per_floor.max)
  local columns = {}
  for col = 0, num_columns do
    columns[col] = {}
  end

  self:_build_start_column(floor, columns, floor_index, config)
  self:_build_middle_columns(floor, columns, floor_index, config, num_columns)
  self:_build_boss_column(floor, columns, floor_index, config, num_columns)

  return columns, num_columns
end

---@param floor Floor
---@param columns table<number, Node[]>
---@param floor_index number
---@param config table
---@return nil
function MapGenerator:_build_start_column(floor, columns, floor_index, config)
  local start_cfg = config.start_nodes_per_column or {min = 4, max = 5}
  local node_count = rand_int(start_cfg.min, start_cfg.max)

  for row = 1, node_count do
    local y = (row / (node_count + 1)) * MAP_HEIGHT
    local node = CombatNode:new(self:_generate_id(), {x = 0, y = y}, floor_index, nil, false)
    table.insert(columns[0], node)
    floor:add_node(node)
  end
end

---@param floor Floor
---@param columns table<number, Node[]>
---@param floor_index number
---@param config table
---@param num_columns number
---@return nil
function MapGenerator:_build_middle_columns(floor, columns, floor_index, config, num_columns)
  local segment_width = self:_get_segment_width(config)
  for col = 1, num_columns - 1 do
    local node_count = rand_int(config.nodes_per_column.min, config.nodes_per_column.max)
    local x = col * segment_width

    for row = 1, node_count do
      local y = (row / (node_count + 1)) * MAP_HEIGHT
      local node = nil
      if math.random() < config.combat_ratio then
        node = CombatNode:new(self:_generate_id(), {x = x, y = y}, floor_index, nil, false)
      else
        node = EventNode:new(self:_generate_id(), {x = x, y = y}, floor_index, nil)
      end

      table.insert(columns[col], node)
      floor:add_node(node)
    end
  end
end

---@param floor Floor
---@param columns table<number, Node[]>
---@param floor_index number
---@param config table
---@param num_columns number
---@return nil
function MapGenerator:_build_boss_column(floor, columns, floor_index, config, num_columns)
  local segment_width = self:_get_segment_width(config)
  local boss_x = num_columns * segment_width
  local boss_pos = {x = boss_x, y = MAP_HEIGHT / 2}
  local boss_node = CombatNode:new(self:_generate_id(), boss_pos, floor_index, nil, true)
  table.insert(columns[num_columns], boss_node)
  floor:add_node(boss_node)
end

---@param current_idx number
---@param next_count number
---@return number[]
function MapGenerator:_candidate_next_indices(current_idx, next_count)
  local result = {}
  local seen = {}
  for offset = -1, 1 do
    local next_idx = clamp(current_idx + offset, 1, next_count)
    if not seen[next_idx] then
      seen[next_idx] = true
      table.insert(result, next_idx)
    end
  end
  return result
end

---@param current_idx number
---@param next_idx number
---@param next_count number
---@return boolean
function MapGenerator:_is_neighbor_index(current_idx, next_idx, next_count)
  local candidates = self:_candidate_next_indices(current_idx, next_count)
  for _, idx in ipairs(candidates) do
    if idx == next_idx then
      return true
    end
  end
  return false
end

---@param existing_pairs table[]
---@param from_idx number
---@param to_idx number
---@return boolean
function MapGenerator:_would_cross(existing_pairs, from_idx, to_idx)
  for _, pair in ipairs(existing_pairs) do
    local from_diff = pair.from_idx - from_idx
    local to_diff = pair.to_idx - to_idx
    if from_diff * to_diff < 0 then
      return true
    end
  end
  return false
end

---@param candidates number[]
---@param count_table table<number, number>
---@return number
function MapGenerator:_pick_lowest_count_random(candidates, count_table)
  local min_count = math.huge
  local best = {}

  for _, idx in ipairs(candidates) do
    local count = count_table[idx] or 0
    if count < min_count then
      min_count = count
      best = {idx}
    elseif count == min_count then
      table.insert(best, idx)
    end
  end

  return best[rand_int(1, #best)]
end

---@param current_col Node[]
---@param next_col Node[]
---@param config table
---@return table[]|nil
function MapGenerator:_build_regular_pair_edges(current_col, next_col, config)
  local max_out = self:_get_max_out_edges(config)
  local max_in = self:_get_max_in_edges(config)

  local out_count = {}
  local in_count = {}
  local has_edge = {}
  local pairs = {}

  for current_idx = 1, #current_col do
    out_count[current_idx] = 0
    has_edge[current_idx] = {}
  end
  for next_idx = 1, #next_col do
    in_count[next_idx] = 0
  end

  ---@param current_idx number
  ---@param next_idx number
  ---@return boolean
  local function can_add(current_idx, next_idx)
    if has_edge[current_idx][next_idx] then
      return false
    end
    if out_count[current_idx] >= max_out then
      return false
    end
    if in_count[next_idx] >= max_in then
      return false
    end
    if not self:_is_neighbor_index(current_idx, next_idx, #next_col) then
      return false
    end
    if self:_would_cross(pairs, current_idx, next_idx) then
      return false
    end
    return true
  end

  ---@param current_idx number
  ---@param next_idx number
  ---@return nil
  local function add_pair(current_idx, next_idx)
    out_count[current_idx] = out_count[current_idx] + 1
    in_count[next_idx] = in_count[next_idx] + 1
    has_edge[current_idx][next_idx] = true
    table.insert(pairs, {from_idx = current_idx, to_idx = next_idx})
  end

  -- Ensure every node in next column has at least one incoming edge.
  for next_idx = 1, #next_col do
    local candidates = {}
    for current_idx = 1, #current_col do
      if can_add(current_idx, next_idx) then
        table.insert(candidates, current_idx)
      end
    end
    if #candidates == 0 then
      return nil
    end
    local chosen_current = self:_pick_lowest_count_random(candidates, out_count)
    add_pair(chosen_current, next_idx)
  end

  -- Ensure every node in current column has at least one outgoing edge.
  for current_idx = 1, #current_col do
    if out_count[current_idx] == 0 then
      local candidates = {}
      for next_idx = 1, #next_col do
        if can_add(current_idx, next_idx) then
          table.insert(candidates, next_idx)
        end
      end
      if #candidates == 0 then
        return nil
      end
      local chosen_next = self:_pick_lowest_count_random(candidates, in_count)
      add_pair(current_idx, chosen_next)
    end
  end

  -- Add optional extra edges up to per-node target (max 3).
  for current_idx = 1, #current_col do
    local desired = rand_int(config.edges_per_node.min, config.edges_per_node.max)
    local target_out = math.min(desired, max_out)

    while out_count[current_idx] < target_out do
      local candidates = {}
      for next_idx = 1, #next_col do
        if can_add(current_idx, next_idx) then
          table.insert(candidates, next_idx)
        end
      end
      if #candidates == 0 then
        break
      end
      local chosen_next = self:_pick_lowest_count_random(candidates, in_count)
      add_pair(current_idx, chosen_next)
    end
  end

  local edge_specs = {}
  for _, pair in ipairs(pairs) do
    table.insert(edge_specs, {
      from_node = current_col[pair.from_idx],
      to_node = next_col[pair.to_idx],
    })
  end

  return edge_specs
end

---@param previous_col Node[]
---@param boss_node Node
---@return table[]
function MapGenerator:_build_boss_edges(previous_col, boss_node)
  local edge_specs = {}
  for _, from_node in ipairs(previous_col) do
    table.insert(edge_specs, {
      from_node = from_node,
      to_node = boss_node,
    })
  end
  return edge_specs
end

---@param floor Floor
---@param columns table<number, Node[]>
---@return table<Node, number>, table<Node, number>
function MapGenerator:_build_degree_maps(floor, columns)
  local incoming = {}
  local outgoing = {}

  for col = 0, #columns do
    for _, node in ipairs(columns[col]) do
      incoming[node] = 0
      outgoing[node] = 0
    end
  end

  for _, edge in ipairs(floor:get_edges()) do
    local from_node = edge:get_from_node()
    local to_node = edge:get_to_node()
    outgoing[from_node] = (outgoing[from_node] or 0) + 1
    incoming[to_node] = (incoming[to_node] or 0) + 1
  end

  return incoming, outgoing
end

---@param floor Floor
---@param columns table<number, Node[]>
---@param config table
---@return boolean
function MapGenerator:_validate_floor_graph(floor, columns, config)
  local final_col = #columns
  local start_cfg = config.start_nodes_per_column or {min = 4, max = 5}
  local middle_cfg = config.nodes_per_column
  local max_out = self:_get_max_out_edges(config)
  local max_in = self:_get_max_in_edges(config)
  local boss_node = columns[final_col][1]
  local incoming, outgoing = self:_build_degree_maps(floor, columns)

  if #columns[0] < start_cfg.min or #columns[0] > start_cfg.max then
    return false
  end
  if #columns[final_col] ~= 1 then
    return false
  end
  if not boss_node:is_boss() then
    return false
  end

  for col = 1, final_col - 1 do
    local count = #columns[col]
    if count < middle_cfg.min or count > middle_cfg.max then
      return false
    end
  end

  for col = 0, final_col do
    for _, node in ipairs(columns[col]) do
      local node_in = incoming[node] or 0
      local node_out = outgoing[node] or 0

      if node == boss_node then
        if node_out ~= 0 then
          return false
        end
      else
        if node_in > max_in or node_out > max_out then
          return false
        end
      end
    end
  end

  -- Start nodes must be independent entry points.
  for _, start_node in ipairs(columns[0]) do
    if (incoming[start_node] or 0) ~= 0 then
      return false
    end
    if (outgoing[start_node] or 0) < 1 then
      return false
    end
  end

  for col = 1, final_col - 1 do
    for _, node in ipairs(columns[col]) do
      if (incoming[node] or 0) < 1 then
        return false
      end
      if (outgoing[node] or 0) < 1 then
        return false
      end
    end
  end

  -- Boss must receive all nodes from previous column.
  local expected_boss_in = #columns[final_col - 1]
  if (incoming[boss_node] or 0) ~= expected_boss_in then
    return false
  end

  -- Validate regular column pairs: only neighbor connections and non-crossing.
  for col = 0, final_col - 2 do
    local current_col = columns[col]
    local next_col = columns[col + 1]
    local current_index = {}
    local next_index = {}
    for idx, node in ipairs(current_col) do
      current_index[node] = idx
    end
    for idx, node in ipairs(next_col) do
      next_index[node] = idx
    end

    local pair_edges = {}
    for _, edge in ipairs(floor:get_edges()) do
      local from_node = edge:get_from_node()
      local to_node = edge:get_to_node()
      local from_idx = current_index[from_node]
      local to_idx = next_index[to_node]
      if from_idx and to_idx then
        if not self:_is_neighbor_index(from_idx, to_idx, #next_col) then
          return false
        end
        if self:_would_cross(pair_edges, from_idx, to_idx) then
          return false
        end
        table.insert(pair_edges, {from_idx = from_idx, to_idx = to_idx})
      end
    end
  end

  return true
end

return MapGenerator
