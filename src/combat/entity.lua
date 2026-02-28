local class = require('lib.middleclass')
local i18n = require('src.i18n.init')
local StatusContainer = require('src.combat.status_container')

---@class Entity
---@field name string
---@field hp number
---@field max_hp number
---@field attack number
---@field defense number
---@field speed number
---@field status_container StatusContainer
local Entity = class('Entity')

---@param name string
---@param stats {hp: number, attack: number, defense: number, speed?: number}
function Entity:initialize(name, stats)
  self.name = name
  self.max_hp = stats.hp
  self.hp = stats.hp
  self.attack = stats.attack
  self.defense = stats.defense
  self.speed = stats.speed or 0
  self.status_container = StatusContainer:new(self, "character")
end

---@param stat_name string
---@param value number
---@return number
function Entity:_resolve_effective_stat(stat_name, value)
  local ctx = {
    owner = self,
    stat = stat_name,
    value = value,
  }
  if self.status_container then
    self.status_container:emit("modify_stat", ctx)
  end
  return math.max(0, ctx.value or 0)
end

---@param amount number
---@return number actual damage dealt
function Entity:take_damage(amount)
  local defense = self:get_defense()
  local actual = math.max(0, amount - defense)
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

---@return {name: string, hp: number, max_hp: number, attack: number, defense: number, speed: number}
function Entity:get_stats()
  return {
    name = self.name,
    hp = self.hp,
    max_hp = self.max_hp,
    attack = self:get_attack(),
    defense = self:get_defense(),
    speed = self:get_speed(),
  }
end

---@return string
function Entity:get_name()
  return i18n.t(self.name)
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
  return self:_resolve_effective_stat("attack", self.attack)
end

---@return number
function Entity:get_defense()
  return self:_resolve_effective_stat("defense", self.defense)
end

---@return number
function Entity:get_speed()
  return self:_resolve_effective_stat("speed", self.speed)
end

---@param status_id string
---@param spec? table
---@return StatusInstance|nil
function Entity:add_status(status_id, spec)
  if not self.status_container then
    return nil
  end
  return self.status_container:add(status_id, spec)
end

---@param uid string
---@return boolean
function Entity:remove_status(uid)
  if not self.status_container then
    return false
  end
  return self.status_container:remove(uid)
end

---@param status_id string
---@return boolean
function Entity:has_status(status_id)
  if not self.status_container then
    return false
  end
  return self.status_container:has(status_id)
end

---@return StatusInstance[]
function Entity:get_statuses()
  if not self.status_container then
    return {}
  end
  return self.status_container:get_all()
end

--- Create a snapshot of current state for simulation
---@return table
function Entity:snapshot()
  return {
    hp = self.hp,
    max_hp = self.max_hp,
    attack = self.attack,
    defense = self.defense,
    speed = self.speed,
    status_container = self.status_container and self.status_container:snapshot() or nil,
  }
end

--- Restore state from a snapshot
---@param snap table
function Entity:restore(snap)
  self.hp = snap.hp
  self.max_hp = snap.max_hp
  self.attack = snap.attack
  self.defense = snap.defense
  self.speed = snap.speed or self.speed
  if self.status_container then
    self.status_container:restore(snap.status_container)
  end
end

return Entity
