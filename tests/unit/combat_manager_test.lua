local TestHelper = require("tests.test_helper")
local CombatManager = require("src.combat.combat_manager")
local Hero = require("src.combat.hero")
local Enemy = require("src.combat.enemy")

local suite = {}

---@return CombatManager, Hero, Enemy
local function create_fixture()
  local combat_manager = CombatManager:new()
  local hero = Hero:new({hp = 50, attack = 8, defense = 2, speed = 8})
  local enemy = Enemy:new("enemy.slime", {
    hp = 24,
    attack = 6,
    defense = 1,
    speed = 6,
  }, {
    {type = "attack", damage_mult = 1.0},
  })
  combat_manager:start_combat(hero, {enemy})
  return combat_manager, hero, enemy
end

---@return nil
function suite.test_temp_defense_bonus_lasts_through_next_turn()
  local combat_manager, hero = create_fixture()

  combat_manager:_apply_temp_defense_bonus(hero, 3)

  TestHelper.assert_equal(hero:get_defense(), 5, "방어 직후에는 즉시 방어도가 올라야 합니다.")
  TestHelper.assert_equal(combat_manager:get_temp_defense_bonus(hero), 3, "임시 방어도 합계가 추적되어야 합니다.")

  combat_manager:next_planning()
  TestHelper.assert_equal(hero:get_defense(), 5, "다음 턴 계획 단계에서도 방어도가 유지되어야 합니다.")
  TestHelper.assert_equal(combat_manager:get_temp_defense_bonus(hero), 3, "다음 턴 시작 전에는 임시 방어가 남아 있어야 합니다.")

  combat_manager:next_planning()
  TestHelper.assert_equal(hero:get_defense(), 2, "한 턴을 지난 뒤에는 임시 방어가 해제되어야 합니다.")
  TestHelper.assert_equal(combat_manager:get_temp_defense_bonus(hero), 0, "만료된 임시 방어는 추적 목록에서도 제거되어야 합니다.")
end

---@return nil
function suite.test_temp_defense_bonus_expires_per_stack()
  local combat_manager, hero = create_fixture()

  combat_manager:_apply_temp_defense_bonus(hero, 3)
  combat_manager:next_planning()
  combat_manager:_apply_temp_defense_bonus(hero, 2)

  TestHelper.assert_equal(hero:get_defense(), 7, "연속 방어는 누적 적용되어야 합니다.")
  TestHelper.assert_equal(combat_manager:get_temp_defense_bonus(hero), 5, "누적 임시 방어 합계가 반영되어야 합니다.")

  combat_manager:next_planning()
  TestHelper.assert_equal(hero:get_defense(), 4, "더 먼저 건 방어만 먼저 만료되어야 합니다.")
  TestHelper.assert_equal(combat_manager:get_temp_defense_bonus(hero), 2, "남은 스택만 유지되어야 합니다.")

  combat_manager:next_planning()
  TestHelper.assert_equal(hero:get_defense(), 2, "마지막 임시 방어도 만료되면 기본 방어도로 돌아와야 합니다.")
  TestHelper.assert_equal(combat_manager:get_temp_defense_bonus(hero), 0, "모든 임시 방어 스택이 정리되어야 합니다.")
end

return suite
