local class = require('lib.middleclass')

local Floor = class('Floor')

function Floor:initialize(floor_index)
  self.floor_index = floor_index
  self.nodes = {}
  self.edges = {}
end

function Floor:add_node(node)
  table.insert(self.nodes, node)
end

function Floor:add_edge(edge)
  table.insert(self.edges, edge)
end

function Floor:get_nodes()
  return self.nodes
end

function Floor:get_edges_from(node)
  local result = {}
  for _, edge in ipairs(self.edges) do
    if edge:get_from_node() == node then
      table.insert(result, edge)
    end
  end
  return result
end

function Floor:get_start_nodes()
  local has_incoming = {}

  -- Mark all nodes that have incoming edges
  for _, edge in ipairs(self.edges) do
    has_incoming[edge:get_to_node()] = true
  end

  -- Return nodes with no incoming edges
  local result = {}
  for _, node in ipairs(self.nodes) do
    if not has_incoming[node] then
      table.insert(result, node)
    end
  end

  return result
end

function Floor:get_boss_node()
  for _, node in ipairs(self.nodes) do
    if node:get_type() == "combat" and node:is_boss() then
      return node
    end
  end
  return nil
end

return Floor
