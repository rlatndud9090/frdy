local TestHelper = require('tests.test_helper')
local Hero = require('src.combat.hero')
local Enemy = require('src.combat.enemy')
local PatternResolver = require('src.combat.pattern_resolver')
local CombatManager = require('src.combat.combat_manager')

local suite = {}

---@return nil
function suite.test_fallback_pattern_is_selected_when_no_other_condition_matches()
  local hero = Hero:new({hp = 50, attack = 8, defense = 2, speed = 8})
  local enemy = Enemy:new('Skeleton', {hp = 25, attack = 8, defense = 2, speed = 5}, {
    {type = "attack", damage_mult = 1.0},
  })

  local pattern = PatternResolver.resolve(hero.action_patterns, {
    actor = hero,
    target = enemy,
    enemies = {enemy},
    cooldown_tracker = hero.cooldown_tracker,
    current_turn = 1,
  })

  TestHelper.assert_true(pattern ~= nil, "기본 fallback 패턴은 선택되어야 합니다.")
  TestHelper.assert_equal(pattern.id, "hero_attack")
end

---@return nil
function suite.test_combat_timeline_includes_and_executes_hero_action()
  local hero = Hero:new({hp = 50, attack = 8, defense = 2, speed = 8})
  local enemy = Enemy:new('Skeleton', {hp = 25, attack = 8, defense = 2, speed = 5}, {
    {type = "attack", damage_mult = 1.0},
  })
  local combat_manager = CombatManager:new()

  combat_manager:start_combat(hero, {enemy})

  local timeline = combat_manager:get_timeline_manager():get_timeline()
  TestHelper.assert_equal(#timeline, 2, "용사와 적 행동이 모두 타임라인에 있어야 합니다.")
  TestHelper.assert_equal(timeline[1]:get_source_type(), "hero")

  combat_manager:start_execution()
  local first_action = combat_manager:execute_next_action()

  TestHelper.assert_true(first_action ~= nil, "첫 번째 실행 액션이 존재해야 합니다.")
  TestHelper.assert_equal(first_action:get_source_type(), "hero")
  TestHelper.assert_equal(enemy:get_hp(), 19, "용사 기본 공격이 실제로 적 체력을 깎아야 합니다.")
end

return suite
