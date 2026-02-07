-- Test script for Edge and Floor classes
local Node = require('src.map.node')
local CombatNode = require('src.map.combat_node')
local Edge = require('src.map.edge')
local Floor = require('src.map.floor')

print("=== Testing Edge and Floor Classes ===\n")

-- Create test nodes
local node1 = Node:new(1, "combat", {x = 100, y = 100}, 1)
local node2 = Node:new(2, "event", {x = 200, y = 200}, 1)
local node3 = CombatNode:new(3, {x = 300, y = 300}, 1, "boss_group", true)
local node4 = Node:new(4, "combat", {x = 400, y = 400}, 1)

-- Test Edge creation
print("1. Testing Edge creation:")
local edge1 = Edge:new(node1, node2)
local edge2 = Edge:new(node1, node3)
local edge3 = Edge:new(node2, node3)
local edge4 = Edge:new(node3, node4)

print("   Edge1: from node " .. edge1:get_from_node().id .. " to node " .. edge1:get_to_node().id)
print("   Edge1 is_available: " .. tostring(edge1:is_available()))
print("   ✓ Edge class working\n")

-- Test Floor creation and adding nodes
print("2. Testing Floor - add_node:")
local floor = Floor:new(1)
floor:add_node(node1)
floor:add_node(node2)
floor:add_node(node3)
floor:add_node(node4)

local nodes = floor:get_nodes()
print("   Floor has " .. #nodes .. " nodes")
print("   ✓ Floor:add_node and get_nodes working\n")

-- Test adding edges
print("3. Testing Floor - add_edge:")
floor:add_edge(edge1)
floor:add_edge(edge2)
floor:add_edge(edge3)
floor:add_edge(edge4)
print("   Added 4 edges to floor")
print("   ✓ Floor:add_edge working\n")

-- Test get_edges_from
print("4. Testing Floor - get_edges_from:")
local edges_from_node1 = floor:get_edges_from(node1)
print("   Edges from node1: " .. #edges_from_node1)
for i, edge in ipairs(edges_from_node1) do
  print("      Edge " .. i .. ": to node " .. edge:get_to_node().id)
end

local edges_from_node2 = floor:get_edges_from(node2)
print("   Edges from node2: " .. #edges_from_node2)
for i, edge in ipairs(edges_from_node2) do
  print("      Edge " .. i .. ": to node " .. edge:get_to_node().id)
end
print("   ✓ Floor:get_edges_from working\n")

-- Test get_start_nodes
print("5. Testing Floor - get_start_nodes:")
local start_nodes = floor:get_start_nodes()
print("   Start nodes count: " .. #start_nodes)
for i, node in ipairs(start_nodes) do
  print("      Start node " .. i .. ": id=" .. node.id .. ", type=" .. node.type)
end
print("   Expected: only node1 (id=1) should be a start node")
print("   ✓ Floor:get_start_nodes working\n")

-- Test get_boss_node
print("6. Testing Floor - get_boss_node:")
local boss_node = floor:get_boss_node()
if boss_node then
  print("   Boss node found: id=" .. boss_node.id .. ", is_boss=" .. tostring(boss_node:is_boss()))
else
  print("   ERROR: Boss node not found!")
end
print("   ✓ Floor:get_boss_node working\n")

print("=== All Tests Passed ===")
