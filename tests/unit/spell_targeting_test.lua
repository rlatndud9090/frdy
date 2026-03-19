local TestHelper = require('tests.test_helper')
local CombatHandler = require('src.handler.combat_handler')
local Hero = require('src.combat.hero')
local Enemy = require('src.combat.enemy')
local Spell = require('src.spell.spell')
local RewardCatalog = require('src.reward.reward_catalog')
local starter_spell_ids = require('data.spells.starter_spell_ids')

---@class SpellTargetingTestSuite
local suite = {}

---@return Hero
local function create_hero()
  return Hero:new({hp = 50, attack = 8, defense = 2, speed = 8})
end

---@return Enemy
local function create_enemy()
  return Enemy:new("enemy.slime", {hp = 24, attack = 6, defense = 1, speed = 7}, {
    {type = "attack", damage_mult = 1.0},
  })
end

---@param hero Hero
---@param enemies Enemy[]
---@return CombatHandler
local function create_handler(hero, enemies)
  local handler = CombatHandler:new()
  local turn_manager = {
    get_living_enemies = function()
      return enemies
    end,
  }

  handler.combat_manager = {
    get_hero = function()
      return hero
    end,
    get_turn_manager = function()
      return turn_manager
    end,
    get_enemies = function()
      return enemies
    end,
  }

  return handler
end

---@return nil
function suite.test_single_target_spells_can_target_hero_and_enemy()
  local hero = create_hero()
  local enemy = create_enemy()
  local handler = create_handler(hero, {enemy})
  local spell = Spell:new(RewardCatalog.get_spell_data("divine_strike"))

  local candidates = handler:_get_single_target_candidates(spell)

  TestHelper.assert_equal(#candidates, 2, "개별 타깃 스펠은 양 진영 모두 후보여야 합니다.")
  TestHelper.assert_equal(candidates[1], hero)
  TestHelper.assert_equal(candidates[2], enemy)
end

---@return nil
function suite.test_faction_target_spells_can_target_hero_and_enemy_sides()
  local hero = create_hero()
  local enemy = create_enemy()
  local handler = create_handler(hero, {enemy})

  local sides = handler:_get_available_faction_sides()

  TestHelper.assert_equal(#sides, 2, "진영 타깃 스펠은 양 진영 모두 후보여야 합니다.")
  TestHelper.assert_equal(sides[1], "hero")
  TestHelper.assert_equal(sides[2], "enemy")
end

---@return nil
function suite.test_single_target_spell_suspicion_depends_on_selected_side()
  local hero = create_hero()
  local enemy = create_enemy()
  local spell = Spell:new(RewardCatalog.get_spell_data("divine_strike"))

  TestHelper.assert_equal(spell:get_signed_suspicion_delta(hero, hero), -6)
  TestHelper.assert_equal(spell:get_signed_suspicion_delta(enemy, hero), 6)
end

---@return nil
function suite.test_faction_target_spell_suspicion_depends_on_selected_side()
  local hero = create_hero()
  local enemy = create_enemy()
  local spell = Spell:new(RewardCatalog.get_spell_data("weaken_foe"))
  local hero_target = {
    target_mode = "char_faction",
    faction = "hero",
    entities = {hero},
    primary = hero,
  }
  local enemy_target = {
    target_mode = "char_faction",
    faction = "enemy",
    entities = {enemy},
    primary = enemy,
  }

  TestHelper.assert_equal(spell:get_signed_suspicion_delta(hero_target, hero), -3)
  TestHelper.assert_equal(spell:get_signed_suspicion_delta(enemy_target, hero), 3)
end

---@return nil
function suite.test_all_target_spell_targets_everyone_without_selection()
  local hero = create_hero()
  local enemy_a = create_enemy()
  local enemy_b = create_enemy()
  local handler = create_handler(hero, {enemy_a, enemy_b})
  local spell = Spell:new(RewardCatalog.get_spell_data("healing_rain"))

  TestHelper.assert_false(handler:_spell_requires_target_selection(spell), "전체 타깃 스펠은 별도 대상 선택이 없어야 합니다.")

  local payload = handler:_get_default_insert_target(spell)

  TestHelper.assert_true(payload ~= nil, "전체 타깃 payload가 생성되어야 합니다.")
  TestHelper.assert_equal(payload.target_mode, "char_all")
  TestHelper.assert_equal(#payload.entities, 3)
  TestHelper.assert_equal(payload.entities[1], hero)
  TestHelper.assert_equal(payload.entities[2], enemy_a)
  TestHelper.assert_equal(payload.entities[3], enemy_b)
end

---@return nil
function suite.test_all_target_spell_has_no_suspicion()
  local hero = create_hero()
  local enemy = create_enemy()
  local spell = Spell:new(RewardCatalog.get_spell_data("healing_rain"))
  local target = {
    target_mode = "char_all",
    entities = {hero, enemy},
    primary = hero,
  }

  TestHelper.assert_equal(spell:get_signed_suspicion_delta(target, hero), 0)
end

---@return nil
function suite.test_starter_spell_pool_includes_all_target_spells()
  local has_healing_rain = false
  local has_rain_of_ruin = false

  for _, spell_id in ipairs(starter_spell_ids) do
    if spell_id == "healing_rain" then
      has_healing_rain = true
    elseif spell_id == "rain_of_ruin" then
      has_rain_of_ruin = true
    end
  end

  TestHelper.assert_true(has_healing_rain, "시작 덱에 치유의 비가 포함되어야 합니다.")
  TestHelper.assert_true(has_rain_of_ruin, "시작 덱에 파멸의 비가 포함되어야 합니다.")
end

---@return nil
function suite.test_legacy_target_scope_faction_maps_to_char_faction()
  local spell = Spell:new({
    id = "legacy_faction",
    name = "Legacy Faction",
    cost = 1,
    suspicion_abs = 1,
    target_scope = "faction",
    effect = {
      type = "buff_attack",
      amount = 1,
    },
  })

  TestHelper.assert_equal(spell:get_target_mode(), "char_faction")
end

---@return nil
function suite.test_legacy_target_mode_any_maps_to_char_single()
  local spell = Spell:new({
    id = "legacy_any",
    name = "Legacy Any",
    cost = 1,
    suspicion_abs = 1,
    target_mode = "any",
    effect = {
      type = "heal",
      amount = 1,
    },
  })

  TestHelper.assert_equal(spell:get_target_mode(), "char_single")
end

return suite
