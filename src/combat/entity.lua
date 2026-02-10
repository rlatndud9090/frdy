local class = require('lib.middleclass')

---@class Entity
---@field name string
---@field hp number
---@field max_hp number
---@field attack number
---@field defense number
local Entity = class('Entity')

---@param name string
---@param stats {hp: number, attack: number, defense: number}
function Entity:initialize(name, stats)
  self.name = name
  self.max_hp = stats.hp
  self.hp = stats.hp
  self.attack = stats.attack
  self.defense = stats.defense
end

---@param amount number
---@return number actual damage dealt
function Entity:take_damage(amount)
  local actual = math.max(0, amount - self.defense)
  self.hp = math.max(0, self.hp - actual)
  return actual
end

---@param amount number
function Entity:heal(amount)
  self.hp = math.min(self.max_hp, self.hp + amount)
end

---@return boolean
function Entity:is_alive()
  return self.hp > 0
end

---@return {name: string, hp: number, max_hp: number, attack: number, defense: number}
function Entity:get_stats()
  return {
    name = self.name,
    hp = self.hp,
    max_hp = self.max_hp,
    attack = self.attack,
    defense = self.defense,
  }
end

---@return string
function Entity:get_name()
  return self.name
end

---@return number
function Entity:get_hp()
  return self.hp
end

---@return number
function Entity:get_max_hp()
  return self.max_hp
end

---@return number
function Entity:get_attack()
  return self.attack
end

---@return number
function Entity:get_defense()
  return self.defense
end

return Entity
