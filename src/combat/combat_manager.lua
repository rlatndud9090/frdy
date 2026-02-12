local class = require('lib.middleclass')
local TurnManager = require('src.combat.turn_manager')
local ActionQueue = require('src.combat.action_queue')

---@class CombatManager
---@field hero Hero|nil
---@field enemies Enemy[]|nil
---@field turn_manager TurnManager|nil
---@field action_queue ActionQueue|nil
---@field state string
---@field on_combat_end function|nil
local CombatManager = class('CombatManager')

function CombatManager:initialize()
  self.hero = nil
  self.enemies = nil
  self.turn_manager = nil
  self.action_queue = nil
  self.state = "idle"
  self.on_combat_end = nil
end

---@param hero Hero
---@param enemies Enemy[]
function CombatManager:start_combat(hero, enemies)
  self.hero = hero
  self.enemies = enemies
  self.turn_manager = TurnManager:new(hero, enemies)
  self.action_queue = ActionQueue:new()
  self.state = "active"
  self.turn_manager:prepare_enemy_intents()
end

function CombatManager:end_combat()
  if self.on_combat_end then
    self.on_combat_end(self.state)
  end
end

---@return boolean
function CombatManager:is_combat_over()
  return self.state == "victory" or self.state == "defeat"
end

---@return string
function CombatManager:get_state()
  return self.state
end

---@return TurnManager|nil
function CombatManager:get_turn_manager()
  return self.turn_manager
end

---@return Hero|nil
function CombatManager:get_hero()
  return self.hero
end

---@return Enemy[]|nil
function CombatManager:get_enemies()
  return self.enemies
end

function CombatManager:execute_hero_turn()
  local pattern = self.hero:choose_action({
    target = self.turn_manager:get_living_enemies()[1],
    enemies = self.turn_manager:get_living_enemies(),
  })

  if pattern then
    local living = self.turn_manager:get_living_enemies()
    if #living > 0 then
      pattern:execute(self.hero, living[1])
    end
  end

  -- Victory check
  local living = self.turn_manager:get_living_enemies()
  if #living == 0 then
    self.state = "victory"
  end
end

function CombatManager:execute_enemy_turn()
  local living = self.turn_manager:get_living_enemies()
  for _, enemy in ipairs(living) do
    local pattern = enemy:choose_action({
      actor = enemy,
      target = self.hero,
    })
    if pattern then
      if pattern.type == "attack" then
        pattern:execute(enemy, self.hero)
      elseif pattern.type == "defend" then
        pattern:execute(enemy, enemy)
      end
    end
  end

  -- Defeat check
  if not self.hero:is_alive() then
    self.state = "defeat"
  end
end

function CombatManager:advance_phase()
  if self:is_combat_over() then
    return
  end

  local phase = self.turn_manager:get_phase()

  if phase == "DEMON_LORD_TURN" then
    self.turn_manager:next_turn()
  elseif phase == "HERO_TURN" then
    self:execute_hero_turn()
    self.turn_manager:next_turn()
  elseif phase == "ENEMY_TURN" then
    self:execute_enemy_turn()
    self.turn_manager:next_turn()
  end
end

---@param callback function
function CombatManager:set_on_combat_end(callback)
  self.on_combat_end = callback
end

return CombatManager
