local Node = require('src.map.node')

local CombatNode = Node:subclass('CombatNode')

function CombatNode:initialize(id, position, floor_index, enemy_group_id, is_boss_flag)
  Node.initialize(self, id, "combat", position, floor_index)
  self.enemy_group_id = enemy_group_id
  self._is_boss = is_boss_flag or false
end

function CombatNode:is_boss()
  return self._is_boss
end

return CombatNode
