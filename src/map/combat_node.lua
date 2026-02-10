local Node = require('src.map.node')

---@class CombatNode : Node
---@field enemy_group_id string|nil
---@field _is_boss boolean
local CombatNode = Node:subclass('CombatNode')

---@param id number
---@param position {x: number, y: number}
---@param floor_index number
---@param enemy_group_id? string
---@param is_boss_flag? boolean
function CombatNode:initialize(id, position, floor_index, enemy_group_id, is_boss_flag)
  Node.initialize(self, id, "combat", position, floor_index)
  self.enemy_group_id = enemy_group_id
  self._is_boss = is_boss_flag or false
end

---@return boolean
function CombatNode:is_boss()
  return self._is_boss
end

---@return string|nil
function CombatNode:get_enemy_group()
  return self.enemy_group_id
end

return CombatNode
