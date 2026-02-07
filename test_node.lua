-- Test script for Node classes
local Node = require('src.map.node')
local CombatNode = require('src.map.combat_node')
local EventNode = require('src.map.event_node')

print("=== Node Class Test ===")

-- Test Node base class
local node = Node:new("node1", "generic", {x = 10, y = 20}, 1)
print("Node type:", node:get_type())
print("Node position:", node:get_position().x, node:get_position().y)
print("Node completed:", node:is_completed())
node:mark_completed()
print("Node completed after mark:", node:is_completed())

print("\n=== CombatNode Test ===")

-- Test CombatNode
local combat_node = CombatNode:new("combat1", {x = 30, y = 40}, 2, "goblin_group", false)
print("CombatNode type:", combat_node:get_type())
print("CombatNode position:", combat_node:get_position().x, combat_node:get_position().y)
print("CombatNode enemy_group_id:", combat_node.enemy_group_id)
print("CombatNode is_boss:", combat_node:is_boss())

-- Test boss combat node
local boss_node = CombatNode:new("boss1", {x = 50, y = 60}, 3, "dragon_boss", true)
print("BossNode type:", boss_node:get_type())
print("BossNode is_boss:", boss_node:is_boss())

print("\n=== EventNode Test ===")

-- Test EventNode
local event_node = EventNode:new("event1", {x = 70, y = 80}, 1, "treasure_chest")
print("EventNode type:", event_node:get_type())
print("EventNode position:", event_node:get_position().x, event_node:get_position().y)
print("EventNode event_id:", event_node.event_id)

print("\n=== Inheritance Test ===")

-- Test inheritance
print("CombatNode is instance of Node:", combat_node:isInstanceOf(Node))
print("EventNode is instance of Node:", event_node:isInstanceOf(Node))
print("Node is instance of CombatNode:", node:isInstanceOf(CombatNode))

print("\n=== All tests completed successfully! ===")
