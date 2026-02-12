local class = require('lib.middleclass')
local CombatManager = require('src.combat.combat_manager')
local Gauge = require('src.ui.gauge')
local Button = require('src.ui.button')
local SpellPanel = require('src.ui.spell_panel')
local i18n = require('src.i18n.init')

---@class CombatHandler
---@field combat_manager CombatManager
---@field spell_book SpellBook|nil
---@field mana_manager ManaManager|nil
---@field suspicion_manager SuspicionManager|nil
---@field hero_gauge Gauge
---@field enemy_gauges Gauge[]
---@field end_turn_button Button
---@field spell_panel SpellPanel
---@field on_combat_end function|nil
---@field enemy_world_x number
---@field enemy_world_y number
---@field ui_offset_y number
---@field active boolean
---@field phase_timer number
---@field combat_log string[]
---@field log_timer number
local CombatHandler = class('CombatHandler')

function CombatHandler:initialize()
  self.combat_manager = CombatManager:new()
  self.spell_book = nil
  self.mana_manager = nil
  self.suspicion_manager = nil

  -- UI
  self.hero_gauge = Gauge:new(50, 520, 200, 25, "entity.hero", {0.2, 0.8, 0.2})
  self.enemy_gauges = {}

  self.end_turn_button = Button:new(1100, 620, 120, 40, "ui.end_turn")
  self.end_turn_button:set_on_click(function()
    self:_end_demon_lord_turn()
  end)
  self.end_turn_button:set_visible(false)

  self.spell_panel = SpellPanel:new()
  self.spell_panel:set_visible(false)
  self.spell_panel:set_on_play(function(spell, index)
    self:_play_spell(spell, index)
  end)

  self.on_combat_end = nil

  -- 애니메이션 필드
  self.enemy_world_x = 1280 + 200
  self.enemy_world_y = 300
  self.ui_offset_y = 200

  self.active = false
  self.phase_timer = 0

  self.combat_log = {}
  self.log_timer = 0
end

function CombatHandler:set_on_combat_end(callback)
  self.on_combat_end = callback
end

--- 전투 시작
function CombatHandler:start_combat(hero, enemies, spell_book, mana_manager, suspicion_manager)
  self.spell_book = spell_book
  self.mana_manager = mana_manager
  self.suspicion_manager = suspicion_manager
  self.combat_log = {}

  self.combat_manager:start_combat(hero, enemies)
  self.combat_manager:set_on_combat_end(function(result)
    if self.on_combat_end then
      self.on_combat_end(result)
    end
  end)

  -- 적 HP 게이지 생성
  self.enemy_gauges = {}
  for i, enemy in ipairs(enemies) do
    local g = Gauge:new(800, 460 + (i-1) * 35, 180, 25, enemy:get_name(), {0.8, 0.2, 0.2})
    g:set_value(enemy:get_hp(), enemy:get_max_hp())
    table.insert(self.enemy_gauges, g)
  end

  -- hero gauge 업데이트
  self.hero_gauge:set_value(hero:get_hp(), hero:get_max_hp())

  -- 첫 턴 시작 (DEMON_LORD_TURN)
  self:_start_demon_lord_turn()
end

function CombatHandler:activate()
  self.active = true
end

function CombatHandler:deactivate()
  self.active = false
  self.spell_panel:set_visible(false)
  self.end_turn_button:set_visible(false)
end

function CombatHandler:update(dt)
  if not self.active then return end

  local tm = self.combat_manager:get_turn_manager()
  if not tm then return end

  local phase = tm:get_phase()

  -- 로그 타이머
  if self.log_timer > 0 then
    self.log_timer = self.log_timer - dt
  end

  -- HERO_TURN / ENEMY_TURN은 자동 진행
  if phase == "HERO_TURN" or phase == "ENEMY_TURN" then
    self.phase_timer = self.phase_timer - dt
    if self.phase_timer <= 0 then
      self:_auto_advance()
    end
  end

  -- UI 업데이트
  self.spell_panel:update(dt)
  self.end_turn_button:update(dt)

  -- 게이지 업데이트
  self:_update_gauges()
end

function CombatHandler:draw_world()
  -- 적 그리기 (빨간 원)
  local enemies = self.combat_manager:get_enemies() or {}
  for i, enemy in ipairs(enemies) do
    if enemy:is_alive() then
      local offset_y = (i - 1) * 70
      love.graphics.setColor(0.8, 0.2, 0.2, 1)
      love.graphics.circle('fill', self.enemy_world_x, self.enemy_world_y + offset_y, 30)
      -- 적 이름
      love.graphics.setColor(1, 1, 1, 1)
      love.graphics.printf(enemy:get_name(), self.enemy_world_x - 50, self.enemy_world_y + offset_y - 45, 100, 'center')
      -- intent 표시
      local intent = enemy:get_intent()
      if intent then
        if intent.type == "attack" then
          love.graphics.setColor(1, 0.4, 0.4, 1)
        else
          love.graphics.setColor(0.4, 0.7, 1, 1)
        end
        love.graphics.printf(intent.description, self.enemy_world_x - 60, self.enemy_world_y + offset_y + 35, 120, 'center')
      end
    end
  end
  love.graphics.setColor(1, 1, 1, 1)
end

function CombatHandler:draw_ui()
  love.graphics.push()
  love.graphics.translate(0, self.ui_offset_y)

  local tm = self.combat_manager:get_turn_manager()
  local phase = tm and tm:get_phase() or ""
  local turn_count = tm and tm:get_turn_count() or 0

  -- 턴 정보
  love.graphics.setColor(1, 1, 1, 0.9)
  local phase_text = i18n.t("combat.in_combat")
  if phase == "DEMON_LORD_TURN" then
    phase_text = i18n.t("combat.demon_lord_turn", {turn = turn_count})
  elseif phase == "HERO_TURN" then
    phase_text = i18n.t("combat.hero_turn")
  elseif phase == "ENEMY_TURN" then
    phase_text = i18n.t("combat.enemy_turn")
  end
  love.graphics.printf(phase_text, 0, 20, 1280, 'center')

  -- 마나 표시
  if self.mana_manager then
    love.graphics.setColor(0, 0.5, 1, 1)
    love.graphics.printf(
      i18n.t("combat.mana_display", {current = self.mana_manager:get_current(), max = self.mana_manager:get_max()}),
      0, 45, 1280, 'center'
    )
  end

  -- Hero intent 표시
  local hero = self.combat_manager:get_hero()
  if hero and hero:is_alive() then
    local hero_intent = hero:get_intent()
    if hero_intent then
      love.graphics.setColor(1, 0.8, 0, 0.8)
      love.graphics.print(i18n.t("combat.hero_intent", {desc = hero_intent.description, damage = hero_intent.value}), 50, 490)
    end
  end

  -- 게이지
  self.hero_gauge:draw()
  for _, g in ipairs(self.enemy_gauges) do
    g:draw()
  end

  -- 전투 로그 (최근 3개)
  love.graphics.setColor(1, 1, 1, 0.7)
  local log_y = 70
  local start_idx = math.max(1, #self.combat_log - 2)
  for i = start_idx, #self.combat_log do
    love.graphics.printf(self.combat_log[i], 300, log_y, 680, 'center')
    log_y = log_y + 18
  end

  -- SpellPanel + 턴 종료 버튼
  self.spell_panel:draw()
  self.end_turn_button:draw()

  love.graphics.pop()
  love.graphics.setColor(1, 1, 1, 1)
end

function CombatHandler:mousepressed(x, y, button)
  if not self.active then return end
  local adjusted_y = y - self.ui_offset_y

  self.spell_panel:mousepressed(x, adjusted_y, button)
  self.end_turn_button:mousepressed(x, adjusted_y, button)
end

--- 마왕 턴 시작
function CombatHandler:_start_demon_lord_turn()
  if not self.spell_book or not self.mana_manager then return end

  local tm = self.combat_manager:get_turn_manager()
  if not tm then return end

  -- 새 턴 시작: 사용 기록 초기화
  self.spell_book:start_planning()

  -- SpellPanel 갱신
  self.spell_panel:set_spell_book(self.spell_book)
  self.spell_panel:set_mana_manager(self.mana_manager)
  self.spell_panel:set_visible(true)
  self.end_turn_button:set_visible(true)

  table.insert(self.combat_log, i18n.t("combat.demon_lord_turn_log", {turn = tm:get_turn_count()}))
end

--- 마법 사용
---@param spell Spell
---@param index number
function CombatHandler:_play_spell(spell, index)
  local hero = self.combat_manager:get_hero()
  local enemies = self.combat_manager:get_enemies()
  if not hero or not enemies then return end

  -- 타겟 결정: effect type에 따라
  local effect = spell:get_effect()
  ---@type Entity
  local target = hero  -- 기본: hero
  if effect and (effect.type == "damage" or effect.type == "debuff_attack") then
    -- 첫 번째 살아있는 적을 타겟
    local living = self.combat_manager:get_turn_manager():get_living_enemies()
    if #living > 0 then
      target = living[1]
    end
  end

  -- 마법 사용
  local context = {
    hero = hero,
    enemies = enemies,
    mana_manager = self.mana_manager,
    suspicion_manager = self.suspicion_manager,
  }
  spell:play(target, context)

  -- 사용 기록
  self.spell_book:mark_used(spell)

  -- 로그
  table.insert(self.combat_log, i18n.t("combat.demon_lord_used_spell", {spell = spell:get_name()}))

  -- 게이지 갱신
  self:_update_gauges()
end

--- 마왕 턴 종료
function CombatHandler:_end_demon_lord_turn()
  self.spell_panel:set_visible(false)
  self.end_turn_button:set_visible(false)

  -- 턴 종료 (추가 처리 없음, start_planning에서 초기화)

  -- advance_phase: DEMON_LORD → HERO
  self.combat_manager:advance_phase()

  -- 전투 종료 체크
  if self.combat_manager:is_combat_over() then
    self.combat_manager:end_combat()
    return
  end

  -- HERO 턴 자동 진행 타이머
  self.phase_timer = 0.8
  table.insert(self.combat_log, i18n.t("combat.hero_acts"))
end

--- 자동 진행 (HERO/ENEMY 턴)
function CombatHandler:_auto_advance()
  local tm = self.combat_manager:get_turn_manager()
  if not tm then return end

  local phase = tm:get_phase()

  if phase == "HERO_TURN" then
    self.combat_manager:advance_phase()

    if self.combat_manager:is_combat_over() then
      self.combat_manager:end_combat()
      return
    end

    -- ENEMY 턴 타이머
    self.phase_timer = 0.8
    table.insert(self.combat_log, i18n.t("combat.enemy_acts"))

  elseif phase == "ENEMY_TURN" then
    self.combat_manager:advance_phase()

    if self.combat_manager:is_combat_over() then
      self.combat_manager:end_combat()
      return
    end

    -- 다시 DEMON_LORD 턴
    self:_start_demon_lord_turn()
  end
end

--- 게이지 갱신
function CombatHandler:_update_gauges()
  local hero = self.combat_manager:get_hero()
  if hero then
    self.hero_gauge:set_value(hero:get_hp(), hero:get_max_hp())
  end

  local enemies = self.combat_manager:get_enemies() or {}
  for i, enemy in ipairs(enemies) do
    if self.enemy_gauges[i] then
      self.enemy_gauges[i]:set_value(enemy:get_hp(), enemy:get_max_hp())
    end
  end
end

return CombatHandler
